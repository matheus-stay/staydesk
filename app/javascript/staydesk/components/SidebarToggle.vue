<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

// Compactar a barra lateral para só os ícones. O produto já sabia fazer isso, mas
// só por duplo clique na borda, que ninguém descobre.
const props = defineProps({
  isCollapsed: { type: Boolean, default: false },
});
defineEmits(['toggle']);

const { t } = useI18n();
const label = computed(() =>
  props.isCollapsed
    ? t('STAYDESK.SIDEBAR.EXPAND')
    : t('STAYDESK.SIDEBAR.COLLAPSE')
);
</script>

<template>
  <li>
    <button
      v-tooltip.right="isCollapsed ? label : null"
      type="button"
      class="flex w-full min-w-0 items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-n-slate-11 hover:bg-n-alpha-1"
      :class="{ 'justify-center': isCollapsed }"
      :aria-label="label"
      @click="$emit('toggle')"
    >
      <Icon
        :icon="
          isCollapsed ? 'i-lucide-panel-left-open' : 'i-lucide-panel-left-close'
        "
        class="flex-shrink-0"
      />
      <span v-if="!isCollapsed" class="truncate">{{ label }}</span>
    </button>
  </li>
</template>
