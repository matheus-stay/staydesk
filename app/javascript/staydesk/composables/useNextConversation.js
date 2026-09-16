import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import {
  conversationListPageURL,
  conversationUrl,
  frontendURL,
} from 'dashboard/helper/URLHelper';

// "Avançar" e "fechar", como no Zendesk: a próxima conversa da lista carregada,
// na ordem em que a lista está, ou a volta para a lista.
export const useNextConversation = () => {
  const store = useStore();
  const route = useRoute();

  const nextId = currentId => {
    const list = store.getters.getAllConversations;
    const index = list.findIndex(item => item.id === Number(currentId));
    return (
      list[index + 1]?.id ??
      list.find(item => item.id !== Number(currentId))?.id
    );
  };

  const goToList = router =>
    router.push({
      path: frontendURL(
        conversationListPageURL({ accountId: route.params.accountId })
      ),
    });

  const goToNext = async (currentId, router) => {
    const id = nextId(currentId);
    if (!id) return goToList(router);
    return router.push({
      path: frontendURL(
        conversationUrl({ accountId: route.params.accountId, id })
      ),
    });
  };

  return { nextId, goToNext, goToList };
};
