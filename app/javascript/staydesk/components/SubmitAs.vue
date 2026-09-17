<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import { useWorkspace } from '../composables/useWorkspace';
import { useNextConversation } from '../composables/useNextConversation';
import { useTicketStatusStore } from '../store/ticketStatus';

// "Enviar como <status>", como no Zendesk: manda a resposta e muda o status numa
// ação só. Depois, conforme a área de trabalho: fica, abre a próxima ou fecha.
const props = defineProps({
  conversationId: { type: [Number, String], required: true },
  send: { type: Function, required: true },
  disabled: { type: Boolean, default: false },
});

const STATUSES = ['open', 'pending', 'snoozed', 'resolved'];

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { composer, role } = useWorkspace();
const { goToNext, goToList } = useNextConversation();
const currentChat = useMapGetter('getSelectedChat');
const ticketStatuses = useTicketStatusStore();

const status = ref(null);
const isSubmitting = ref(false);
const enabled = computed(
  () => composer.value.submit_as !== false && role.value !== 'light'
);
ticketStatuses.ensureLoaded();
// Com catálogo (SPEC-10) o valor é "ts:<id>" do status personalizado; sem, o status base.
const currentValue = computed(() => {
  if (ticketStatuses.enabled) {
    const current = ticketStatuses.forConversation(currentChat.value);
    return current ? `ts:${current.id}` : null;
  }
  return currentChat.value.status || 'open';
});
const selected = computed(() => status.value || currentValue.value);
const statusOptions = computed(() =>
  ticketStatuses.enabled
    ? ticketStatuses.active.map(item => ({
        value: `ts:${item.id}`,
        label: item.name,
      }))
    : STATUSES.map(value => ({
        value,
        label: t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${value}.TEXT`),
      }))
);
const selectedLabel = computed(
  () =>
    statusOptions.value.find(option => option.value === selected.value)
      ?.label || ''
);

const changeStatus = async () => {
  if (selected.value === currentValue.value) return;
  if (String(selected.value).startsWith('ts:')) {
    const data = await ticketStatuses.apply(
      props.conversationId,
      Number(selected.value.slice(3))
    );
    await store.dispatch('updateConversation', data);
    return;
  }
  await store.dispatch('toggleStatus', {
    conversationId: props.conversationId,
    status: selected.value,
  });
};

const afterSend = async () => {
  const mode = composer.value.after_send;
  if (mode === 'next') await goToNext(props.conversationId, router);
  if (mode === 'close') await goToList(router);
};

const submit = async () => {
  if (props.disabled || isSubmitting.value) return;
  isSubmitting.value = true;
  try {
    await props.send();
    await changeStatus();
    await afterSend();
  } catch {
    useAlert(t('STAYDESK.SUBMIT_AS.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div
    v-if="enabled"
    class="flex items-center justify-end gap-2 border-t border-n-weak px-3 py-2"
  >
    <Select v-model="status" :options="statusOptions" :disabled="disabled" />
    <Button
      sm
      solid
      blue
      :disabled="disabled"
      :is-loading="isSubmitting"
      @click="submit"
    >
      {{ t('STAYDESK.SUBMIT_AS.BUTTON', { status: selectedLabel }) }}
    </Button>
  </div>
</template>
