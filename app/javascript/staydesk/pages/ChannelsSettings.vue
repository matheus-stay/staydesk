<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { canaisDaConta } from '../helpers/canais';

// Central › Canais: as caixas do Chatwoot apresentadas como canais, agrupadas
// por tipo como na central do Zendesk. A configuração de cada uma continua sendo
// a tela do produto; aqui é só a porta de entrada com o vocabulário certo.
const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const inboxes = useMapGetter('inboxes/getInboxes');
const uiFlags = useMapGetter('inboxes/getUIFlags');

const grupos = computed(() =>
  canaisDaConta(inboxes.value).map(tipo => ({
    ...tipo,
    canais: inboxes.value.filter(canal => canal.channel_type === tipo.value),
  }))
);

const configurar = canal =>
  router.push(accountScopedRoute('settings_inbox_show', { inboxId: canal.id }));
const novo = () => router.push(accountScopedRoute('settings_inbox_new'));

onMounted(() => store.dispatch('inboxes/get'));
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching && !inboxes.length"
    :no-records-found="!inboxes.length"
    :no-records-message="t('STAYDESK.CHANNELS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.CHANNELS.SETTINGS_TITLE')"
        :description="t('STAYDESK.CHANNELS.SETTINGS_DESCRIPTION')"
      >
        <template #actions>
          <Button
            sm
            solid
            blue
            :label="t('STAYDESK.CHANNELS.NEW')"
            @click="novo"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <section v-for="grupo in grupos" :key="grupo.value" class="mb-6">
        <h3 class="mb-2 text-sm font-medium text-n-slate-12">
          {{ grupo.label }}
          <span class="text-xs font-normal text-n-slate-11">
            · {{ t('STAYDESK.CHANNELS.COUNT', grupo.canais.length) }}
          </span>
        </h3>
        <table class="w-full text-sm">
          <tbody class="divide-y divide-n-weak">
            <tr v-for="canal in grupo.canais" :key="canal.id">
              <td class="py-3 pr-4 text-n-slate-12">
                <p class="m-0">{{ canal.name }}</p>
                <p class="m-0 text-xs text-n-slate-11">
                  {{ t('STAYDESK.CHANNELS.MEMBERS_NOTE') }}
                </p>
              </td>
              <td class="whitespace-nowrap py-3 text-right">
                <Button
                  sm
                  faded
                  slate
                  :label="t('STAYDESK.CHANNELS.CONFIGURE')"
                  @click="configurar(canal)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </section>
    </template>
  </SettingsLayout>
</template>
