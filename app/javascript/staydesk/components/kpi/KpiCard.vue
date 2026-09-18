<script setup>
import { computed } from 'vue';

// Cartão de detalhamento: rótulo, valor, ajuda e o desvio contra o período
// anterior. A explicação da métrica fica no (i).
const props = defineProps({
  label: { type: String, required: true },
  value: { type: String, required: true },
  helper: { type: String, default: '' },
  delta: { type: Object, default: null },
  deltaLabel: { type: String, default: '' },
  tooltip: { type: String, default: '' },
});

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
    class="flex h-full flex-col gap-2 rounded-xl border border-n-weak bg-n-solid-1 p-4"
  >
    <p
      class="m-0 flex items-start justify-between gap-2 text-xs font-medium uppercase tracking-wider text-n-slate-11"
    >
      <span class="line-clamp-2">{{ label }}</span>
      <span
        v-if="tooltip"
        v-tooltip.top="tooltip"
        class="i-lucide-info size-3.5 shrink-0 text-n-slate-10"
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
