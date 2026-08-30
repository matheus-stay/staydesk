<script setup>
import { computed, useTemplateRef } from 'vue';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import CardAvatar from './CardAvatar.vue';
import CardContent from './CardContent.vue';
import CardLabels from './CardLabelsV5.vue';
import CardPriorityIcon from './CardPriorityIcon.vue';
import InboxName from 'dashboard/components-next/Conversation/InboxName.vue';
import Avatar from 'next/avatar/Avatar.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';
import CardStatusIcon from './CardStatusIcon.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  chat: { type: Object, required: true },
  currentContact: { type: Object, required: true },
  assignee: { type: Object, default: () => ({}) },
  inbox: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
  isActiveChat: { type: Boolean, default: false },
  showAssignee: { type: Boolean, default: false },
  showInboxName: { type: Boolean, default: false },
  isInboxView: { type: Boolean, default: false },
});

const emit = defineEmits([
  'selectConversation',
  'deSelectConversation',
  'click',
  'contextmenu',
]);

const lastMessageInChat = computed(() => getLastMessage(props.chat));
const showLabelsSection = computed(() => props.chat.labels?.length > 0);

const voiceCallData = computed(() => {
  const last = lastMessageInChat.value;
  if (last?.content_type !== 'voice_call' || !last.call) {
    return { status: null, direction: null };
  }
  return {
    status: last.call.status,
    direction: last.call.direction === 'outgoing' ? 'outbound' : 'inbound',
  };
});

const unreadCount = computed(() => props.chat.unread_count);

const slaCardLabel = useTemplateRef('slaCardLabel');

const hasSlaPolicyId = computed(
  () =>
    !props.currentContact?.blocked &&
    (props.chat?.applied_sla?.id || slaCardLabel.value?.hasSlaThreshold)
);

const selectedModel = computed({
  get: () => props.selected,
  set: value => {
    if (value) {
      emit('selectConversation', value);
    } else {
      emit('deSelectConversation', value);
    }
  },
});
</script>

<template>
  <div
    class="conversation group relative grid h-12 cursor-pointer items-center gap-2 border-b border-n-slate-3 px-3 transition-colors duration-[120ms] ease-out before:pointer-events-none before:absolute before:inset-x-0 before:-top-px before:h-px before:bg-n-surface-1 before:content-[none] hover:z-[1] hover:border-n-surface-1 hover:before:content-[''] motion-reduce:transition-none"
    :class="{
      'active bg-n-brand/5 dark:bg-n-brand/10 !border-n-surface-1 !border-s-2 !border-s-n-brand':
        isActiveChat,
      'selected bg-n-brand/10 dark:bg-n-brand/20 !border-n-surface-1 !border-s-2 !border-s-n-brand':
        selected,
      'hover:bg-n-slate-2/70 dark:hover:bg-n-slate-3/60':
        !isActiveChat && !selected,
      'grid-cols-[minmax(0,2fr)_minmax(0,1fr)]': showLabelsSection,
      'grid-cols-[minmax(0,2fr)_max-content]': !showLabelsSection,
    }"
    @click="$emit('click', $event)"
    @contextmenu="$emit('contextmenu', $event)"
  >
    <!-- LEFT SECTION -->
    <div class="flex min-w-0 flex-1 items-center gap-2">
      <div class="flex flex-shrink-0 items-center justify-center" @click.stop>
        <Checkbox v-model="selectedModel" />
      </div>

      <div class="h-3 w-px flex-shrink-0 bg-n-slate-6" />

      <div class="flex w-4 flex-shrink-0 items-center justify-center">
        <CardPriorityIcon :priority="chat.priority" show-empty />
      </div>

      <div class="flex w-4 flex-shrink-0 items-center justify-center">
        <Avatar
          v-if="showAssignee && assignee.name"
          v-tooltip.top="{
            content: assignee.name,
            delay: { show: 500, hide: 0 },
          }"
          :name="assignee.name"
          :src="assignee.thumbnail"
          :size="14"
          :status="assignee.availability_status"
          hide-offline-status
        />
        <Icon
          v-else
          icon="i-woot-empty-assignee"
          class="size-4 text-n-slate-7"
        />
      </div>

      <div class="flex w-4 flex-shrink-0 items-center justify-center">
        <CardStatusIcon :status="chat.status" show-empty />
      </div>

      <div class="h-3 w-px flex-shrink-0 bg-n-slate-6" />

      <div v-if="!isInboxView && showInboxName" class="w-20 flex-shrink-0">
        <InboxName v-if="showInboxName" :inbox="inbox" class="min-w-0" />
      </div>

      <div
        v-if="!isInboxView && showInboxName"
        class="h-3 w-px flex-shrink-0 bg-n-slate-6"
      />

      <div
        v-tooltip.top="{
          content: chat.id,
          delay: { show: 500, hide: 0 },
        }"
        class="flex h-6 max-w-20 w-full min-w-0 flex-shrink-0 items-center gap-1"
      >
        <Icon
          icon="i-woot-hash"
          class="size-3.5 flex-shrink-0 text-n-slate-10"
        />
        <span class="text-body-main truncate text-n-slate-11">
          {{ chat.id }}
        </span>
      </div>

      <CardAvatar
        :contact="currentContact"
        :selected="false"
        :enable-selection="false"
        :hide-thumbnail="false"
      />

      <h4
        class="my-0 w-32 flex-shrink-0 truncate capitalize text-heading-3 font-semibold text-n-slate-12"
      >
        {{ currentContact.name }}
      </h4>

      <CardContent
        :last-message="lastMessageInChat"
        :voice-call-status="voiceCallData.status"
        :voice-call-direction="voiceCallData.direction"
        :unread-count="unreadCount"
        :show-expanded-preview="false"
      />
    </div>

    <!-- RIGHT SECTION -->
    <div class="flex flex-shrink-0 items-center justify-end gap-1.5">
      <div v-if="showLabelsSection" class="min-w-0 w-full">
        <CardLabels
          :labels="chat.labels"
          disable-toggle
          class="my-0 justify-end [&>div]:justify-end"
        />
      </div>

      <div v-if="hasSlaPolicyId" class="flex-shrink-0">
        <SLACardLabel ref="slaCardLabel" :chat="chat" />
      </div>

      <div class="w-[4.375rem] flex-shrink-0 text-end tabular-nums">
        <TimeAgo
          :conversation-id="chat.id"
          :last-activity-timestamp="chat.timestamp"
          :created-at-timestamp="chat.created_at"
          class="!text-xs font-medium text-n-slate-11"
        />
      </div>
    </div>
  </div>
</template>
