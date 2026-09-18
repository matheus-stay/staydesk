<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import Select from 'dashboard/components-next/select/Select.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import KpisAPI from '../api/kpis';
import AgentStatusesAPI from '../api/agentStatuses';
import KpiHero from '../components/kpi/KpiHero.vue';
import KpiCard from '../components/kpi/KpiCard.vue';
import KpiSection from '../components/kpi/KpiSection.vue';
import TrendChart from '../components/kpi/TrendChart.vue';
import { emDuracao } from '../helpers/duracao';
import { desvio, percentual, semaforo } from '../helpers/kpi';

// Central › Relatórios › Indicadores da operação, no desenho do dashboard da
// casa: os heróis com semáforo respondem "como estamos?", a tendência mostra o
// dia a dia, e o detalhamento traz cada métrica com o desvio contra o período
// anterior. O dashboard e o MCP leem a mesma conta.
const { t } = useI18n();
const store = useStore();
const agentsStore = useMapGetter('agents/getAgents');
const teamsStore = useMapGetter('teams/getTeams');
const kpis = ref(null);
const carregando = ref(true);
const PERIODOS = [7, 30, 90];
const dias = ref(7);
const comparar = ref(true);
// Datas livres: preenchidas, valem em vez do atalho de dias.
const datas = ref({ de: '', ate: '' });
const diasDoRecorte = computed(() => {
  if (!datas.value.de || !datas.value.ate) return dias.value;
  const de = new Date(datas.value.de);
  const ate = new Date(datas.value.ate);
  return Math.max(1, Math.round((ate - de) / 86400000) + 1);
});
// Recortes: agente, canal de trabalho e grupo. Vazio é "todos".
const filtros = ref({ userId: null, loadQueue: null, teamId: null });
const canaisDeTrabalho = ref([]);

const buscar = async () => {
  carregando.value = true;
  try {
    const livre = datas.value.de && datas.value.ate;
    const desde = livre
      ? new Date(`${datas.value.de}T00:00:00`).toISOString()
      : new Date(Date.now() - dias.value * 86400000).toISOString();
    const ate = livre
      ? new Date(`${datas.value.ate}T23:59:59`).toISOString()
      : undefined;
    const { data } = await KpisAPI.show({
      since: desde,
      until: ate,
      compare: comparar.value ? 1 : undefined,
      user_id: filtros.value.userId || undefined,
      load_queue: filtros.value.loadQueue || undefined,
      team_id: filtros.value.teamId || undefined,
    });
    kpis.value = data;
  } finally {
    carregando.value = false;
  }
};

const opcoesDeAgente = computed(() => [
  { value: null, label: t('STAYDESK.KPIS.FILTERS.ALL_AGENTS') },
  ...agentsStore.value.map(agente => ({
    value: agente.id,
    label: agente.name,
  })),
]);
const opcoesDeCanal = computed(() => [
  { value: null, label: t('STAYDESK.KPIS.FILTERS.ALL_CHANNELS') },
  ...canaisDeTrabalho.value.map(canal => ({
    value: canal.key,
    label: canal.name,
  })),
]);
const opcoesDeGrupo = computed(() => [
  { value: null, label: t('STAYDESK.KPIS.FILTERS.ALL_TEAMS') },
  ...teamsStore.value.map(time => ({ value: time.id, label: time.name })),
]);
const filtrar = (chave, valor) => {
  filtros.value = { ...filtros.value, [chave]: valor };
  buscar();
};

// Tempo real: status, conexão e carga de cada agente, a cada 15 segundos.
const agora = ref([]);
let relogio = null;
const buscarAgora = async () => {
  const [{ data: cargas }, { data: diagnostico }] = await Promise.all([
    AgentStatusesAPI.loads(),
    AgentStatusesAPI.distributionChecks(),
  ]);
  const conexao = new Map(
    diagnostico.map(linha => [linha.user_id, linha.online])
  );
  agora.value = cargas.map(linha => ({
    ...linha,
    online: conexao.get(linha.user_id) || false,
  }));
};
const cargaDe = (entrada, chave) => {
  const carga = entrada.load?.[chave] ?? 0;
  const teto = entrada.capacity?.[chave];
  if (teto === 0) return t('STAYDESK.KPIS.REALTIME.NONE');
  if (teto === null || teto === undefined)
    return t('STAYDESK.KPIS.REALTIME.UNLIMITED', { load: carga });
  return t('STAYDESK.KPIS.REALTIME.LOAD', { load: carga, capacity: teto });
};
const cheio = (entrada, chave) => {
  const teto = entrada.capacity?.[chave];
  return teto > 0 && (entrada.load?.[chave] ?? 0) >= teto;
};
const trocarPeriodo = valor => {
  dias.value = valor;
  datas.value = { de: '', ate: '' };
  buscar();
};
const trocarDatas = (chave, valor) => {
  datas.value = { ...datas.value, [chave]: valor };
  if (datas.value.de && datas.value.ate) buscar();
};
const trocarComparacao = valor => {
  comparar.value = valor;
  buscar();
};

const anterior = computed(() => kpis.value?.anterior || null);
const rotuloAnterior = computed(() =>
  anterior.value
    ? t('STAYDESK.KPIS.PREVIOUS', { days: diasDoRecorte.value })
    : ''
);
const onlineAgora = computed(
  () => (kpis.value?.agentes || []).filter(agente => agente.online).length
);
const agentes = computed(() =>
  [...(kpis.value?.agentes || [])].sort(
    (um, outro) => outro.segundos_online - um.segundos_online
  )
);
const filas = computed(() => Object.entries(kpis.value?.tempos || {}));
const tempoAnterior = (fila, metrica) =>
  anterior.value?.tempos?.[fila]?.[metrica]?.segundos ?? null;

const heroCsat = computed(() => ({
  value: percentual(kpis.value.csat.percentual),
  severity: semaforo(kpis.value.csat.percentual, { bom: 90, atencao: 75 }),
  delta: desvio(kpis.value.csat.percentual, anterior.value?.csat?.percentual, {
    unidade: 'pp',
  }),
}));
const heroAceitacao = computed(() => ({
  value: percentual(kpis.value.aceitacao?.percentual),
  severity: semaforo(kpis.value.aceitacao?.percentual, {
    bom: 90,
    atencao: 70,
  }),
  delta: desvio(
    kpis.value.aceitacao?.percentual,
    anterior.value?.aceitacao?.percentual,
    { unidade: 'pp' }
  ),
}));
const heroFila = computed(() => ({
  value: String(kpis.value.fila.total),
  severity: semaforo(kpis.value.fila.total, {
    bom: 0,
    atencao: 5,
    maiorMelhor: false,
  }),
}));
const heroOnline = computed(() => ({
  value: String(onlineAgora.value),
  severity: onlineAgora.value > 0 ? 'good' : 'warn',
}));

const aceitacaoDoAgente = agente =>
  semaforo(agente.aceitacao_percentual, { bom: 90, atencao: 70 });
const PONTO = {
  good: 'bg-n-teal-9',
  warn: 'bg-n-amber-9',
  bad: 'bg-n-ruby-9',
  neutral: 'bg-n-slate-8',
};

onMounted(async () => {
  store.dispatch('agents/get');
  store.dispatch('teams/get');
  AgentStatusesAPI.loadQueues().then(({ data }) => {
    canaisDeTrabalho.value = data.load_queues || [];
  });
  buscar();
  buscarAgora();
  relogio = setInterval(buscarAgora, 15000);
});
onBeforeUnmount(() => clearInterval(relogio));
</script>

<template>
  <SettingsLayout :is-loading="carregando && !kpis">
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.KPIS.TITLE')"
        :description="t('STAYDESK.KPIS.DESCRIPTION')"
      >
        <template #actions>
          <div class="flex flex-wrap items-center gap-3">
            <div class="flex rounded-lg border border-n-weak p-0.5">
              <button
                v-for="periodo in PERIODOS"
                :key="periodo"
                type="button"
                class="rounded-md px-2.5 py-1 text-xs"
                :class="
                  dias === periodo
                    ? 'bg-n-alpha-2 text-n-slate-12'
                    : 'text-n-slate-11 hover:bg-n-alpha-1'
                "
                @click="trocarPeriodo(periodo)"
              >
                {{ t('STAYDESK.CENTRAL.KPIS.DAYS', { days: periodo }) }}
              </button>
            </div>
            <label class="flex items-center gap-1 text-xs text-n-slate-11">
              <input
                :value="datas.de"
                type="date"
                class="h-8 rounded-lg border border-n-weak bg-n-alpha-1 px-2 text-xs text-n-slate-12"
                @change="trocarDatas('de', $event.target.value)"
              />
              –
              <input
                :value="datas.ate"
                type="date"
                class="h-8 rounded-lg border border-n-weak bg-n-alpha-1 px-2 text-xs text-n-slate-12"
                @change="trocarDatas('ate', $event.target.value)"
              />
            </label>
            <label class="flex items-center gap-2 text-xs text-n-slate-11">
              <Switch
                :model-value="comparar"
                @update:model-value="trocarComparacao"
              />
              {{ t('STAYDESK.KPIS.COMPARE') }}
            </label>
          </div>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div class="mb-6 flex flex-wrap gap-3">
        <label class="grid w-56 gap-1 text-xs text-n-slate-11">
          {{ t('STAYDESK.KPIS.FILTERS.AGENT') }}
          <Select
            :model-value="filtros.userId"
            :options="opcoesDeAgente"
            @update:model-value="valor => filtrar('userId', valor)"
          />
        </label>
        <label class="grid w-56 gap-1 text-xs text-n-slate-11">
          {{ t('STAYDESK.KPIS.FILTERS.CHANNEL') }}
          <Select
            :model-value="filtros.loadQueue"
            :options="opcoesDeCanal"
            @update:model-value="valor => filtrar('loadQueue', valor)"
          />
        </label>
        <label class="grid w-56 gap-1 text-xs text-n-slate-11">
          {{ t('STAYDESK.KPIS.FILTERS.TEAM') }}
          <Select
            :model-value="filtros.teamId"
            :options="opcoesDeGrupo"
            @update:model-value="valor => filtrar('teamId', valor)"
          />
        </label>
      </div>
      <KpiSection
        v-if="agora.length"
        class="mb-8"
        :title="t('STAYDESK.KPIS.REALTIME.TITLE')"
        :subtitle="t('STAYDESK.KPIS.REALTIME.SUBTITLE')"
      >
        <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          <article
            v-for="entrada in agora"
            :key="entrada.user_id"
            class="flex items-center gap-3 rounded-xl border border-n-weak bg-n-solid-1 p-3"
          >
            <span
              class="inline-block size-3 shrink-0 rounded-full"
              :class="entrada.status ? '' : 'bg-n-slate-8'"
              :style="
                entrada.status ? { backgroundColor: entrada.status.color } : {}
              "
            />
            <div class="min-w-0 flex-1">
              <p class="m-0 truncate text-sm font-medium text-n-slate-12">
                {{ entrada.name }}
              </p>
              <p class="m-0 text-xs text-n-slate-11">
                {{
                  entrada.status?.name || t('STAYDESK.KPIS.REALTIME.NO_STATUS')
                }}
                ·
                <span
                  :class="entrada.online ? 'text-n-teal-11' : 'text-n-slate-10'"
                >
                  {{
                    entrada.online
                      ? t('STAYDESK.CENTRAL.KPIS.CONNECTED')
                      : t('STAYDESK.CENTRAL.KPIS.AWAY')
                  }}
                </span>
              </p>
            </div>
            <div class="grid shrink-0 gap-0.5 text-right text-xs tabular-nums">
              <span
                v-for="canal in canaisDeTrabalho"
                :key="canal.key"
                :class="
                  cheio(entrada, canal.key)
                    ? 'text-n-amber-11'
                    : 'text-n-slate-11'
                "
              >
                {{ canal.name }}: {{ cargaDe(entrada, canal.key) }}
              </span>
            </div>
          </article>
        </div>
      </KpiSection>
      <div v-if="kpis" class="grid gap-8">
        <KpiSection
          :title="t('STAYDESK.KPIS.HERO_TITLE')"
          :subtitle="t('STAYDESK.KPIS.HERO_SUBTITLE', { days: diasDoRecorte })"
        >
          <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <KpiHero
              :label="t('STAYDESK.CENTRAL.KPIS.CSAT')"
              :value="heroCsat.value"
              :severity="heroCsat.severity"
              :helper="
                t('STAYDESK.CENTRAL.KPIS.CSAT_HINT', {
                  answers: kpis.csat.respostas,
                })
              "
              :delta="heroCsat.delta"
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.CSAT')"
            />
            <KpiHero
              :label="t('STAYDESK.KPIS.ACCEPTANCE.TITLE')"
              :value="heroAceitacao.value"
              :severity="heroAceitacao.severity"
              :helper="
                t('STAYDESK.KPIS.ACCEPTANCE.HINT', {
                  accepted: kpis.aceitacao?.aceitos || 0,
                  offers: kpis.aceitacao?.convites || 0,
                })
              "
              :delta="heroAceitacao.delta"
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.ACCEPTANCE')"
            />
            <KpiHero
              :label="t('STAYDESK.CENTRAL.KPIS.QUEUE')"
              :value="heroFila.value"
              :severity="heroFila.severity"
              :helper="
                t('STAYDESK.CENTRAL.KPIS.QUEUE_HINT', {
                  wait: emDuracao(kpis.fila.espera_mais_antiga_em_segundos),
                })
              "
              :tooltip="t('STAYDESK.KPIS.TIPS.QUEUE')"
            />
            <KpiHero
              :label="t('STAYDESK.CENTRAL.KPIS.ONLINE')"
              :value="heroOnline.value"
              :severity="heroOnline.severity"
              :helper="
                t('STAYDESK.CENTRAL.KPIS.ONLINE_HINT', {
                  total: kpis.agentes.length,
                })
              "
              :tooltip="t('STAYDESK.KPIS.TIPS.ONLINE')"
            />
          </div>
        </KpiSection>

        <KpiSection
          :title="t('STAYDESK.KPIS.TREND_TITLE')"
          :subtitle="t('STAYDESK.KPIS.TREND_SUBTITLE')"
        >
          <div class="rounded-xl border border-n-weak bg-n-solid-1 p-4">
            <TrendChart
              :series="kpis.por_dia || []"
              :created-label="t('STAYDESK.KPIS.TREND_CREATED')"
              :resolved-label="t('STAYDESK.KPIS.TREND_RESOLVED')"
            />
          </div>
        </KpiSection>

        <KpiSection
          :title="t('STAYDESK.KPIS.DETAIL_TITLE')"
          :subtitle="
            anterior
              ? t('STAYDESK.KPIS.DETAIL_SUBTITLE_COMPARED', {
                  days: diasDoRecorte,
                })
              : t('STAYDESK.KPIS.DETAIL_SUBTITLE', { days: diasDoRecorte })
          "
        >
          <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <KpiCard
              :label="t('STAYDESK.KPIS.CARDS.CREATED')"
              :value="String(kpis.volumes?.criadas ?? 0)"
              :delta="
                desvio(kpis.volumes?.criadas, anterior?.volumes?.criadas, {
                  bomQuando: 'none',
                })
              "
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.CREATED')"
            />
            <KpiCard
              :label="t('STAYDESK.KPIS.CARDS.RESOLVED')"
              :value="String(kpis.volumes?.resolvidas ?? 0)"
              :delta="
                desvio(kpis.volumes?.resolvidas, anterior?.volumes?.resolvidas)
              "
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.RESOLVED')"
            />
            <KpiCard
              :label="t('STAYDESK.KPIS.CARDS.BACKLOG')"
              :value="String(kpis.volumes?.abertas_agora ?? 0)"
              :helper="
                t('STAYDESK.KPIS.CARDS.BACKLOG_HELPER', {
                  waiting: kpis.volumes?.esperando_suporte ?? 0,
                  overdue: kpis.volumes?.vencidas_agora ?? 0,
                })
              "
              :tooltip="t('STAYDESK.KPIS.TIPS.BACKLOG')"
            />
            <KpiCard
              :label="t('STAYDESK.KPIS.CARDS.REOPENED')"
              :value="String(kpis.volumes?.reabertas ?? 0)"
              :delta="
                desvio(kpis.volumes?.reabertas, anterior?.volumes?.reabertas, {
                  bomQuando: 'down',
                })
              "
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.REOPENED')"
            />
            <KpiCard
              :label="t('STAYDESK.KPIS.CARDS.FCR')"
              :value="percentual(kpis.volumes?.fcr_percentual)"
              :helper="
                t('STAYDESK.KPIS.CARDS.BASE', {
                  base: kpis.volumes?.fcr_base ?? 0,
                })
              "
              :delta="
                desvio(
                  kpis.volumes?.fcr_percentual,
                  anterior?.volumes?.fcr_percentual,
                  { unidade: 'pp' }
                )
              "
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.FCR')"
            />
            <KpiCard
              :label="t('STAYDESK.KPIS.CARDS.SLA_FIRST_REPLY')"
              :value="percentual(kpis.sla?.primeira_resposta?.percentual)"
              :helper="
                t('STAYDESK.KPIS.CARDS.BASE', {
                  base: kpis.sla?.primeira_resposta?.base ?? 0,
                })
              "
              :delta="
                desvio(
                  kpis.sla?.primeira_resposta?.percentual,
                  anterior?.sla?.primeira_resposta?.percentual,
                  { unidade: 'pp' }
                )
              "
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.SLA')"
            />
            <KpiCard
              :label="t('STAYDESK.KPIS.CARDS.SLA_RESOLUTION')"
              :value="percentual(kpis.sla?.resolucao?.percentual)"
              :helper="
                t('STAYDESK.KPIS.CARDS.BASE', {
                  base: kpis.sla?.resolucao?.base ?? 0,
                })
              "
              :delta="
                desvio(
                  kpis.sla?.resolucao?.percentual,
                  anterior?.sla?.resolucao?.percentual,
                  { unidade: 'pp' }
                )
              "
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.SLA')"
            />
            <template v-for="[fila, tempos] in filas" :key="fila">
              <KpiCard
                v-for="metrica in [
                  'primeira_resposta',
                  'resposta',
                  'resolucao',
                ]"
                :key="`${fila}-${metrica}`"
                :label="t(`STAYDESK.KPIS.CARDS.${metrica}`, { channel: fila })"
                :value="emDuracao(tempos[metrica]?.segundos)"
                :helper="
                  tempos[metrica]?.amostras
                    ? t('STAYDESK.KPIS.CARDS.SAMPLES', {
                        count: tempos[metrica].amostras,
                        business: emDuracao(
                          tempos[metrica].segundos_no_horario
                        ),
                      })
                    : t('STAYDESK.KPIS.CARDS.NO_SAMPLES')
                "
                :delta="
                  desvio(
                    tempos[metrica]?.segundos,
                    tempoAnterior(fila, metrica),
                    {
                      bomQuando: 'down',
                    }
                  )
                "
                :delta-label="rotuloAnterior"
                :tooltip="t('STAYDESK.KPIS.TIPS.TIMES')"
              />
            </template>
            <KpiCard
              :label="t('STAYDESK.CENTRAL.KPIS.ONLINE_TIME')"
              :value="
                emDuracao(kpis.resumo_dos_agentes?.media_diaria_online_segundos)
              "
              :helper="
                t('STAYDESK.CENTRAL.KPIS.ONLINE_TIME_HINT', {
                  agents:
                    kpis.resumo_dos_agentes?.agentes_com_tempo_online || 0,
                })
              "
              :delta="
                desvio(
                  kpis.resumo_dos_agentes?.media_diaria_online_segundos,
                  anterior?.resumo_dos_agentes?.media_diaria_online_segundos
                )
              "
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.ONLINE_TIME')"
            />
            <KpiCard
              :label="t('STAYDESK.KPIS.CARDS.INVITES')"
              :value="String(kpis.aceitacao?.convites || 0)"
              :helper="
                t('STAYDESK.KPIS.CARDS.INVITES_HELPER', {
                  accepted: kpis.aceitacao?.aceitos || 0,
                  declined: kpis.aceitacao?.recusados || 0,
                  expired: kpis.aceitacao?.vencidos || 0,
                })
              "
              :delta="
                desvio(
                  kpis.aceitacao?.convites,
                  anterior?.aceitacao?.convites,
                  {
                    bomQuando: 'none',
                  }
                )
              "
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.ACCEPTANCE')"
            />
          </div>
        </KpiSection>

        <KpiSection
          :title="t('STAYDESK.KPIS.AGENTS.TITLE')"
          :subtitle="t('STAYDESK.KPIS.AGENTS.HINT')"
        >
          <div class="overflow-x-auto">
            <table class="w-full min-w-[64rem] border-collapse text-sm">
              <thead>
                <tr class="text-left text-xs text-n-slate-11">
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.AGENT') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.NOW') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.AVAILABLE_TIME') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.AGENTS.RESOLVED') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.AGENTS.TIMES') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.ACCEPTANCE.OFFERS') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.ACCEPTANCE.RATE') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.ACCEPTANCE.ANSWER_TIME') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.CSAT') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak">
                <tr v-for="agente in agentes" :key="agente.user_id">
                  <td class="py-2 pr-4 font-medium text-n-slate-12">
                    {{ agente.nome }}
                  </td>
                  <td class="py-2 pr-4 text-n-slate-11">
                    <span class="flex items-center gap-1.5">
                      <span
                        class="inline-block size-2 rounded-full"
                        :class="agente.online ? 'bg-n-teal-9' : 'bg-n-slate-8'"
                      />
                      {{ agente.status_atual || '—' }}
                    </span>
                  </td>
                  <td class="py-2 pr-4 tabular-nums text-n-slate-11">
                    {{ emDuracao(agente.segundos_online) }}
                    <span class="text-xs text-n-slate-10">
                      {{
                        t('STAYDESK.CENTRAL.KPIS.PER_DAY', {
                          time: emDuracao(agente.media_diaria_online_segundos),
                        })
                      }}
                    </span>
                  </td>
                  <td class="py-2 pr-4 tabular-nums text-n-slate-11">
                    {{ agente.resolvidas ?? 0 }}
                  </td>
                  <td class="py-2 pr-4 tabular-nums text-n-slate-11">
                    {{
                      t('STAYDESK.KPIS.AGENTS.TIMES_CELL', {
                        first: emDuracao(agente.primeira_resposta_segundos),
                        resolution: emDuracao(agente.resolucao_segundos),
                      })
                    }}
                  </td>
                  <td class="py-2 pr-4 tabular-nums text-n-slate-11">
                    {{
                      t('STAYDESK.KPIS.ACCEPTANCE.BREAKDOWN', {
                        offers: agente.convites,
                        accepted: agente.aceitos,
                        declined: agente.recusados,
                        expired: agente.vencidos,
                      })
                    }}
                  </td>
                  <td class="py-2 pr-4 tabular-nums text-n-slate-11">
                    <span class="flex items-center gap-1.5">
                      <span
                        class="inline-block size-2 rounded-full"
                        :class="PONTO[aceitacaoDoAgente(agente)]"
                      />
                      {{ percentual(agente.aceitacao_percentual) }}
                    </span>
                  </td>
                  <td class="py-2 pr-4 tabular-nums text-n-slate-11">
                    {{ emDuracao(agente.tempo_medio_aceite_segundos) }}
                  </td>
                  <td class="py-2 pr-4 tabular-nums text-n-slate-11">
                    {{ percentual(agente.csat_percentual) }}
                    <span
                      v-if="agente.csat_respostas"
                      class="text-xs text-n-slate-10"
                    >
                      ({{ agente.csat_respostas }})
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </KpiSection>
      </div>
    </template>
  </SettingsLayout>
</template>
