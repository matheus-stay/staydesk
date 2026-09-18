<script setup>
import { onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import Button from 'dashboard/components-next/button/Button.vue';
import { useOffers } from '../composables/useOffers';

// Os convites aparecem no canto, um cartão por conversa, cada um com o relógio
// correndo: só o canal e o nome do cliente, sem o assunto. Aceitar abre a
// conversa numa aba do espaço de trabalho (as outras abas ficam); recusar
// devolve para a fila na hora.
const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const { offers, start, accept, decline, onArrive } = useOffers();

const avisar = convite => {
  if (!('Notification' in window) || Notification.permission !== 'granted')
    return;
  const titulo = t('STAYDESK.OFFERS.NOTIFICATION', {
    contact: convite.contact_name || '',
  });
  const aviso = new Notification(titulo, {
    body: t('STAYDESK.OFFERS.TITLE', { inbox: convite.inbox_name || '' }),
  });
  setTimeout(() => aviso.close(), 10000);
};

const aoAceitar = async id => {
  const convite = await accept(id);
  if (!convite) return;
  router.push(
    accountScopedRoute('inbox_conversation', {
      conversation_id: convite.conversation_id,
    })
  );
};

onMounted(() => {
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission();
  }
  onArrive(avisar);
  start();
});
</script>

<template>
  <div
    v-if="offers.length"
    class="fixed bottom-4 right-4 z-50 flex w-80 flex-col gap-2"
  >
    <div
      v-for="offer in offers"
      :key="offer.id"
      class="rounded-xl border border-n-weak bg-n-solid-1 p-4 shadow-lg"
    >
      <div class="flex items-center justify-between">
        <p class="text-sm font-medium text-n-slate-12">
          {{ t('STAYDESK.OFFERS.TITLE', { inbox: offer.inbox_name }) }}
        </p>
        <span class="text-sm font-medium text-n-amber-11">
          {{
            t('STAYDESK.OFFERS.SECONDS_LEFT', { seconds: offer.secondsLeft })
          }}
        </span>
      </div>
      <p class="mt-1 text-sm text-n-slate-12">{{ offer.contact_name }}</p>
      <div class="mt-3 flex justify-end gap-2">
        <Button sm faded slate @click="decline(offer.id)">
          {{ t('STAYDESK.OFFERS.DECLINE') }}
        </Button>
        <Button sm solid blue @click="aoAceitar(offer.id)">
          {{ t('STAYDESK.OFFERS.ACCEPT') }}
        </Button>
      </div>
    </div>
  </div>
</template>
