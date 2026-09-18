<script setup>
import { computed, onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import { useAgentStatusStore } from '../store/agentStatus';
import { emDuracao } from '../helpers/duracao';
import { fromSaveButton } from '../helpers/form';

// Configurações › Status dos agentes: o catálogo que aparece no menu de disponibilidade.
const { t } = useI18n();
const store = useAgentStatusStore();
const inboxes = useMapGetter('inboxes/getInboxes');

const editing = ref(null);
const deleting = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');
const emptyForm = () => ({
  name: '',
  color: '#1a9f63',
  availability: 'online',
  inboxIds: [],
  active: true,
  capacity: {},
});
const form = ref(emptyForm());

const statuses = computed(() => store.statuses);
// Os limites seguem as filas de carga configuradas, não uma lista fixa no código.
const loadQueues = computed(() => store.loadQueues);
const loads = computed(() => store.loads);
const offerStats = computed(() =>
  store.offerStats.filter(linha => linha.offers > 0)
);
const availabilityOptions = computed(() => [
  { value: 'online', label: t('STAYDESK.AGENT_STATUS.AVAILABILITY.online') },
  { value: 'busy', label: t('STAYDESK.AGENT_STATUS.AVAILABILITY.busy') },
]);

const inboxNames = status =>
  status.inbox_ids.length
    ? inboxes.value
        .filter(inbox => status.inbox_ids.includes(inbox.id))
        .map(inbox => inbox.name)
        .join(', ')
    : t('STAYDESK.AGENT_STATUS.ALL_INBOXES');

const startEdit = status => {
  editing.value = status || 'new';
  form.value = status
    ? {
        name: status.name,
        color: status.color || '#1a9f63',
        availability: status.availability,
        inboxIds: [...status.inbox_ids],
        active: status.active,
        capacity: {
          chat: status.capacity?.chat ?? '',
          ticket: status.capacity?.ticket ?? '',
        },
      }
    : emptyForm();
};

const inboxOptions = computed(() =>
  inboxes.value.map(inbox => ({ value: inbox.id, label: inbox.name }))
);

const save = async () => {
  if (!form.value.name.trim()) return;
  try {
    await store.save(editing.value === 'new' ? null : editing.value.id, {
      name: form.value.name.trim(),
      color: form.value.color,
      availability: form.value.availability,
      inbox_ids: form.value.inboxIds,
      active: form.value.active,
      capacity: {
        chat: form.value.capacity.chat,
        ticket: form.value.capacity.ticket,
      },
    });
    useAlert(t('STAYDESK.AGENT_STATUS.API.SAVE_SUCCESS'));
    editing.value = null;
  } catch {
    useAlert(t('STAYDESK.AGENT_STATUS.API.SAVE_ERROR'));
  }
};

const openDelete = status => {
  deleting.value = status;
  deleteDialog.value.open();
};

const confirmDelete = async () => {
  try {
    await store.remove(deleting.value.id);
    useAlert(t('STAYDESK.AGENT_STATUS.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.AGENT_STATUS.API.DELETE_ERROR'));
  } finally {
    deleteDialog.value.close();
    deleting.value = null;
  }
};

// Rótulo de um limite: número, "não recebe" quando é zero, "sem limite" quando não há.
const capacityLabel = value => {
  if (value === 0) return t('STAYDESK.AGENT_STATUS.CAPACITY.NONE');
  if (value === null || value === undefined || value === '')
    return t('STAYDESK.AGENT_STATUS.CAPACITY.UNLIMITED');
  return String(value);
};

const capacitySummary = status => {
  const definidos = loadQueues.value.filter(
    fila => status.capacity?.[fila.key] !== undefined
  );
  if (!definidos.length) return t('STAYDESK.AGENT_STATUS.CAPACITY.UNLIMITED');
  return definidos
    .map(fila => `${fila.name}: ${capacityLabel(status.capacity[fila.key])}`)
    .join(' · ');
};

const loadLabel = (entry, queue) =>
  `${entry.load?.[queue] ?? 0} / ${capacityLabel(entry.capacity?.[queue])}`;

onMounted(() => {
  store.fetch();
  store.fetchLoadQueues();
  store.fetchLoads();
  store.fetchOfferStats();
});
// Só o botão de salvar (ou o Enter) envia: clique em botão de dentro não salva.
const aoEnviar = event => {
  if (fromSaveButton(event)) save();
};
</script>

<template>
  <SettingsLayout
    :is-loading="store.uiFlags.isFetching && !statuses.length"
    :no-records-found="!statuses.length && !editing"
    :no-records-message="t('STAYDESK.AGENT_STATUS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.AGENT_STATUS.SETTINGS_TITLE')"
        :description="t('STAYDESK.AGENT_STATUS.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            v-if="!editing"
            :label="t('STAYDESK.AGENT_STATUS.NEW')"
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
        <div class="grid gap-4 md:grid-cols-3">
          <Input
            v-model="form.name"
            :label="t('STAYDESK.AGENT_STATUS.FORM.NAME')"
          />
          <label class="grid gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.AGENT_STATUS.FORM.AVAILABILITY') }}</span>
            <Select
              v-model="form.availability"
              :options="availabilityOptions"
            />
          </label>
          <label class="grid gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.AGENT_STATUS.FORM.COLOR') }}</span>
            <input
              v-model="form.color"
              type="color"
              class="h-9 w-16 cursor-pointer rounded-lg border border-n-weak bg-n-alpha-1 p-0"
            />
          </label>
        </div>
        <div class="grid gap-4 md:grid-cols-2">
          <label
            v-for="fila in loadQueues"
            :key="fila.key"
            class="grid gap-1 text-sm text-n-slate-12"
          >
            <span>
              {{
                t('STAYDESK.AGENT_STATUS.FORM.CAPACITY_QUEUE', {
                  queue: fila.name,
                })
              }}
            </span>
            <input
              v-model="form.capacity[fila.key]"
              type="number"
              min="0"
              class="h-9 w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12"
            />
          </label>
        </div>
        <p class="text-xs text-n-slate-11">
          {{ t('STAYDESK.AGENT_STATUS.FORM.CAPACITY_HINT') }}
        </p>
        <fieldset class="grid gap-2">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.AGENT_STATUS.FORM.INBOXES') }}
          </legend>
          <p class="text-xs text-n-slate-11">
            {{ t('STAYDESK.AGENT_STATUS.FORM.INBOXES_HINT') }}
          </p>
          <TagMultiSelectComboBox
            v-model="form.inboxIds"
            :options="inboxOptions"
            :placeholder="t('STAYDESK.AGENT_STATUS.FORM.INBOXES_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
        </fieldset>
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <Switch v-model="form.active" />
          {{ t('STAYDESK.AGENT_STATUS.FORM.ACTIVE') }}
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
            :is-loading="store.uiFlags.isSaving"
          >
            {{ t('STAYDESK.TEAM_VIEWS.FORM.SAVE') }}
          </Button>
        </div>
      </form>
    </template>
    <template #body>
      <table class="w-full text-sm">
        <tbody class="divide-y divide-n-weak">
          <tr v-for="status in statuses" :key="status.id">
            <td class="py-3 pr-4">
              <span
                class="inline-flex items-center gap-2 font-medium text-n-slate-12"
              >
                <span
                  class="inline-block size-2.5 rounded"
                  :style="{ backgroundColor: status.color || '#1a9f63' }"
                />
                {{ status.name }}
              </span>
            </td>
            <td class="py-3 pr-4 text-n-slate-11">
              {{
                t(`STAYDESK.AGENT_STATUS.AVAILABILITY.${status.availability}`)
              }}
            </td>
            <td class="py-3 pr-4 text-n-slate-11">{{ inboxNames(status) }}</td>
            <td class="py-3 pr-4 text-n-slate-11">
              {{ capacitySummary(status) }}
            </td>
            <td class="whitespace-nowrap py-3 text-right">
              <Button
                v-tooltip.top="t('STAYDESK.AGENT_STATUS.EDIT')"
                icon="i-woot-settings"
                slate
                sm
                @click="startEdit(status)"
              />
              <Button
                v-tooltip.top="t('STAYDESK.AGENT_STATUS.DELETE.BUTTON')"
                icon="i-woot-bin"
                slate
                sm
                class="hover:enabled:bg-n-ruby-2 hover:enabled:text-n-ruby-11"
                @click="openDelete(status)"
              />
            </td>
          </tr>
        </tbody>
      </table>
      <section class="mt-8">
        <div class="flex items-center justify-between gap-4">
          <div>
            <h3 class="text-base font-medium text-n-slate-12">
              {{ t('STAYDESK.AGENT_STATUS.LOAD.TITLE') }}
            </h3>
            <p class="text-xs text-n-slate-11">
              {{ t('STAYDESK.AGENT_STATUS.LOAD.DESCRIPTION') }}
            </p>
          </div>
          <Button
            sm
            faded
            slate
            :is-loading="store.uiFlags.isFetchingLoads"
            @click="store.fetchLoads()"
          >
            {{ t('STAYDESK.AGENT_STATUS.LOAD.REFRESH') }}
          </Button>
        </div>
        <table class="mt-3 w-full text-sm">
          <thead>
            <tr class="text-left text-xs uppercase text-n-slate-11">
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.AGENT_STATUS.LOAD.AGENT') }}
              </th>
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.AGENT_STATUS.LOAD.STATUS') }}
              </th>
              <th
                v-for="fila in loadQueues"
                :key="fila.key"
                class="py-2 pr-4 font-medium"
              >
                {{ fila.name }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-weak">
            <tr v-for="entry in loads" :key="entry.user_id">
              <td class="py-2 pr-4 text-n-slate-12">{{ entry.name }}</td>
              <td class="py-2 pr-4 text-n-slate-11">
                <span
                  v-if="entry.status"
                  class="inline-flex items-center gap-2"
                >
                  <span
                    class="inline-block size-2 rounded-full"
                    :style="{
                      backgroundColor: entry.status.color || '#1a9f63',
                    }"
                  />
                  {{ entry.status.name }}
                </span>
                <span v-else>
                  {{ t('STAYDESK.AGENT_STATUS.LOAD.NO_STATUS') }}
                </span>
              </td>
              <td
                v-for="fila in loadQueues"
                :key="fila.key"
                class="py-2 pr-4 text-n-slate-11"
              >
                {{ loadLabel(entry, fila.key) }}
              </td>
            </tr>
          </tbody>
        </table>
      </section>
      <section v-if="offerStats.length" class="mt-8 grid gap-3">
        <header class="grid gap-1">
          <h3 class="m-0 text-sm font-medium text-n-slate-12">
            {{ t('STAYDESK.AGENT_STATUS.OFFERS.TITLE') }}
          </h3>
          <p class="m-0 text-xs text-n-slate-11">
            {{ t('STAYDESK.AGENT_STATUS.OFFERS.DESCRIPTION') }}
          </p>
        </header>
        <div class="overflow-x-auto">
          <table class="w-full min-w-[32rem] border-collapse text-sm">
            <thead>
              <tr class="text-left text-xs uppercase text-n-slate-11">
                <th class="py-2 pr-4 font-medium">
                  {{ t('STAYDESK.AGENT_STATUS.LOAD.AGENT') }}
                </th>
                <th class="py-2 pr-4 font-medium">
                  {{ t('STAYDESK.AGENT_STATUS.OFFERS.OFFERED') }}
                </th>
                <th class="py-2 pr-4 font-medium">
                  {{ t('STAYDESK.AGENT_STATUS.OFFERS.ACCEPTED') }}
                </th>
                <th class="py-2 pr-4 font-medium">
                  {{ t('STAYDESK.AGENT_STATUS.OFFERS.RATE') }}
                </th>
                <th class="py-2 font-medium">
                  {{ t('STAYDESK.AGENT_STATUS.OFFERS.ANSWER_TIME') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-n-weak">
              <tr v-for="linha in offerStats" :key="linha.user_id">
                <td class="py-2 pr-4 text-n-slate-12">{{ linha.name }}</td>
                <td class="py-2 pr-4 text-n-slate-11">{{ linha.offers }}</td>
                <td class="py-2 pr-4 text-n-slate-11">{{ linha.accepted }}</td>
                <td class="py-2 pr-4 text-n-slate-11">
                  {{
                    linha.acceptance_rate === null
                      ? '—'
                      : `${linha.acceptance_rate}%`
                  }}
                </td>
                <td class="py-2 text-n-slate-11">
                  {{ emDuracao(linha.average_answer_seconds) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </template>
  </SettingsLayout>
  <Dialog
    ref="deleteDialog"
    type="alert"
    :title="t('STAYDESK.AGENT_STATUS.DELETE.BUTTON')"
    :description="
      t('STAYDESK.AGENT_STATUS.DELETE.CONFIRM', { name: deleting?.name || '' })
    "
    :confirm-button-label="t('STAYDESK.AGENT_STATUS.DELETE.BUTTON')"
    :cancel-button-label="t('STAYDESK.TEAM_VIEWS.FORM.CANCEL')"
    @confirm="confirmDelete"
  />
</template>
