<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import SlaBadge from './SlaBadge.vue';
import { DEFAULT_COLUMNS } from '../helpers/teamViewQuery';
import { tempoRelativo } from '../helpers/tempo';
import { useTicketStatusStore } from '../store/ticketStatus';

// A lista de conversas em tabela, como a view do Zendesk: colunas configuradas
// pela área de trabalho do time, ordenação vinda da lista, clique abre a conversa.
const props = defineProps({
  conversationList: { type: Array, default: () => [] },
  columns: { type: Array, default: () => DEFAULT_COLUMNS },
  isLoading: { type: Boolean, default: false },
  showEndOfListMessage: { type: Boolean, default: false },
});

const emit = defineEmits(['loadMore']);

const { t, locale } = useI18n();
const route = useRoute();
const router = useRouter();
const currentChat = useMapGetter('getSelectedChat');
const inboxes = useMapGetter('inboxes/getInboxes');
const ticketStatuses = useTicketStatusStore();
ticketStatuses.ensureLoaded();

const visibleColumns = computed(() =>
  props.columns.length ? props.columns : DEFAULT_COLUMNS
);

const inboxName = id =>
  inboxes.value.find(inbox => inbox.id === id)?.name || '';

const subject = conversation =>
  conversation.custom_attributes?.assunto ||
  conversation.additional_attributes?.mail_subject ||
  conversation.last_non_activity_message?.content ||
  '';

const seconds = value => tempoRelativo(value, locale.value);

const cell = (conversation, column) => {
  switch (column) {
    case 'status':
      return (
        ticketStatuses.forConversation(conversation)?.name ||
        t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${conversation.status}.TEXT`)
      );
    case 'subject':
      return subject(conversation);
    case 'contact':
      return conversation.meta?.sender?.name || '';
    case 'inbox':
      return inboxName(conversation.inbox_id);
    case 'created_at':
      return seconds(conversation.created_at);
    case 'waiting_since':
      return seconds(
        conversation.waiting_since || conversation.last_activity_at
      );
    case 'assignee':
      return conversation.meta?.assignee?.name || '';
    case 'team':
      return conversation.meta?.team?.name || '';
    case 'priority':
      return conversation.priority
        ? t(
            `CONVERSATION.PRIORITY.OPTIONS.${conversation.priority.toUpperCase()}`
          )
        : '';
    case 'labels':
      return (conversation.labels || []).join(', ');
    default:
      return '';
  }
};

const isActive = conversation => currentChat.value?.id === conversation.id;

const open = conversation => {
  router.push({
    path: frontendURL(
      conversationUrl({
        accountId: route.params.accountId,
        id: conversation.id,
      })
    ),
  });
};
</script>

<template>
  <div class="flex h-full flex-col overflow-auto">
    <table class="w-full text-left text-sm">
      <thead
        class="sticky top-0 bg-n-surface-1 text-xs uppercase text-n-slate-11"
      >
        <tr>
          <th
            v-for="column in visibleColumns"
            :key="column"
            class="whitespace-nowrap border-b border-n-weak px-3 py-2 font-medium"
          >
            {{ t(`STAYDESK.TEAM_VIEWS.COLUMN.${column}`) }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="conversation in conversationList"
          :key="conversation.id"
          class="cursor-pointer border-b border-n-weak hover:bg-n-alpha-1"
          :class="{ 'bg-n-alpha-2': isActive(conversation) }"
          @click="open(conversation)"
        >
          <td
            v-for="column in visibleColumns"
            :key="column"
            class="max-w-xs truncate px-3 py-2 text-n-slate-12"
            :class="{ 'font-medium': conversation.unread_count > 0 }"
          >
            <SlaBadge
              v-if="column === 'sla'"
              :attributes="conversation.custom_attributes"
            />
            <template v-else>{{ cell(conversation, column) }}</template>
          </td>
        </tr>
      </tbody>
    </table>
    <div class="flex justify-center py-3">
      <Button
        v-if="!showEndOfListMessage"
        sm
        ghost
        slate
        :is-loading="isLoading"
        @click="emit('loadMore')"
      >
        {{ t('CHAT_LIST.LOAD_MORE_CONVERSATIONS') }}
      </Button>
      <span v-else class="text-xs text-n-slate-11">
        {{ t('CHAT_LIST.EOF') }}
      </span>
    </div>
  </div>
</template>
