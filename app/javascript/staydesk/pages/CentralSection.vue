<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useCentralStore } from '../store/central';

// A home de uma seção da Central: o que ela cobre e cada tela dela com uma
// linha explicando para que serve, como a central de administração do Zendesk
// faz por área.
const { t, te } = useI18n();
const route = useRoute();
const router = useRouter();
const central = useCentralStore();

const secao = computed(() => central.secao(route.params.secao));

const descricaoDe = item => {
  const chave = `STAYDESK.CENTRAL.ITEM_HINTS.${item.name}`;
  return te(chave) ? t(chave) : '';
};
const descricaoDaSecao = computed(() => {
  const chave = `STAYDESK.CENTRAL.SECTION_HINTS.${secao.value?.name}`;
  return te(chave) ? t(chave) : '';
});
</script>

<template>
  <div class="mx-auto w-full max-w-5xl px-8 pb-16 pt-6 font-inter">
    <p v-if="!secao" class="text-sm text-n-slate-11">
      {{ t('STAYDESK.CENTRAL.SECTION_NOT_FOUND') }}
    </p>
    <template v-else>
      <header class="mb-8 grid gap-2">
        <div class="flex items-center gap-3">
          <span
            class="flex size-10 items-center justify-center rounded-xl bg-n-alpha-2 text-n-slate-12"
          >
            <Icon :icon="secao.icon" class="size-5" />
          </span>
          <h1 class="m-0 text-2xl font-medium tracking-tight text-n-slate-12">
            {{ secao.label }}
          </h1>
        </div>
        <p
          v-if="descricaoDaSecao"
          class="m-0 max-w-2xl text-[15px] leading-relaxed text-n-slate-11"
        >
          {{ descricaoDaSecao }}
        </p>
      </header>

      <div class="grid gap-3 md:grid-cols-2">
        <button
          v-for="item in secao.children"
          :key="item.name"
          type="button"
          class="group grid gap-1.5 rounded-2xl border border-n-weak bg-n-surface-1 p-5 text-start transition-colors hover:border-n-brand/50 hover:bg-n-alpha-1"
          @click="router.push(item.to)"
        >
          <span
            class="flex items-center gap-2 text-[15px] font-medium text-n-slate-12"
          >
            <Icon
              :icon="item.icon"
              class="size-4 flex-shrink-0 text-n-slate-10 group-hover:text-n-brand"
            />
            {{ item.label }}
          </span>
          <span
            v-if="descricaoDe(item)"
            class="text-sm leading-relaxed text-n-slate-11"
          >
            {{ descricaoDe(item) }}
          </span>
        </button>
      </div>
    </template>
  </div>
</template>
