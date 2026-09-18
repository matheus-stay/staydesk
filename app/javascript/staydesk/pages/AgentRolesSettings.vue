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
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import AgentRolesAPI from '../api/agentRoles';
import { fromSaveButton } from '../helpers/form';

// Papéis e permissões (SPEC-05, SPEC-12 e SPEC-13): o tipo do agente, o papel
// granular que pode ser concedido ou revogado a qualquer momento, e o acesso
// "entrar como" para acompanhar o trabalho de quem atende.
const KINDS = ['full', 'light'];
const SEM_PAPEL = 0;

const { t } = useI18n();
const agents = ref([]);
const roles = ref([]);
const permissions = ref([]);
const trail = ref([]);
const isLoading = ref(false);
const saving = ref({});
const editing = ref(null);
const deleting = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');
const emptyForm = () => ({ name: '', description: '', permissions: [] });
const form = ref(emptyForm());

const kindOptions = computed(() =>
  KINDS.map(value => ({
    value,
    label: t(`STAYDESK.AGENT_ROLES.KIND.${value}`),
  }))
);
const roleOptions = computed(() => [
  { value: SEM_PAPEL, label: t('STAYDESK.AGENT_ROLES.ROLES.NONE') },
  ...roles.value.map(role => ({ value: role.id, label: role.name })),
]);
const permissionLabel = key => t(`STAYDESK.AGENT_ROLES.PERMISSIONS.${key}`);

const load = async () => {
  isLoading.value = true;
  try {
    const [agentes, papeis, trilha] = await Promise.all([
      AgentRolesAPI.listAgents(),
      AgentRolesAPI.listRoles(),
      AgentRolesAPI.listImpersonations(),
    ]);
    agents.value = agentes.data;
    roles.value = papeis.data.roles;
    permissions.value = papeis.data.permissions;
    trail.value = trilha.data;
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

const setRole = async (agent, roleId) => {
  saving.value[agent.user_id] = true;
  try {
    const { data } = await AgentRolesAPI.setRole(
      agent.user_id,
      roleId === SEM_PAPEL ? null : roleId
    );
    Object.assign(agent, data[0]);
    useAlert(t('STAYDESK.AGENT_ROLES.API.SAVE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.AGENT_ROLES.API.SAVE_ERROR'));
  } finally {
    saving.value[agent.user_id] = false;
  }
};

// Abre a sessão do agente numa aba nova; o link vale cinco minutos.
const impersonate = async agent => {
  saving.value[agent.user_id] = true;
  try {
    const { data } = await AgentRolesAPI.impersonate(agent.user_id);
    window.open(data.url, '_blank', 'noopener');
    trail.value = (await AgentRolesAPI.listImpersonations()).data;
  } catch {
    useAlert(t('STAYDESK.AGENT_ROLES.IMPERSONATION.ERROR'));
  } finally {
    saving.value[agent.user_id] = false;
  }
};

const startEdit = role => {
  editing.value = role || 'new';
  form.value = role
    ? {
        name: role.name,
        description: role.description || '',
        permissions: [...role.permissions],
      }
    : emptyForm();
};

const permissionOptions = computed(() =>
  permissions.value.map(key => ({ value: key, label: permissionLabel(key) }))
);

const saveRole = async () => {
  if (!form.value.name.trim()) return;
  try {
    const payload = {
      name: form.value.name.trim(),
      description: form.value.description.trim(),
      permissions: form.value.permissions,
    };
    const { data } =
      editing.value === 'new'
        ? await AgentRolesAPI.createRole(payload)
        : await AgentRolesAPI.updateRole(editing.value.id, payload);
    roles.value =
      editing.value === 'new'
        ? [...roles.value, data]
        : roles.value.map(role => (role.id === data.id ? data : role));
    editing.value = null;
    useAlert(t('STAYDESK.AGENT_ROLES.API.SAVE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.AGENT_ROLES.API.SAVE_ERROR'));
  }
};

const openDelete = role => {
  deleting.value = role;
  deleteDialog.value.open();
};

const confirmDelete = async () => {
  try {
    await AgentRolesAPI.deleteRole(deleting.value.id);
    roles.value = roles.value.filter(role => role.id !== deleting.value.id);
    agents.value.forEach(agent => {
      if (agent.staydesk_role_id === deleting.value.id)
        agent.staydesk_role_id = null;
    });
    useAlert(t('STAYDESK.AGENT_ROLES.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.AGENT_ROLES.API.DELETE_ERROR'));
  } finally {
    deleteDialog.value.close();
    deleting.value = null;
  }
};

onMounted(load);
// Só o botão de salvar (ou o Enter) envia: clique em botão de dentro não salva.
const aoEnviar = event => {
  if (fromSaveButton(event)) saveRole();
};
</script>

<template>
  <SettingsLayout :is-loading="isLoading" :no-records-found="false">
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.AGENT_ROLES.SETTINGS_TITLE')"
        :description="t('STAYDESK.AGENT_ROLES.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            v-if="!editing"
            :label="t('STAYDESK.AGENT_ROLES.ROLES.NEW')"
            size="sm"
            @click="startEdit(null)"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <form
        v-if="editing"
        class="mb-6 grid gap-4 rounded-xl border border-n-weak bg-n-solid-1 p-6"
        @submit.prevent="aoEnviar"
      >
        <div class="grid gap-4 md:grid-cols-2">
          <Input
            v-model="form.name"
            :label="t('STAYDESK.AGENT_ROLES.ROLES.NAME')"
          />
          <Input
            v-model="form.description"
            :label="t('STAYDESK.AGENT_ROLES.ROLES.DESCRIPTION')"
          />
        </div>
        <fieldset class="grid gap-2">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.AGENT_ROLES.ROLES.PERMISSIONS') }}
          </legend>
          <TagMultiSelectComboBox
            v-model="form.permissions"
            :options="permissionOptions"
            :placeholder="
              t('STAYDESK.AGENT_ROLES.ROLES.PERMISSIONS_PLACEHOLDER')
            "
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
        </fieldset>
        <div class="flex justify-end gap-2">
          <Button sm faded slate type="button" @click="editing = null">
            {{ t('STAYDESK.TEAM_VIEWS.FORM.CANCEL') }}
          </Button>
          <Button sm solid blue type="submit" data-staydesk-save>
            {{ t('STAYDESK.TEAM_VIEWS.FORM.SAVE') }}
          </Button>
        </div>
      </form>

      <section v-if="roles.length" class="mb-8">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('STAYDESK.AGENT_ROLES.ROLES.TITLE') }}
        </h3>
        <table class="mt-2 w-full text-sm">
          <tbody class="divide-y divide-n-weak">
            <tr v-for="role in roles" :key="role.id">
              <td class="py-3 pr-4">
                <p class="font-medium text-n-slate-12">{{ role.name }}</p>
                <p v-if="role.description" class="text-xs text-n-slate-11">
                  {{ role.description }}
                </p>
              </td>
              <td class="py-3 pr-4 text-xs text-n-slate-11">
                {{
                  role.permissions.map(permissionLabel).join(' · ') ||
                  t('STAYDESK.AGENT_ROLES.ROLES.NO_PERMISSIONS')
                }}
              </td>
              <td class="whitespace-nowrap py-3 text-right">
                <Button
                  v-tooltip.top="t('STAYDESK.AGENT_ROLES.ROLES.EDIT')"
                  icon="i-woot-settings"
                  slate
                  sm
                  @click="startEdit(role)"
                />
                <Button
                  v-tooltip.top="t('STAYDESK.AGENT_ROLES.ROLES.DELETE')"
                  icon="i-woot-bin"
                  slate
                  sm
                  class="hover:enabled:bg-n-ruby-2 hover:enabled:text-n-ruby-11"
                  @click="openDelete(role)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </section>

      <section>
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('STAYDESK.AGENT_ROLES.AGENTS_TITLE') }}
        </h3>
        <table class="mt-2 w-full text-sm">
          <tbody class="divide-y divide-n-weak">
            <tr v-for="agent in agents" :key="agent.user_id">
              <td class="py-3 pr-4">
                <p class="font-medium text-n-slate-12">{{ agent.name }}</p>
                <p class="text-xs text-n-slate-11">{{ agent.email }}</p>
              </td>
              <td class="py-3 pr-4 text-n-slate-11">
                {{ t(`AGENT_MGMT.AGENT_TYPES.${agent.role.toUpperCase()}`) }}
              </td>
              <td class="py-3 pr-4">
                <Select
                  :model-value="agent.kind"
                  :options="kindOptions"
                  :disabled="
                    agent.role === 'administrator' || saving[agent.user_id]
                  "
                  @update:model-value="kind => setKind(agent, kind)"
                />
              </td>
              <td class="py-3 pr-4">
                <Select
                  :model-value="agent.staydesk_role_id || 0"
                  :options="roleOptions"
                  :disabled="saving[agent.user_id]"
                  @update:model-value="id => setRole(agent, id)"
                />
              </td>
              <td class="py-3 text-right">
                <Button
                  sm
                  faded
                  slate
                  :disabled="saving[agent.user_id]"
                  @click="impersonate(agent)"
                >
                  {{ t('STAYDESK.AGENT_ROLES.IMPERSONATION.BUTTON') }}
                </Button>
              </td>
            </tr>
          </tbody>
        </table>
      </section>

      <section v-if="trail.length" class="mt-8">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('STAYDESK.AGENT_ROLES.IMPERSONATION.TRAIL') }}
        </h3>
        <p class="text-xs text-n-slate-11">
          {{ t('STAYDESK.AGENT_ROLES.IMPERSONATION.TRAIL_HINT') }}
        </p>
        <ul class="mt-2 grid gap-1 text-sm text-n-slate-11">
          <li v-for="item in trail" :key="item.id">
            {{
              t('STAYDESK.AGENT_ROLES.IMPERSONATION.TRAIL_LINE', {
                actor: item.actor_name,
                target: item.target_name,
                when: new Date(item.created_at).toLocaleString(),
              })
            }}
          </li>
        </ul>
      </section>
    </template>
  </SettingsLayout>
  <Dialog
    ref="deleteDialog"
    type="alert"
    :title="t('STAYDESK.AGENT_ROLES.ROLES.DELETE')"
    :description="
      t('STAYDESK.AGENT_ROLES.ROLES.DELETE_CONFIRM', {
        name: deleting?.name || '',
      })
    "
    :confirm-button-label="t('STAYDESK.AGENT_ROLES.ROLES.DELETE')"
    :cancel-button-label="t('STAYDESK.TEAM_VIEWS.FORM.CANCEL')"
    @confirm="confirmDelete"
  />
</template>
