<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import { useWorkspace } from '../composables/useWorkspace';
import { useNextConversation } from '../composables/useNextConversation';
import { useTicketStatusStore } from '../store/ticketStatus';

// "Enviar como <status>", como no Zendesk: um botão dividido. A parte grande
// manda a resposta e muda o status numa ação só; a seta escolhe outro status
// para enviar. Depois, conforme a área de trabalho: fica, abre a próxima ou fecha.
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
const aberto = ref(false);
const raiz = ref(null);

const escolher = valor => {
  status.value = valor;
  aberto.value = false;
};
// Clique fora fecha a lista.
const foraDaLista = evento => {
  if (raiz.value && !raiz.value.contains(evento.target)) aberto.value = false;
};
onMounted(() => document.addEventListener('click', foraDaLista));
onBeforeUnmount(() => document.removeEventListener('click', foraDaLista));
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
    ref="raiz"
    class="relative flex items-center justify-end border-t border-n-weak px-3 py-2"
  >
    <div class="inline-flex items-stretch">
      <Button
        sm
        solid
        blue
        class="rounded-e-none"
        :disabled="disabled"
        :is-loading="isSubmitting"
        @click="submit"
      >
        {{ t('STAYDESK.SUBMIT_AS.BUTTON', { status: selectedLabel }) }}
      </Button>
      <Button
        sm
        solid
        blue
        icon="i-lucide-chevron-down"
        class="rounded-s-none border-s border-white/30 !px-1.5"
        :disabled="disabled"
        :aria-label="t('STAYDESK.SUBMIT_AS.PICK')"
        @click="aberto = !aberto"
      />
    </div>
    <ul
      v-if="aberto"
      role="menu"
      class="absolute bottom-full right-3 z-20 mb-1 min-w-52 list-none rounded-lg border border-n-weak bg-n-solid-1 py-1 shadow-lg"
    >
      <li v-for="option in statusOptions" :key="option.value">
        <button
          type="button"
          role="menuitem"
          class="flex w-full items-center justify-between gap-3 px-3 py-1.5 text-left text-sm text-n-slate-12 hover:bg-n-alpha-2"
          @click="escolher(option.value)"
        >
          {{ t('STAYDESK.SUBMIT_AS.BUTTON', { status: option.label }) }}
          <span
            v-if="option.value === selected"
            class="i-lucide-check size-3.5 text-n-brand"
          />
        </button>
      </li>
    </ul>
  </div>
</template>
