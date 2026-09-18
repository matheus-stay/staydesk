<script setup>
import { computed, onMounted, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import ApiTokensAPI from '../api/apiTokens';
import { fromSaveButton } from '../helpers/form';

// Central › Tokens de API: chave com escopo próprio, para integração ler e
// escrever só o que precisa. O valor aparece uma vez; depois, só revogar.
const { t } = useI18n();
const store = useStore();
const agents = useMapGetter('agents/getAgents');

const tokens = ref([]);
const escopos = ref([]);
const criando = ref(false);
const recemCriado = ref(null);
const apagando = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');
const vazio = () => ({
  name: '',
  description: '',
  scopes: [],
  userId: null,
  expiresAt: '',
});
const form = ref(vazio());

const opcoesDeEscopo = computed(() =>
  escopos.value.map(escopo => {
    const [grupo, acao] = escopo.split(':');
    return {
      value: escopo,
      label: `${t(`STAYDESK.API_TOKENS.SCOPES.${grupo}`)} · ${t(
        `STAYDESK.API_TOKENS.ACTIONS.${acao}`
      )}`,
    };
  })
);
const opcoesDeAgente = computed(() =>
  agents.value.map(agente => ({ value: agente.id, label: agente.name }))
);

const buscar = async () => {
  const { data } = await ApiTokensAPI.list();
  tokens.value = data.api_tokens;
  escopos.value = data.scopes;
};

const salvar = async evento => {
  if (!fromSaveButton(evento)) return;
  if (!form.value.name.trim() || !form.value.scopes.length) return;
  try {
    const { data } = await ApiTokensAPI.create({
      name: form.value.name.trim(),
      description: form.value.description.trim(),
      scopes: form.value.scopes,
      user_id: form.value.userId,
      expires_at: form.value.expiresAt || null,
    });
    recemCriado.value = data;
    criando.value = false;
    form.value = vazio();
    await buscar();
  } catch {
    useAlert(t('STAYDESK.API_TOKENS.API.SAVE_ERROR'));
  }
};

const alternar = async token => {
  await ApiTokensAPI.update(token.id, { active: !token.active });
  await buscar();
};

const confirmarExclusao = token => {
  apagando.value = token;
  deleteDialog.value.open();
};

const excluir = async () => {
  try {
    await ApiTokensAPI.delete(apagando.value.id);
    await buscar();
  } finally {
    deleteDialog.value.close();
    apagando.value = null;
  }
};

const copiar = async valor => {
  await navigator.clipboard.writeText(valor);
  useAlert(t('STAYDESK.API_TOKENS.COPIED'));
};

const rotuloDoEscopo = escopo =>
  opcoesDeEscopo.value.find(opcao => opcao.value === escopo)?.label || escopo;

onMounted(() => {
  buscar();
  store.dispatch('agents/get');
});
</script>

<template>
  <SettingsLayout>
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.API_TOKENS.SETTINGS_TITLE')"
        :description="t('STAYDESK.API_TOKENS.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            sm
            solid
            blue
            :label="t('STAYDESK.API_TOKENS.NEW')"
            @click="criando = true"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div
        v-if="recemCriado"
        class="mb-6 grid gap-2 rounded-xl border border-n-weak bg-n-alpha-1 p-4"
      >
        <p class="m-0 text-sm font-medium text-n-slate-12">
          {{ t('STAYDESK.API_TOKENS.CREATED_TITLE') }}
        </p>
        <p class="m-0 text-xs text-n-slate-11">
          {{ t('STAYDESK.API_TOKENS.CREATED_HINT') }}
        </p>
        <div class="flex items-center gap-2">
          <code
            class="flex-1 overflow-x-auto rounded-lg bg-n-solid-1 px-3 py-2 text-xs text-n-slate-12"
          >
            {{ recemCriado.token }}
          </code>
          <Button
            sm
            faded
            slate
            :label="t('STAYDESK.API_TOKENS.COPY')"
            @click="copiar(recemCriado.token)"
          />
          <Button
            sm
            faded
            slate
            :label="t('STAYDESK.API_TOKENS.DISMISS')"
            @click="recemCriado = null"
          />
        </div>
      </div>

      <form v-if="criando" class="mb-8 grid gap-4" @submit.prevent="salvar">
        <Input
          v-model="form.name"
          :label="t('STAYDESK.API_TOKENS.FORM.NAME')"
        />
        <Input
          v-model="form.description"
          :label="t('STAYDESK.API_TOKENS.FORM.DESCRIPTION')"
        />
        <fieldset class="grid gap-2">
          <legend class="text-sm text-n-slate-12">
            {{ t('STAYDESK.API_TOKENS.FORM.SCOPES') }}
          </legend>
          <p class="m-0 text-xs text-n-slate-11">
            {{ t('STAYDESK.API_TOKENS.FORM.SCOPES_HINT') }}
          </p>
          <TagMultiSelectComboBox
            v-model="form.scopes"
            :options="opcoesDeEscopo"
            :placeholder="t('STAYDESK.API_TOKENS.FORM.SCOPES_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
        </fieldset>
        <label class="grid max-w-sm gap-1 text-sm text-n-slate-12">
          <span>{{ t('STAYDESK.API_TOKENS.FORM.ACTS_AS') }}</span>
          <Select v-model="form.userId" :options="opcoesDeAgente" />
          <span class="text-xs text-n-slate-11">
            {{ t('STAYDESK.API_TOKENS.FORM.ACTS_AS_HINT') }}
          </span>
        </label>
        <label class="grid max-w-xs gap-1 text-sm text-n-slate-12">
          <span>{{ t('STAYDESK.API_TOKENS.FORM.EXPIRES_AT') }}</span>
          <input
            v-model="form.expiresAt"
            type="date"
            class="h-9 w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12"
          />
        </label>
        <div class="flex justify-end gap-2">
          <Button sm faded slate type="button" @click="criando = false">
            {{ t('STAYDESK.TEAM_VIEWS.FORM.CANCEL') }}
          </Button>
          <Button sm solid blue type="submit" data-staydesk-save>
            {{ t('STAYDESK.API_TOKENS.FORM.CREATE') }}
          </Button>
        </div>
      </form>

      <p v-if="!tokens.length" class="text-sm text-n-slate-11">
        {{ t('STAYDESK.API_TOKENS.EMPTY') }}
      </p>
      <div v-else class="overflow-x-auto">
        <table class="w-full min-w-[40rem] border-collapse text-sm">
          <thead>
            <tr class="text-left text-xs uppercase text-n-slate-11">
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.API_TOKENS.TABLE.NAME') }}
              </th>
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.API_TOKENS.TABLE.SCOPES') }}
              </th>
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.API_TOKENS.TABLE.ACTS_AS') }}
              </th>
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.API_TOKENS.TABLE.LAST_USED') }}
              </th>
              <th class="py-2 font-medium" />
            </tr>
          </thead>
          <tbody class="divide-y divide-n-weak">
            <tr v-for="token in tokens" :key="token.id">
              <td class="py-3 pr-4 text-n-slate-12">
                <p class="m-0">{{ token.name }}</p>
                <p class="m-0 text-xs text-n-slate-11">
                  {{
                    t('STAYDESK.API_TOKENS.TABLE.HINT', {
                      hint: token.token_hint,
                    })
                  }}
                  <template v-if="!token.active">
                    · {{ t('STAYDESK.API_TOKENS.TABLE.INACTIVE') }}
                  </template>
                </p>
              </td>
              <td class="py-3 pr-4 text-xs text-n-slate-11">
                {{ token.scopes.map(rotuloDoEscopo).join(' · ') }}
              </td>
              <td class="py-3 pr-4 text-n-slate-11">{{ token.user_name }}</td>
              <td class="py-3 pr-4 text-n-slate-11">
                {{ token.last_used_at || t('STAYDESK.API_TOKENS.TABLE.NEVER') }}
              </td>
              <td class="whitespace-nowrap py-3 text-right">
                <Button
                  sm
                  faded
                  slate
                  :label="
                    token.active
                      ? t('STAYDESK.API_TOKENS.SUSPEND')
                      : t('STAYDESK.API_TOKENS.RESUME')
                  "
                  @click="alternar(token)"
                />
                <Button
                  sm
                  faded
                  ruby
                  class="ml-2"
                  :label="t('STAYDESK.API_TOKENS.REVOKE')"
                  @click="confirmarExclusao(token)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </SettingsLayout>
  <Dialog
    ref="deleteDialog"
    type="alert"
    :title="t('STAYDESK.API_TOKENS.REVOKE')"
    :description="
      t('STAYDESK.API_TOKENS.REVOKE_CONFIRM', { name: apagando?.name || '' })
    "
    :confirm-button-label="t('STAYDESK.API_TOKENS.REVOKE')"
    @confirm="excluir"
  />
</template>
