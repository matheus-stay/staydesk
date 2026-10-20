import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useTeamViewsStore } from '../store/teamViews';

// Mutações da store do produto que mudam em qual visualização a conversa cai.
// Chegam pelo tempo real (conversa nova, status, responsável, grupo, campos).
export const MUTACOES_QUE_MUDAM_CONTAGEM = new Set([
  'ADD_CONVERSATION',
  'UPDATE_CONVERSATION',
  'CHANGE_CONVERSATION_STATUS',
  'ASSIGN_AGENT',
  'ASSIGN_TEAM',
  'UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES',
  'SET_CONVERSATION_LABELS',
  'DELETE_CONVERSATION',
]);

// Várias mudanças em rajada viram um pedido só.
export const ESPERA_MS = 1500;

// O número ao lado de cada visualização acompanha a lista em tempo real: a cada
// mudança de conversa que chega, a contagem é pedida de novo ao servidor.
export const atualizarContagensEmTempoReal = ({ store, pinia }) => {
  if (!store?.subscribe || !pinia) return () => {};

  let agendado = null;
  const atualizar = () => {
    if (agendado) return;
    agendado = setTimeout(() => {
      agendado = null;
      const visualizacoes = useTeamViewsStore(pinia);
      if (visualizacoes.uiFlags.hasFetched) {
        visualizacoes.fetchCounts().catch(() => {});
      }
    }, ESPERA_MS);
  };

  const parar = store.subscribe(mutacao => {
    if (MUTACOES_QUE_MUDAM_CONTAGEM.has(mutacao.type)) atualizar();
  });
  emitter.on(BUS_EVENTS.WEBSOCKET_RECONNECT, atualizar);

  return () => {
    parar();
    emitter.off(BUS_EVENTS.WEBSOCKET_RECONNECT, atualizar);
    clearTimeout(agendado);
  };
};
