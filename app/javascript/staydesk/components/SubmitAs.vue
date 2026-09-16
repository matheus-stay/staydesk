<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import { useWorkspace } from '../composables/useWorkspace';
import { useNextConversation } from '../composables/useNextConversation';

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

const status = ref(null);
const isSubmitting = ref(false);
const enabled = computed(
  () => composer.value.submit_as !== false && role.value !== 'light'
);
const selected = computed(
  () => status.value || currentChat.value.status || 'open'
);

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
    if (selected.value !== currentChat.value.status) {
      await store.dispatch('toggleStatus', {
        conversationId: props.conversationId,
        status: selected.value,
      });
    }
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
    <select
      v-model="status"
      class="h-8 rounded-lg border border-n-weak bg-n-alpha-1 px-2 text-sm text-n-slate-12"
      :disabled="disabled"
    >
      <option v-for="option in STATUSES" :key="option" :value="option">
        {{ t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${option}.TEXT`) }}
      </option>
    </select>
    <Button
      sm
      solid
      blue
      :disabled="disabled"
      :is-loading="isSubmitting"
      @click="submit"
    >
      {{
        t('STAYDESK.SUBMIT_AS.BUTTON', {
          status: t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${selected}.TEXT`),
        })
      }}
    </Button>
  </div>
</template>
