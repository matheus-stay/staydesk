<script setup>
import { computed, onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import SlaPolicyForm from '../components/SlaPolicyForm.vue';
import { useSlaStore } from '../store/sla';

// Configurações › SLA: políticas em ordem de prioridade de escolha.
const { t } = useI18n();
const store = useSlaStore();

const editing = ref(null); // null | 'new' | policy
const deleting = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');

const policies = computed(() => store.policies);
const calendarName = id =>
  store.calendars.find(calendar => calendar.id === id)?.name ||
  t('STAYDESK.SLA.FORM.NO_CALENDAR');

const summary = policy =>
  ['first_response', 'next_response', 'resolution']
    .map(metric => policy.targets?.default?.[metric])
    .map((minutes, index) =>
      minutes
        ? `${t(`STAYDESK.SLA.METRIC_SHORT.${['first_response', 'next_response', 'resolution'][index]}`)} ${minutes} min`
        : null
    )
    .filter(Boolean)
    .join(' · ');

onMounted(() => store.fetch());

const save = async payload => {
  try {
    await store.savePolicy(
      editing.value === 'new' ? null : editing.value.id,
      payload
    );
    useAlert(t('STAYDESK.SLA.API.SAVE_SUCCESS'));
    editing.value = null;
  } catch {
    useAlert(t('STAYDESK.SLA.API.SAVE_ERROR'));
  }
};

const move = async (policy, direction) => {
  const ids = policies.value.map(item => item.id);
  const index = ids.indexOf(policy.id);
  const target = index + direction;
  if (target < 0 || target >= ids.length) return;
  [ids[index], ids[target]] = [ids[target], ids[index]];
  await store.reorderPolicies(ids);
};

const openDelete = policy => {
  deleting.value = policy;
  deleteDialog.value.open();
};

const confirmDelete = async () => {
  try {
    await store.removePolicy(deleting.value.id);
    useAlert(t('STAYDESK.SLA.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.SLA.API.DELETE_ERROR'));
  } finally {
    deleteDialog.value.close();
    deleting.value = null;
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="store.uiFlags.isFetching && !policies.length"
    :no-records-found="!policies.length && !editing"
    :no-records-message="t('STAYDESK.SLA.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.SLA.SETTINGS_TITLE')"
        :description="t('STAYDESK.SLA.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            v-if="!editing"
            :label="t('STAYDESK.SLA.NEW')"
            size="sm"
            @click="editing = 'new'"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #preBody>
      <SlaPolicyForm
        v-if="editing"
        :key="editing === 'new' ? 'new' : editing.id"
        :policy="editing === 'new' ? null : editing"
        :calendars="store.calendars"
        :is-saving="store.uiFlags.isSaving"
        class="mb-6"
        @save="save"
        @cancel="editing = null"
      />
    </template>
    <template #body>
      <table class="w-full text-sm">
        <tbody class="divide-y divide-n-weak">
          <tr v-for="(policy, index) in policies" :key="policy.id">
            <td class="w-10 py-3 pr-2 text-n-slate-11">{{ index + 1 }}</td>
            <td class="py-3 pr-4">
              <p class="font-medium text-n-slate-12">
                {{ policy.name }}
                <span
                  v-if="!policy.active"
                  class="ml-2 rounded bg-n-slate-3 px-1.5 py-0.5 text-xs text-n-slate-11"
                >
                  {{ t('STAYDESK.SLA.INACTIVE') }}
                </span>
              </p>
              <p class="text-xs text-n-slate-11">{{ summary(policy) }}</p>
            </td>
            <td class="py-3 pr-4 text-n-slate-11">
              {{ calendarName(policy.calendar_id) }}
            </td>
            <td class="py-3 pr-4 text-n-slate-11">
              {{
                t('STAYDESK.SLA.CONDITIONS_COUNT', {
                  count: policy.conditions.length,
                })
              }}
            </td>
            <td class="whitespace-nowrap py-3 text-right">
              <Button
                icon="i-lucide-arrow-up"
                slate
                sm
                :disabled="index === 0"
                @click="move(policy, -1)"
              />
              <Button
                icon="i-lucide-arrow-down"
                slate
                sm
                :disabled="index === policies.length - 1"
                @click="move(policy, 1)"
              />
              <Button
                v-tooltip.top="t('STAYDESK.SLA.EDIT')"
                icon="i-woot-settings"
                slate
                sm
                @click="editing = policy"
              />
              <Button
                v-tooltip.top="t('STAYDESK.SLA.DELETE.BUTTON')"
                icon="i-woot-bin"
                slate
                sm
                class="hover:enabled:bg-n-ruby-2 hover:enabled:text-n-ruby-11"
                @click="openDelete(policy)"
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
    :title="t('STAYDESK.SLA.DELETE.BUTTON')"
    :description="
      t('STAYDESK.SLA.DELETE.CONFIRM', { name: deleting?.name || '' })
    "
    :confirm-button-label="t('STAYDESK.SLA.DELETE.BUTTON')"
    :cancel-button-label="t('STAYDESK.TEAM_VIEWS.FORM.CANCEL')"
    @confirm="confirmDelete"
  />
</template>
