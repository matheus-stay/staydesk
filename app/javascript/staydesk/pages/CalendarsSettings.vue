<script setup>
import { computed, onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CalendarForm from '../components/CalendarForm.vue';
import { useSlaStore } from '../store/sla';

const { t } = useI18n();
const store = useSlaStore();

const editing = ref(null);
const deleting = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');
const calendars = computed(() => store.calendars);

onMounted(() => store.fetch());

const save = async payload => {
  try {
    await store.saveCalendar(
      editing.value === 'new' ? null : editing.value.id,
      payload
    );
    useAlert(t('STAYDESK.CALENDARS.API.SAVE_SUCCESS'));
    editing.value = null;
  } catch {
    useAlert(t('STAYDESK.CALENDARS.API.SAVE_ERROR'));
  }
};

const openDelete = calendar => {
  deleting.value = calendar;
  deleteDialog.value.open();
};

const confirmDelete = async () => {
  try {
    await store.removeCalendar(deleting.value.id);
    useAlert(t('STAYDESK.CALENDARS.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.CALENDARS.API.DELETE_ERROR'));
  } finally {
    deleteDialog.value.close();
    deleting.value = null;
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="store.uiFlags.isFetching && !calendars.length"
    :no-records-found="!calendars.length && !editing"
    :no-records-message="t('STAYDESK.CALENDARS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.CALENDARS.SETTINGS_TITLE')"
        :description="t('STAYDESK.CALENDARS.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            v-if="!editing"
            :label="t('STAYDESK.CALENDARS.NEW')"
            size="sm"
            @click="editing = 'new'"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #preBody>
      <CalendarForm
        v-if="editing"
        :key="editing === 'new' ? 'new' : editing.id"
        :calendar="editing === 'new' ? null : editing"
        :is-saving="store.uiFlags.isSaving"
        class="mb-6"
        @save="save"
        @cancel="editing = null"
      />
    </template>
    <template #body>
      <table class="w-full text-sm">
        <tbody class="divide-y divide-n-weak">
          <tr v-for="calendar in calendars" :key="calendar.id">
            <td class="py-3 pr-4 font-medium text-n-slate-12">
              {{ calendar.name }}
            </td>
            <td class="py-3 pr-4 text-n-slate-11">{{ calendar.timezone }}</td>
            <td class="py-3 pr-4 text-n-slate-11">
              {{
                t('STAYDESK.CALENDARS.SUMMARY', {
                  days: calendar.weekly_hours.length,
                  holidays: calendar.holidays.length,
                })
              }}
            </td>
            <td class="whitespace-nowrap py-3 text-right">
              <Button
                v-tooltip.top="t('STAYDESK.CALENDARS.EDIT')"
                icon="i-woot-settings"
                slate
                sm
                @click="editing = calendar"
              />
              <Button
                v-tooltip.top="t('STAYDESK.CALENDARS.DELETE.BUTTON')"
                icon="i-woot-bin"
                slate
                sm
                class="hover:enabled:bg-n-ruby-2 hover:enabled:text-n-ruby-11"
                @click="openDelete(calendar)"
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
    :title="t('STAYDESK.CALENDARS.DELETE.BUTTON')"
    :description="
      t('STAYDESK.CALENDARS.DELETE.CONFIRM', { name: deleting?.name || '' })
    "
    :confirm-button-label="t('STAYDESK.CALENDARS.DELETE.BUTTON')"
    :cancel-button-label="t('STAYDESK.TEAM_VIEWS.FORM.CANCEL')"
    @confirm="confirmDelete"
  />
</template>
