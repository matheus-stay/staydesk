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
// Recortes: agente, canal de trabalho e grupo. Vazio é "todos".
const filtros = ref({ userId: null, loadQueue: null, teamId: null });
const canaisDeTrabalho = ref([]);

const buscar = async () => {
  carregando.value = true;
  try {
    const desde = new Date(Date.now() - dias.value * 86400000).toISOString();
    const { data } = await KpisAPI.show({
      since: desde,
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
  buscar();
};
const trocarComparacao = valor => {
  comparar.value = valor;
  buscar();
};

const anterior = computed(() => kpis.value?.anterior || null);
const rotuloAnterior = computed(() =>
  anterior.value ? t('STAYDESK.KPIS.PREVIOUS', { days: dias.value }) : ''
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
      <div class="mb-6 grid gap-3 md:grid-cols-3">
        <label class="grid gap-1 text-xs text-n-slate-11">
          {{ t('STAYDESK.KPIS.FILTERS.AGENT') }}
          <Select
            :model-value="filtros.userId"
            :options="opcoesDeAgente"
            @update:model-value="valor => filtrar('userId', valor)"
          />
        </label>
        <label class="grid gap-1 text-xs text-n-slate-11">
          {{ t('STAYDESK.KPIS.FILTERS.CHANNEL') }}
          <Select
            :model-value="filtros.loadQueue"
            :options="opcoesDeCanal"
            @update:model-value="valor => filtrar('loadQueue', valor)"
          />
        </label>
        <label class="grid gap-1 text-xs text-n-slate-11">
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
              :style="{
                backgroundColor: entrada.status?.color || 'var(--slate-8)',
              }"
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
          :subtitle="t('STAYDESK.KPIS.HERO_SUBTITLE', { days: dias })"
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
              ? t('STAYDESK.KPIS.DETAIL_SUBTITLE_COMPARED', { days: dias })
              : t('STAYDESK.KPIS.DETAIL_SUBTITLE', { days: dias })
          "
        >
          <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
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
            <KpiCard
              :label="t('STAYDESK.KPIS.CARDS.CSAT_ANSWERS')"
              :value="String(kpis.csat.respostas)"
              :helper="
                t('STAYDESK.KPIS.CARDS.CSAT_HELPER', {
                  good: kpis.csat.satisfeitos,
                  bad: kpis.csat.insatisfeitos,
                })
              "
              :delta="
                desvio(kpis.csat.respostas, anterior?.csat?.respostas, {
                  bomQuando: 'none',
                })
              "
              :delta-label="rotuloAnterior"
              :tooltip="t('STAYDESK.KPIS.TIPS.CSAT')"
            />
          </div>
        </KpiSection>

        <KpiSection
          :title="t('STAYDESK.KPIS.AGENTS.TITLE')"
          :subtitle="t('STAYDESK.KPIS.AGENTS.HINT')"
        >
          <div
            class="overflow-x-auto rounded-xl border border-n-weak bg-n-solid-1"
          >
            <table class="w-full min-w-[56rem] border-collapse text-sm">
              <thead>
                <tr
                  class="border-b border-n-weak text-left text-xs uppercase tracking-wider text-n-slate-11"
                >
                  <th class="px-4 py-2.5 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.AGENT') }}
                  </th>
                  <th class="px-4 py-2.5 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.NOW') }}
                  </th>
                  <th class="px-4 py-2.5 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.AVAILABLE_TIME') }}
                  </th>
                  <th class="px-4 py-2.5 font-medium">
                    {{ t('STAYDESK.KPIS.ACCEPTANCE.OFFERS') }}
                  </th>
                  <th class="px-4 py-2.5 font-medium">
                    {{ t('STAYDESK.KPIS.ACCEPTANCE.RATE') }}
                  </th>
                  <th class="px-4 py-2.5 font-medium">
                    {{ t('STAYDESK.KPIS.ACCEPTANCE.ANSWER_TIME') }}
                  </th>
                  <th class="px-4 py-2.5 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.CSAT') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak">
                <tr v-for="agente in agentes" :key="agente.user_id">
                  <td class="px-4 py-2.5 font-medium text-n-slate-12">
                    {{ agente.nome }}
                  </td>
                  <td class="px-4 py-2.5 text-n-slate-11">
                    <span class="flex items-center gap-1.5">
                      <span
                        class="inline-block size-2 rounded-full"
                        :class="agente.online ? 'bg-n-teal-9' : 'bg-n-slate-8'"
                      />
                      {{ agente.status_atual || '—' }}
                    </span>
                  </td>
                  <td class="px-4 py-2.5 tabular-nums text-n-slate-11">
                    {{ emDuracao(agente.segundos_online) }}
                    <span class="text-xs text-n-slate-10">
                      {{
                        t('STAYDESK.CENTRAL.KPIS.PER_DAY', {
                          time: emDuracao(agente.media_diaria_online_segundos),
                        })
                      }}
                    </span>
                  </td>
                  <td class="px-4 py-2.5 tabular-nums text-n-slate-11">
                    {{
                      t('STAYDESK.KPIS.ACCEPTANCE.BREAKDOWN', {
                        offers: agente.convites,
                        accepted: agente.aceitos,
                        declined: agente.recusados,
                        expired: agente.vencidos,
                      })
                    }}
                  </td>
                  <td class="px-4 py-2.5 tabular-nums text-n-slate-11">
                    <span class="flex items-center gap-1.5">
                      <span
                        class="inline-block size-2 rounded-full"
                        :class="PONTO[aceitacaoDoAgente(agente)]"
                      />
                      {{ percentual(agente.aceitacao_percentual) }}
                    </span>
                  </td>
                  <td class="px-4 py-2.5 tabular-nums text-n-slate-11">
                    {{ emDuracao(agente.tempo_medio_aceite_segundos) }}
                  </td>
                  <td class="px-4 py-2.5 tabular-nums text-n-slate-11">
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
