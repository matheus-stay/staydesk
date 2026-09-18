<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import LoadQueuesAPI from '../api/loadQueues';
import { canaisDaConta, nomeDoCanal } from '../helpers/canais';
import { fromSaveButton } from '../helpers/form';

// Central › Filas de carga: quantas conversas simultâneas o agente aguenta é
// contado por fila, e é a caixa que diz de qual fila a conversa é. Não confundir
// com as filas de encaminhamento, que decidem o grupo dono do trabalho.
const { t } = useI18n();
const store = useStore();
const inboxes = useMapGetter('inboxes/getInboxes');

const filas = ref([]);
const editando = ref(null);
const vazio = () => ({
  key: '',
  name: '',
  channelTypes: [],
  inboxIds: [],
  catchAll: false,
});
const form = ref(vazio());

const canalOptions = computed(() => canaisDaConta(inboxes.value));
const caixaOptions = computed(() =>
  inboxes.value.map(caixa => ({ value: caixa.id, label: caixa.name }))
);

const buscar = async () => {
  const { data } = await LoadQueuesAPI.list();
  filas.value = data.load_queues;
};

const editar = fila => {
  editando.value = fila || 'nova';
  form.value = fila
    ? {
        key: fila.key,
        name: fila.name,
        channelTypes: [...(fila.channel_types || [])],
        inboxIds: [...(fila.inbox_ids || [])],
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
    channel_types: form.value.channelTypes,
    inbox_ids: form.value.inboxIds,
    catch_all: form.value.catchAll,
  };
  try {
    if (editando.value === 'nova') await LoadQueuesAPI.create(payload);
    else await LoadQueuesAPI.update(editando.value.id, payload);
    editando.value = null;
    await buscar();
  } catch {
    useAlert(t('STAYDESK.LOAD_QUEUES.API.SAVE_ERROR'));
  }
};

const excluir = async fila => {
  await LoadQueuesAPI.delete(fila.id);
  await buscar();
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
  <SettingsLayout>
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
    <template #body>
      <form v-if="editando" class="mb-8 grid gap-4" @submit.prevent="salvar">
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
            v-model="form.channelTypes"
            :options="canalOptions"
            :placeholder="t('STAYDESK.LOAD_QUEUES.FORM.CHANNELS_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
        </label>
        <label class="grid gap-1 text-sm text-n-slate-12">
          <span>{{ t('STAYDESK.LOAD_QUEUES.FORM.INBOXES') }}</span>
          <TagMultiSelectComboBox
            v-model="form.inboxIds"
            :options="caixaOptions"
            :placeholder="t('STAYDESK.LOAD_QUEUES.FORM.INBOXES_PLACEHOLDER')"
            :search-placeholder="t('STAYDESK.PICKER.SEARCH')"
            :empty-state="t('STAYDESK.PICKER.EMPTY')"
          />
          <span class="text-xs text-n-slate-11">
            {{ t('STAYDESK.LOAD_QUEUES.FORM.INBOXES_HINT') }}
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
          <Button sm solid blue type="submit" data-staydesk-save>
            {{ t('STAYDESK.TEAM_VIEWS.FORM.SAVE') }}
          </Button>
        </div>
      </form>

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
                  sm
                  faded
                  slate
                  :label="t('STAYDESK.TEAM_VIEWS.FORM.EDIT')"
                  @click="editar(fila)"
                />
                <Button
                  v-if="fila.id"
                  sm
                  faded
                  ruby
                  class="ml-2"
                  :label="t('STAYDESK.TEAM_VIEWS.FORM.DELETE')"
                  @click="excluir(fila)"
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
</template>
