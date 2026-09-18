<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

// Bloco de código escuro, com rótulo e botão de copiar, como nas referências de
// API que a gente gosta de ler. Escuro nos dois temas: o token de slate inverte
// junto com o tema, então o contraste se mantém.
defineProps({
  label: { type: String, required: true },
  code: { type: String, required: true },
  language: { type: String, default: 'bash' },
});

const { t } = useI18n();
const copiado = ref(false);

const copiar = async valor => {
  await navigator.clipboard.writeText(valor);
  copiado.value = true;
  setTimeout(() => {
    copiado.value = false;
  }, 1500);
};
</script>

<template>
  <div class="overflow-hidden rounded-xl bg-n-slate-12 text-n-slate-2">
    <div
      class="flex items-center justify-between border-b border-n-slate-11/40 px-4 py-2"
    >
      <span
        class="text-[11px] font-medium uppercase tracking-wide text-n-slate-6"
      >
        {{ label }}
        <span class="ml-2 normal-case tracking-normal text-n-slate-8">
          {{ language }}
        </span>
      </span>
      <button
        type="button"
        class="rounded px-2 py-0.5 text-[11px] text-n-slate-6 hover:bg-n-slate-11 hover:text-n-slate-2"
        @click="copiar(code)"
      >
        {{
          copiado ? t('STAYDESK.API_DOCS.COPIED') : t('STAYDESK.API_DOCS.COPY')
        }}
      </button>
    </div>
    <pre
      class="m-0 max-h-96 overflow-auto px-4 py-3 font-mono text-[12.5px] leading-relaxed"
    ><code>{{ code }}</code></pre>
  </div>
</template>
