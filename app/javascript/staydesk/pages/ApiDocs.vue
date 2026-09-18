<script setup>
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
} from 'vue';
import { useI18n } from 'vue-i18n';
import ApiReferenceAPI from '../api/apiReference';
import EndpointCard from '../components/EndpointCard.vue';
import TryItPanel from '../components/TryItPanel.vue';
import { paraHtml } from '../helpers/markdownLeve';

// Central › Documentação da API. Três colunas: o índice, a referência e o painel
// de teste, que acompanha o endpoint em foco. O conteúdo vem do servidor, do
// mesmo arquivo que um teste confere contra as rotas.
const { t } = useI18n();

const referencia = ref(null);
const busca = ref('');
const selecionado = ref(null);
const grupoAtivo = ref(null);
const conteudo = ref(null);
let observador = null;

const base = computed(() => referencia.value?.base || '');
const grupos = computed(() => referencia.value?.grupos || []);
const total = computed(() =>
  grupos.value.reduce((soma, grupo) => soma + grupo.endpoints.length, 0)
);

const casa = (endpoint, termo) =>
  [
    endpoint.titulo,
    endpoint.caminho,
    endpoint.resumo,
    endpoint.metodo,
    endpoint.mcp,
  ]
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

const idDe = endpoint => `${endpoint.metodo}-${endpoint.caminho}`;

const selecionar = endpoint => {
  selecionado.value = endpoint;
};

const irPara = (grupo, endpoint = null) => {
  grupoAtivo.value = grupo.chave;
  if (endpoint) selecionar(endpoint);
  const alvo = endpoint
    ? document.getElementById(idDe(endpoint))
    : document.getElementById(`grupo-${grupo.chave}`);
  alvo?.scrollIntoView({ behavior: 'smooth', block: 'start' });
};

// Quem está no meio da tela vira o endpoint em foco, para o painel de teste
// acompanhar a leitura sem clique.
const observar = () => {
  observador?.disconnect();
  observador = new IntersectionObserver(
    entradas => {
      const visivel = entradas
        .filter(entrada => entrada.isIntersecting)
        .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
      if (!visivel) return;
      const id = visivel.target.id;
      const grupo = grupos.value.find(item =>
        item.endpoints.some(endpoint => idDe(endpoint) === id)
      );
      if (!grupo) return;
      selecionado.value = grupo.endpoints.find(
        endpoint => idDe(endpoint) === id
      );
      grupoAtivo.value = grupo.chave;
    },
    {
      root: conteudo.value?.closest('.overflow-auto') || null,
      rootMargin: '-15% 0px -60% 0px',
      threshold: 0,
    }
  );
  document
    .querySelectorAll('article[id]')
    .forEach(el => observador.observe(el));
};

watch(gruposVisiveis, async () => {
  await nextTick();
  observar();
});

onMounted(async () => {
  const { data } = await ApiReferenceAPI.show();
  referencia.value = data;
  selecionado.value = data.grupos[0]?.endpoints[0] || null;
  grupoAtivo.value = data.grupos[0]?.chave || null;
  await nextTick();
  observar();
});

onBeforeUnmount(() => observador?.disconnect());
</script>

<template>
  <div class="mx-auto w-full max-w-[110rem] px-8 pb-16 pt-6 font-inter">
    <header class="mb-8 flex flex-wrap items-end justify-between gap-4">
      <div class="grid gap-1">
        <h1 class="m-0 text-2xl font-medium tracking-tight text-n-slate-12">
          {{ t('STAYDESK.API_DOCS.TITLE') }}
        </h1>
        <p class="m-0 max-w-3xl text-sm text-n-slate-11">
          {{ t('STAYDESK.API_DOCS.DESCRIPTION', { total }) }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <code
          class="rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-1.5 font-mono text-xs text-n-slate-11"
        >
          {{ base }}
        </code>
        <input
          v-model="busca"
          type="search"
          :placeholder="t('STAYDESK.API_DOCS.SEARCH')"
          class="h-9 w-72 rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12"
        />
      </div>
    </header>

    <p v-if="!referencia" class="text-sm text-n-slate-11">
      {{ t('STAYDESK.API_DOCS.LOADING') }}
    </p>

    <div v-else class="grid gap-8 xl:grid-cols-[15rem_minmax(0,1fr)_26rem]">
      <nav class="hidden xl:block">
        <div
          class="sticky top-6 grid max-h-[calc(100vh-6rem)] gap-4 overflow-auto pr-2"
        >
          <div
            v-for="grupo in gruposVisiveis"
            :key="grupo.chave"
            class="grid gap-0.5"
          >
            <button
              type="button"
              class="rounded-lg px-2 py-1.5 text-start text-[13px] font-medium"
              :class="
                grupoAtivo === grupo.chave
                  ? 'text-n-slate-12'
                  : 'text-n-slate-11 hover:text-n-slate-12'
              "
              @click="irPara(grupo)"
            >
              {{ grupo.titulo }}
            </button>
            <button
              v-for="endpoint in grupo.endpoints"
              :key="idDe(endpoint)"
              type="button"
              class="flex items-center gap-2 rounded-lg px-2 py-1 text-start text-xs"
              :class="
                selecionado && idDe(selecionado) === idDe(endpoint)
                  ? 'bg-n-alpha-2 text-n-slate-12'
                  : 'text-n-slate-11 hover:bg-n-alpha-1'
              "
              @click="irPara(grupo, endpoint)"
            >
              <span
                class="w-11 shrink-0 font-mono text-[10px] font-semibold text-n-slate-10"
              >
                {{ endpoint.metodo }}
              </span>
              <span class="truncate">{{ endpoint.titulo }}</span>
            </button>
          </div>
        </div>
      </nav>

      <div ref="conteudo" class="grid gap-12">
        <p v-if="!gruposVisiveis.length" class="text-sm text-n-slate-11">
          {{ t('STAYDESK.API_DOCS.EMPTY', { term: busca }) }}
        </p>
        <section
          v-for="grupo in gruposVisiveis"
          :id="`grupo-${grupo.chave}`"
          :key="grupo.chave"
          class="grid gap-5 scroll-mt-6"
        >
          <div class="grid gap-3">
            <h2 class="m-0 text-2xl font-medium tracking-tight text-n-slate-12">
              {{ grupo.titulo }}
            </h2>
            <div
              v-if="grupo.texto"
              class="grid max-w-3xl gap-3 text-[14.5px] leading-relaxed text-n-slate-11 [&_p]:m-0"
              v-html="paraHtml(grupo.texto)"
            />
            <pre
              v-if="grupo.exemplo"
              class="m-0 max-w-3xl overflow-x-auto rounded-xl bg-n-slate-12 px-4 py-3 font-mono text-[12.5px] leading-relaxed text-n-slate-2"
            ><code>{{ grupo.exemplo }}</code></pre>
          </div>
          <EndpointCard
            v-for="endpoint in grupo.endpoints"
            :key="idDe(endpoint)"
            :endpoint="endpoint"
            :base="base"
            :selected="!!selecionado && idDe(selecionado) === idDe(endpoint)"
            @select="selecionar"
          />
        </section>
      </div>

      <div class="hidden xl:block">
        <div class="sticky top-6 max-h-[calc(100vh-6rem)] overflow-auto pr-1">
          <TryItPanel :endpoint="selecionado" :base="base" />
        </div>
      </div>
    </div>
  </div>
</template>
