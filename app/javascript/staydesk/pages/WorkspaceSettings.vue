<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import wootConstants from 'dashboard/constants/globals';
import WorkspaceAPI from '../api/workspace';
import { TEAM_VIEW_COLUMNS } from '../helpers/teamViewQuery';

// Administração da área de trabalho: padrão da conta e sobreposição por time.
// Lista vazia significa "herdar"; a chave só é gravada quando o admin marca algo.
const MENU_NAMES = [
  'Inbox',
  'Conversation',
  'Calls',
  'Contacts',
  'Reports',
  'Captain',
  'Companies',
  'Campaigns',
  'Portals',
];
const PANEL_NAMES = [
  'conversation_actions',
  'macros',
  'conversation_info',
  'contact_attributes',
  'contact_notes',
  'shared_files',
  'previous_conversation',
  'conversation_participants',
  'linear_issues',
  'shopify_orders',
];
const STANDARD_FIELDS = ['assignee', 'team', 'priority', 'labels'];
const SORT_OPTIONS = Object.values(wootConstants.SORT_BY_TYPE);

const { t } = useI18n();
const store = useStore();
const teams = useMapGetter('teams/getTeams');
const dashboardApps = useMapGetter('dashboardApps/getRecords');
const macros = useMapGetter('macros/getMacros');
const attributesByModel = useMapGetter('attributes/getAttributesByModel');

const selectedTeam = ref('default');
const isLoading = ref(false);
const isSaving = ref(false);

const emptyForm = () => ({
  menu: [],
  layout: '',
  columns: [],
  sortBy: '',
  standardFields: false,
  fields: [],
  panels: [],
  apps: [],
  macrosMode: '',
  macroIds: [],
  submitAs: '',
  afterSend: '',
});
const form = ref(emptyForm());

const customAttributes = computed(
  () => attributesByModel.value('conversation_attribute') || []
);

const fromConfig = config => {
  const fields = config.conversation?.fields || [];
  return {
    menu: config.menu || [],
    layout: config.list?.layout || '',
    columns: config.list?.columns || [],
    sortBy: config.list?.sort_by || '',
    standardFields: fields.some(field => STANDARD_FIELDS.includes(field)),
    fields: fields.filter(field => !STANDARD_FIELDS.includes(field)),
    panels: config.conversation?.panels || [],
    apps: config.conversation?.apps || [],
    macrosMode: config.macros?.mode || '',
    macroIds: config.macros?.ids || [],
    submitAs:
      config.composer?.submit_as === undefined
        ? ''
        : String(config.composer.submit_as),
    afterSend: config.composer?.after_send || '',
  };
};

const toConfig = () => {
  const config = {};
  if (form.value.menu.length) config.menu = form.value.menu;
  const list = {};
  if (form.value.layout) list.layout = form.value.layout;
  if (form.value.columns.length) list.columns = form.value.columns;
  if (form.value.sortBy) list.sort_by = form.value.sortBy;
  if (Object.keys(list).length) config.list = list;
  const conversation = {};
  const fields = [
    ...(form.value.standardFields ? STANDARD_FIELDS : []),
    ...form.value.fields,
  ];
  if (fields.length) conversation.fields = fields;
  if (form.value.panels.length) conversation.panels = form.value.panels;
  if (form.value.apps.length) conversation.apps = form.value.apps;
  if (Object.keys(conversation).length) config.conversation = conversation;
  if (form.value.macrosMode) {
    config.macros = { mode: form.value.macrosMode, ids: form.value.macroIds };
  }
  const composer = {};
  if (form.value.submitAs) composer.submit_as = form.value.submitAs === 'true';
  if (form.value.afterSend) composer.after_send = form.value.afterSend;
  if (Object.keys(composer).length) config.composer = composer;
  return config;
};

const load = async () => {
  isLoading.value = true;
  try {
    const { data } = await WorkspaceAPI.teamWorkspace(selectedTeam.value);
    form.value = fromConfig(data.config || {});
  } finally {
    isLoading.value = false;
  }
};

const save = async () => {
  isSaving.value = true;
  try {
    await WorkspaceAPI.updateTeamWorkspace(selectedTeam.value, toConfig());
    useAlert(t('STAYDESK.WORKSPACE.API.SAVE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.WORKSPACE.API.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const toggle = (list, value) => {
  const index = list.indexOf(value);
  if (index === -1) list.push(value);
  else list.splice(index, 1);
};

const orderedPanels = computed(() =>
  PANEL_NAMES.filter(name => form.value.panels.includes(name))
);

onMounted(async () => {
  await Promise.all([
    store.dispatch('dashboardApps/get'),
    store.dispatch('macros/get'),
    store.dispatch('attributes/get'),
  ]);
  await load();
});

watch(selectedTeam, load);
</script>

<template>
  <SettingsLayout :is-loading="isLoading">
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.WORKSPACE.SETTINGS_TITLE')"
        :description="t('STAYDESK.WORKSPACE.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            :label="t('STAYDESK.WORKSPACE.SAVE')"
            size="sm"
            :is-loading="isSaving"
            @click="save"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <form class="grid gap-6" @submit.prevent="save">
        <label class="grid gap-1 text-sm text-n-slate-12">
          <span>{{ t('STAYDESK.WORKSPACE.TEAM') }}</span>
          <select
            v-model="selectedTeam"
            class="h-9 max-w-sm rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12"
          >
            <option value="default">
              {{ t('STAYDESK.WORKSPACE.ACCOUNT_DEFAULT') }}
            </option>
            <option v-for="team in teams" :key="team.id" :value="team.id">
              {{ team.name }}
            </option>
          </select>
        </label>

        <fieldset class="grid gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.MENU') }}
          </legend>
          <div class="flex flex-wrap gap-3">
            <label
              v-for="name in MENU_NAMES"
              :key="name"
              class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-1.5 text-sm text-n-slate-12"
            >
              <input
                type="checkbox"
                :checked="form.menu.includes(name)"
                @change="toggle(form.menu, name)"
              />
              {{ t(`STAYDESK.WORKSPACE.MENU_ITEMS.${name}`) }}
            </label>
          </div>
        </fieldset>

        <fieldset class="grid gap-3">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.LIST') }}
          </legend>
          <div class="grid gap-4 md:grid-cols-2">
            <label class="grid gap-1 text-sm text-n-slate-12">
              <span>{{ t('STAYDESK.WORKSPACE.LAYOUT') }}</span>
              <select
                v-model="form.layout"
                class="h-9 rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm"
              >
                <option value="">{{ t('STAYDESK.WORKSPACE.INHERIT') }}</option>
                <option value="cards">
                  {{ t('STAYDESK.WORKSPACE.LAYOUT_CARDS') }}
                </option>
                <option value="table">
                  {{ t('STAYDESK.WORKSPACE.LAYOUT_TABLE') }}
                </option>
              </select>
            </label>
            <label class="grid gap-1 text-sm text-n-slate-12">
              <span>{{ t('STAYDESK.TEAM_VIEWS.FORM.SORT_BY') }}</span>
              <select
                v-model="form.sortBy"
                class="h-9 rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm"
              >
                <option value="">{{ t('STAYDESK.WORKSPACE.INHERIT') }}</option>
                <option
                  v-for="option in SORT_OPTIONS"
                  :key="option"
                  :value="option"
                >
                  {{ t(`STAYDESK.TEAM_VIEWS.SORT.${option}`) }}
                </option>
              </select>
            </label>
          </div>
          <span class="text-sm text-n-slate-12">{{
            t('STAYDESK.WORKSPACE.COLUMNS')
          }}</span>
          <div class="flex flex-wrap gap-3">
            <label
              v-for="column in TEAM_VIEW_COLUMNS"
              :key="column"
              class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-1.5 text-sm text-n-slate-12"
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

        <fieldset class="grid gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.FIELDS') }}
          </legend>
          <p class="text-xs text-n-slate-11">
            {{ t('STAYDESK.WORKSPACE.FIELDS_HINT') }}
          </p>
          <div class="flex flex-wrap gap-3">
            <label
              class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-1.5 text-sm text-n-slate-12"
            >
              <input v-model="form.standardFields" type="checkbox" />
              {{ t('STAYDESK.WORKSPACE.STANDARD_FIELDS') }}
            </label>
            <label
              v-for="attribute in customAttributes"
              :key="attribute.attribute_key"
              class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-1.5 text-sm text-n-slate-12"
            >
              <input
                type="checkbox"
                :checked="form.fields.includes(attribute.attribute_key)"
                @change="toggle(form.fields, attribute.attribute_key)"
              />
              {{ attribute.attribute_display_name }}
            </label>
          </div>
        </fieldset>

        <fieldset class="grid gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.PANELS') }}
          </legend>
          <div class="flex flex-wrap gap-3">
            <label
              v-for="name in PANEL_NAMES"
              :key="name"
              class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-1.5 text-sm text-n-slate-12"
            >
              <input
                type="checkbox"
                :checked="orderedPanels.includes(name)"
                @change="toggle(form.panels, name)"
              />
              {{ t(`STAYDESK.WORKSPACE.PANEL_ITEMS.${name}`) }}
            </label>
          </div>
        </fieldset>

        <fieldset v-if="dashboardApps.length" class="grid gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.APPS') }}
          </legend>
          <div class="flex flex-wrap gap-3">
            <label
              v-for="app in dashboardApps"
              :key="app.id"
              class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-1.5 text-sm text-n-slate-12"
            >
              <input
                type="checkbox"
                :checked="form.apps.includes(app.id)"
                @change="toggle(form.apps, app.id)"
              />
              {{ app.title }}
            </label>
          </div>
        </fieldset>

        <fieldset class="grid gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.MACROS') }}
          </legend>
          <select
            v-model="form.macrosMode"
            class="h-9 max-w-sm rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12"
          >
            <option value="">{{ t('STAYDESK.WORKSPACE.INHERIT') }}</option>
            <option value="all">
              {{ t('STAYDESK.WORKSPACE.MACROS_ALL') }}
            </option>
            <option value="list">
              {{ t('STAYDESK.WORKSPACE.MACROS_LIST') }}
            </option>
          </select>
          <div v-if="form.macrosMode === 'list'" class="flex flex-wrap gap-3">
            <label
              v-for="macro in macros"
              :key="macro.id"
              class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-1.5 text-sm text-n-slate-12"
            >
              <input
                type="checkbox"
                :checked="form.macroIds.includes(macro.id)"
                @change="toggle(form.macroIds, macro.id)"
              />
              {{ macro.name }}
            </label>
          </div>
        </fieldset>

        <fieldset class="grid gap-3">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.COMPOSER') }}
          </legend>
          <div class="grid gap-4 md:grid-cols-2">
            <label class="grid gap-1 text-sm text-n-slate-12">
              <span>{{ t('STAYDESK.WORKSPACE.SUBMIT_AS') }}</span>
              <select
                v-model="form.submitAs"
                class="h-9 rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm"
              >
                <option value="">{{ t('STAYDESK.WORKSPACE.INHERIT') }}</option>
                <option value="true">{{ t('STAYDESK.WORKSPACE.YES') }}</option>
                <option value="false">{{ t('STAYDESK.WORKSPACE.NO') }}</option>
              </select>
            </label>
            <label class="grid gap-1 text-sm text-n-slate-12">
              <span>{{ t('STAYDESK.WORKSPACE.AFTER_SEND') }}</span>
              <select
                v-model="form.afterSend"
                class="h-9 rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm"
              >
                <option value="">{{ t('STAYDESK.WORKSPACE.INHERIT') }}</option>
                <option value="stay">
                  {{ t('STAYDESK.WORKSPACE.AFTER_SEND_STAY') }}
                </option>
                <option value="next">
                  {{ t('STAYDESK.WORKSPACE.AFTER_SEND_NEXT') }}
                </option>
                <option value="close">
                  {{ t('STAYDESK.WORKSPACE.AFTER_SEND_CLOSE') }}
                </option>
              </select>
            </label>
          </div>
        </fieldset>
      </form>
    </template>
  </SettingsLayout>
</template>
