<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useTeamViews } from '../composables/useTeamViews';
import { estaNaCentral } from '../helpers/central';

// Dentro da central de administração a barra é o menu da central, então o
// caminho de volta para o atendimento fica aqui em cima, antes da lista, que é
// longa e rola. Volta na primeira visualização, que é por onde se atende.
defineProps({
  isCollapsed: { type: Boolean, default: false },
});

const { t } = useI18n();
const route = useRoute();
const { accountScopedRoute } = useAccount();
const { views } = useTeamViews();

const naCentral = computed(() => estaNaCentral(route.path));
const destino = computed(() => {
  const primeira = views.value?.[0];
  return primeira
    ? accountScopedRoute('staydesk_view_conversations', { id: primeira.id })
    : accountScopedRoute('home');
});
const label = computed(() => t('STAYDESK.SIDEBAR.BACK_TO_WORK'));
</script>

<template>
  <li v-if="naCentral">
    <router-link
      v-tooltip.right="isCollapsed ? label : null"
      :to="destino"
      class="flex w-full min-w-0 items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-n-slate-11 hover:bg-n-alpha-1"
      :class="{ 'justify-center': isCollapsed }"
      :aria-label="label"
    >
      <Icon icon="i-lucide-arrow-left" class="flex-shrink-0" />
      <span v-if="!isCollapsed" class="truncate">{{ label }}</span>
    </router-link>
  </li>
</template>
