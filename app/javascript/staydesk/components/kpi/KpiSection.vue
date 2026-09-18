<script setup>
// Seção com título e subtítulo, como as do dashboard: a pergunta em cima, os
// números embaixo.
defineProps({
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
});
</script>

<template>
  <section class="grid gap-3">
    <header class="flex flex-wrap items-end justify-between gap-2">
      <div>
        <h3 class="m-0 text-base font-medium text-n-slate-12">{{ title }}</h3>
        <p v-if="subtitle" class="m-0 text-xs text-n-slate-11">
          {{ subtitle }}
        </p>
      </div>
      <slot name="right" />
    </header>
    <slot />
  </section>
</template>
