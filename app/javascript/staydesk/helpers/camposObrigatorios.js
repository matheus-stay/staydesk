import store from 'dashboard/store';

// Os campos marcados como obrigatórios para resolver no StayDesk entram na
// lista que o produto já usa para pedir os campos antes de encerrar: o botão
// Resolver, o seletor de status e o menu da conversa abrem a mesma janela com o
// que falta, em vez de um erro genérico.
export const obrigatoriosStaydesk = () =>
  (store.getters['attributes/getConversationAttributes'] || [])
    .filter(atributo => atributo.staydeskRequiredToResolve)
    .map(atributo => atributo.attributeKey);
