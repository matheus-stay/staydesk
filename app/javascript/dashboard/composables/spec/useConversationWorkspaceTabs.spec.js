import { beforeEach, describe, expect, it, vi } from 'vitest';

const loadComposable = async (accountId = 1) => {
  const module = await import('../useConversationWorkspaceTabs');
  return {
    ...module,
    workspaceTabs: module.useConversationWorkspaceTabs(accountId),
  };
};

describe('useConversationWorkspaceTabs', () => {
  beforeEach(() => {
    window.sessionStorage.clear();
    vi.resetModules();
  });

  it('opens a tab and marks its conversation active', async () => {
    const { workspaceTabs, CONVERSATION_WORKSPACE_TABS_STORAGE_KEY } =
      await loadComposable();
    const tab = {
      id: 42,
      title: 'Billing issue',
      path: '/app/accounts/1/conversations/42',
    };

    workspaceTabs.openTab(tab);

    expect(workspaceTabs.openTabs.value).toEqual([tab]);
    expect(workspaceTabs.activeConversationId.value).toBe(42);
    expect(
      JSON.parse(
        sessionStorage.getItem(`${CONVERSATION_WORKSPACE_TABS_STORAGE_KEY}:1`)
      )
    ).toEqual({
      openTabs: [tab],
      activeConversationId: 42,
    });
  });

  it('updates an existing tab without duplicating it', async () => {
    const { workspaceTabs } = await loadComposable();

    workspaceTabs.openTab({
      id: 42,
      title: 'Original title',
      path: '/app/accounts/1/conversations/42',
    });
    workspaceTabs.openTab({
      id: '42',
      title: 'Updated title',
      path: '/app/accounts/1/conversations/42?view=mine',
    });

    expect(workspaceTabs.openTabs.value).toEqual([
      {
        id: '42',
        title: 'Updated title',
        path: '/app/accounts/1/conversations/42?view=mine',
      },
    ]);
  });

  it('hydrates the workspace from session storage', async () => {
    const firstInstance = await loadComposable();
    firstInstance.workspaceTabs.openTab({
      id: 42,
      title: 'Billing issue',
      path: '/app/accounts/1/conversations/42',
    });

    vi.resetModules();
    const secondInstance = await loadComposable();

    expect(secondInstance.workspaceTabs.openTabs.value).toEqual(
      firstInstance.workspaceTabs.openTabs.value
    );
    expect(secondInstance.workspaceTabs.activeConversationId.value).toBe(42);
  });

  it('keeps tabs isolated by account', async () => {
    const firstAccount = await loadComposable(1);
    const secondAccount = await loadComposable(2);

    firstAccount.workspaceTabs.openTab({
      id: 42,
      title: 'First account ticket',
      path: '/app/accounts/1/conversations/42',
    });
    secondAccount.workspaceTabs.openTab({
      id: 42,
      title: 'Second account ticket',
      path: '/app/accounts/2/conversations/42',
    });

    expect(firstAccount.workspaceTabs.openTabs.value[0].title).toBe(
      'First account ticket'
    );
    expect(secondAccount.workspaceTabs.openTabs.value[0].title).toBe(
      'Second account ticket'
    );
  });

  it('marks only open conversations as active', async () => {
    const { workspaceTabs } = await loadComposable();
    workspaceTabs.openTab({
      id: 42,
      title: 'Billing issue',
      path: '/app/accounts/1/conversations/42',
    });

    expect(workspaceTabs.setActiveConversation('42')).toBe(true);
    expect(workspaceTabs.setActiveConversation(99)).toBe(false);
    expect(workspaceTabs.activeConversationId.value).toBe(42);
  });

  it('selects an adjacent tab when closing the active tab', async () => {
    const { workspaceTabs } = await loadComposable();
    workspaceTabs.openTab({
      id: 41,
      title: 'First ticket',
      path: '/app/accounts/1/conversations/41',
    });
    workspaceTabs.openTab({
      id: 42,
      title: 'Second ticket',
      path: '/app/accounts/1/conversations/42',
    });
    workspaceTabs.openTab({
      id: 43,
      title: 'Third ticket',
      path: '/app/accounts/1/conversations/43',
    });
    workspaceTabs.setActiveConversation(42);

    expect(workspaceTabs.closeTab(42)).toBe(true);
    expect(workspaceTabs.openTabs.value.map(tab => tab.id)).toEqual([41, 43]);
    expect(workspaceTabs.activeConversationId.value).toBe(43);
  });

  it('clears all tabs and their persisted state', async () => {
    const { workspaceTabs, CONVERSATION_WORKSPACE_TABS_STORAGE_KEY } =
      await loadComposable();
    workspaceTabs.openTab({
      id: 42,
      title: 'Billing issue',
      path: '/app/accounts/1/conversations/42',
    });

    workspaceTabs.clearTabs();

    expect(workspaceTabs.openTabs.value).toEqual([]);
    expect(workspaceTabs.activeConversationId.value).toBeNull();
    expect(
      sessionStorage.getItem(`${CONVERSATION_WORKSPACE_TABS_STORAGE_KEY}:1`)
    ).toBeNull();
  });

  it('rejects incomplete tab data', async () => {
    const { workspaceTabs } = await loadComposable();

    expect(() =>
      workspaceTabs.openTab({
        id: 42,
        title: 'Billing issue',
      })
    ).toThrowError('Conversation tab requires id, title, and path');
  });
});
