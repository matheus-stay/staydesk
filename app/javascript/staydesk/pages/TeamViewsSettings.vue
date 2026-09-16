<script setup>
import { computed, onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TeamViewForm from '../components/TeamViewForm.vue';
import { useTeamViewsStore } from '../store/teamViews';

const { t } = useI18n();
const store = useTeamViewsStore();
const teams = useMapGetter('teams/getTeams');

const editing = ref(null); // null | 'new' | view
const deleting = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');

const views = computed(() => store.ordered);
const isSaving = computed(() => store.uiFlags.isSaving);

const teamNames = view =>
  teams.value
    .filter(team => view.team_ids.includes(team.id))
    .map(team => team.name)
    .join(', ');

onMounted(() => store.fetch());

const save = async payload => {
  try {
    if (editing.value === 'new') await store.create(payload);
    else await store.update(editing.value.id, payload);
    useAlert(t('STAYDESK.TEAM_VIEWS.API.SAVE_SUCCESS'));
    editing.value = null;
  } catch {
    useAlert(t('STAYDESK.TEAM_VIEWS.API.SAVE_ERROR'));
  }
};

const openDelete = view => {
  deleting.value = view;
  deleteDialog.value.open();
};

const confirmDelete = async () => {
  try {
    await store.remove(deleting.value.id);
    useAlert(t('STAYDESK.TEAM_VIEWS.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.TEAM_VIEWS.API.DELETE_ERROR'));
  } finally {
    deleteDialog.value.close();
    deleting.value = null;
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="store.uiFlags.isFetching && !views.length"
    :no-records-found="!views.length && !editing"
    :no-records-message="t('STAYDESK.TEAM_VIEWS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.TEAM_VIEWS.SETTINGS_TITLE')"
        :description="t('STAYDESK.TEAM_VIEWS.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            v-if="!editing"
            :label="t('STAYDESK.TEAM_VIEWS.NEW')"
            size="sm"
            @click="editing = 'new'"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #preBody>
      <TeamViewForm
        v-if="editing"
        :key="editing === 'new' ? 'new' : editing.id"
        :view="editing === 'new' ? null : editing"
        :is-saving="isSaving"
        class="mb-6"
        @save="save"
        @cancel="editing = null"
      />
    </template>
    <template #body>
      <table class="w-full text-sm divide-y divide-n-weak">
        <tbody class="divide-y divide-n-weak">
          <tr v-for="view in views" :key="view.id">
            <td class="py-3 pr-4">
              <div class="flex items-center gap-2">
                <span
                  class="inline-block rounded-full size-2.5"
                  :style="{ backgroundColor: view.color || 'currentColor' }"
                />
                <span class="font-medium text-n-slate-12">{{ view.name }}</span>
              </div>
              <p v-if="view.description" class="mt-0.5 text-xs text-n-slate-11">
                {{ view.description }}
              </p>
            </td>
            <td class="py-3 pr-4 text-n-slate-11">
              {{ teamNames(view) || t('STAYDESK.TEAM_VIEWS.FORM.TEAMS_HINT') }}
            </td>
            <td class="py-3 pr-4 text-n-slate-11">
              {{
                t(
                  `STAYDESK.TEAM_VIEWS.SORT.${view.sort_by || 'last_activity_at_desc'}`
                )
              }}
            </td>
            <td class="py-3 text-right whitespace-nowrap">
              <Button
                v-tooltip.top="t('STAYDESK.TEAM_VIEWS.EDIT')"
                icon="i-woot-settings"
                slate
                sm
                @click="editing = view"
              />
              <Button
                v-tooltip.top="t('STAYDESK.TEAM_VIEWS.DELETE.BUTTON')"
                icon="i-woot-bin"
                slate
                sm
                class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                @click="openDelete(view)"
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
    :title="t('STAYDESK.TEAM_VIEWS.DELETE.BUTTON')"
    :description="
      t('STAYDESK.TEAM_VIEWS.DELETE.CONFIRM', { name: deleting?.name || '' })
    "
    :confirm-button-label="t('STAYDESK.TEAM_VIEWS.DELETE.BUTTON')"
    :cancel-button-label="t('STAYDESK.TEAM_VIEWS.FORM.CANCEL')"
    @confirm="confirmDelete"
  />
</template>
