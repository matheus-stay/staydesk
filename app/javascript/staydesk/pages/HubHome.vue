<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import ConversationApi from 'dashboard/api/inbox/conversation';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import { useTeamViews } from '../composables/useTeamViews';
import { useAgentStatusStore } from '../store/agentStatus';
import SlaBadge from '../components/SlaBadge.vue';
import { emDuracao } from '../helpers/duracao';

// A porta de entrada do Hub, para quem atende: o status de agora com troca
// rápida, as visualizações com a contagem, e o que está com a pessoa neste
// momento para retomar de onde parou. Sem número de gestão: isso é da Central.
const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const currentUser = useMapGetter('getCurrentUser');
const { views, ensureLoaded, pollCounts, countFor } = useTeamViews();
const statuses = useAgentStatusStore();

const comigo = ref([]);
const carregando = ref(true);

const saudacao = computed(() => {
  const hora = new Date().getHours();
  if (hora < 12) return t('STAYDESK.HUB.GOOD_MORNING');
  if (hora < 18) return t('STAYDESK.HUB.GOOD_AFTERNOON');
  return t('STAYDESK.HUB.GOOD_EVENING');
});
const primeiroNome = computed(
  () => String(currentUser.value?.name || '').split(' ')[0]
);
const opcoesDeStatus = computed(() =>
  statuses.active.map(status => ({ value: status.id, label: status.name }))
);
// O seletor não escreve direto na store: ele espelha o status atual e só troca
// quando a pessoa escolhe outro de fato. Sem isso, o componente de seleção
// dispara ao montar e muda o status do agente sem ninguém pedir.
const statusAtual = ref(null);
watch(
  () => statuses.currentStatusId,
  id => {
    statusAtual.value = id;
  },
  { immediate: true }
);
const trocarStatus = id => {
  if (!id || id === statuses.currentStatusId) return;
  statuses.changeMine(id);
};
const esperandoNasMinhasFilas = computed(() =>
  views.value.reduce((soma, view) => soma + (countFor(view.id) || 0), 0)
);

const abrirView = view =>
  router.push(
    accountScopedRoute('staydesk_view_conversations', { id: view.id })
  );
const abrirConversa = conversa =>
  router.push(
    accountScopedRoute('inbox_conversation', { conversation_id: conversa.id })
  );

const assunto = conversa =>
  conversa.custom_attributes?.assunto ||
  conversa.additional_attributes?.mail_subject ||
  conversa.messages?.at(-1)?.content ||
  '';
const esperaDesde = conversa =>
  conversa.last_activity_at
    ? emDuracao(Date.now() / 1000 - conversa.last_activity_at)
    : '';

onMounted(async () => {
  await Promise.all([
    ensureLoaded(),
    statuses.ensureLoaded?.() || statuses.fetch(),
  ]);
  pollCounts();
  try {
    const { data } = await ConversationApi.get({
      assigneeType: 'me',
      status: 'open',
      page: 1,
    });
    comigo.value = (data?.data?.payload || []).slice(0, 8);
  } finally {
    carregando.value = false;
  }
});
</script>

<template>
  <div class="mx-auto w-full max-w-5xl px-8 pb-16 pt-8 font-inter">
    <header class="mb-8 flex flex-wrap items-end justify-between gap-4">
      <div class="grid gap-1">
        <h1 class="m-0 text-2xl font-medium tracking-tight text-n-slate-12">
          {{ saudacao }}{{ primeiroNome ? `, ${primeiroNome}` : '' }}
        </h1>
        <p class="m-0 text-sm text-n-slate-11">
          {{ t('STAYDESK.HUB.SUBTITLE') }}
        </p>
      </div>
      <label
        v-if="opcoesDeStatus.length"
        class="grid min-w-[14rem] gap-1 text-xs text-n-slate-11"
      >
        <span>{{ t('STAYDESK.HUB.MY_STATUS') }}</span>
        <Select
          :model-value="statusAtual"
          :options="opcoesDeStatus"
          @update:model-value="trocarStatus"
        />
      </label>
    </header>

    <div class="mb-8 grid gap-4 sm:grid-cols-2">
      <div class="rounded-2xl border border-n-weak bg-n-surface-1 p-5">
        <p
          class="m-0 text-[11px] font-semibold uppercase tracking-wide text-n-slate-10"
        >
          {{ t('STAYDESK.HUB.WITH_ME') }}
        </p>
        <p class="m-0 text-3xl font-medium text-n-slate-12">
          {{ comigo.length }}
        </p>
        <p class="m-0 text-xs text-n-slate-11">
          {{ t('STAYDESK.HUB.WITH_ME_HINT') }}
        </p>
      </div>
      <div class="rounded-2xl border border-n-weak bg-n-surface-1 p-5">
        <p
          class="m-0 text-[11px] font-semibold uppercase tracking-wide text-n-slate-10"
        >
          {{ t('STAYDESK.HUB.IN_MY_VIEWS') }}
        </p>
        <p class="m-0 text-3xl font-medium text-n-slate-12">
          {{ esperandoNasMinhasFilas }}
        </p>
        <p class="m-0 text-xs text-n-slate-11">
          {{ t('STAYDESK.HUB.IN_MY_VIEWS_HINT') }}
        </p>
      </div>
    </div>

    <div class="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)]">
      <section class="grid content-start gap-3">
        <h2 class="m-0 text-sm font-medium text-n-slate-12">
          {{ t('STAYDESK.HUB.MY_VIEWS') }}
        </h2>
        <ul class="m-0 grid list-none gap-1 p-0">
          <li v-for="view in views" :key="view.id">
            <button
              type="button"
              class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-start hover:bg-n-alpha-1"
              @click="abrirView(view)"
            >
              <span
                class="inline-block size-2 flex-shrink-0 rounded-full"
                :style="{ backgroundColor: view.color || 'currentColor' }"
              />
              <span class="flex-1 truncate text-sm text-n-slate-12">{{
                view.name
              }}</span>
              <span
                class="rounded-full bg-n-alpha-2 px-2 py-0.5 text-xs tabular-nums text-n-slate-11"
              >
                {{ countFor(view.id) ?? '–' }}
              </span>
            </button>
          </li>
        </ul>
      </section>

      <section class="grid content-start gap-3">
        <h2 class="m-0 text-sm font-medium text-n-slate-12">
          {{ t('STAYDESK.HUB.RESUME') }}
        </h2>
        <p v-if="carregando" class="m-0 text-sm text-n-slate-11">
          {{ t('STAYDESK.HUB.LOADING') }}
        </p>
        <p v-else-if="!comigo.length" class="m-0 text-sm text-n-slate-11">
          {{ t('STAYDESK.HUB.NOTHING_WITH_ME') }}
        </p>
        <ul v-else class="m-0 grid list-none gap-1 p-0">
          <li v-for="conversa in comigo" :key="conversa.id">
            <button
              type="button"
              class="grid w-full grid-cols-[minmax(0,1fr)_auto] items-center gap-3 rounded-xl px-3 py-2 text-start hover:bg-n-alpha-1"
              @click="abrirConversa(conversa)"
            >
              <span class="grid min-w-0 gap-0.5">
                <span class="truncate text-sm text-n-slate-12">
                  {{ conversa.meta?.sender?.name || `#${conversa.id}` }}
                  <span class="text-n-slate-10">#{{ conversa.id }}</span>
                </span>
                <span class="truncate text-xs text-n-slate-11">{{
                  assunto(conversa)
                }}</span>
              </span>
              <span class="flex items-center gap-2 text-xs text-n-slate-11">
                <SlaBadge :attributes="conversa.custom_attributes || {}" />
                <span class="tabular-nums">{{ esperaDesde(conversa) }}</span>
                <Icon
                  icon="i-lucide-chevron-right"
                  class="size-3.5 text-n-slate-10"
                />
              </span>
            </button>
          </li>
        </ul>
      </section>
    </div>
  </div>
</template>
