<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useNow } from '@vueuse/core';
import { slaState } from '../helpers/sla';

const props = defineProps({
  attributes: { type: Object, default: () => ({}) },
});

const { t } = useI18n();
const now = useNow({ interval: 30 * 1000 });

const state = computed(() => slaState(props.attributes, now.value.getTime()));

const CLASSES = {
  running: 'bg-n-teal-3 text-n-teal-11',
  warning: 'bg-n-amber-3 text-n-amber-11',
  breached: 'bg-n-ruby-3 text-n-ruby-11',
  paused: 'bg-n-slate-3 text-n-slate-11',
};

const text = computed(() => {
  if (!state.value) return '';
  if (state.value.status === 'paused') return t('STAYDESK.SLA.PAUSED');
  return (
    state.value.label || t(`STAYDESK.SLA.${state.value.status.toUpperCase()}`)
  );
});
</script>

<template>
  <span
    v-if="state"
    v-tooltip.top="props.attributes.sla_alvo || ''"
    class="inline-flex items-center rounded px-1.5 py-0.5 text-xs font-medium tabular-nums"
    :class="CLASSES[state.status]"
  >
    {{ text }}
  </span>
</template>
