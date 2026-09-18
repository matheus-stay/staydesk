<script setup>
/* global axios */
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import Button from 'dashboard/components-next/button/Button.vue';
import CodePanel from './CodePanel.vue';
import { LINGUAGENS } from '../helpers/exemplosDeCodigo';

// O painel de "testar" da referência: monta a chamada com os parâmetros que a
// pessoa preencher, mostra o código em três linguagens e dispara de verdade,
// com a sessão de quem está logado. Escrita pede confirmação: altera a conta.
const props = defineProps({
  endpoint: { type: Object, default: null },
  base: { type: String, default: '' },
});

const { t } = useI18n();
const { accountId } = useAccount();

const valores = ref({});
const corpo = ref('');
const linguagem = ref('curl');
const resultado = ref(null);
const executando = ref(false);
const confirmando = ref(false);

const escrita = computed(
  () => props.endpoint && props.endpoint.metodo !== 'GET'
);

watch(
  () => props.endpoint,
  endpoint => {
    valores.value = {};
    resultado.value = null;
    confirmando.value = false;
    [...(endpoint?.path || []), ...(endpoint?.query || [])].forEach(param => {
      valores.value[param.nome] =
        param.exemplo !== undefined ? String(param.exemplo) : '';
    });
    corpo.value = endpoint?.payload
      ? JSON.stringify(endpoint.payload, null, 2)
      : '';
  },
  { immediate: true }
);

const caminho = computed(() => {
  if (!props.endpoint) return '';
  let resultadoCaminho = `${props.base}/${props.endpoint.caminho}`.replace(
    '{account_id}',
    accountId.value
  );
  (props.endpoint.path || []).forEach(param => {
    resultadoCaminho = resultadoCaminho.replace(
      `{${param.nome}}`,
      valores.value[param.nome] || `{${param.nome}}`
    );
  });
  const query = (props.endpoint.query || [])
    .filter(param => valores.value[param.nome])
    .map(
      param => `${param.nome}=${encodeURIComponent(valores.value[param.nome])}`
    );
  return query.length
    ? `${resultadoCaminho}?${query.join('&')}`
    : resultadoCaminho;
});

const corpoParseado = computed(() => {
  if (!escrita.value || !corpo.value.trim()) return null;
  try {
    return JSON.parse(corpo.value);
  } catch {
    return undefined;
  }
});

const codigo = computed(() => {
  if (!props.endpoint) return '';
  const gerar = LINGUAGENS.find(item => item.chave === linguagem.value)?.gerar;
  return gerar({
    metodo: props.endpoint.metodo,
    url: `${window.location.origin}${caminho.value}`,
    token: 'SEU_TOKEN',
    corpo: corpoParseado.value || null,
  });
});

const executar = async () => {
  if (escrita.value && !confirmando.value) {
    confirmando.value = true;
    return;
  }
  confirmando.value = false;
  executando.value = true;
  const inicio = performance.now();
  try {
    const resposta = await axios.request({
      method: props.endpoint.metodo.toLowerCase(),
      url: caminho.value,
      data: corpoParseado.value || undefined,
    });
    resultado.value = {
      status: resposta.status,
      dados: resposta.data,
      ms: Math.round(performance.now() - inicio),
    };
  } catch (erro) {
    resultado.value = {
      status: erro.response?.status || 0,
      dados: erro.response?.data || { error: erro.message },
      ms: Math.round(performance.now() - inicio),
    };
  } finally {
    executando.value = false;
  }
};

const corDoStatus = status => {
  if (status >= 200 && status < 300) return 'bg-n-teal-9';
  if (status >= 400 && status < 500) return 'bg-n-amber-9';
  return 'bg-n-ruby-9';
};

const respostaFormatada = computed(() =>
  resultado.value ? JSON.stringify(resultado.value.dados, null, 2) : ''
);
</script>

<template>
  <aside class="grid content-start gap-3">
    <div
      v-if="!endpoint"
      class="rounded-2xl border border-n-weak p-6 text-sm text-n-slate-11"
    >
      {{ t('STAYDESK.API_DOCS.TRY.PICK') }}
    </div>
    <template v-else>
      <div class="rounded-2xl border border-n-weak bg-n-surface-1">
        <div class="border-b border-n-weak px-4 py-3">
          <p
            class="m-0 text-[11px] font-semibold uppercase tracking-wide text-n-slate-10"
          >
            {{ t('STAYDESK.API_DOCS.TRY.TITLE') }}
          </p>
          <p class="m-0 mt-1 break-all font-mono text-xs text-n-slate-12">
            <span class="font-semibold">{{ endpoint.metodo }}</span>
            {{ caminho }}
          </p>
        </div>

        <div class="grid gap-3 px-4 py-3">
          <template v-for="grupo in ['path', 'query']" :key="grupo">
            <div v-if="(endpoint[grupo] || []).length" class="grid gap-2">
              <p
                class="m-0 text-[11px] font-semibold uppercase tracking-wide text-n-slate-10"
              >
                {{
                  grupo === 'path'
                    ? t('STAYDESK.API_DOCS.PARAMS.PATH')
                    : t('STAYDESK.API_DOCS.PARAMS.QUERY')
                }}
              </p>
              <label
                v-for="param in endpoint[grupo]"
                :key="param.nome"
                class="grid grid-cols-[9rem_minmax(0,1fr)] items-center gap-2 text-sm"
              >
                <code class="truncate font-mono text-xs text-n-slate-12">{{
                  param.nome
                }}</code>
                <input
                  v-model="valores[param.nome]"
                  type="text"
                  :placeholder="param.tipo"
                  class="h-8 w-full rounded-lg border border-n-weak bg-n-alpha-1 px-2 font-mono text-xs text-n-slate-12"
                />
              </label>
            </div>
          </template>

          <div v-if="escrita" class="grid gap-2">
            <p
              class="m-0 text-[11px] font-semibold uppercase tracking-wide text-n-slate-10"
            >
              {{ t('STAYDESK.API_DOCS.PARAMS.BODY') }}
            </p>
            <textarea
              v-model="corpo"
              rows="8"
              spellcheck="false"
              class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-2 py-1.5 font-mono text-xs text-n-slate-12"
              :class="{ 'border-n-ruby-9': corpoParseado === undefined }"
            />
            <p
              v-if="corpoParseado === undefined"
              class="m-0 text-xs text-n-ruby-11"
            >
              {{ t('STAYDESK.API_DOCS.TRY.INVALID_JSON') }}
            </p>
          </div>

          <div class="flex items-center justify-between gap-2">
            <p v-if="confirmando" class="m-0 text-xs text-n-amber-11">
              {{ t('STAYDESK.API_DOCS.TRY.CONFIRM') }}
            </p>
            <span v-else />
            <Button
              sm
              solid
              :blue="!confirmando"
              :amber="confirmando"
              :is-loading="executando"
              :disabled="corpoParseado === undefined"
              :label="
                confirmando
                  ? t('STAYDESK.API_DOCS.TRY.CONFIRM_BUTTON')
                  : t('STAYDESK.API_DOCS.TRY.RUN')
              "
              @click="executar"
            />
          </div>
        </div>
      </div>

      <div class="grid gap-2">
        <div class="flex gap-1">
          <button
            v-for="item in LINGUAGENS"
            :key="item.chave"
            type="button"
            class="rounded-lg px-2.5 py-1 text-xs"
            :class="
              linguagem === item.chave
                ? 'bg-n-alpha-2 text-n-slate-12'
                : 'text-n-slate-11 hover:bg-n-alpha-1'
            "
            @click="linguagem = item.chave"
          >
            {{ item.rotulo }}
          </button>
        </div>
        <CodePanel
          :label="t('STAYDESK.API_DOCS.REQUEST')"
          :code="codigo"
          :language="linguagem"
        />
      </div>

      <div v-if="resultado" class="grid gap-2">
        <div class="flex items-center gap-2 text-xs text-n-slate-11">
          <span
            class="rounded-md px-2 py-0.5 font-semibold text-white"
            :class="corDoStatus(resultado.status)"
          >
            {{ resultado.status }}
          </span>
          {{ t('STAYDESK.API_DOCS.TRY.TOOK', { ms: resultado.ms }) }}
        </div>
        <CodePanel
          :label="t('STAYDESK.API_DOCS.RESPONSE')"
          :code="respostaFormatada"
          language="json"
        />
      </div>
    </template>
  </aside>
</template>
