<script setup>
import { computed, onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import CapacityRulesAPI from '../api/capacityRules';
import AgentStatusesAPI from '../api/agentStatuses';
import { fromSaveButton } from '../helpers/form';

// Central › Distribuição de trabalho › Regras de capacidade: quantas conversas
// de cada canal de trabalho o agente aguenta ao mesmo tempo, como no Zendesk.
// O status diz o que ele recebe agora; a regra diz quanto.
const { t } = useI18n();
const store = useStore();
const agents = useMapGetter('agents/getAgents');

const regras = ref([]);
const canais = ref([]);
const isLoading = ref(false);
const isSaving = ref(false);
const editando = ref(null);
const excluindo = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');
const vazio = () => ({
  name: '',
  description: '',
  limits: {},
  isDefault: false,
  userIds: [],
});
const form = ref(vazio());

const agentOptions = computed(() =>
  agents.value.map(agent => ({ value: agent.id, label: agent.name }))
);

const buscar = async () => {
  isLoading.value = true;
  try {
    const { data } = await CapacityRulesAPI.list();
    regras.value = data;
  } finally {
    isLoading.value = false;
  }
};

// Os canais de trabalho da conta: é deles que saem os campos de limite.
const buscarCanais = async () => {
  const { data } = await AgentStatusesAPI.loadQueues();
  canais.value = data.load_queues || [];
};

const editar = regra => {
  editando.value = regra || 'nova';
  form.value = regra
    ? {
        name: regra.name,
        description: regra.description || '',
        limits: { ...(regra.limits || {}) },
        isDefault: regra.is_default,
        userIds: [...(regra.user_ids || [])],
      }
    : vazio();
};

const salvar = async evento => {
  if (!fromSaveButton(evento)) return;
  if (!form.value.name.trim()) return;
  // Campo em branco é sem limite: não vai no payload.
  const limits = {};
  canais.value.forEach(canal => {
    const valor = form.value.limits[canal.key];
    if (valor !== '' && valor !== null && valor !== undefined) {
      limits[canal.key] = Number(valor);
    }
  });
  const payload = {
    name: form.value.name.trim(),
    description: form.value.description.trim(),
    limits,
    is_default: form.value.isDefault,
    user_ids: form.value.userIds,
  };
  isSaving.value = true;
  try {
    if (editando.value === 'nova') await CapacityRulesAPI.create(payload);
    else await CapacityRulesAPI.update(editando.value.id, payload);
    editando.value = null;
    await buscar();
    useAlert(t('STAYDESK.CAPACITY_RULES.API.SAVE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.CAPACITY_RULES.API.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const pedirExclusao = regra => {
  excluindo.value = regra;
  deleteDialog.value.open();
};

const excluir = async () => {
  try {
    await CapacityRulesAPI.delete(excluindo.value.id);
    await buscar();
    useAlert(t('STAYDESK.CAPACITY_RULES.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.CAPACITY_RULES.API.DELETE_ERROR'));
  } finally {
    deleteDialog.value.close();
    excluindo.value = null;
  }
};

// Rótulo de um teto: número, "não recebe" no zero, "sem limite" em branco.
const limite = (regra, chave) => {
  const valor = regra.limits?.[chave];
  if (valor === 0) return t('STAYDESK.CAPACITY_RULES.NONE');
  if (valor === null || valor === undefined)
    return t('STAYDESK.CAPACITY_RULES.UNLIMITED');
  return String(valor);
};

const quem = regra => {
  if ((regra.user_names || []).length) return regra.user_names.join(', ');
  return regra.is_default
    ? t('STAYDESK.CAPACITY_RULES.DEFAULT_AGENTS')
    : t('STAYDESK.CAPACITY_RULES.NO_AGENTS');
};

onMounted(() => {
  buscar();
  buscarCanais();
  store.dispatch('agents/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :no-records-found="!regras.length && !editando"
    :no-records-message="t('STAYDESK.CAPACITY_RULES.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.CAPACITY_RULES.SETTINGS_TITLE')"
        :description="t('STAYDESK.CAPACITY_RULES.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            v-if="!editando"
            sm
            solid
            blue
            :label="t('STAYDESK.CAPACITY_RULES.NEW')"
            @click="editar(null)"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #preBody>
      <form
        v-if="editando"
        class="mb-6 grid gap-4 rounded-xl border border-n-weak bg-n-solid-1 p-6"
        @submit.prevent="salvar"
      >
        <div class="grid gap-4 md:grid-cols-2">
          <Input
            v-model="form.name"
            :label="t('STAYDESK.CAPACITY_RULES.FORM.NAME')"
          />
          <Input
            v-model="form.description"
            :label="t('STAYDESK.CAPACITY_RULES.FORM.DESCRIPTION')"
          />
        </div>
        <fieldset class="grid gap-3">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.CAPACITY_RULES.FORM.LIMITS') }}
          </legend>
          <p class="m-0 text-xs text-n-slate-11">
            {{ t('STAYDESK.CAPACITY_RULES.FORM.LIMITS_HINT') }}
          </p>
          <div class="grid gap-4 md:grid-cols-3">
            <label
              v-for="canal in canais"
              :key="canal.key"
              class="grid gap-1 text-sm text-n-slate-12"
            >
              <span>{{ canal.name }}</span>
              <input
                v-model="form.limits[canal.key]"
                type="number"
                min="0"
                :placeholder="t('STAYDESK.CAPACITY_RULES.UNLIMITED')"
                class="h-9 w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12"
              />
            </label>
          </div>
        </fieldset>
        <label class="flex items-start gap-2 text-sm text-n-slate-12">
          <Switch v-model="form.isDefault" />
          <span class="grid gap-0.5">
            <span>{{ t('STAYDESK.CAPACITY_RULES.FORM.IS_DEFAULT') }}</span>
            <span class="text-xs text-n-slate-11">
              {{ t('STAYDESK.CAPACITY_RULES.FORM.IS_DEFAULT_HINT') }}
            </span>
          </span>
        </label>
        <label class="grid gap-1 text-sm text-n-slate-12">
          <span>{{ t('STAYDESK.CAPACITY_RULES.FORM.AGENTS') }}</span>
          <TagMultiSelectComboBox
            v-model="form.userIds"
            :options="agentOptions"
            :placeholder="t('STAYDESK.CAPACITY_RULES.FORM.AGENTS_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
          <span class="text-xs text-n-slate-11">
            {{ t('STAYDESK.CAPACITY_RULES.FORM.AGENTS_HINT') }}
          </span>
        </label>
        <div class="flex justify-end gap-2">
          <Button sm faded slate type="button" @click="editando = null">
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
      <div class="overflow-x-auto">
        <table class="w-full min-w-[36rem] border-collapse text-sm">
          <thead>
            <tr class="text-left text-xs uppercase text-n-slate-11">
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.CAPACITY_RULES.TABLE.RULE') }}
              </th>
              <th
                v-for="canal in canais"
                :key="canal.key"
                class="py-2 pr-4 font-medium"
              >
                {{ canal.name }}
              </th>
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.CAPACITY_RULES.TABLE.AGENTS') }}
              </th>
              <th class="py-2 font-medium" />
            </tr>
          </thead>
          <tbody class="divide-y divide-n-weak">
            <tr v-for="regra in regras" :key="regra.id">
              <td class="py-3 pr-4 text-n-slate-12">
                <p class="m-0 flex items-center gap-2">
                  {{ regra.name }}
                  <span
                    v-if="regra.is_default"
                    class="rounded bg-n-slate-3 px-1.5 py-0.5 text-xs text-n-slate-11"
                  >
                    {{ t('STAYDESK.CAPACITY_RULES.DEFAULT_BADGE') }}
                  </span>
                </p>
                <p v-if="regra.description" class="m-0 text-xs text-n-slate-11">
                  {{ regra.description }}
                </p>
              </td>
              <td
                v-for="canal in canais"
                :key="canal.key"
                class="py-3 pr-4 text-n-slate-11"
              >
                {{ limite(regra, canal.key) }}
              </td>
              <td class="py-3 pr-4 text-n-slate-11">{{ quem(regra) }}</td>
              <td class="whitespace-nowrap py-3 text-right">
                <Button
                  v-tooltip.top="t('STAYDESK.CAPACITY_RULES.EDIT')"
                  icon="i-woot-settings"
                  slate
                  sm
                  @click="editar(regra)"
                />
                <Button
                  v-tooltip.top="t('STAYDESK.CAPACITY_RULES.DELETE.BUTTON')"
                  icon="i-woot-bin"
                  slate
                  sm
                  class="hover:enabled:bg-n-ruby-2 hover:enabled:text-n-ruby-11"
                  @click="pedirExclusao(regra)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-4 text-xs text-n-slate-11">
        {{ t('STAYDESK.CAPACITY_RULES.FOOTNOTE') }}
      </p>
    </template>
  </SettingsLayout>
  <Dialog
    ref="deleteDialog"
    type="alert"
    :title="t('STAYDESK.CAPACITY_RULES.DELETE.BUTTON')"
    :description="
      t('STAYDESK.CAPACITY_RULES.DELETE.CONFIRM', {
        name: excluindo?.name || '',
      })
    "
    :confirm-button-label="t('STAYDESK.CAPACITY_RULES.DELETE.BUTTON')"
    :cancel-button-label="t('STAYDESK.TEAM_VIEWS.FORM.CANCEL')"
    @confirm="excluir"
  />
</template>
