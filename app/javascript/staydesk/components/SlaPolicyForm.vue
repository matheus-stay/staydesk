<script setup>
import { onMounted, ref, useTemplateRef, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useConversationFilterContext } from 'dashboard/components-next/filter/provider';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import {
  newConditionRow,
  payloadToRows,
  rowsToQuery,
} from '../helpers/teamViewQuery';

const props = defineProps({
  policy: { type: Object, default: null },
  calendars: { type: Array, default: () => [] },
  isSaving: { type: Boolean, default: false },
});
const emit = defineEmits(['save', 'cancel']);
// Política de SLA: condições (o construtor do upstream), alvos por prioridade em
// minutos, calendário, status que pausam e a fração de aviso.
const METRICS = ['first_response', 'next_response', 'resolution'];
const PRIORITIES = ['default', 'urgent', 'high', 'medium', 'low'];
const PAUSE_STATUSES = ['pending', 'snoozed'];

const { t } = useI18n();
const store = useStore();
const { filterTypes, attributeFilterTypes } = useConversationFilterContext();

const emptyTargets = () =>
  Object.fromEntries(
    PRIORITIES.map(priority => [
      priority,
      Object.fromEntries(METRICS.map(metric => [metric, ''])),
    ])
  );

const form = ref({
  name: '',
  description: '',
  calendarId: '',
  pauseStatuses: [...PAUSE_STATUSES],
  warningRatio: 20,
  active: true,
});
const targets = ref(emptyTargets());
const rows = ref([]);
const conditionsRef = useTemplateRef('conditionsRef');

const calendarOptions = computed(() => [
  { value: '', label: t('STAYDESK.SLA.FORM.NO_CALENDAR') },
  ...props.calendars.map(calendar => ({
    value: String(calendar.id),
    label: calendar.name,
  })),
]);

onMounted(async () => {
  await store.dispatch('attributes/get');
  if (!props.policy) return;
  form.value = {
    name: props.policy.name,
    description: props.policy.description || '',
    calendarId: props.policy.calendar_id
      ? String(props.policy.calendar_id)
      : '',
    pauseStatuses: [...(props.policy.pause_statuses || [])],
    warningRatio: Math.round((props.policy.warning_ratio || 0.2) * 100),
    active: props.policy.active,
  };
  const saved = emptyTargets();
  Object.entries(props.policy.targets || {}).forEach(([priority, metrics]) => {
    Object.entries(metrics).forEach(([metric, minutes]) => {
      if (saved[priority]) saved[priority][metric] = minutes ?? '';
    });
  });
  targets.value = saved;
  rows.value = payloadToRows(props.policy.conditions || [], filterTypes.value);
});

const toggle = (list, value) => {
  const index = list.indexOf(value);
  if (index === -1) list.push(value);
  else list.splice(index, 1);
};

const addRow = () => rows.value.push(newConditionRow());
const removeRow = index => rows.value.splice(index, 1);

const cleanTargets = () =>
  Object.fromEntries(
    Object.entries(targets.value)
      .map(([priority, metrics]) => [
        priority,
        Object.fromEntries(
          Object.entries(metrics)
            .filter(([, minutes]) => minutes !== '' && minutes !== null)
            .map(([metric, minutes]) => [metric, Number(minutes)])
        ),
      ])
      .filter(([, metrics]) => Object.keys(metrics).length)
  );

const isValid = () =>
  Boolean(form.value.name.trim()) &&
  (conditionsRef.value || []).every(row => row.validate());

const submit = () => {
  if (!isValid()) return;
  emit('save', {
    name: form.value.name.trim(),
    description: form.value.description,
    calendar_id: form.value.calendarId || null,
    pause_statuses: form.value.pauseStatuses,
    warning_ratio: Number(form.value.warningRatio) / 100,
    active: form.value.active,
    conditions: rows.value.length ? rowsToQuery(rows.value).payload : [],
    targets: cleanTargets(),
  });
};
</script>

<template>
  <form
    class="grid gap-6 rounded-xl border border-n-weak bg-n-solid-1 p-6"
    @submit.prevent="submit"
  >
    <div class="grid gap-4 md:grid-cols-2">
      <Input
        v-model="form.name"
        :label="t('STAYDESK.SLA.FORM.NAME')"
        :placeholder="t('STAYDESK.SLA.FORM.NAME_PLACEHOLDER')"
      />
      <Input
        v-model="form.description"
        :label="t('STAYDESK.SLA.FORM.DESCRIPTION')"
      />
    </div>

    <div class="grid gap-4 md:grid-cols-3">
      <label class="grid gap-1 text-sm text-n-slate-12">
        <span>{{ t('STAYDESK.SLA.FORM.CALENDAR') }}</span>
        <Select v-model="form.calendarId" :options="calendarOptions" />
      </label>
      <Input
        v-model="form.warningRatio"
        type="number"
        min="1"
        max="99"
        :label="t('STAYDESK.SLA.FORM.WARNING_RATIO')"
      />
      <fieldset class="grid gap-1 text-sm text-n-slate-12">
        <legend>{{ t('STAYDESK.SLA.FORM.PAUSE_STATUSES') }}</legend>
        <div class="flex gap-3 pt-1">
          <label
            v-for="status in PAUSE_STATUSES"
            :key="status"
            class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-1.5"
          >
            <input
              type="checkbox"
              :checked="form.pauseStatuses.includes(status)"
              @change="toggle(form.pauseStatuses, status)"
            />
            {{ t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${status}.TEXT`) }}
          </label>
        </div>
      </fieldset>
    </div>

    <fieldset class="grid gap-2">
      <legend class="text-sm font-medium text-n-slate-12">
        {{ t('STAYDESK.SLA.FORM.TARGETS') }}
      </legend>
      <p class="text-xs text-n-slate-11">
        {{ t('STAYDESK.SLA.FORM.TARGETS_HINT') }}
      </p>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="text-xs uppercase text-n-slate-11">
            <tr>
              <th class="px-2 py-1 text-left">
                {{ t('STAYDESK.SLA.FORM.PRIORITY') }}
              </th>
              <th
                v-for="metric in METRICS"
                :key="metric"
                class="px-2 py-1 text-left"
              >
                {{ t(`STAYDESK.SLA.METRIC.${metric}`) }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="priority in PRIORITIES" :key="priority">
              <td class="px-2 py-1 text-n-slate-12">
                {{ t(`STAYDESK.SLA.PRIORITY.${priority}`) }}
              </td>
              <td v-for="metric in METRICS" :key="metric" class="px-2 py-1">
                <input
                  v-model="targets[priority][metric]"
                  type="number"
                  min="1"
                  class="h-8 w-24 rounded-lg border border-n-weak bg-n-alpha-1 px-2 text-sm text-n-slate-12"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </fieldset>

    <fieldset class="grid gap-3">
      <legend class="text-sm font-medium text-n-slate-12">
        {{ t('STAYDESK.SLA.FORM.CONDITIONS') }}
      </legend>
      <p class="text-xs text-n-slate-11">
        {{ t('STAYDESK.SLA.FORM.CONDITIONS_HINT') }}
      </p>
      <ul class="grid min-w-0 list-none gap-4">
        <template v-for="(row, index) in rows" :key="index">
          <ConditionRow
            v-if="index === 0"
            ref="conditionsRef"
            v-model:attribute-key="row.attributeKey"
            v-model:filter-operator="row.filterOperator"
            v-model:values="row.values"
            :filter-types="attributeFilterTypes"
            :show-query-operator="false"
            @remove="removeRow(index)"
          />
          <ConditionRow
            v-else
            ref="conditionsRef"
            v-model:attribute-key="row.attributeKey"
            v-model:filter-operator="row.filterOperator"
            v-model:query-operator="rows[index - 1].queryOperator"
            v-model:values="row.values"
            show-query-operator
            :filter-types="attributeFilterTypes"
            @remove="removeRow(index)"
          />
        </template>
      </ul>
      <div>
        <Button sm ghost blue type="button" @click="addRow">
          {{ t('STAYDESK.TEAM_VIEWS.FORM.ADD_CONDITION') }}
        </Button>
      </div>
    </fieldset>

    <label class="flex items-center gap-2 text-sm text-n-slate-12">
      <input v-model="form.active" type="checkbox" />
      {{ t('STAYDESK.SLA.FORM.ACTIVE') }}
    </label>

    <div class="flex justify-end gap-2">
      <Button sm faded slate type="button" @click="emit('cancel')">
        {{ t('STAYDESK.TEAM_VIEWS.FORM.CANCEL') }}
      </Button>
      <Button sm solid blue type="submit" :is-loading="isSaving">
        {{ t('STAYDESK.TEAM_VIEWS.FORM.SAVE') }}
      </Button>
    </div>
  </form>
</template>
