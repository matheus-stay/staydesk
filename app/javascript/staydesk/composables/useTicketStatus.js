import { computed } from 'vue';
import { useTicketStatusStore } from '../store/ticketStatus';

// Ponto de entrada do upstream para o catálogo de status do ticket (SPEC-10):
// diz se a conta tem catálogo e resolve o status personalizado de uma conversa.
export const useStaydeskTicketStatus = () => {
  const store = useTicketStatusStore();
  store.ensureLoaded();

  const enabled = computed(() => store.enabled);
  const statuses = computed(() => store.active);
  const forConversation = conversation => store.forConversation(conversation);

  return { enabled, statuses, forConversation, store };
};
