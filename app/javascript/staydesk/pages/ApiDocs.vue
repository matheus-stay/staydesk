<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ApiReferenceAPI from '../api/apiReference';
import EndpointCard from '../components/EndpointCard.vue';

// Central › Documentação da API: a referência inteira numa página, no formato de
// quem vai integrar. O conteúdo vem do servidor, do mesmo arquivo que um teste
// confere contra as rotas, então o que está aqui existe de verdade.
const { t } = useI18n();

const referencia = ref(null);
const busca = ref('');
const grupoAtivo = ref(null);

const base = computed(() => referencia.value?.base || '');
const grupos = computed(() => referencia.value?.grupos || []);

const casa = (endpoint, termo) =>
  [endpoint.caminho, endpoint.resumo, endpoint.metodo, endpoint.mcp]
    .filter(Boolean)
    .some(campo => campo.toLowerCase().includes(termo));

const gruposVisiveis = computed(() => {
  const termo = busca.value.trim().toLowerCase();
  if (!termo) return grupos.value;
  return grupos.value
    .map(grupo => ({
      ...grupo,
      endpoints: grupo.endpoints.filter(endpoint => casa(endpoint, termo)),
    }))
    .filter(grupo => grupo.endpoints.length);
});

const total = computed(() =>
  grupos.value.reduce((soma, grupo) => soma + grupo.endpoints.length, 0)
);

const irPara = chave => {
  grupoAtivo.value = chave;
  document
    .getElementById(`grupo-${chave}`)
    ?.scrollIntoView({ behavior: 'smooth' });
};

onMounted(async () => {
  const { data } = await ApiReferenceAPI.show();
  referencia.value = data;
});
</script>

<template>
  <SettingsLayout>
    <template #header>
      <BaseSettingsHeader
        :title="t('STAYDESK.API_DOCS.TITLE')"
        :description="t('STAYDESK.API_DOCS.DESCRIPTION', { total })"
      />
    </template>
    <template #body>
      <div class="grid gap-6 lg:grid-cols-[14rem_minmax(0,1fr)]">
        <nav class="hidden lg:block">
          <div class="sticky top-4 grid gap-1">
            <button
              v-for="grupo in grupos"
              :key="grupo.chave"
              type="button"
              class="rounded-lg px-2 py-1.5 text-start text-sm"
              :class="
                grupoAtivo === grupo.chave
                  ? 'bg-n-alpha-2 text-n-slate-12'
                  : 'text-n-slate-11 hover:bg-n-alpha-1'
              "
              @click="irPara(grupo.chave)"
            >
              {{ grupo.titulo }}
              <span class="ml-1 text-xs text-n-slate-10">
                {{ grupo.endpoints.length }}
              </span>
            </button>
          </div>
        </nav>

        <div class="grid gap-8">
          <Input v-model="busca" :placeholder="t('STAYDESK.API_DOCS.SEARCH')" />
          <p v-if="!referencia" class="text-sm text-n-slate-11">
            {{ t('STAYDESK.API_DOCS.LOADING') }}
          </p>
          <p v-else-if="!gruposVisiveis.length" class="text-sm text-n-slate-11">
            {{ t('STAYDESK.API_DOCS.EMPTY', { term: busca }) }}
          </p>
          <section
            v-for="grupo in gruposVisiveis"
            :id="`grupo-${grupo.chave}`"
            :key="grupo.chave"
            class="grid gap-2 scroll-mt-4"
          >
            <h2 class="m-0 text-lg font-medium text-n-slate-12">
              {{ grupo.titulo }}
            </h2>
            <p
              v-if="grupo.texto"
              class="m-0 whitespace-pre-line text-sm text-n-slate-11"
            >
              {{ grupo.texto }}
            </p>
            <pre
              v-if="grupo.exemplo"
              class="m-0 overflow-x-auto rounded-lg bg-n-solid-1 p-3 text-xs text-n-slate-12"
            ><code>{{ grupo.exemplo }}</code></pre>
            <EndpointCard
              v-for="endpoint in grupo.endpoints"
              :key="`${endpoint.metodo}-${endpoint.caminho}`"
              :endpoint="endpoint"
              :base="base"
            />
          </section>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
