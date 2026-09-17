<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useNow } from '@vueuse/core';
import SlaAPI from '../api/sla';
import { formatDuration } from '../helpers/sla';

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

const metricClass = metric => {
  if (metric.met_at) return 'text-n-teal-11';
  if (metric.breached) return 'text-n-ruby-11';
  return 'text-n-slate-12';
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
          <template v-if="metric.met_at">{{
            t('STAYDESK.SLA.MET_AT')
          }}</template>
          <template v-else-if="metric.due_at">{{
            remaining(metric.due_at)
          }}</template>
          <template v-else>—</template>
        </span>
      </div>
    </template>
  </div>
</template>
