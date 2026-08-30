<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  count: { type: Number, required: true },
  alignBottom: { type: Boolean, default: false },
});

const { t } = useI18n();

const displayCount = computed(() =>
  props.count > 9 ? t('CHAT_LIST.UNREAD_COUNT_OVERFLOW') : props.count
);
</script>

<template>
  <span
    v-if="count > 0"
    class="inline-grid h-4 min-w-4 max-w-5 w-fit flex-shrink-0 place-items-center rounded-full bg-n-slate-12 px-1 text-xxs font-medium leading-3 text-n-surface-1"
    :class="{
      'mb-0.5': alignBottom,
    }"
  >
    {{ displayCount }}
  </span>
  <span v-else />
</template>
