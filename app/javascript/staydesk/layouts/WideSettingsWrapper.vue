<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';

// O mesmo chassi das telas da Central, sem a largura máxima: a documentação da
// API precisa de três colunas e a leitura fica melhor com espaço.
const route = useRoute();
const routeKey = computed(() => route.fullPath);
</script>

<template>
  <div class="flex h-full w-full flex-col overflow-auto bg-n-surface-1">
    <router-view v-slot="{ Component }">
      <component :is="Component" :key="routeKey" />
    </router-view>
  </div>
</template>
