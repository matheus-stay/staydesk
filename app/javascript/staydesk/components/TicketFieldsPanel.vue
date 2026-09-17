<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import ConversationAction from 'dashboard/routes/dashboard/conversation/ConversationAction.vue';
import ConversationInfo from 'dashboard/routes/dashboard/conversation/ConversationInfo.vue';
import ConversationParticipant from 'dashboard/routes/dashboard/conversation/ConversationParticipant.vue';
import NextInView from './NextInView.vue';
import SlaBadge from './SlaBadge.vue';
import SlaDetail from './SlaDetail.vue';
import { useWorkspace } from '../composables/useWorkspace';

// O painel de propriedades do ticket, como no Zendesk: responsável, time,
// prioridade e os atributos personalizados na ordem que a área de trabalho
// do time define (workspace.conversation.fields).
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

const STANDARD_FIELDS = ['assignee', 'team', 'priority', 'labels'];

const { t } = useI18n();
const store = useStore();
const { fields } = useWorkspace();
const openSections = ref({
  participants: false,
  information: true,
});
const currentChat = useMapGetter('getSelectedChat');
const conversationMetadataGetter = useMapGetter(
  'conversationMetadata/getConversationMetadata'
);
const contactGetter = useMapGetter('contacts/getContact');
const attributesByModel = useMapGetter('attributes/getAttributesByModel');

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
const customAttributes = computed(
  () => currentChat.value.custom_attributes || {}
);

const showActions = computed(
  () =>
    !Array.isArray(fields.value) ||
    fields.value.some(field => STANDARD_FIELDS.includes(field))
);

// Atributos personalizados: os da área de trabalho, na ordem dela; sem
// configuração, todos os definidos para conversa.
const customFields = computed(() => {
  const definitions = attributesByModel.value('conversation_attribute') || [];
  if (!Array.isArray(fields.value)) return definitions;
  return fields.value
    .filter(field => !STANDARD_FIELDS.includes(field))
    .map(key =>
      definitions.find(definition => definition.attribute_key === key)
    )
    .filter(Boolean);
});

const saveAttributes = async attributes => {
  try {
    await store.dispatch('updateCustomAttributes', {
      conversationId: props.conversationId,
      customAttributes: attributes,
    });
    useAlert(t('CUSTOM_ATTRIBUTES.FORM.UPDATE.SUCCESS'));
  } catch {
    useAlert(t('CUSTOM_ATTRIBUTES.FORM.UPDATE.ERROR'));
  }
};

const onUpdate = (key, value) =>
  saveAttributes({ ...customAttributes.value, [key]: value });

const onDelete = key => {
  const { [key]: removed, ...rest } = customAttributes.value;
  return saveAttributes(rest);
};

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
      class="flex h-14 min-h-14 items-center justify-between gap-2 border-b border-n-weak px-4"
    >
      <div class="min-w-0">
        <p class="truncate text-sm font-semibold text-n-slate-12">
          {{ currentChat.meta?.sender?.name }}
        </p>
        <p class="text-xs tabular-nums text-n-slate-10">
          {{ `#${conversationId}` }}
        </p>
      </div>
      <div class="flex items-center gap-2">
        <SlaBadge :attributes="customAttributes" />
        <NextInView :conversation-id="conversationId" />
      </div>
    </header>

    <div class="flex-1 overflow-y-auto pb-8 pt-3">
      <div class="flex flex-col gap-2 px-3">
        <section
          v-if="showActions"
          class="rounded border border-n-weak bg-n-surface-1 px-3 pb-3"
        >
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

        <section class="rounded border border-n-weak bg-n-surface-1 px-3 pb-3">
          <h2
            class="border-b border-n-weak py-3 text-sm font-medium text-n-slate-12"
          >
            {{ t('STAYDESK.SLA.DETAIL_TITLE') }}
          </h2>
          <SlaDetail
            class="pt-3"
            :conversation-id="conversationId"
            :attributes="customAttributes"
          />
        </section>

        <section
          v-if="customFields.length"
          class="rounded border border-n-weak bg-n-surface-1 px-3 pb-3"
        >
          <h2
            class="border-b border-n-weak py-3 text-sm font-medium text-n-slate-12"
          >
            {{ t('STAYDESK.FIELDS_TITLE') }}
          </h2>
          <div class="flex flex-col gap-2 pt-3">
            <CustomAttribute
              v-for="definition in customFields"
              :key="definition.id"
              :attribute-key="definition.attribute_key"
              :attribute-type="definition.attribute_display_type"
              :values="definition.attribute_values"
              :label="definition.attribute_display_name"
              :description="definition.attribute_description"
              :value="customAttributes[definition.attribute_key]"
              show-actions
              :attribute-regex="definition.regex_pattern"
              :regex-cue="definition.regex_cue"
              :contact-id="contactId"
              @update="onUpdate"
              @delete="onDelete"
            />
          </div>
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
