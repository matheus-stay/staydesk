<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import Button from 'dashboard/components-next/button/Button.vue';
import { useNextConversation } from '../composables/useNextConversation';

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
});

const { t } = useI18n();
const router = useRouter();
const { nextId, goToNext } = useNextConversation();

const hasNext = computed(() => Boolean(nextId(props.conversationId)));
</script>

<template>
  <Button
    v-if="hasNext"
    sm
    faded
    slate
    trailing-icon
    icon="i-lucide-arrow-right"
    @click="goToNext(conversationId, router)"
  >
    {{ t('STAYDESK.NEXT.BUTTON') }}
  </Button>
</template>
