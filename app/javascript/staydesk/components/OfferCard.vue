<script setup>
import { onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import Button from 'dashboard/components-next/button/Button.vue';
import { useOffers } from '../composables/useOffers';

// O convite aparece no canto, com o relógio correndo. Aceitar abre a conversa;
// recusar devolve para a fila na hora.
const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const { offer, secondsLeft, start, accept, decline } = useOffers();

const avisar = () => {
  if (!('Notification' in window) || Notification.permission !== 'granted')
    return;
  const titulo = t('STAYDESK.OFFERS.NOTIFICATION', {
    contact: offer.value.contact_name || '',
  });
  const aviso = new Notification(titulo, {
    body: offer.value.last_message || '',
  });
  setTimeout(() => aviso.close(), 10000);
};

const aoAceitar = async () => {
  const convite = await accept();
  if (!convite) return;
  router.push(
    accountScopedRoute('inbox_conversation', {
      conversation_id: convite.conversation_id,
    })
  );
};

watch(offer, novo => {
  if (novo) avisar();
});

onMounted(() => {
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission();
  }
  start();
});
</script>

<template>
  <div
    v-if="offer"
    class="fixed bottom-4 right-4 z-50 w-80 rounded-xl border border-n-weak bg-n-solid-1 p-4 shadow-lg"
  >
    <div class="flex items-center justify-between">
      <p class="text-sm font-medium text-n-slate-12">
        {{ t('STAYDESK.OFFERS.TITLE', { inbox: offer.inbox_name }) }}
      </p>
      <span class="text-sm font-medium text-n-amber-11">
        {{ t('STAYDESK.OFFERS.SECONDS_LEFT', { seconds: secondsLeft }) }}
      </span>
    </div>
    <p class="mt-1 text-sm text-n-slate-12">{{ offer.contact_name }}</p>
    <p
      v-if="offer.last_message"
      class="mt-1 line-clamp-2 text-xs text-n-slate-11"
    >
      {{ offer.last_message }}
    </p>
    <div class="mt-3 flex justify-end gap-2">
      <Button sm faded slate @click="decline">
        {{ t('STAYDESK.OFFERS.DECLINE') }}
      </Button>
      <Button sm solid blue @click="aoAceitar">
        {{ t('STAYDESK.OFFERS.ACCEPT') }}
      </Button>
    </div>
  </div>
</template>
