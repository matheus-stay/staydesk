<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import wootConstants from 'dashboard/constants/globals';
import Select from 'dashboard/components-next/select/Select.vue';
import ReorderableMultiSelect from 'dashboard/components-next/combobox/ReorderableMultiSelect.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
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
const inherit = () => ({ value: '', label: t('STAYDESK.WORKSPACE.INHERIT') });
const teamOptions = computed(() => [
  { value: 'default', label: t('STAYDESK.WORKSPACE.ACCOUNT_DEFAULT') },
  ...teams.value.map(team => ({ value: team.id, label: team.name })),
]);
const layoutOptions = computed(() => [
  inherit(),
  { value: 'cards', label: t('STAYDESK.WORKSPACE.LAYOUT_CARDS') },
  { value: 'table', label: t('STAYDESK.WORKSPACE.LAYOUT_TABLE') },
]);
const sortOptions = computed(() => [
  inherit(),
  ...SORT_OPTIONS.map(value => ({
    value,
    label: t(`STAYDESK.TEAM_VIEWS.SORT.${value}`),
  })),
]);
const macrosOptions = computed(() => [
  inherit(),
  { value: 'all', label: t('STAYDESK.WORKSPACE.MACROS_ALL') },
  { value: 'list', label: t('STAYDESK.WORKSPACE.MACROS_LIST') },
]);
const submitAsOptions = computed(() => [
  inherit(),
  { value: 'true', label: t('STAYDESK.WORKSPACE.YES') },
  { value: 'false', label: t('STAYDESK.WORKSPACE.NO') },
]);
const afterSendOptions = computed(() => [
  inherit(),
  { value: 'stay', label: t('STAYDESK.WORKSPACE.AFTER_SEND_STAY') },
  { value: 'next', label: t('STAYDESK.WORKSPACE.AFTER_SEND_NEXT') },
  { value: 'close', label: t('STAYDESK.WORKSPACE.AFTER_SEND_CLOSE') },
]);
const dashboardApps = useMapGetter('dashboardApps/getRecords');
const macros = useMapGetter('macros/getMacros');
const attributesByModel = useMapGetter('attributes/getAttributesByModel');

const selectedTeam = ref('default');
const isLoading = ref(false);
const isSaving = ref(false);

const emptyForm = () => ({
  menu: [],
  conversationMenu: [],
  layout: '',
  columns: [],
  sortBy: '',
  hideWhenOpen: false,
  standardFields: false,
  fields: [],
  panels: [],
  apps: [],
  sideApps: [],
  macrosMode: '',
  macroIds: [],
  submitAs: '',
  afterSend: '',
});
const form = ref(emptyForm());

const CONVERSATION_MENU_NAMES = [
  'All',
  'Mentions',
  'Participating',
  'Unattended',
  'Folders',
  'StaydeskTeamViews',
  'Teams',
  'Channels',
];
const conversationMenuOptions = computed(() =>
  CONVERSATION_MENU_NAMES.map(name => ({
    value: name,
    label: t(`STAYDESK.WORKSPACE.CONVERSATION_MENU_ITEMS.${name}`),
  }))
);
const menuOptions = computed(() =>
  MENU_NAMES.map(name => ({
    value: name,
    label: t(`STAYDESK.WORKSPACE.MENU_ITEMS.${name}`),
  }))
);
const columnOptions = computed(() =>
  TEAM_VIEW_COLUMNS.map(column => ({
    value: column,
    label: t(`STAYDESK.TEAM_VIEWS.COLUMN.${column}`),
  }))
);
const panelOptions = computed(() =>
  PANEL_NAMES.map(name => ({
    value: name,
    label: t(`STAYDESK.WORKSPACE.PANEL_ITEMS.${name}`),
  }))
);
const customAttributes = computed(
  () => attributesByModel.value('conversation_attribute') || []
);
const appOptions = computed(() =>
  dashboardApps.value.map(app => ({ value: app.id, label: app.title }))
);
const macroOptions = computed(() =>
  macros.value.map(macro => ({ value: macro.id, label: macro.name }))
);
const sideAppOptions = computed(() =>
  dashboardApps.value.map(app => ({ value: app.id, label: app.title }))
);
const fieldOptions = computed(() =>
  customAttributes.value.map(attribute => ({
    value: attribute.attribute_key,
    label: attribute.attribute_display_name,
  }))
);

const fromConfig = config => {
  const fields = config.conversation?.fields || [];
  return {
    menu: config.menu || [],
    conversationMenu: config.conversation_menu || [],
    layout: config.list?.layout || '',
    columns: config.list?.columns || [],
    hideWhenOpen: config.list?.hide_when_open === true,
    sortBy: config.list?.sort_by || '',
    standardFields: fields.some(field => STANDARD_FIELDS.includes(field)),
    fields: fields.filter(field => !STANDARD_FIELDS.includes(field)),
    panels: config.conversation?.panels || [],
    apps: config.conversation?.apps || [],
    sideApps: config.conversation?.side_apps || [],
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
  if (form.value.conversationMenu.length)
    config.conversation_menu = form.value.conversationMenu;
  const list = {};
  if (form.value.layout) list.layout = form.value.layout;
  if (form.value.columns.length) list.columns = form.value.columns;
  if (form.value.sortBy) list.sort_by = form.value.sortBy;
  if (form.value.hideWhenOpen) list.hide_when_open = true;
  if (Object.keys(list).length) config.list = list;
  const conversation = {};
  const fields = [
    ...(form.value.standardFields ? STANDARD_FIELDS : []),
    ...form.value.fields,
  ];
  if (fields.length) conversation.fields = fields;
  if (form.value.panels.length) conversation.panels = form.value.panels;
  if (form.value.apps.length) conversation.apps = form.value.apps;
  if (form.value.sideApps.length) conversation.side_apps = form.value.sideApps;
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
          <Select v-model="selectedTeam" :options="teamOptions" />
        </label>

        <fieldset class="grid gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.MENU') }}
          </legend>
          <ReorderableMultiSelect
            v-model="form.menu"
            :options="menuOptions"
            :max="MENU_NAMES.length"
            :add-label="t('STAYDESK.WORKSPACE.ADD_MENU_ITEM')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
          <p class="text-xs text-n-slate-11">
            {{ t('STAYDESK.WORKSPACE.CONVERSATION_MENU_HINT') }}
          </p>
          <ReorderableMultiSelect
            v-model="form.conversationMenu"
            :options="conversationMenuOptions"
            :max="CONVERSATION_MENU_NAMES.length"
            :add-label="t('STAYDESK.WORKSPACE.ADD_CONVERSATION_ITEM')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
        </fieldset>

        <fieldset class="grid gap-3">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.LIST') }}
          </legend>
          <div class="grid gap-4 md:grid-cols-2">
            <label class="grid gap-1 text-sm text-n-slate-12">
              <span>{{ t('STAYDESK.WORKSPACE.LAYOUT') }}</span>
              <Select v-model="form.layout" :options="layoutOptions" />
            </label>
            <label class="grid gap-1 text-sm text-n-slate-12">
              <span>{{ t('STAYDESK.TEAM_VIEWS.FORM.SORT_BY') }}</span>
              <Select v-model="form.sortBy" :options="sortOptions" />
            </label>
          </div>
          <span class="text-sm text-n-slate-12">{{
            t('STAYDESK.WORKSPACE.COLUMNS')
          }}</span>
          <label class="flex items-center gap-3 text-sm text-n-slate-12">
            <Switch v-model="form.hideWhenOpen" />
            {{ t('STAYDESK.WORKSPACE.HIDE_LIST_WHEN_OPEN') }}
          </label>
          <ReorderableMultiSelect
            v-model="form.columns"
            :options="columnOptions"
            :max="TEAM_VIEW_COLUMNS.length"
            :add-label="t('STAYDESK.TEAM_VIEWS.FORM.ADD_COLUMN')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
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
              <Switch v-model="form.standardFields" />
              {{ t('STAYDESK.WORKSPACE.STANDARD_FIELDS') }}
            </label>
            <ReorderableMultiSelect
              v-model="form.fields"
              :options="fieldOptions"
              :max="Math.max(fieldOptions.length, 1)"
              :add-label="t('STAYDESK.WORKSPACE.ADD_FIELD')"
              :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
              :empty-state="t('STAYDESK.PICKER.EMPTY')"
            />
          </div>
        </fieldset>

        <fieldset class="grid gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.PANELS') }}
          </legend>
          <ReorderableMultiSelect
            v-model="form.panels"
            :options="panelOptions"
            :max="PANEL_NAMES.length"
            :add-label="t('STAYDESK.WORKSPACE.ADD_PANEL')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
        </fieldset>

        <fieldset v-if="dashboardApps.length" class="grid gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.APPS') }}
          </legend>
          <TagMultiSelectComboBox
            v-model="form.apps"
            :options="appOptions"
            :placeholder="t('STAYDESK.WORKSPACE.APPS_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
          <p class="text-xs text-n-slate-11">
            {{ t('STAYDESK.WORKSPACE.SIDE_APPS_HINT') }}
          </p>
          <TagMultiSelectComboBox
            v-model="form.sideApps"
            :options="sideAppOptions"
            :placeholder="t('STAYDESK.WORKSPACE.SIDE_APPS_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
        </fieldset>

        <fieldset class="grid gap-2">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.MACROS') }}
          </legend>
          <Select v-model="form.macrosMode" :options="macrosOptions" />
          <TagMultiSelectComboBox
            v-if="form.macrosMode === 'list'"
            v-model="form.macroIds"
            :options="macroOptions"
            :placeholder="t('STAYDESK.WORKSPACE.MACROS_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
        </fieldset>

        <fieldset class="grid gap-3">
          <legend class="text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.WORKSPACE.COMPOSER') }}
          </legend>
          <div class="grid gap-4 md:grid-cols-2">
            <label class="grid gap-1 text-sm text-n-slate-12">
              <span>{{ t('STAYDESK.WORKSPACE.SUBMIT_AS') }}</span>
              <Select v-model="form.submitAs" :options="submitAsOptions" />
            </label>
            <label class="grid gap-1 text-sm text-n-slate-12">
              <span>{{ t('STAYDESK.WORKSPACE.AFTER_SEND') }}</span>
              <Select v-model="form.afterSend" :options="afterSendOptions" />
            </label>
          </div>
        </fieldset>
      </form>
    </template>
  </SettingsLayout>
</template>
