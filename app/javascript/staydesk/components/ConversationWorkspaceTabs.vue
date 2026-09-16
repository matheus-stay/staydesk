<script setup>
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  tabs: {
    type: Array,
    default: () => [],
  },
  activeConversationId: {
    type: [String, Number],
    default: 0,
  },
});

const emit = defineEmits(['select', 'close']);
</script>

<template>
  <header
    class="flex h-12 min-h-12 min-w-0 items-stretch border-b border-n-weak bg-n-surface-2"
  >
    <nav
      :aria-label="$t('CHAT_LIST.TAB_HEADING')"
      class="no-scrollbar flex min-w-0 flex-1 items-stretch overflow-x-auto"
      role="tablist"
    >
      <div
        v-for="tab in tabs"
        :key="tab.id"
        class="group relative flex h-full w-52 min-w-40 max-w-52 items-center border-e border-n-weak"
        :class="
          Number(activeConversationId) === Number(tab.id)
            ? 'bg-n-surface-1 text-n-slate-12'
            : 'bg-n-surface-2 text-n-slate-11 hover:bg-n-alpha-2'
        "
      >
        <button
          type="button"
          role="tab"
          :aria-selected="Number(activeConversationId) === Number(tab.id)"
          :title="tab.title"
          class="flex h-full min-w-0 flex-1 flex-col justify-center px-3 pe-8 text-start outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-n-brand"
          @click="emit('select', tab)"
        >
          <span class="w-full truncate text-xs font-medium leading-4">
            {{ tab.title }}
          </span>
          <span class="flex w-full items-center gap-1 text-xxs leading-4">
            <span class="tabular-nums text-n-slate-10">{{ `#${tab.id}` }}</span>
            <span
              v-if="tab.hasDraft"
              class="flex min-w-0 items-center gap-1 font-medium text-n-amber-11"
            >
              <span class="size-1.5 shrink-0 rounded-full bg-n-amber-9" />
              <span class="truncate">{{
                $t('CHAT_LIST.WORKSPACE_TABS.UNSAVED')
              }}</span>
            </span>
          </span>
        </button>

        <button
          type="button"
          :aria-label="`${$t('GENERAL.CLOSE')} #${tab.id}`"
          class="absolute end-1.5 top-1/2 flex size-6 -translate-y-1/2 items-center justify-center rounded text-n-slate-9 outline-none hover:bg-n-alpha-3 hover:text-n-slate-12 focus-visible:ring-2 focus-visible:ring-n-brand"
          @click.stop="emit('close', tab)"
        >
          <span class="i-lucide-x size-3.5" />
        </button>

        <span
          v-if="Number(activeConversationId) === Number(tab.id)"
          class="absolute inset-x-0 bottom-0 h-0.5 bg-n-brand"
        />
      </div>
    </nav>

    <ComposeConversation align="start">
      <template #trigger="{ isOpen }">
        <Button
          :aria-label="$t('NEW_CONVERSATION.TITLE')"
          :title="$t('NEW_CONVERSATION.TITLE')"
          icon="i-lucide-plus"
          color="slate"
          size="sm"
          class="!h-12 !w-12 !rounded-none !border-0 !text-n-slate-11 !outline-0 hover:!bg-n-alpha-3"
          :class="{ '!bg-n-alpha-3': isOpen }"
        />
      </template>
    </ComposeConversation>
  </header>
</template>
