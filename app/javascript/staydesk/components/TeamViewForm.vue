<script setup>
import { onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useConversationFilterContext } from 'dashboard/components-next/filter/provider';
import wootConstants from 'dashboard/constants/globals';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import {
  DEFAULT_COLUMNS,
  TEAM_VIEW_COLUMNS,
  newConditionRow,
  payloadToRows,
  rowsToQuery,
} from '../helpers/teamViewQuery';

const props = defineProps({
  view: { type: Object, default: null },
  isSaving: { type: Boolean, default: false },
});

const emit = defineEmits(['save', 'cancel']);

const { t } = useI18n();
const sortOptions = Object.values(wootConstants.SORT_BY_TYPE).map(value => ({
  value,
  label: t(`STAYDESK.TEAM_VIEWS.SORT.${value}`),
}));
const store = useStore();
const teams = useMapGetter('teams/getTeams');
const { filterTypes, attributeFilterTypes } = useConversationFilterContext();

const form = ref({
  name: '',
  description: '',
  color: '#545DFF',
  teamIds: [],
  sortBy: wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC,
  columns: [...DEFAULT_COLUMNS],
});
const rows = ref([newConditionRow()]);
const conditionsRef = useTemplateRef('conditionsRef');

onMounted(async () => {
  // Atributos personalizados e campanhas alimentam as opções de condição.
  await Promise.all([
    store.dispatch('attributes/get'),
    store.dispatch('campaigns/get'),
  ]);
  if (!props.view) return;
  form.value = {
    name: props.view.name,
    description: props.view.description || '',
    color: props.view.color || '#545DFF',
    teamIds: [...(props.view.team_ids || [])],
    sortBy:
      props.view.sort_by || wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC,
    columns: props.view.columns?.length
      ? [...props.view.columns]
      : [...DEFAULT_COLUMNS],
  };
  const payload = props.view.query?.payload || [];
  rows.value = payload.length
    ? payloadToRows(payload, filterTypes.value)
    : [newConditionRow()];
});

const toggle = (list, value) => {
  const index = list.indexOf(value);
  if (index === -1) list.push(value);
  else list.splice(index, 1);
};

const addRow = () => rows.value.push(newConditionRow());

const removeRow = index => {
  if (rows.value.length === 1) rows.value = [newConditionRow()];
  else rows.value.splice(index, 1);
};

const isValid = () =>
  Boolean(form.value.name.trim()) &&
  (conditionsRef.value || []).every(row => row.validate());

const submit = () => {
  if (!isValid()) return;
  emit('save', {
    name: form.value.name.trim(),
    description: form.value.description,
    color: form.value.color,
    team_ids: form.value.teamIds,
    sort_by: form.value.sortBy,
    columns: form.value.columns,
    query: rowsToQuery(rows.value),
  });
};
</script>

<template>
  <form
    class="grid gap-6 p-6 border rounded-xl border-n-weak bg-n-solid-1"
    @submit.prevent="submit"
  >
    <div class="grid gap-4 md:grid-cols-2">
      <Input
        v-model="form.name"
        :label="t('STAYDESK.TEAM_VIEWS.FORM.NAME')"
        :placeholder="t('STAYDESK.TEAM_VIEWS.FORM.NAME_PLACEHOLDER')"
      />
      <Input
        v-model="form.description"
        :label="t('STAYDESK.TEAM_VIEWS.FORM.DESCRIPTION')"
      />
    </div>

    <div class="grid gap-4 md:grid-cols-3">
      <label class="grid gap-1 text-sm text-n-slate-12">
        <span>{{ t('STAYDESK.TEAM_VIEWS.FORM.COLOR') }}</span>
        <input
          v-model="form.color"
          type="color"
          class="w-16 h-9 p-0 border rounded-lg cursor-pointer border-n-weak bg-n-alpha-1"
        />
      </label>
      <label class="grid gap-1 text-sm text-n-slate-12 md:col-span-2">
        <span>{{ t('STAYDESK.TEAM_VIEWS.FORM.SORT_BY') }}</span>
        <Select v-model="form.sortBy" :options="sortOptions" />
      </label>
    </div>

    <fieldset class="grid gap-2">
      <legend class="text-sm text-n-slate-12">
        {{ t('STAYDESK.TEAM_VIEWS.FORM.TEAMS') }}
      </legend>
      <p class="text-xs text-n-slate-11">
        {{ t('STAYDESK.TEAM_VIEWS.FORM.TEAMS_HINT') }}
      </p>
      <div class="flex flex-wrap gap-3">
        <label
          v-for="team in teams"
          :key="team.id"
          class="flex items-center gap-2 px-3 py-1.5 text-sm border rounded-lg cursor-pointer border-n-weak text-n-slate-12"
        >
          <input
            type="checkbox"
            :checked="form.teamIds.includes(team.id)"
            @change="toggle(form.teamIds, team.id)"
          />
          {{ team.name }}
        </label>
      </div>
    </fieldset>

    <fieldset class="grid gap-2">
      <legend class="text-sm text-n-slate-12">
        {{ t('STAYDESK.TEAM_VIEWS.FORM.COLUMNS') }}
      </legend>
      <div class="flex flex-wrap gap-3">
        <label
          v-for="column in TEAM_VIEW_COLUMNS"
          :key="column"
          class="flex items-center gap-2 px-3 py-1.5 text-sm border rounded-lg cursor-pointer border-n-weak text-n-slate-12"
        >
          <input
            type="checkbox"
            :checked="form.columns.includes(column)"
            @change="toggle(form.columns, column)"
          />
          {{ t(`STAYDESK.TEAM_VIEWS.COLUMN.${column}`) }}
        </label>
      </div>
    </fieldset>

    <fieldset class="grid gap-3">
      <legend class="text-sm text-n-slate-12">
        {{ t('STAYDESK.TEAM_VIEWS.FORM.CONDITIONS') }}
      </legend>
      <ul class="grid gap-4 list-none min-w-0">
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
