<script setup>
import { computed } from 'vue';

// Número grande com semáforo, para responder "como estamos?" em três
// segundos: cartão neutro, a cor fica na barra e no valor, como no dashboard.
const props = defineProps({
  label: { type: String, required: true },
  value: { type: String, required: true },
  helper: { type: String, default: '' },
  severity: { type: String, default: 'neutral' },
  delta: { type: Object, default: null },
  deltaLabel: { type: String, default: '' },
  tooltip: { type: String, default: '' },
});

const TONS = {
  good: { valor: 'text-n-teal-11', barra: 'bg-n-teal-9' },
  warn: { valor: 'text-n-amber-11', barra: 'bg-n-amber-9' },
  bad: { valor: 'text-n-ruby-11', barra: 'bg-n-ruby-9' },
  neutral: { valor: 'text-n-slate-12', barra: 'bg-n-brand' },
};
const tom = computed(() => TONS[props.severity] || TONS.neutral);
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
    class="relative flex h-full flex-col gap-1 overflow-hidden rounded-xl border border-n-weak bg-n-solid-1 p-5"
  >
    <span class="absolute inset-y-0 left-0 w-1" :class="tom.barra" />
    <p
      class="m-0 flex items-center gap-1.5 text-xs font-medium uppercase tracking-wider text-n-slate-11"
    >
      {{ label }}
      <span
        v-if="tooltip"
        v-tooltip.top="tooltip"
        class="i-lucide-info size-3.5 text-n-slate-10"
      />
    </p>
    <p class="m-0 text-3xl font-medium tabular-nums" :class="tom.valor">
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
