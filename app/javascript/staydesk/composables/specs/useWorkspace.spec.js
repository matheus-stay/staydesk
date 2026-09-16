import { createPinia, setActivePinia } from 'pinia';
import { useWorkspaceStore } from '../../store/workspace';
import { useWorkspace } from '../useWorkspace';

describe('useWorkspace', () => {
  beforeEach(() => setActivePinia(createPinia()));

  it('does not restrict anything before the workspace is loaded', () => {
    const { filterMenuNames, filterPanels, filterApps, allowsMacro, isTable } =
      useWorkspace();

    expect(filterMenuNames(['Inbox', 'Reports'])).toEqual(['Inbox', 'Reports']);
    expect(filterPanels([{ name: 'macros' }])).toEqual([{ name: 'macros' }]);
    expect(filterApps([{ id: 1 }])).toEqual([{ id: 1 }]);
    expect(allowsMacro(9)).toBe(true);
    expect(isTable.value).toBe(false);
  });

  it('applies the resolved configuration', () => {
    const store = useWorkspaceStore();
    store.config = {
      ...store.config,
      menu: ['Conversation'],
      list: { layout: 'table', columns: ['status'] },
      conversation: {
        fields: ['assignee'],
        panels: ['macros', 'conversation_info'],
        apps: [2],
      },
      macros: { mode: 'list', ids: [4] },
    };
    const {
      filterMenuNames,
      filterPanels,
      filterApps,
      allowsMacro,
      isTable,
      columns,
    } = useWorkspace();

    expect(filterMenuNames(['Inbox', 'Conversation', 'Reports'])).toEqual([
      'Conversation',
    ]);
    expect(
      filterPanels([
        { name: 'conversation_info' },
        { name: 'macros' },
        { name: 'shared_files' },
      ])
    ).toEqual([{ name: 'macros' }, { name: 'conversation_info' }]);
    expect(filterApps([{ id: 1 }, { id: 2 }])).toEqual([{ id: 2 }]);
    expect(allowsMacro(4)).toBe(true);
    expect(allowsMacro(5)).toBe(false);
    expect(isTable.value).toBe(true);
    expect(columns.value).toEqual(['status']);
  });
});
