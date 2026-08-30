<script setup>
import { computed } from 'vue';
import { REPLY_EDITOR_MODES } from './constants';

const props = defineProps({
  mode: {
    type: String,
    default: REPLY_EDITOR_MODES.REPLY,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  isReplyRestricted: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['toggleMode']);

/**
 * Computed boolean indicating if the editor is in private note mode
 * When isReplyRestricted is true, force switch to private note
 * Otherwise, respect the current mode prop
 * @type {ComputedRef<boolean>}
 */
const isPrivate = computed(() => {
  if (props.isReplyRestricted) {
    // Force switch to private note when replies are restricted
    return true;
  }
  // Otherwise respect the current mode
  return props.mode === REPLY_EDITOR_MODES.NOTE;
});
</script>

<template>
  <button
    class="relative z-0 flex h-11 w-auto items-stretch border-0 bg-transparent p-0 text-sm transition-colors duration-150 motion-reduce:transition-none"
    :disabled="disabled || isReplyRestricted"
    :aria-pressed="isPrivate"
    :class="{
      'cursor-not-allowed opacity-60': disabled || isReplyRestricted,
    }"
    @click="$emit('toggleMode')"
  >
    <span
      class="flex items-center gap-1.5 border-b-2 px-3 font-medium transition-colors duration-150 motion-reduce:transition-none"
      :class="
        isPrivate
          ? 'border-transparent text-n-slate-10 hover:text-n-slate-12'
          : 'border-n-brand bg-n-alpha-1 text-n-slate-12'
      "
    >
      <span class="i-ph-chat-circle-dots text-base" aria-hidden="true" />
      {{ $t('CONVERSATION.REPLYBOX.REPLY') }}
    </span>
    <span
      class="flex items-center gap-1.5 border-b-2 px-3 font-medium transition-colors duration-150 motion-reduce:transition-none"
      :class="
        isPrivate
          ? 'border-n-amber-9 bg-n-amber-2/70 text-n-amber-11'
          : 'border-transparent text-n-slate-10 hover:text-n-slate-12'
      "
    >
      <span class="i-ph-lock-simple text-base" aria-hidden="true" />
      {{ $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE') }}
    </span>
  </button>
</template>
