<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useRoute } from 'vue-router';
import { estaNaCentral } from '../helpers/central';
import Icon from 'dashboard/components-next/icon/Icon.vue';

// A central de administração abre numa aba própria, como no Zendesk: o espaço de
// atendimento não se mistura com o de configurar.
const props = defineProps({
  item: { type: Object, required: true },
  isCollapsed: { type: Boolean, default: false },
});

const { t } = useI18n();
const router = useRouter();
const { checkPermissions } = usePolicy();
const route = useRoute();
// Já estando na Central, o link não tem para onde levar: quem está lá volta é
// para o Hub, pelo caminho de volta no topo da barra.
const foraDaCentral = computed(() => !estaNaCentral(route.path));

// O item de Configurações do produto só agrupa filhos: não tem destino próprio.
// A central abre nas configurações da conta, que é a casa do administrador, e
// de lá a barra de configurações leva ao resto, inclusive ao que é do StayDesk.
const HOME = 'Settings Account Settings';

// Quem não é administrador entra pela primeira área que o papel dele libera; sem
// nenhuma, o link não existe. As áreas do produto (conta, agentes, caixas) não
// declaram permissão porque continuam sendo só do administrador.
const destino = computed(() => {
  if (props.item?.to) return props.item.to;

  const filhos = props.item?.children || [];
  const liberado = filhos.find(
    filho =>
      filho.to && filho.permissions && checkPermissions(filho.permissions)
  );
  if (!checkPermissions(['administrator'])) return liberado?.to || null;

  return (
    filhos.find(filho => filho.name === HOME && filho.to)?.to ||
    liberado?.to ||
    null
  );
});

const href = computed(() =>
  destino.value ? router.resolve(destino.value).href : '#'
);
const label = computed(() => props.item?.label || t('SIDEBAR.SETTINGS'));
</script>

<template>
  <li v-if="destino && foraDaCentral">
    <a
      :href="href"
      target="_blank"
      rel="noopener noreferrer"
      class="flex min-w-0 items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-n-slate-12 hover:bg-n-alpha-1"
    >
      <Icon :icon="item.icon || 'i-lucide-settings'" class="flex-shrink-0" />
      <span v-if="!isCollapsed" class="truncate">{{ label }}</span>
    </a>
  </li>
</template>
