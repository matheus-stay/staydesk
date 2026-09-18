<script setup>
import { useI18n } from 'vue-i18n';
import Switch from 'dashboard/components-next/switch/Switch.vue';

// Campo do ticket que precisa estar preenchido para o agente resolver, como no
// Zendesk. Só faz sentido em campo de conversa: contato não se resolve.
defineProps({
  modelValue: { type: Boolean, default: false },
  attributeModel: { type: String, default: 'conversation_attribute' },
});
defineEmits(['update:modelValue']);

const { t } = useI18n();
</script>

<template>
  <label
    v-if="attributeModel === 'conversation_attribute'"
    class="flex items-start gap-2 py-2 text-sm text-n-slate-12"
  >
    <Switch
      :model-value="modelValue"
      @update:model-value="$emit('update:modelValue', $event)"
    />
    <span class="grid gap-0.5">
      <span>{{ t('STAYDESK.TICKET_FIELDS.REQUIRED') }}</span>
      <span class="text-xs text-n-slate-11">
        {{ t('STAYDESK.TICKET_FIELDS.REQUIRED_HINT') }}
      </span>
    </span>
  </label>
</template>
