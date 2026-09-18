<script setup>
import { computed } from 'vue';

// Linha do tempo em SVG puro: sem biblioteca, o suficiente para ver a
// tendência de conversas criadas e resolvidas por dia.
const props = defineProps({
  series: { type: Array, default: () => [] },
  createdLabel: { type: String, default: '' },
  resolvedLabel: { type: String, default: '' },
});

const LARGURA = 640;
const ALTURA = 200;
const MARGEM = { topo: 12, direita: 12, baixo: 28, esquerda: 32 };

const maximo = computed(() =>
  Math.max(1, ...props.series.map(dia => Math.max(dia.criadas, dia.resolvidas)))
);
const x = indice =>
  MARGEM.esquerda +
  (indice * (LARGURA - MARGEM.esquerda - MARGEM.direita)) /
    Math.max(props.series.length - 1, 1);
const y = valor =>
  ALTURA -
  MARGEM.baixo -
  (valor * (ALTURA - MARGEM.topo - MARGEM.baixo)) / maximo.value;
const linha = campo =>
  props.series.map((dia, i) => `${x(i)},${y(dia[campo])}`).join(' ');
const linhas = computed(() => ({
  criadas: linha('criadas'),
  resolvidas: linha('resolvidas'),
}));
// Quatro linhas-guia e rótulos de dia espaçados para não amontoar.
const guias = computed(() =>
  [0, 0.25, 0.5, 0.75, 1].map(fracao => ({
    y: y(maximo.value * fracao),
    valor: Math.round(maximo.value * fracao),
  }))
);
const rotulos = computed(() => {
  const passo = Math.max(1, Math.ceil(props.series.length / 8));
  return props.series
    .map((dia, i) => ({
      i,
      dia: dia.dia.slice(8, 10) + '/' + dia.dia.slice(5, 7),
    }))
    .filter(item => item.i % passo === 0 || item.i === props.series.length - 1);
});
</script>

<template>
  <div class="grid gap-2">
    <svg
      :viewBox="`0 0 ${LARGURA} ${ALTURA}`"
      class="h-48 w-full text-n-slate-11"
      role="img"
    >
      <g v-for="guia in guias" :key="guia.valor">
        <line
          :x1="MARGEM.esquerda"
          :x2="LARGURA - MARGEM.direita"
          :y1="guia.y"
          :y2="guia.y"
          class="stroke-n-weak"
          stroke-width="1"
        />
        <text
          :x="MARGEM.esquerda - 6"
          :y="guia.y + 3"
          text-anchor="end"
          class="fill-current text-[10px]"
        >
          {{ guia.valor }}
        </text>
      </g>
      <polyline
        :points="linhas.criadas"
        fill="none"
        class="stroke-n-brand"
        stroke-width="2"
        stroke-linejoin="round"
      />
      <polyline
        :points="linhas.resolvidas"
        fill="none"
        class="stroke-n-teal-9"
        stroke-width="2"
        stroke-linejoin="round"
      />
      <text
        v-for="rotulo in rotulos"
        :key="rotulo.i"
        :x="x(rotulo.i)"
        :y="ALTURA - 8"
        text-anchor="middle"
        class="fill-current text-[10px]"
      >
        {{ rotulo.dia }}
      </text>
    </svg>
    <div class="flex gap-4 text-xs text-n-slate-11">
      <span class="flex items-center gap-1.5">
        <span class="inline-block h-0.5 w-4 bg-n-brand" />{{ createdLabel }}
      </span>
      <span class="flex items-center gap-1.5">
        <span class="inline-block h-0.5 w-4 bg-n-teal-9" />{{ resolvedLabel }}
      </span>
    </div>
  </div>
</template>
