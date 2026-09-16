<script setup>
import { computed, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import ConversationAction from 'dashboard/routes/dashboard/conversation/ConversationAction.vue';
import ConversationInfo from 'dashboard/routes/dashboard/conversation/ConversationInfo.vue';
import ConversationParticipant from 'dashboard/routes/dashboard/conversation/ConversationParticipant.vue';
import SlaBadge from './SlaBadge.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  inboxId: {
    type: [Number, String],
    default: undefined,
  },
});

const store = useStore();
const openSections = ref({
  participants: false,
  information: true,
});
const currentChat = useMapGetter('getSelectedChat');
const conversationMetadataGetter = useMapGetter(
  'conversationMetadata/getConversationMetadata'
);
const contactGetter = useMapGetter('contacts/getContact');

const conversationMetadata = computed(() =>
  conversationMetadataGetter.value(props.conversationId)
);
const conversationAttributes = computed(
  () => conversationMetadata.value.additional_attributes || {}
);
const contactId = computed(() => currentChat.value.meta?.sender?.id);
const contact = computed(() => contactGetter.value(contactId.value));
const contactAttributes = computed(
  () => contact.value.additional_attributes || {}
);

onMounted(() => {
  store.dispatch('attributes/get', 0);
});
</script>

<template>
  <aside
    :aria-label="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_INFO')"
    class="hidden h-full w-[19.375rem] min-w-[19.375rem] flex-col overflow-hidden border-e border-n-weak bg-n-surface-1 lg:flex"
  >
    <header
      class="flex h-14 min-h-14 items-center justify-between border-b border-n-weak px-4"
    >
      <div class="min-w-0">
        <p class="truncate text-sm font-semibold text-n-slate-12">
          {{ currentChat.meta?.sender?.name }}
        </p>
        <p class="text-xs tabular-nums text-n-slate-10">
          {{ `#${conversationId}` }}
        </p>
      </div>
      <SlaBadge :attributes="currentChat.custom_attributes" />
    </header>

    <div class="flex-1 overflow-y-auto pb-8 pt-3">
      <div class="flex flex-col gap-2 px-3">
        <section class="rounded border border-n-weak bg-n-surface-1 px-3 pb-3">
          <h2
            class="border-b border-n-weak py-3 text-sm font-medium text-n-slate-12"
          >
            {{ $t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_ACTIONS') }}
          </h2>
          <ConversationAction
            class="pt-3"
            :conversation-id="conversationId"
            :inbox-id="inboxId"
          />
        </section>

        <AccordionItem
          :title="$t('CONVERSATION_PARTICIPANTS.SIDEBAR_TITLE')"
          :is-open="openSections.participants"
          @toggle="value => (openSections.participants = value)"
        >
          <ConversationParticipant
            :conversation-id="conversationId"
            :inbox-id="inboxId"
          />
        </AccordionItem>

        <AccordionItem
          :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_INFO')"
          :is-open="openSections.information"
          compact
          @toggle="value => (openSections.information = value)"
        >
          <ConversationInfo
            :conversation-attributes="conversationAttributes"
            :contact-attributes="contactAttributes"
          />
        </AccordionItem>
      </div>
    </div>
  </aside>
</template>
