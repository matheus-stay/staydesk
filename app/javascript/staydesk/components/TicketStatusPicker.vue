<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useConversationRequiredAttributes } from 'dashboard/composables/useConversationRequiredAttributes';
import Button from 'dashboard/components-next/button/Button.vue';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';
import { useTicketStatusStore } from '../store/ticketStatus';

// Seletor de status do ticket no cabeçalho da conversa (SPEC-10): substitui o
// botão Resolver do upstream quando a conta tem catálogo de status personalizados.
const { t } = useI18n();
const store = useStore();
const ticketStatuses = useTicketStatusStore();
const currentChat = useMapGetter('getSelectedChat');
const { checkMissingAttributes } = useConversationRequiredAttributes();

const [isOpen, toggle] = useToggle(false);
const isSaving = ref(false);
const pendingStatus = ref(null);
const resolveAttributesModalRef = ref(null);

const current = computed(() =>
  ticketStatuses.forConversation(currentChat.value)
);
const options = computed(() => ticketStatuses.active);

const applyStatus = async ticketStatus => {
  isSaving.value = true;
  try {
    const data = await ticketStatuses.apply(
      currentChat.value.id,
      ticketStatus.id
    );
    await store.dispatch('updateConversation', data);
    useAlert(t('STAYDESK.TICKET_STATUS.PICKER.SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.TICKET_STATUS.PICKER.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const choose = ticketStatus => {
  toggle(false);
  if (ticketStatus.id === current.value?.id) return;
  if (ticketStatus.base_status === 'resolved') {
    const customAttributes = currentChat.value.custom_attributes || {};
    const { hasMissing, missing } = checkMissingAttributes(customAttributes);
    if (hasMissing) {
      pendingStatus.value = ticketStatus;
      resolveAttributesModalRef.value?.open(missing, customAttributes, {
        id: currentChat.value.id,
        snoozedUntil: null,
      });
      return;
    }
  }
  applyStatus(ticketStatus);
};

// Atributos obrigatórios preenchidos no modal do upstream: resolve por ele e
// depois grava o status escolhido (o alinhamento automático usaria o padrão).
const handleResolveWithAttributes = async ({ attributes, context }) => {
  try {
    await store.dispatch('toggleStatus', {
      conversationId: context.id,
      status: 'resolved',
      snoozedUntil: context.snoozedUntil,
      customAttributes: attributes,
    });
    if (pendingStatus.value) await applyStatus(pendingStatus.value);
  } catch {
    useAlert(t('STAYDESK.TICKET_STATUS.PICKER.ERROR'));
  } finally {
    pendingStatus.value = null;
  }
};
</script>

<template>
  <div v-on-clickaway="() => toggle(false)" class="relative">
    <Button
      size="sm"
      variant="outline"
      color="slate"
      :is-loading="isSaving"
      icon="i-lucide-chevron-down"
      trailing-icon
      @click="toggle()"
    >
      <span
        class="inline-block size-2 rounded-full"
        :style="{ backgroundColor: current?.color || '#545DFF' }"
      />
      {{ current?.name || t('STAYDESK.TICKET_STATUS.PICKER.LABEL') }}
    </Button>
    <ul
      v-if="isOpen"
      class="absolute right-0 top-full z-50 mt-1 min-w-48 rounded-xl border border-n-weak bg-n-solid-1 p-1 shadow-lg"
    >
      <li v-for="option in options" :key="option.id">
        <button
          type="button"
          class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-left text-sm text-n-slate-12 hover:bg-n-alpha-1"
          :class="{ 'bg-n-alpha-1': option.id === current?.id }"
          @click="choose(option)"
        >
          <span
            class="inline-block size-2 rounded-full"
            :style="{ backgroundColor: option.color || '#545DFF' }"
          />
          <span class="flex-1">{{ option.name }}</span>
          <span v-if="option.description" class="text-xs text-n-slate-11">
            {{ option.description }}
          </span>
        </button>
      </li>
    </ul>
    <ConversationResolveAttributesModal
      ref="resolveAttributesModalRef"
      @submit="handleResolveWithAttributes"
    />
  </div>
</template>
