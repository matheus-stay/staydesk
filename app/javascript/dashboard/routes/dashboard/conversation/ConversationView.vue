<script>
import { mapGetters } from 'vuex';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAccount } from 'dashboard/composables/useAccount';
import ChatList from '../../../components/ChatList.vue';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox.vue';
import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import CmdBarConversationSnooze from 'dashboard/routes/dashboard/commands/CmdBarConversationSnooze.vue';
import { emitter } from 'shared/helpers/mitt';
import SidepanelSwitch from 'dashboard/components-next/Conversation/SidepanelSwitch.vue';
import ConversationWorkspaceTabs from 'staydesk/components/ConversationWorkspaceTabs.vue';
import ConversationSidebar from 'dashboard/components/widgets/conversation/ConversationSidebar.vue';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
import { useConversationWorkspaceTabs } from 'staydesk/composables/useConversationWorkspaceTabs';
import TicketFieldsPanel from 'staydesk/components/TicketFieldsPanel.vue';

export default {
  components: {
    ChatList,
    ConversationBox,
    CmdBarConversationSnooze,
    SidepanelSwitch,
    ConversationWorkspaceTabs,
    ConversationSidebar,
    TicketFieldsPanel,
  },
  beforeRouteLeave(to, from, next) {
    // Clear selected state if navigating away from a conversation to a route without a conversationId to prevent stale data issues
    // and resolves timing issues during navigation with conversation view and other screens
    if (this.conversationId) {
      this.$store.dispatch('clearSelectedState');
    }
    next(); // Continue with navigation
  },
  props: {
    inboxId: {
      type: [String, Number],
      default: 0,
    },
    conversationId: {
      type: [String, Number],
      default: 0,
    },
    label: {
      type: String,
      default: '',
    },
    teamId: {
      type: String,
      default: '',
    },
    conversationType: {
      type: String,
      default: '',
    },
    foldersId: {
      type: [String, Number],
      default: 0,
    },
  },
  setup() {
    const { uiSettings, updateUISettings } = useUISettings();
    const { accountId } = useAccount();
    const {
      openTabs,
      activeConversationId,
      openTab,
      closeTab,
      setActiveConversation,
    } = useConversationWorkspaceTabs(accountId);

    return {
      uiSettings,
      updateUISettings,
      accountId,
      openTabs,
      activeConversationId,
      openTab,
      closeTab,
      setActiveConversation,
    };
  },
  data() {
    return {
      showSearchModal: false,
    };
  },
  computed: {
    ...mapGetters({
      chatList: 'getAllConversations',
      currentChat: 'getSelectedChat',
    }),
    showConversationList() {
      return !this.conversationId;
    },
    showMessageView() {
      return Boolean(this.conversationId);
    },
    workspaceTabs() {
      const drafts = this.$store.state.draftMessages?.records || {};
      return this.openTabs.map(tab => ({
        ...tab,
        hasDraft: ['REPLY', 'NOTE'].some(mode =>
          this.hasMeaningfulDraft(drafts[`draft-${tab.id}-${mode}`])
        ),
      }));
    },
    conversationListUrl() {
      const {
        params: { inbox_id: inboxId, label, teamId, id: customViewId },
        name,
      } = this.$route;
      const conversationTypeMap = {
        conversation_through_mentions: 'mention',
        conversation_through_participating: 'participating',
        conversation_through_unattended: 'unattended',
      };

      return conversationListPageURL({
        accountId: this.accountId,
        inboxId,
        label,
        teamId,
        conversationType: conversationTypeMap[name],
        customViewId,
      });
    },
    isOnExpandedLayout() {
      const {
        LAYOUT_TYPES: { CONDENSED },
      } = wootConstants;
      const { conversation_display_type: conversationDisplayType = CONDENSED } =
        this.uiSettings;
      return conversationDisplayType !== CONDENSED;
    },

    shouldShowSidebar() {
      if (!this.currentChat.id) {
        return false;
      }

      const { is_contact_sidebar_open: isContactSidebarOpen } = this.uiSettings;
      return isContactSidebarOpen;
    },
  },
  watch: {
    conversationId() {
      this.fetchConversationIfUnavailable();
      if (this.conversationId) {
        this.setActiveConversation(this.conversationId);
        this.registerCurrentConversationTab();
      }
    },
    'currentChat.id'() {
      this.registerCurrentConversationTab();
    },
  },

  created() {
    // Clear selected state early if no conversation is selected
    // This prevents child components from accessing stale data
    // and resolves timing issues during navigation
    // with conversation view and other screens
    if (!this.conversationId) {
      this.$store.dispatch('clearSelectedState');
    }
  },

  mounted() {
    this.$store.dispatch('agents/get');
    this.$store.dispatch('portals/index');
    this.initialize();
    this.$watch('$store.state.route', () => this.initialize());
    this.$watch('chatList.length', () => {
      this.setActiveChat();
    });
  },

  methods: {
    onConversationLoad() {
      this.fetchConversationIfUnavailable();
    },
    initialize() {
      this.$store.dispatch('setActiveInbox', this.inboxId);
      this.setActiveChat();
    },
    toggleConversationLayout() {
      const { LAYOUT_TYPES } = wootConstants;
      const {
        conversation_display_type:
          conversationDisplayType = LAYOUT_TYPES.CONDENSED,
      } = this.uiSettings;
      const newViewType =
        conversationDisplayType === LAYOUT_TYPES.CONDENSED
          ? LAYOUT_TYPES.EXPANDED
          : LAYOUT_TYPES.CONDENSED;
      this.updateUISettings({
        conversation_display_type: newViewType,
        previously_used_conversation_display_type: newViewType,
      });
    },
    fetchConversationIfUnavailable() {
      if (!this.conversationId) {
        return;
      }
      const chat = this.findConversation();
      if (!chat) {
        this.$store.dispatch('getConversation', this.conversationId);
      }
    },
    findConversation() {
      const conversationId = parseInt(this.conversationId, 10);
      const [chat] = this.chatList.filter(c => c.id === conversationId);
      return chat;
    },
    setActiveChat() {
      if (this.conversationId) {
        const selectedConversation = this.findConversation();
        // If conversation doesn't exist or selected conversation is same as the active
        // conversation, don't set active conversation.
        if (
          !selectedConversation ||
          selectedConversation.id === this.currentChat.id
        ) {
          return;
        }
        const { messageId } = this.$route.query;
        this.$store
          .dispatch('setActiveChat', {
            data: selectedConversation,
            after: messageId,
          })
          .then(() => {
            emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
          });
      } else {
        this.$store.dispatch('clearSelectedState');
      }
    },
    onSearch() {
      this.showSearchModal = true;
    },
    closeSearch() {
      this.showSearchModal = false;
    },
    hasMeaningfulDraft(draft) {
      if (!draft) return false;

      return (
        String(draft)
          .replace(/<[^>]*>/g, '')
          .replace(/&nbsp;/g, ' ')
          .trim().length > 0
      );
    },
    registerCurrentConversationTab() {
      if (
        !this.conversationId ||
        Number(this.currentChat.id) !== Number(this.conversationId)
      ) {
        return;
      }

      const title =
        this.currentChat.additional_attributes?.mail_subject ||
        this.currentChat.meta?.sender?.name ||
        `#${this.currentChat.id}`;

      this.openTab({
        id: this.currentChat.id,
        title,
        path: this.$route.fullPath,
      });
    },
    selectWorkspaceTab(tab) {
      this.setActiveConversation(tab.id);
      if (tab.path !== this.$route.fullPath) {
        this.$router.push(tab.path);
      }
    },
    closeWorkspaceTab(tab) {
      const isActiveTab = Number(tab.id) === Number(this.conversationId);
      if (!this.closeTab(tab.id) || !isActiveTab) {
        return;
      }

      const nextTab = this.openTabs.find(
        openTabItem =>
          Number(openTabItem.id) === Number(this.activeConversationId)
      );
      this.$router.push(nextTab?.path || this.conversationListUrl);
    },
  },
};
</script>

<template>
  <section class="flex h-full min-h-0 min-w-0 w-full flex-col bg-n-surface-1">
    <ConversationWorkspaceTabs
      :tabs="workspaceTabs"
      :active-conversation-id="conversationId"
      @select="selectWorkspaceTab"
      @close="closeWorkspaceTab"
    />
    <div class="flex min-h-0 min-w-0 flex-1 gap-0 p-0">
      <ChatList
        :show-conversation-list="showConversationList"
        :conversation-inbox="inboxId"
        :label="label"
        :team-id="teamId"
        :conversation-type="conversationType"
        :folders-id="foldersId"
        :is-on-expanded-layout="isOnExpandedLayout || !conversationId"
        @conversation-load="onConversationLoad"
      />
      <TicketFieldsPanel
        v-if="currentChat.id"
        :conversation-id="currentChat.id"
        :inbox-id="currentChat.inbox_id"
      />
      <ConversationBox
        v-if="showMessageView"
        :inbox-id="inboxId"
        :is-on-expanded-layout="isOnExpandedLayout"
      >
        <SidepanelSwitch v-if="currentChat.id" />
      </ConversationBox>
      <ConversationSidebar
        v-if="shouldShowSidebar"
        :current-chat="currentChat"
      />
      <CmdBarConversationSnooze />
    </div>
  </section>
</template>
