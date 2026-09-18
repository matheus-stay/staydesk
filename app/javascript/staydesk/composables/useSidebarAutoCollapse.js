import { computed, watch } from 'vue';
import { useRoute } from 'vue-router';

// Ao abrir um chat ou ticket em tela cheia, a barra lateral encolhe para os
// ícones e devolve o espaço ao atendimento. Ao voltar para a visualização, ela
// volta à largura que estava. É estado de tela, não preferência: não grava no
// perfil, então o que o agente escolheu no botão continua valendo.
export function useSidebarAutoCollapse({
  sidebarWidth,
  setSidebarWidth,
  COLLAPSED_THRESHOLD,
  MIN_WIDTH,
}) {
  const route = useRoute();
  const isConversationOpen = computed(() =>
    Boolean(route.params?.conversation_id)
  );

  let widthBeforeConversation = null;

  watch(
    isConversationOpen,
    (isOpen, wasOpen) => {
      if (isOpen === wasOpen) return;

      if (isOpen) {
        if (sidebarWidth.value < COLLAPSED_THRESHOLD) return;
        widthBeforeConversation = sidebarWidth.value;
        setSidebarWidth(MIN_WIDTH);
        return;
      }

      if (widthBeforeConversation === null) return;
      setSidebarWidth(widthBeforeConversation);
      widthBeforeConversation = null;
    },
    { immediate: true }
  );
}
