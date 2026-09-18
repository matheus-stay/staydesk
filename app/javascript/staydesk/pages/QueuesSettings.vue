<script setup>
import { computed, onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import { useConversationFilterContext } from 'dashboard/components-next/filter/provider';
import {
  newConditionRow,
  payloadToRows,
  rowsToQuery,
} from '../helpers/teamViewQuery';
import QueuesAPI from '../api/queues';
import { fromSaveButton } from '../helpers/form';
import { canaisDaConta, nomeDoCanal } from '../helpers/canais';

// Filas de encaminhamento (SPEC-15), no modelo do Zendesk: a conversa que chega é
// comparada com as filas em ordem e a primeira que casar entrega ao time dela.
// As condições usam o mesmo construtor do filtro avançado, então qualquer campo
// da conversa serve, inclusive os atributos que a operação criar.
const { t } = useI18n();
const store = useStore();
const teams = useMapGetter('teams/getTeams');
const inboxes = useMapGetter('inboxes/getInboxes');
const { filterTypes, attributeFilterTypes } = useConversationFilterContext();

const queues = ref([]);
const isLoading = ref(false);
const isSaving = ref(false);
const editing = ref(null);
const deleting = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');
const emptyForm = () => ({
  name: '',
  description: '',
  teamId: null,
  fallbackTeamIds: [],
  fallbackMode: 'quando_faltar',
  priorityMode: 'chegada',
  fallbackAfterMinutes: '',
  channelTypes: [],
  inboxIds: [],
  acceptRequired: false,
  acceptTimeoutSeconds: 30,
  active: true,
});
const form = ref(emptyForm());
const rows = ref([]);
const conditionsRef = useTemplateRef('conditionsRef');

const teamOptions = computed(() =>
  teams.value.map(team => ({ value: team.id, label: team.name }))
);
const fallbackTeams = computed(() =>
  teams.value.filter(team => team.id !== form.value.teamId)
);
const modeOptions = computed(() =>
  ['quando_faltar', 'sempre'].map(value => ({
    value,
    label: t(`STAYDESK.QUEUES.FORM.MODE_OPTIONS.${value}`),
  }))
);
const canalOptions = computed(() => canaisDaConta(inboxes.value));
const caixaOptions = computed(() =>
  inboxes.value.map(caixa => ({ value: caixa.id, label: caixa.name }))
);

// Resumo do que a fila pega, na linguagem da operação.
const oQuePega = queue => {
  const canais = (queue.channel_types || []).map(nomeDoCanal);
  const caixas = (queue.inbox_ids || [])
    .map(id => inboxes.value.find(caixa => caixa.id === id)?.name)
    .filter(Boolean);
  const partes = [...canais, ...caixas];
  if (!partes.length) return t('STAYDESK.QUEUES.ALL_CHANNELS');
  return partes.join(', ');
};

const priorityOptions = computed(() =>
  ['chegada', 'sla'].map(value => ({
    value,
    label: t(`STAYDESK.QUEUES.FORM.PRIORITY_OPTIONS.${value}`),
  }))
);
const fallbackOptions = computed(() =>
  fallbackTeams.value.map(team => ({ value: team.id, label: team.name }))
);
// Para quem a fila transborda, e quando: o nome do grupo já diz o essencial.
const transbordo = queue => {
  const nomes = (queue.fallback_team_names || []).join(', ');
  if (!nomes) return '';
  if (queue.fallback_mode === 'sempre') {
    return t('STAYDESK.QUEUES.FALLBACK_ALWAYS', { teams: nomes });
  }
  return queue.fallback_after_minutes
    ? t('STAYDESK.QUEUES.FALLBACK_AFTER', {
        teams: nomes,
        minutes: queue.fallback_after_minutes,
      })
    : t('STAYDESK.QUEUES.FALLBACK_WHEN_MISSING', { teams: nomes });
};

const addRow = () => rows.value.push(newConditionRow());
const removeRow = index => rows.value.splice(index, 1);

// Resumo legível da fila na listagem: o nome do campo e os valores escolhidos.
const resumo = queue => {
  const condicoes = queue.conditions || [];
  if (!condicoes.length) return t('STAYDESK.QUEUES.CATCH_ALL');

  return condicoes
    .map(condicao => {
      const tipo = (filterTypes.value || []).find(
        item => item.attributeKey === condicao.attribute_key
      );
      const valores = (condicao.values || [])
        .map(valor => {
          if (condicao.attribute_key === 'inbox_id')
            return (
              inboxes.value.find(inbox => inbox.id === valor)?.name || valor
            );
          if (condicao.attribute_key === 'team_id')
            return teams.value.find(team => team.id === valor)?.name || valor;
          return valor?.name || valor;
        })
        .join(', ');
      return `${tipo?.attributeName || condicao.attribute_key}: ${valores}`;
    })
    .join(' · ');
};

const load = async () => {
  isLoading.value = true;
  try {
    const { data } = await QueuesAPI.get();
    queues.value = data;
  } finally {
    isLoading.value = false;
  }
};

const startEdit = queue => {
  editing.value = queue || 'new';
  form.value = queue
    ? {
        name: queue.name,
        description: queue.description || '',
        teamId: queue.team_id,
        fallbackTeamIds: [...(queue.fallback_team_ids || [])],
        fallbackMode: queue.fallback_mode || 'quando_faltar',
        priorityMode: queue.priority_mode || 'chegada',
        fallbackAfterMinutes: queue.fallback_after_minutes ?? '',
        channelTypes: [...(queue.channel_types || [])],
        inboxIds: [...(queue.inbox_ids || [])],
        acceptRequired: queue.accept_required || false,
        acceptTimeoutSeconds: queue.accept_timeout_seconds ?? 30,
        active: queue.active,
      }
    : emptyForm();
  rows.value = queue
    ? payloadToRows(queue.conditions || [], filterTypes.value)
    : [];
};

const save = async () => {
  if (!form.value.name.trim() || !form.value.teamId) return;
  if (!(conditionsRef.value || []).every(row => row.validate())) return;
  isSaving.value = true;
  try {
    const payload = {
      name: form.value.name.trim(),
      description: form.value.description.trim(),
      team_id: form.value.teamId,
      fallback_team_ids: form.value.fallbackTeamIds,
      fallback_mode: form.value.fallbackMode,
      priority_mode: form.value.priorityMode,
      fallback_after_minutes: form.value.fallbackAfterMinutes || null,
      channel_types: form.value.channelTypes,
      inbox_ids: form.value.inboxIds,
      accept_required: form.value.acceptRequired,
      accept_timeout_seconds: Number(form.value.acceptTimeoutSeconds) || 30,
      active: form.value.active,
      conditions: rows.value.length ? rowsToQuery(rows.value).payload : [],
    };
    const { data } =
      editing.value === 'new'
        ? await QueuesAPI.create({ queue: payload })
        : await QueuesAPI.update(editing.value.id, { queue: payload });
    queues.value =
      editing.value === 'new'
        ? [...queues.value, data]
        : queues.value.map(queue => (queue.id === data.id ? data : queue));
    editing.value = null;
    useAlert(t('STAYDESK.QUEUES.API.SAVE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.QUEUES.API.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const move = async (queue, direction) => {
  const ids = queues.value.map(item => item.id);
  const from = ids.indexOf(queue.id);
  const to = from + direction;
  if (to < 0 || to >= ids.length) return;
  ids.splice(from, 1);
  ids.splice(to, 0, queue.id);
  try {
    const { data } = await QueuesAPI.reorder(ids);
    queues.value = data;
  } catch {
    useAlert(t('STAYDESK.QUEUES.API.SAVE_ERROR'));
  }
};

const openDelete = queue => {
  deleting.value = queue;
  deleteDialog.value.open();
};

const confirmDelete = async () => {
  try {
    await QueuesAPI.delete(deleting.value.id);
    queues.value = queues.value.filter(queue => queue.id !== deleting.value.id);
    useAlert(t('STAYDESK.QUEUES.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.QUEUES.API.DELETE_ERROR'));
  } finally {
    deleteDialog.value.close();
    deleting.value = null;
  }
};

onMounted(async () => {
  await Promise.all([
    store.dispatch('attributes/get'),
    store.dispatch('agents/get'),
    store.dispatch('teams/get'),
    store.dispatch('inboxes/get'),
    store.dispatch('labels/get'),
  ]);
  await load();
});
// Só o botão de salvar (ou o Enter) envia: clique em botão de dentro não salva.
const aoEnviar = event => {
  if (fromSaveButton(event)) save();
};
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :no-records-found="!queues.length && !editing"
    :no-records-message="t('STAYDESK.QUEUES.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.QUEUES.SETTINGS_TITLE')"
        :description="t('STAYDESK.QUEUES.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            v-if="!editing"
            :label="t('STAYDESK.QUEUES.NEW')"
            size="sm"
            @click="startEdit(null)"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #preBody>
      <form
        v-if="editing"
        class="mb-6 grid gap-4 rounded-xl border border-n-weak bg-n-solid-1 p-6"
        @submit.prevent="aoEnviar"
      >
        <div class="grid gap-4 md:grid-cols-2">
          <Input v-model="form.name" :label="t('STAYDESK.QUEUES.FORM.NAME')" />
          <label class="grid gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.QUEUES.FORM.TEAM') }}</span>
            <Select v-model="form.teamId" :options="teamOptions" />
          </label>
        </div>
        <Input
          v-model="form.description"
          :label="t('STAYDESK.QUEUES.FORM.DESCRIPTION')"
        />
        <fieldset class="grid gap-3">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.QUEUES.FORM.INTAKE') }}
          </legend>
          <p class="m-0 text-xs text-n-slate-11">
            {{ t('STAYDESK.QUEUES.FORM.INTAKE_HINT') }}
          </p>
          <label class="grid gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.QUEUES.FORM.CHANNELS') }}</span>
            <TagMultiSelectComboBox
              v-model="form.channelTypes"
              :options="canalOptions"
              :placeholder="t('STAYDESK.QUEUES.FORM.CHANNELS_PLACEHOLDER')"
              :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
              :empty-state="t('STAYDESK.PICKER.EMPTY')"
            />
          </label>
          <label class="grid gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.QUEUES.FORM.INBOXES') }}</span>
            <TagMultiSelectComboBox
              v-model="form.inboxIds"
              :options="caixaOptions"
              :placeholder="t('STAYDESK.QUEUES.FORM.INBOXES_PLACEHOLDER')"
              :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
              :empty-state="t('STAYDESK.PICKER.EMPTY')"
            />
          </label>
        </fieldset>
        <fieldset class="grid gap-2">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.QUEUES.FORM.FALLBACK_TEAMS') }}
          </legend>
          <TagMultiSelectComboBox
            v-model="form.fallbackTeamIds"
            :options="fallbackOptions"
            :placeholder="t('STAYDESK.QUEUES.FORM.FALLBACK_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
          <label class="grid max-w-md gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.QUEUES.FORM.MODE') }}</span>
            <Select
              v-model="form.fallbackMode"
              :options="modeOptions"
              :disabled="!form.fallbackTeamIds.length"
            />
          </label>
          <label class="grid max-w-xs gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.QUEUES.FORM.FALLBACK_MINUTES') }}</span>
            <input
              v-model="form.fallbackAfterMinutes"
              type="number"
              min="1"
              :disabled="
                !form.fallbackTeamIds.length || form.fallbackMode === 'sempre'
              "
              class="h-9 w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12 disabled:opacity-50"
            />
          </label>
        </fieldset>
        <p class="text-xs text-n-slate-11">
          {{ t('STAYDESK.QUEUES.FORM.FALLBACK_HINT') }}
        </p>
        <fieldset class="grid gap-3">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.QUEUES.FORM.PRIORITY') }}
          </legend>
          <label class="grid max-w-sm gap-1 text-sm text-n-slate-12">
            <Select v-model="form.priorityMode" :options="priorityOptions" />
          </label>
          <p class="m-0 text-xs text-n-slate-11">
            {{ t('STAYDESK.QUEUES.FORM.PRIORITY_HINT') }}
          </p>
        </fieldset>
        <fieldset class="grid gap-3">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.QUEUES.FORM.ACCEPT') }}
          </legend>
          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Switch v-model="form.acceptRequired" />
            {{ t('STAYDESK.QUEUES.FORM.ACCEPT_REQUIRED') }}
          </label>
          <label class="grid max-w-xs gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.QUEUES.FORM.ACCEPT_TIMEOUT') }}</span>
            <input
              v-model="form.acceptTimeoutSeconds"
              type="number"
              min="5"
              max="600"
              :disabled="!form.acceptRequired"
              class="h-9 w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12 disabled:opacity-50"
            />
          </label>
          <p class="text-xs text-n-slate-11">
            {{ t('STAYDESK.QUEUES.FORM.ACCEPT_HINT') }}
          </p>
        </fieldset>
        <fieldset class="grid gap-3">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.QUEUES.FORM.CONDITIONS') }}
          </legend>
          <p class="text-xs text-n-slate-11">
            {{ t('STAYDESK.QUEUES.FORM.CONDITIONS_HINT') }}
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
          <Switch v-model="form.active" />
          {{ t('STAYDESK.QUEUES.FORM.ACTIVE') }}
        </label>
        <div class="flex justify-end gap-2">
          <Button sm faded slate type="button" @click="editing = null">
            {{ t('STAYDESK.TEAM_VIEWS.FORM.CANCEL') }}
          </Button>
          <Button
            sm
            solid
            blue
            type="submit"
            data-staydesk-save
            :is-loading="isSaving"
          >
            {{ t('STAYDESK.TEAM_VIEWS.FORM.SAVE') }}
          </Button>
        </div>
      </form>
    </template>
    <template #body>
      <table class="w-full text-sm">
        <tbody class="divide-y divide-n-weak">
          <tr
            v-for="(queue, index) in queues"
            :key="queue.id"
            :class="{ 'opacity-60': !queue.active }"
          >
            <td class="w-10 py-3 pr-2 text-n-slate-11">{{ index + 1 }}</td>
            <td class="py-3 pr-4">
              <p class="font-medium text-n-slate-12">{{ queue.name }}</p>
              <p v-if="queue.description" class="text-xs text-n-slate-11">
                {{ queue.description }}
              </p>
            </td>
            <td class="py-3 pr-4 text-n-slate-11">
              <p class="m-0">{{ oQuePega(queue) }}</p>
              <p
                v-if="(queue.conditions || []).length"
                class="m-0 text-xs text-n-slate-11"
              >
                {{ resumo(queue) }}
              </p>
            </td>
            <td class="py-3 pr-4 text-n-slate-12">
              {{ queue.team_name }}
              <span
                v-if="(queue.fallback_team_names || []).length"
                class="text-xs text-n-slate-11"
              >
                {{ transbordo(queue) }}
              </span>
              <span
                v-if="queue.priority_mode === 'sla'"
                class="text-xs text-n-slate-11"
              >
                {{ t('STAYDESK.QUEUES.PRIORITY_BADGE') }}
              </span>
              <span
                v-if="queue.accept_required"
                class="text-xs text-n-slate-11"
              >
                {{
                  t('STAYDESK.QUEUES.ACCEPT_BADGE', {
                    seconds: queue.accept_timeout_seconds,
                  })
                }}
              </span>
            </td>
            <td class="whitespace-nowrap py-3 text-right">
              <Button
                v-tooltip.top="t('STAYDESK.QUEUES.MOVE_UP')"
                icon="i-lucide-chevron-up"
                slate
                sm
                :disabled="index === 0"
                @click="move(queue, -1)"
              />
              <Button
                v-tooltip.top="t('STAYDESK.QUEUES.MOVE_DOWN')"
                icon="i-lucide-chevron-down"
                slate
                sm
                :disabled="index === queues.length - 1"
                @click="move(queue, 1)"
              />
              <Button
                v-tooltip.top="t('STAYDESK.QUEUES.EDIT')"
                icon="i-woot-settings"
                slate
                sm
                @click="startEdit(queue)"
              />
              <Button
                v-tooltip.top="t('STAYDESK.QUEUES.DELETE.BUTTON')"
                icon="i-woot-bin"
                slate
                sm
                class="hover:enabled:bg-n-ruby-2 hover:enabled:text-n-ruby-11"
                @click="openDelete(queue)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </template>
  </SettingsLayout>
  <Dialog
    ref="deleteDialog"
    type="alert"
    :title="t('STAYDESK.QUEUES.DELETE.BUTTON')"
    :description="
      t('STAYDESK.QUEUES.DELETE.CONFIRM', { name: deleting?.name || '' })
    "
    :confirm-button-label="t('STAYDESK.QUEUES.DELETE.BUTTON')"
    :cancel-button-label="t('STAYDESK.TEAM_VIEWS.FORM.CANCEL')"
    @confirm="confirmDelete"
  />
</template>
