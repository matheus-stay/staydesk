<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import AgentRolesAPI from '../api/agentRoles';

// Papel StayDesk por agente: completo ou leve (lê e só escreve nota interna).
const KINDS = ['full', 'light'];

const { t } = useI18n();
const agents = ref([]);
const isLoading = ref(false);
const saving = ref({});

const load = async () => {
  isLoading.value = true;
  try {
    const { data } = await AgentRolesAPI.get();
    agents.value = data;
  } finally {
    isLoading.value = false;
  }
};

const setKind = async (agent, kind) => {
  saving.value[agent.user_id] = true;
  try {
    await AgentRolesAPI.setKind(agent.user_id, kind);
    agent.kind = kind;
    useAlert(t('STAYDESK.AGENT_ROLES.API.SAVE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.AGENT_ROLES.API.SAVE_ERROR'));
  } finally {
    saving.value[agent.user_id] = false;
  }
};

onMounted(load);
</script>

<template>
  <SettingsLayout :is-loading="isLoading" :no-records-found="!agents.length">
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.AGENT_ROLES.SETTINGS_TITLE')"
        :description="t('STAYDESK.AGENT_ROLES.SETTINGS_DESCRIPTION')"
      />
    </template>
    <template #body>
      <table class="w-full text-sm">
        <tbody class="divide-y divide-n-weak">
          <tr v-for="agent in agents" :key="agent.user_id">
            <td class="py-3 pr-4">
              <p class="font-medium text-n-slate-12">{{ agent.name }}</p>
              <p class="text-xs text-n-slate-11">{{ agent.email }}</p>
            </td>
            <td class="py-3 pr-4 text-n-slate-11">
              {{ t(`AGENT_MGMT.AGENT_TYPES.${agent.role.toUpperCase()}`) }}
            </td>
            <td class="py-3 text-right">
              <select
                :value="agent.kind"
                :disabled="
                  agent.role === 'administrator' || saving[agent.user_id]
                "
                class="h-9 rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12"
                @change="setKind(agent, $event.target.value)"
              >
                <option v-for="kind in KINDS" :key="kind" :value="kind">
                  {{ t(`STAYDESK.AGENT_ROLES.KIND.${kind}`) }}
                </option>
              </select>
            </td>
          </tr>
        </tbody>
      </table>
    </template>
  </SettingsLayout>
</template>
