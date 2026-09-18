<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import KpisAPI from '../api/kpis';
import { emDuracao } from '../helpers/duracao';

// Central › Relatórios › Indicadores da operação: os números que o StayDesk
// calcula, num lugar só. A mesma conta que o dashboard e o MCP leem.
const { t } = useI18n();
const kpis = ref(null);
const carregando = ref(true);
const PERIODOS = [7, 30, 90];
const dias = ref(7);

const buscar = async () => {
  carregando.value = true;
  try {
    const desde = new Date(Date.now() - dias.value * 86400000).toISOString();
    const { data } = await KpisAPI.show({ since: desde });
    kpis.value = data;
  } finally {
    carregando.value = false;
  }
};

const trocarPeriodo = valor => {
  dias.value = valor;
  buscar();
};

const percentual = valor =>
  valor === null || valor === undefined ? '—' : `${valor}%`;
const filas = computed(() => Object.entries(kpis.value?.tempos || {}));
const onlineAgora = computed(
  () => (kpis.value?.agentes || []).filter(agente => agente.online).length
);
const agentes = computed(() =>
  [...(kpis.value?.agentes || [])].sort(
    (um, outro) => outro.segundos_online - um.segundos_online
  )
);

onMounted(buscar);
</script>

<template>
  <SettingsLayout :is-loading="carregando && !kpis">
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.KPIS.TITLE')"
        :description="t('STAYDESK.KPIS.DESCRIPTION')"
      >
        <template #actions>
          <div class="flex gap-1">
            <button
              v-for="periodo in PERIODOS"
              :key="periodo"
              type="button"
              class="rounded-lg px-2 py-1 text-xs"
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
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div v-if="kpis" class="grid gap-8">
        <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <article class="rounded-xl border border-n-weak p-4">
            <p class="m-0 text-xs uppercase text-n-slate-11">
              {{ t('STAYDESK.CENTRAL.KPIS.CSAT') }}
            </p>
            <p class="m-0 text-2xl text-n-slate-12">
              {{ percentual(kpis.csat.percentual) }}
            </p>
            <p class="m-0 text-xs text-n-slate-11">
              {{
                t('STAYDESK.CENTRAL.KPIS.CSAT_HINT', {
                  answers: kpis.csat.respostas,
                })
              }}
            </p>
          </article>
          <article class="rounded-xl border border-n-weak p-4">
            <p class="m-0 text-xs uppercase text-n-slate-11">
              {{ t('STAYDESK.KPIS.ACCEPTANCE.TITLE') }}
            </p>
            <p class="m-0 text-2xl text-n-slate-12">
              {{ percentual(kpis.aceitacao?.percentual) }}
            </p>
            <p class="m-0 text-xs text-n-slate-11">
              {{
                t('STAYDESK.KPIS.ACCEPTANCE.HINT', {
                  accepted: kpis.aceitacao?.aceitos || 0,
                  offers: kpis.aceitacao?.convites || 0,
                })
              }}
            </p>
          </article>
          <article class="rounded-xl border border-n-weak p-4">
            <p class="m-0 text-xs uppercase text-n-slate-11">
              {{ t('STAYDESK.CENTRAL.KPIS.QUEUE') }}
            </p>
            <p class="m-0 text-2xl text-n-slate-12">{{ kpis.fila.total }}</p>
            <p class="m-0 text-xs text-n-slate-11">
              {{
                t('STAYDESK.CENTRAL.KPIS.QUEUE_HINT', {
                  wait: emDuracao(kpis.fila.espera_mais_antiga_em_segundos),
                })
              }}
            </p>
          </article>
          <article class="rounded-xl border border-n-weak p-4">
            <p class="m-0 text-xs uppercase text-n-slate-11">
              {{ t('STAYDESK.CENTRAL.KPIS.ONLINE') }}
            </p>
            <p class="m-0 text-2xl text-n-slate-12">{{ onlineAgora }}</p>
            <p class="m-0 text-xs text-n-slate-11">
              {{
                t('STAYDESK.CENTRAL.KPIS.ONLINE_HINT', {
                  total: kpis.agentes.length,
                })
              }}
            </p>
          </article>
          <article class="rounded-xl border border-n-weak p-4">
            <p class="m-0 text-xs uppercase text-n-slate-11">
              {{ t('STAYDESK.CENTRAL.KPIS.ONLINE_TIME') }}
            </p>
            <p class="m-0 text-2xl text-n-slate-12">
              {{
                emDuracao(kpis.resumo_dos_agentes?.media_diaria_online_segundos)
              }}
            </p>
            <p class="m-0 text-xs text-n-slate-11">
              {{
                t('STAYDESK.CENTRAL.KPIS.ONLINE_TIME_HINT', {
                  agents:
                    kpis.resumo_dos_agentes?.agentes_com_tempo_online || 0,
                })
              }}
            </p>
          </article>
        </section>

        <section class="grid gap-3">
          <h3 class="m-0 text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.KPIS.TIMES.TITLE') }}
          </h3>
          <p class="m-0 text-xs text-n-slate-11">
            {{ t('STAYDESK.KPIS.TIMES.HINT') }}
          </p>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[32rem] border-collapse text-sm">
              <thead>
                <tr class="text-left text-xs uppercase text-n-slate-11">
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.TIMES.CHANNEL') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.TIMES.FIRST_REPLY') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.TIMES.REPLY') }}
                  </th>
                  <th class="py-2 font-medium">
                    {{ t('STAYDESK.KPIS.TIMES.RESOLUTION') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak">
                <tr v-for="[fila, tempos] in filas" :key="fila">
                  <td class="py-2 pr-4 text-n-slate-12">{{ fila }}</td>
                  <td
                    v-for="metrica in [
                      'primeira_resposta',
                      'resposta',
                      'resolucao',
                    ]"
                    :key="metrica"
                    class="py-2 pr-4 text-n-slate-11"
                  >
                    {{ emDuracao(tempos[metrica]?.segundos) }}
                    <span
                      v-if="tempos[metrica]?.amostras"
                      class="text-xs text-n-slate-10"
                    >
                      {{
                        t('STAYDESK.KPIS.TIMES.SAMPLES', {
                          count: tempos[metrica].amostras,
                          business: emDuracao(
                            tempos[metrica].segundos_no_horario
                          ),
                        })
                      }}
                    </span>
                  </td>
                </tr>
                <tr v-if="!filas.length">
                  <td colspan="4" class="py-2 text-n-slate-11">
                    {{ t('STAYDESK.KPIS.TIMES.EMPTY') }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="grid gap-3">
          <h3 class="m-0 text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.KPIS.AGENTS.TITLE') }}
          </h3>
          <p class="m-0 text-xs text-n-slate-11">
            {{ t('STAYDESK.KPIS.AGENTS.HINT') }}
          </p>
          <div class="overflow-x-auto">
            <table class="w-full min-w-[56rem] border-collapse text-sm">
              <thead>
                <tr class="text-left text-xs uppercase text-n-slate-11">
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
                    {{ t('STAYDESK.KPIS.ACCEPTANCE.OFFERS') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.ACCEPTANCE.RATE') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.KPIS.ACCEPTANCE.ANSWER_TIME') }}
                  </th>
                  <th class="py-2 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.CSAT') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak">
                <tr v-for="agente in agentes" :key="agente.user_id">
                  <td class="py-2 pr-4 text-n-slate-12">{{ agente.nome }}</td>
                  <td class="py-2 pr-4 text-n-slate-11">
                    {{ agente.status_atual || '—' }}
                    <span class="text-xs text-n-slate-10">
                      ·
                      {{
                        agente.online
                          ? t('STAYDESK.CENTRAL.KPIS.CONNECTED')
                          : t('STAYDESK.CENTRAL.KPIS.AWAY')
                      }}
                    </span>
                  </td>
                  <td class="py-2 pr-4 text-n-slate-11">
                    {{ emDuracao(agente.segundos_online) }}
                    <span class="text-xs text-n-slate-10">
                      {{
                        t('STAYDESK.CENTRAL.KPIS.PER_DAY', {
                          time: emDuracao(agente.media_diaria_online_segundos),
                        })
                      }}
                    </span>
                  </td>
                  <td class="py-2 pr-4 text-n-slate-11">
                    {{
                      t('STAYDESK.KPIS.ACCEPTANCE.BREAKDOWN', {
                        offers: agente.convites,
                        accepted: agente.aceitos,
                        declined: agente.recusados,
                        expired: agente.vencidos,
                      })
                    }}
                  </td>
                  <td class="py-2 pr-4 text-n-slate-11">
                    {{ percentual(agente.aceitacao_percentual) }}
                  </td>
                  <td class="py-2 pr-4 text-n-slate-11">
                    {{ emDuracao(agente.tempo_medio_aceite_segundos) }}
                  </td>
                  <td class="py-2 text-n-slate-11">
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
        </section>
      </div>
    </template>
  </SettingsLayout>
</template>
