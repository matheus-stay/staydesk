<script setup>
import { computed, onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import { useTicketStatusStore } from '../store/ticketStatus';

// Configurações › Status dos tickets: o catálogo que o agente escolhe na conversa.
// Cada status mapeia para um dos quatro do Chatwoot (aberto, pendente, adiado, resolvido).
const BASE_STATUSES = ['open', 'pending', 'snoozed', 'resolved'];
const DEFAULT_COLOR = '#545DFF';

const { t } = useI18n();
const store = useTicketStatusStore();

const editing = ref(null);
const deleting = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');
const emptyForm = () => ({
  name: '',
  description: '',
  color: DEFAULT_COLOR,
  baseStatus: 'open',
  defaultForBase: false,
  active: true,
});
const form = ref(emptyForm());

const statuses = computed(() => store.statuses);
const baseLabel = value =>
  t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${value}.TEXT`);
const baseOptions = computed(() =>
  BASE_STATUSES.map(value => ({ value, label: baseLabel(value) }))
);

const startEdit = status => {
  editing.value = status || 'new';
  form.value = status
    ? {
        name: status.name,
        description: status.description || '',
        color: status.color || DEFAULT_COLOR,
        baseStatus: status.base_status,
        defaultForBase: status.default_for_base,
        active: status.active,
      }
    : emptyForm();
};

const save = async () => {
  if (!form.value.name.trim()) return;
  try {
    await store.save(editing.value === 'new' ? null : editing.value.id, {
      name: form.value.name.trim(),
      description: form.value.description.trim(),
      color: form.value.color,
      base_status: form.value.baseStatus,
      default_for_base: form.value.defaultForBase,
      active: form.value.active,
    });
    useAlert(t('STAYDESK.TICKET_STATUS.API.SAVE_SUCCESS'));
    editing.value = null;
  } catch {
    useAlert(t('STAYDESK.TICKET_STATUS.API.SAVE_ERROR'));
  }
};

const move = async (status, direction) => {
  const ids = statuses.value.map(item => item.id);
  const from = ids.indexOf(status.id);
  const to = from + direction;
  if (to < 0 || to >= ids.length) return;
  ids.splice(from, 1);
  ids.splice(to, 0, status.id);
  try {
    await store.reorder(ids);
  } catch {
    useAlert(t('STAYDESK.TICKET_STATUS.API.SAVE_ERROR'));
  }
};

const openDelete = status => {
  deleting.value = status;
  deleteDialog.value.open();
};

const confirmDelete = async () => {
  try {
    await store.remove(deleting.value.id);
    useAlert(t('STAYDESK.TICKET_STATUS.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.TICKET_STATUS.API.DELETE_ERROR'));
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
    :no-records-message="t('STAYDESK.TICKET_STATUS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.TICKET_STATUS.SETTINGS_TITLE')"
        :description="t('STAYDESK.TICKET_STATUS.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            v-if="!editing"
            :label="t('STAYDESK.TICKET_STATUS.NEW')"
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
            :label="t('STAYDESK.TICKET_STATUS.FORM.NAME')"
          />
          <label class="grid gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.TICKET_STATUS.FORM.BASE_STATUS') }}</span>
            <Select v-model="form.baseStatus" :options="baseOptions" />
          </label>
          <label class="grid gap-1 text-sm text-n-slate-12">
            <span>{{ t('STAYDESK.TICKET_STATUS.FORM.COLOR') }}</span>
            <input
              v-model="form.color"
              type="color"
              class="h-9 w-16 cursor-pointer rounded-lg border border-n-weak bg-n-alpha-1 p-0"
            />
          </label>
        </div>
        <Input
          v-model="form.description"
          :label="t('STAYDESK.TICKET_STATUS.FORM.DESCRIPTION')"
        />
        <p class="text-xs text-n-slate-11">
          {{ t('STAYDESK.TICKET_STATUS.FORM.BASE_STATUS_HINT') }}
        </p>
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <input v-model="form.defaultForBase" type="checkbox" />
          {{ t('STAYDESK.TICKET_STATUS.FORM.DEFAULT_FOR_BASE') }}
        </label>
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <input v-model="form.active" type="checkbox" />
          {{ t('STAYDESK.TICKET_STATUS.FORM.ACTIVE') }}
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
          <tr
            v-for="(status, index) in statuses"
            :key="status.id"
            :class="{ 'opacity-60': !status.active }"
          >
            <td class="py-3 pr-4">
              <span
                class="inline-flex items-center gap-2 font-medium text-n-slate-12"
              >
                <span
                  class="inline-block size-2.5 rounded"
                  :style="{ backgroundColor: status.color || '#545DFF' }"
                />
                {{ status.name }}
                <span
                  v-if="status.default_for_base"
                  class="rounded bg-n-alpha-2 px-1.5 py-0.5 text-xs text-n-slate-11"
                >
                  {{ t('STAYDESK.TICKET_STATUS.DEFAULT_BADGE') }}
                </span>
              </span>
              <p v-if="status.description" class="text-xs text-n-slate-11">
                {{ status.description }}
              </p>
            </td>
            <td class="py-3 pr-4 text-n-slate-11">
              {{ baseLabel(status.base_status) }}
            </td>
            <td class="whitespace-nowrap py-3 text-right">
              <Button
                v-tooltip.top="t('STAYDESK.TICKET_STATUS.MOVE_UP')"
                icon="i-lucide-chevron-up"
                slate
                sm
                :disabled="index === 0"
                @click="move(status, -1)"
              />
              <Button
                v-tooltip.top="t('STAYDESK.TICKET_STATUS.MOVE_DOWN')"
                icon="i-lucide-chevron-down"
                slate
                sm
                :disabled="index === statuses.length - 1"
                @click="move(status, 1)"
              />
              <Button
                v-tooltip.top="t('STAYDESK.TICKET_STATUS.EDIT')"
                icon="i-woot-settings"
                slate
                sm
                @click="startEdit(status)"
              />
              <Button
                v-tooltip.top="t('STAYDESK.TICKET_STATUS.DELETE.BUTTON')"
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
    :title="t('STAYDESK.TICKET_STATUS.DELETE.BUTTON')"
    :description="
      t('STAYDESK.TICKET_STATUS.DELETE.CONFIRM', {
        name: deleting?.name || '',
      })
    "
    :confirm-button-label="t('STAYDESK.TICKET_STATUS.DELETE.BUTTON')"
    :cancel-button-label="t('STAYDESK.TEAM_VIEWS.FORM.CANCEL')"
    @confirm="confirmDelete"
  />
</template>
