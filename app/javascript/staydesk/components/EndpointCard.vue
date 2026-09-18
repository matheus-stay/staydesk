<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import CodePanel from './CodePanel.vue';
import { paraHtml } from '../helpers/markdownLeve';

// Um endpoint na referência: o que faz, o que aceita, o que devolve. A chamada
// em si fica no painel de teste, à direita.
const props = defineProps({
  endpoint: { type: Object, required: true },
  base: { type: String, default: '' },
  selected: { type: Boolean, default: false },
});
const emit = defineEmits(['select']);

const { t } = useI18n();

const CORES = {
  GET: 'bg-n-teal-9',
  POST: 'bg-n-blue-9',
  PATCH: 'bg-n-amber-9',
  PUT: 'bg-n-amber-9',
  DELETE: 'bg-n-ruby-9',
};

const corDoVerbo = computed(
  () => CORES[props.endpoint.metodo] || 'bg-n-slate-9'
);
const caminhoCompleto = computed(
  () => `${props.base}/${props.endpoint.caminho}`
);
const detalhes = computed(() => paraHtml(props.endpoint.detalhes));
const blocos = computed(() =>
  [
    { chave: 'path', titulo: t('STAYDESK.API_DOCS.PARAMS.PATH') },
    { chave: 'query', titulo: t('STAYDESK.API_DOCS.PARAMS.QUERY') },
    { chave: 'corpo', titulo: t('STAYDESK.API_DOCS.PARAMS.BODY') },
  ].filter(bloco => (props.endpoint[bloco.chave] || []).length)
);
const payload = computed(() =>
  props.endpoint.payload
    ? JSON.stringify(props.endpoint.payload, null, 2)
    : null
);
const resposta = computed(() =>
  props.endpoint.resposta
    ? JSON.stringify(props.endpoint.resposta, null, 2)
    : null
);
const exemploDe = param =>
  param.exemplo === undefined ? '' : JSON.stringify(param.exemplo);
</script>

<template>
  <article
    :id="`${endpoint.metodo}-${endpoint.caminho}`"
    class="scroll-mt-6 rounded-2xl border bg-n-surface-1 transition-colors"
    :class="selected ? 'border-n-brand/60 shadow-sm' : 'border-n-weak'"
    @click="emit('select', endpoint)"
  >
    <header class="grid gap-3 px-7 pt-6">
      <h3 class="m-0 text-xl font-medium tracking-tight text-n-slate-12">
        {{ endpoint.titulo }}
      </h3>
      <div class="flex flex-wrap items-center gap-2">
        <span
          class="inline-flex w-[4.5rem] justify-center rounded-md py-1 text-[11px] font-semibold tracking-wide text-white"
          :class="corDoVerbo"
        >
          {{ endpoint.metodo }}
        </span>
        <code class="font-mono text-[14px] text-n-slate-12">{{
          caminhoCompleto
        }}</code>
        <span class="ml-auto flex flex-wrap items-center gap-2">
          <span
            class="rounded-full border border-n-weak px-2.5 py-0.5 font-mono text-[11px] text-n-slate-11"
            :title="t('STAYDESK.API_DOCS.SCOPE_HINT')"
          >
            {{ endpoint.escopo }}
          </span>
          <span
            v-if="endpoint.mcp"
            class="rounded-full bg-n-brand/10 px-2.5 py-0.5 font-mono text-[11px] text-n-brand"
            :title="t('STAYDESK.API_DOCS.MCP_HINT')"
          >
            {{ endpoint.mcp }}
          </span>
        </span>
      </div>
    </header>

    <div class="grid gap-7 px-7 py-6">
      <div class="grid gap-3">
        <p class="m-0 text-[15px] leading-relaxed text-n-slate-12">
          {{ endpoint.resumo }}
        </p>
        <div
          class="grid gap-3 text-[14px] leading-relaxed text-n-slate-11 [&_p]:m-0"
          v-html="detalhes"
        />
      </div>

      <section v-for="bloco in blocos" :key="bloco.chave" class="grid gap-2">
        <h4
          class="m-0 text-[11px] font-semibold uppercase tracking-wide text-n-slate-10"
        >
          {{ bloco.titulo }}
        </h4>
        <div class="overflow-hidden rounded-xl border border-n-weak">
          <table class="w-full border-collapse text-sm">
            <thead>
              <tr
                class="bg-n-alpha-1 text-left text-[11px] uppercase tracking-wide text-n-slate-10"
              >
                <th class="px-3 py-2 font-medium">
                  {{ t('STAYDESK.API_DOCS.COLS.NAME') }}
                </th>
                <th class="px-3 py-2 font-medium">
                  {{ t('STAYDESK.API_DOCS.COLS.TYPE') }}
                </th>
                <th class="px-3 py-2 font-medium">
                  {{ t('STAYDESK.API_DOCS.COLS.DESCRIPTION') }}
                </th>
                <th class="px-3 py-2 font-medium">
                  {{ t('STAYDESK.API_DOCS.COLS.EXAMPLE') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-n-weak">
              <tr
                v-for="param in endpoint[bloco.chave]"
                :key="param.nome"
                class="align-top"
              >
                <td class="w-[12rem] px-3 py-2.5">
                  <code class="font-mono text-[13px] text-n-slate-12">{{
                    param.nome
                  }}</code>
                  <span
                    v-if="param.obrigatorio"
                    class="ml-1.5 text-[10px] font-semibold uppercase text-n-ruby-11"
                  >
                    {{ t('STAYDESK.API_DOCS.REQUIRED') }}
                  </span>
                </td>
                <td class="w-[8rem] px-3 py-2.5 text-xs text-n-slate-10">
                  {{ param.tipo }}
                </td>
                <td
                  class="px-3 py-2.5 leading-relaxed text-n-slate-11"
                  v-html="paraHtml(param.descricao)"
                />
                <td class="w-[12rem] px-3 py-2.5">
                  <code
                    v-if="exemploDe(param)"
                    class="break-all font-mono text-[11.5px] text-n-slate-11"
                  >
                    {{ exemploDe(param) }}
                  </code>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-if="endpoint.respostas?.length" class="grid gap-2">
        <h4
          class="m-0 text-[11px] font-semibold uppercase tracking-wide text-n-slate-10"
        >
          {{ t('STAYDESK.API_DOCS.RESPONSES') }}
        </h4>
        <div class="overflow-hidden rounded-xl border border-n-weak">
          <table class="w-full border-collapse text-sm">
            <tbody class="divide-y divide-n-weak">
              <tr
                v-for="item in endpoint.respostas"
                :key="item.codigo"
                class="align-top"
              >
                <td class="w-[6rem] px-3 py-2.5">
                  <span
                    class="rounded-md px-2 py-0.5 font-mono text-[11px] font-semibold text-white"
                    :class="
                      item.codigo < 300
                        ? 'bg-n-teal-9'
                        : item.codigo < 500
                          ? 'bg-n-amber-9'
                          : 'bg-n-ruby-9'
                    "
                  >
                    {{ item.codigo }}
                  </span>
                </td>
                <td
                  class="px-3 py-2.5 leading-relaxed text-n-slate-11"
                  v-html="paraHtml(item.descricao)"
                />
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <div v-if="payload || resposta" class="grid gap-3 lg:grid-cols-2">
        <CodePanel
          v-if="payload"
          :label="t('STAYDESK.API_DOCS.PAYLOAD')"
          :code="payload"
          language="json"
        />
        <CodePanel
          v-if="resposta"
          :label="t('STAYDESK.API_DOCS.RESPONSE_EXAMPLE')"
          :code="resposta"
          language="json"
        />
      </div>
    </div>
  </article>
</template>
