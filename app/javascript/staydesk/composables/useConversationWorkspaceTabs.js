import { readonly, ref, unref } from 'vue';
import SessionStorage from 'shared/helpers/sessionStorage';

export const CONVERSATION_WORKSPACE_TABS_STORAGE_KEY =
  'staydeskConversationWorkspaceTabs';

const workspaceStates = new Map();

const hasSameId = (firstId, secondId) => String(firstId) === String(secondId);

const isValidTab = tab => {
  return (
    tab &&
    tab.id !== null &&
    tab.id !== undefined &&
    typeof tab.title === 'string' &&
    typeof tab.path === 'string' &&
    tab.path.length > 0
  );
};

const getStorageKey = accountId => {
  const accountScope = unref(accountId) ?? 'default';
  return `${CONVERSATION_WORKSPACE_TABS_STORAGE_KEY}:${accountScope}`;
};

const createWorkspaceState = storageKey => {
  const storedState = SessionStorage.get(storageKey);
  const storedTabs = Array.isArray(storedState?.openTabs)
    ? storedState.openTabs.filter(isValidTab)
    : [];
  const storedActiveTab = storedTabs.find(tab =>
    hasSameId(tab.id, storedState?.activeConversationId)
  );

  return {
    openTabs: ref(storedTabs),
    activeConversationId: ref(
      storedActiveTab?.id ?? storedTabs.at(-1)?.id ?? null
    ),
  };
};

const getWorkspaceState = storageKey => {
  if (!workspaceStates.has(storageKey)) {
    workspaceStates.set(storageKey, createWorkspaceState(storageKey));
  }

  return workspaceStates.get(storageKey);
};

const normalizeTab = tab => {
  if (!isValidTab(tab)) {
    throw new TypeError('Conversation tab requires id, title, and path');
  }

  return {
    id: tab.id,
    title: tab.title,
    path: tab.path,
  };
};

export function useConversationWorkspaceTabs(accountId) {
  const storageKey = getStorageKey(accountId);
  const state = getWorkspaceState(storageKey);

  const persist = () => {
    SessionStorage.set(storageKey, {
      openTabs: state.openTabs.value,
      activeConversationId: state.activeConversationId.value,
    });
  };

  const openTab = tab => {
    const normalizedTab = normalizeTab(tab);
    const existingIndex = state.openTabs.value.findIndex(openTabItem =>
      hasSameId(openTabItem.id, normalizedTab.id)
    );

    if (existingIndex === -1) {
      state.openTabs.value = [...state.openTabs.value, normalizedTab];
    } else {
      state.openTabs.value = state.openTabs.value.map((openTabItem, index) =>
        index === existingIndex ? normalizedTab : openTabItem
      );
    }

    state.activeConversationId.value = normalizedTab.id;
    persist();
  };

  const closeTab = conversationId => {
    const tabIndex = state.openTabs.value.findIndex(tab =>
      hasSameId(tab.id, conversationId)
    );
    if (tabIndex === -1) return false;

    const isClosingActiveTab = hasSameId(
      state.activeConversationId.value,
      state.openTabs.value[tabIndex].id
    );
    const remainingTabs = state.openTabs.value.filter(
      (_, index) => index !== tabIndex
    );

    state.openTabs.value = remainingTabs;
    if (isClosingActiveTab) {
      state.activeConversationId.value =
        remainingTabs[tabIndex]?.id ?? remainingTabs[tabIndex - 1]?.id ?? null;
    }

    persist();
    return true;
  };

  const clearTabs = () => {
    state.openTabs.value = [];
    state.activeConversationId.value = null;
    SessionStorage.remove(storageKey);
  };

  const setActiveConversation = conversationId => {
    const tab = state.openTabs.value.find(openTabItem =>
      hasSameId(openTabItem.id, conversationId)
    );
    if (!tab) return false;

    state.activeConversationId.value = tab.id;
    persist();
    return true;
  };

  return {
    openTabs: readonly(state.openTabs),
    activeConversationId: readonly(state.activeConversationId),
    openTab,
    closeTab,
    clearTabs,
    setActiveConversation,
  };
}
