<script setup>
import { computed } from 'vue';

// Número grande para responder "como estamos?" em três segundos, no padrão
// StayDesk: cinza, sem decoração; a cor fica só na bolinha ao lado do rótulo.
const props = defineProps({
  label: { type: String, required: true },
  value: { type: String, required: true },
  helper: { type: String, default: '' },
  severity: { type: String, default: 'neutral' },
  delta: { type: Object, default: null },
  deltaLabel: { type: String, default: '' },
  tooltip: { type: String, default: '' },
});

const BOLINHA = {
  good: 'bg-n-teal-9',
  warn: 'bg-n-amber-9',
  bad: 'bg-n-ruby-9',
  neutral: 'bg-n-slate-8',
};
const bolinha = computed(() => BOLINHA[props.severity] || BOLINHA.neutral);
const corDoDesvio = computed(() => {
  if (!props.delta || props.delta.bom === null) return 'text-n-slate-11';
  return props.delta.bom ? 'text-n-teal-11' : 'text-n-ruby-11';
});
const setaDoDesvio = computed(() => {
  if (!props.delta || props.delta.direcao === 'flat') return 'i-lucide-minus';
  return props.delta.direcao === 'up'
    ? 'i-lucide-arrow-up-right'
    : 'i-lucide-arrow-down-right';
});
</script>

<template>
  <article
    class="flex h-full flex-col gap-1 rounded-xl border border-n-weak bg-n-solid-1 p-4"
  >
    <p class="m-0 flex items-center gap-2 text-sm text-n-slate-11">
      <span
        class="inline-block size-2 shrink-0 rounded-full"
        :class="bolinha"
      />
      {{ label }}
      <span
        v-if="tooltip"
        v-tooltip.top="tooltip"
        class="i-lucide-info size-3.5 text-n-slate-10"
      />
    </p>
    <p class="m-0 text-2xl font-medium tabular-nums text-n-slate-12">
      {{ value }}
    </p>
    <p v-if="helper" class="m-0 text-xs text-n-slate-11">{{ helper }}</p>
    <p
      v-if="delta"
      class="m-0 mt-auto flex items-center gap-1 text-xs tabular-nums"
      :class="corDoDesvio"
    >
      <span :class="setaDoDesvio" class="size-3.5" />
      {{ delta.texto }}
      <span class="text-n-slate-10">{{ deltaLabel }}</span>
    </p>
  </article>
</template>
