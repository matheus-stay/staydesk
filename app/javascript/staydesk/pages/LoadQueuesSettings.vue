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
import LoadQueuesAPI from '../api/loadQueues';
import {
  juntarCanais,
  nomeDoCanal,
  opcoesDeCanais,
  separarCanais,
} from '../helpers/canais';
import { fromSaveButton } from '../helpers/form';

// Central › Filas de carga: quantas conversas simultâneas o agente aguenta é
// contado por fila, e é a caixa que diz de qual fila a conversa é. Não confundir
// com as filas de encaminhamento, que decidem para quais grupos o trabalho vai.
const { t } = useI18n();
const store = useStore();
const inboxes = useMapGetter('inboxes/getInboxes');

const filas = ref([]);
const isLoading = ref(false);
const isSaving = ref(false);
const editando = ref(null);
const excluindo = ref(null);
const deleteDialog = useTemplateRef('deleteDialog');
const vazio = () => ({
  key: '',
  name: '',
  canais: [],
  catchAll: false,
});
const form = ref(vazio());

// Tipo inteiro ou canal específico, num campo só.
const canalOptions = computed(() =>
  opcoesDeCanais(inboxes.value, nome =>
    t('STAYDESK.PICKER.ALL_OF_TYPE', { type: nome })
  )
);

const buscar = async () => {
  isLoading.value = true;
  try {
    const { data } = await LoadQueuesAPI.list();
    filas.value = data.load_queues;
  } finally {
    isLoading.value = false;
  }
};

const editar = fila => {
  editando.value = fila || 'nova';
  form.value = fila
    ? {
        key: fila.key,
        name: fila.name,
        canais: juntarCanais(fila.channel_types, fila.inbox_ids),
        catchAll: fila.catch_all,
      }
    : vazio();
};

const salvar = async evento => {
  if (!fromSaveButton(evento)) return;
  if (!form.value.key.trim() || !form.value.name.trim()) return;
  const payload = {
    key: form.value.key.trim(),
    name: form.value.name.trim(),
    channel_types: separarCanais(form.value.canais).channel_types,
    inbox_ids: separarCanais(form.value.canais).inbox_ids,
    catch_all: form.value.catchAll,
  };
  isSaving.value = true;
  try {
    if (editando.value === 'nova') await LoadQueuesAPI.create(payload);
    else await LoadQueuesAPI.update(editando.value.id, payload);
    editando.value = null;
    await buscar();
    useAlert(t('STAYDESK.LOAD_QUEUES.API.SAVE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.LOAD_QUEUES.API.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const pedirExclusao = fila => {
  excluindo.value = fila;
  deleteDialog.value.open();
};

const excluir = async () => {
  try {
    await LoadQueuesAPI.delete(excluindo.value.id);
    await buscar();
    useAlert(t('STAYDESK.LOAD_QUEUES.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('STAYDESK.LOAD_QUEUES.API.DELETE_ERROR'));
  } finally {
    deleteDialog.value.close();
    excluindo.value = null;
  }
};

const oQuePega = fila => {
  if (fila.catch_all) return t('STAYDESK.LOAD_QUEUES.CATCH_ALL');
  const canais = (fila.channel_types || []).map(nomeDoCanal);
  const caixas = (fila.inbox_ids || [])
    .map(id => inboxes.value.find(caixa => caixa.id === id)?.name)
    .filter(Boolean);
  const partes = [...canais, ...caixas];
  return partes.length ? partes.join(', ') : t('STAYDESK.LOAD_QUEUES.NOTHING');
};

onMounted(() => {
  buscar();
  store.dispatch('inboxes/get');
});
</script>

<template>
  <SettingsLayout :is-loading="isLoading">
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.LOAD_QUEUES.SETTINGS_TITLE')"
        :description="t('STAYDESK.LOAD_QUEUES.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            sm
            solid
            blue
            :label="t('STAYDESK.LOAD_QUEUES.NEW')"
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
            :label="t('STAYDESK.LOAD_QUEUES.FORM.NAME')"
          />
          <Input
            v-model="form.key"
            :label="t('STAYDESK.LOAD_QUEUES.FORM.KEY')"
            :disabled="editando !== 'nova'"
          />
        </div>
        <p class="m-0 text-xs text-n-slate-11">
          {{ t('STAYDESK.LOAD_QUEUES.FORM.KEY_HINT') }}
        </p>
        <label class="grid gap-1 text-sm text-n-slate-12">
          <span>{{ t('STAYDESK.LOAD_QUEUES.FORM.CHANNELS') }}</span>
          <TagMultiSelectComboBox
            v-model="form.canais"
            :options="canalOptions"
            :placeholder="t('STAYDESK.LOAD_QUEUES.FORM.CHANNELS_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
          <span class="text-xs text-n-slate-11">
            {{ t('STAYDESK.LOAD_QUEUES.FORM.CHANNELS_HINT') }}
          </span>
        </label>
        <label class="flex items-start gap-2 text-sm text-n-slate-12">
          <Switch v-model="form.catchAll" />
          <span class="grid gap-0.5">
            <span>{{ t('STAYDESK.LOAD_QUEUES.FORM.CATCH_ALL') }}</span>
            <span class="text-xs text-n-slate-11">
              {{ t('STAYDESK.LOAD_QUEUES.FORM.CATCH_ALL_HINT') }}
            </span>
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
        <table class="w-full min-w-[32rem] border-collapse text-sm">
          <thead>
            <tr class="text-left text-xs uppercase text-n-slate-11">
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.LOAD_QUEUES.TABLE.NAME') }}
              </th>
              <th class="py-2 pr-4 font-medium">
                {{ t('STAYDESK.LOAD_QUEUES.TABLE.TAKES') }}
              </th>
              <th class="py-2 font-medium" />
            </tr>
          </thead>
          <tbody class="divide-y divide-n-weak">
            <tr v-for="fila in filas" :key="fila.key">
              <td class="py-3 pr-4 text-n-slate-12">
                <p class="m-0">{{ fila.name }}</p>
                <p class="m-0 text-xs text-n-slate-11">{{ fila.key }}</p>
              </td>
              <td class="py-3 pr-4 text-n-slate-11">{{ oQuePega(fila) }}</td>
              <td class="whitespace-nowrap py-3 text-right">
                <Button
                  v-tooltip.top="t('STAYDESK.LOAD_QUEUES.EDIT')"
                  icon="i-woot-settings"
                  slate
                  sm
                  @click="editar(fila)"
                />
                <Button
                  v-if="fila.id"
                  v-tooltip.top="t('STAYDESK.LOAD_QUEUES.DELETE.BUTTON')"
                  icon="i-woot-bin"
                  slate
                  sm
                  class="hover:enabled:bg-n-ruby-2 hover:enabled:text-n-ruby-11"
                  @click="pedirExclusao(fila)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-4 text-xs text-n-slate-11">
        {{ t('STAYDESK.LOAD_QUEUES.FOOTNOTE') }}
      </p>
    </template>
  </SettingsLayout>
  <Dialog
    ref="deleteDialog"
    type="alert"
    :title="t('STAYDESK.LOAD_QUEUES.DELETE.BUTTON')"
    :description="
      t('STAYDESK.LOAD_QUEUES.DELETE.CONFIRM', { name: excluindo?.name || '' })
    "
    :confirm-button-label="t('STAYDESK.LOAD_QUEUES.DELETE.BUTTON')"
    :cancel-button-label="t('STAYDESK.TEAM_VIEWS.FORM.CANCEL')"
    @confirm="excluir"
  />
</template>
