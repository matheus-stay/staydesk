<script setup>
import { computed, onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import { useAgentStatusStore } from '../store/agentStatus';

// Configurações › Status dos agentes: o catálogo que aparece no menu de disponibilidade.
const { t } = useI18n();
const store = useAgentStatusStore();
const inboxes = useMapGetter('inboxes/getInboxes');

const editing = ref(null);
const deleting = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');
const form = ref({
  name: '',
  color: '#1a9f63',
  availability: 'online',
  inboxIds: [],
  active: true,
});

const statuses = computed(() => store.statuses);
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
      }
    : {
        name: '',
        color: '#1a9f63',
        availability: 'online',
        inboxIds: [],
        active: true,
      };
};

const toggleInbox = id => {
  const index = form.value.inboxIds.indexOf(id);
  if (index === -1) form.value.inboxIds.push(id);
  else form.value.inboxIds.splice(index, 1);
};

const save = async () => {
  if (!form.value.name.trim()) return;
  try {
    await store.save(editing.value === 'new' ? null : editing.value.id, {
      name: form.value.name.trim(),
      color: form.value.color,
      availability: form.value.availability,
      inbox_ids: form.value.inboxIds,
      active: form.value.active,
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

onMounted(() => store.fetch());
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
        @submit.prevent="save"
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
        <fieldset class="grid gap-2">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.AGENT_STATUS.FORM.INBOXES') }}
          </legend>
          <p class="text-xs text-n-slate-11">
            {{ t('STAYDESK.AGENT_STATUS.FORM.INBOXES_HINT') }}
          </p>
          <div class="flex flex-wrap gap-3">
            <label
              v-for="inbox in inboxes"
              :key="inbox.id"
              class="flex items-center gap-2 rounded-lg border border-n-weak px-3 py-1.5 text-sm text-n-slate-12"
            >
              <input
                type="checkbox"
                :checked="form.inboxIds.includes(inbox.id)"
                @change="toggleInbox(inbox.id)"
              />
              {{ inbox.name }}
            </label>
          </div>
        </fieldset>
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <input v-model="form.active" type="checkbox" />
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
