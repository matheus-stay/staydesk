<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useNow } from '@vueuse/core';
import SlaAPI from '../api/sla';
import { formatDuration, metricState } from '../helpers/sla';

// As três métricas do SLA aplicado à conversa, com prazo e estado.
const props = defineProps({
  conversationId: { type: [Number, String], required: true },
  attributes: { type: Object, default: () => ({}) },
});

const { t } = useI18n();
const now = useNow({ interval: 30 * 1000 });
const applied = ref(null);
const isLoading = ref(false);

const load = async () => {
  isLoading.value = true;
  try {
    const { status, data } = await SlaAPI.conversationSla(props.conversationId);
    applied.value = status === 204 ? null : data;
  } catch {
    applied.value = null;
  } finally {
    isLoading.value = false;
  }
};

// Recarrega quando muda de conversa ou quando o motor mexe nos atributos.
watch(
  () => [
    props.conversationId,
    props.attributes?.sla_status,
    props.attributes?.sla_vence_em,
  ],
  load,
  { immediate: true }
);

const remaining = dueAt =>
  dueAt ? formatDuration(new Date(dueAt).getTime() - now.value.getTime()) : '';

const CORES = {
  met: 'text-n-teal-11',
  late: 'text-n-ruby-11',
  breached: 'text-n-ruby-11',
  due: 'text-n-slate-12',
  none: 'text-n-slate-12',
};

const metricClass = metric => CORES[metricState(metric)];

// "cumprido" só quando foi dentro do prazo; fora dele o painel diz o mesmo que
// o selo da conversa.
const metricLabel = metric => {
  const estado = metricState(metric);
  if (estado === 'met') return t('STAYDESK.SLA.MET_AT');
  if (estado === 'late') return t('STAYDESK.SLA.MET_LATE');
  if (estado === 'breached') return t('STAYDESK.SLA.BREACHED');
  if (estado === 'due') return remaining(metric.due_at);
  return '—';
};
</script>

<template>
  <div class="grid gap-1 text-sm">
    <p v-if="!applied && !isLoading" class="text-xs text-n-slate-11">
      {{ t('STAYDESK.SLA.NO_SLA') }}
    </p>
    <template v-else-if="applied">
      <p class="text-xs text-n-slate-11">
        {{ applied.sla_policy_name }} ·
        {{ t(`STAYDESK.SLA.${applied.status.toUpperCase()}`) }}
      </p>
      <div
        v-for="(metric, name) in applied.metrics"
        :key="name"
        class="flex items-center justify-between"
      >
        <span class="text-n-slate-11">{{
          t(`STAYDESK.SLA.METRIC.${name}`)
        }}</span>
        <span class="tabular-nums" :class="metricClass(metric)">
          {{ metricLabel(metric) }}
        </span>
      </div>
    </template>
  </div>
</template>
