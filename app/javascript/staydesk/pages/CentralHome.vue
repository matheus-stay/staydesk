<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useStaydeskSidebar } from '../composables/useStaydeskSidebar';
import KpisAPI from '../api/kpis';
import { emDuracao } from '../helpers/duracao';

// A porta de entrada da Central, como a home da central de administração do
// Zendesk: as seções na frente, para quem configura achar sem caçar no menu.
const { t } = useI18n();
const router = useRouter();
const { settingsItems, organizarCentral } = useStaydeskSidebar();

const secoes = computed(() =>
  organizarCentral([...settingsItems.value]).filter(item => item.children)
);
const atalhos = computed(() =>
  organizarCentral([...settingsItems.value]).filter(
    item => item.to && item.name !== 'StaydeskCentralHome'
  )
);

const abrir = destino => router.push(destino);

// Os números vêm calculados do servidor: a Central, o dashboard e o MCP leem a
// mesma conta, então ninguém discute número em reunião.
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

const filas = computed(() => Object.entries(kpis.value?.tempos || {}));
const onlineAgora = computed(
  () => (kpis.value?.agentes || []).filter(agente => agente.online).length
);
const agentes = computed(() =>
  [...(kpis.value?.agentes || [])].sort(
    (um, outro) => outro.segundos_disponivel - um.segundos_disponivel
  )
);

onMounted(buscar);
</script>

<template>
  <SettingsLayout>
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.CENTRAL.TITLE')"
        :description="t('STAYDESK.CENTRAL.DESCRIPTION')"
      />
    </template>
    <template #body>
      <div class="grid gap-6">
        <section class="grid gap-3">
          <header class="flex flex-wrap items-center justify-between gap-2">
            <h3 class="m-0 text-sm font-medium text-n-slate-12">
              {{ t('STAYDESK.CENTRAL.KPIS.TITLE') }}
            </h3>
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
          </header>
          <p v-if="carregando" class="text-sm text-n-slate-11">
            {{ t('STAYDESK.CENTRAL.KPIS.LOADING') }}
          </p>
          <div
            v-else-if="kpis"
            class="grid gap-4 md:grid-cols-2 xl:grid-cols-4"
          >
            <article class="rounded-xl border border-n-weak p-4">
              <p class="m-0 text-xs uppercase text-n-slate-11">
                {{ t('STAYDESK.CENTRAL.KPIS.CSAT') }}
              </p>
              <p class="m-0 text-2xl text-n-slate-12">
                {{
                  kpis.csat.percentual === null
                    ? '—'
                    : `${kpis.csat.percentual}%`
                }}
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
            <article
              v-for="[fila, tempos] in filas"
              :key="fila"
              class="rounded-xl border border-n-weak p-4"
            >
              <p class="m-0 text-xs uppercase text-n-slate-11">
                {{ t('STAYDESK.CENTRAL.KPIS.FIRST_REPLY', { queue: fila }) }}
              </p>
              <p class="m-0 text-2xl text-n-slate-12">
                {{ emDuracao(tempos.primeira_resposta?.segundos) }}
              </p>
              <p class="m-0 text-xs text-n-slate-11">
                {{
                  t('STAYDESK.CENTRAL.KPIS.RESOLUTION', {
                    time: emDuracao(tempos.resolucao?.segundos),
                  })
                }}
              </p>
            </article>
          </div>
          <div v-if="kpis && agentes.length" class="overflow-x-auto">
            <table class="w-full min-w-[32rem] border-collapse text-sm">
              <thead>
                <tr class="text-left text-xs uppercase text-n-slate-11">
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.AGENT') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.STATUS') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.AVAILABLE_TIME') }}
                  </th>
                  <th class="py-2 font-medium">
                    {{ t('STAYDESK.CENTRAL.KPIS.NOW') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak">
                <tr v-for="agente in agentes" :key="agente.user_id">
                  <td class="py-2 pr-4 text-n-slate-12">{{ agente.nome }}</td>
                  <td class="py-2 pr-4 text-n-slate-11">
                    {{ agente.status_atual || '—' }}
                  </td>
                  <td class="py-2 pr-4 text-n-slate-11">
                    {{ emDuracao(agente.segundos_disponivel) }}
                  </td>
                  <td class="py-2 text-n-slate-11">
                    {{
                      agente.online
                        ? t('STAYDESK.CENTRAL.KPIS.CONNECTED')
                        : t('STAYDESK.CENTRAL.KPIS.AWAY')
                    }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
        <div v-if="atalhos.length" class="flex flex-wrap gap-2">
          <button
            v-for="atalho in atalhos"
            :key="atalho.name"
            type="button"
            class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-1"
            @click="abrir(atalho.to)"
          >
            <Icon :icon="atalho.icon" class="flex-shrink-0" />
            {{ atalho.label }}
          </button>
        </div>
        <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          <section
            v-for="secao in secoes"
            :key="secao.name"
            class="rounded-xl border border-n-weak p-4"
          >
            <h3
              class="mb-3 flex items-center gap-2 text-sm font-medium text-n-slate-12"
            >
              <Icon :icon="secao.icon" class="flex-shrink-0" />
              {{ secao.label }}
            </h3>
            <ul class="grid list-none gap-1 m-0">
              <li v-for="item in secao.children" :key="item.name">
                <button
                  type="button"
                  class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-start text-sm text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12"
                  @click="abrir(item.to)"
                >
                  <Icon :icon="item.icon" class="flex-shrink-0" />
                  <span class="truncate">{{ item.label }}</span>
                </button>
              </li>
            </ul>
          </section>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
