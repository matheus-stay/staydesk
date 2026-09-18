<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

// Um endpoint na referência: verbo, caminho, escopo, parâmetros e exemplo.
const props = defineProps({
  endpoint: { type: Object, required: true },
  base: { type: String, default: '' },
});

const { t } = useI18n();

const CORES = {
  GET: 'bg-n-teal-3 text-n-teal-11',
  POST: 'bg-n-blue-3 text-n-blue-11',
  PATCH: 'bg-n-amber-3 text-n-amber-11',
  PUT: 'bg-n-amber-3 text-n-amber-11',
  DELETE: 'bg-n-ruby-3 text-n-ruby-11',
};

const corDoVerbo = computed(
  () => CORES[props.endpoint.metodo] || 'bg-n-alpha-2 text-n-slate-11'
);
const caminhoCompleto = computed(
  () => `${props.base}/${props.endpoint.caminho}`
);
const blocos = computed(() =>
  [
    { chave: 'path', titulo: t('STAYDESK.API_DOCS.PARAMS.PATH') },
    { chave: 'query', titulo: t('STAYDESK.API_DOCS.PARAMS.QUERY') },
    { chave: 'corpo', titulo: t('STAYDESK.API_DOCS.PARAMS.BODY') },
  ].filter(bloco => (props.endpoint[bloco.chave] || []).length)
);
const exemplo = computed(
  () =>
    props.endpoint.exemplo ||
    `curl -H "api_access_token: $TOKEN" \\\n  "$URL${caminhoCompleto.value}"`
);
const resposta = computed(() =>
  props.endpoint.resposta
    ? JSON.stringify(props.endpoint.resposta, null, 2)
    : null
);

const copiar = valor => navigator.clipboard.writeText(valor);
</script>

<template>
  <article
    :id="endpoint.caminho"
    class="grid gap-3 border-t border-n-weak py-6"
  >
    <header class="flex flex-wrap items-center gap-2">
      <span class="rounded px-2 py-0.5 text-xs font-medium" :class="corDoVerbo">
        {{ endpoint.metodo }}
      </span>
      <code class="text-sm text-n-slate-12">{{ caminhoCompleto }}</code>
      <span class="rounded bg-n-alpha-2 px-2 py-0.5 text-xs text-n-slate-11">
        {{ endpoint.escopo }}
      </span>
      <span
        v-if="endpoint.mcp"
        class="rounded bg-n-alpha-2 px-2 py-0.5 text-xs text-n-slate-11"
      >
        {{ t('STAYDESK.API_DOCS.VIA_MCP', { tool: endpoint.mcp }) }}
      </span>
    </header>
    <p class="m-0 text-sm text-n-slate-11">{{ endpoint.resumo }}</p>

    <div v-for="bloco in blocos" :key="bloco.chave" class="grid gap-1">
      <p class="m-0 text-xs font-medium uppercase text-n-slate-11">
        {{ bloco.titulo }}
      </p>
      <table class="w-full border-collapse text-sm">
        <tbody class="divide-y divide-n-weak">
          <tr v-for="param in endpoint[bloco.chave]" :key="param.nome">
            <td class="w-48 py-1.5 pr-3 align-top">
              <code class="text-n-slate-12">{{ param.nome }}</code>
              <span
                v-if="param.obrigatorio"
                class="ml-1 text-xs text-n-ruby-11"
              >
                {{ t('STAYDESK.API_DOCS.REQUIRED') }}
              </span>
            </td>
            <td class="w-28 py-1.5 pr-3 align-top text-xs text-n-slate-11">
              {{ param.tipo }}
            </td>
            <td class="py-1.5 align-top text-n-slate-11">
              {{ param.descricao }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="grid gap-2 md:grid-cols-2">
      <div class="grid gap-1">
        <div class="flex items-center justify-between">
          <p class="m-0 text-xs font-medium uppercase text-n-slate-11">
            {{ t('STAYDESK.API_DOCS.REQUEST') }}
          </p>
          <Button
            xs
            ghost
            slate
            :label="t('STAYDESK.API_DOCS.COPY')"
            @click="copiar(exemplo)"
          />
        </div>
        <pre
          class="m-0 overflow-x-auto rounded-lg bg-n-solid-1 p-3 text-xs text-n-slate-12"
        ><code>{{ exemplo }}</code></pre>
      </div>
      <div v-if="resposta" class="grid gap-1">
        <p class="m-0 text-xs font-medium uppercase text-n-slate-11">
          {{ t('STAYDESK.API_DOCS.RESPONSE') }}
        </p>
        <pre
          class="m-0 max-h-72 overflow-auto rounded-lg bg-n-solid-1 p-3 text-xs text-n-slate-12"
        ><code>{{ resposta }}</code></pre>
      </div>
    </div>
  </article>
</template>
