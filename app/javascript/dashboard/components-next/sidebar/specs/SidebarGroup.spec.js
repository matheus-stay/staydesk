import { mount } from '@vue/test-utils';
import SidebarGroup from '../SidebarGroup.vue';

const mocks = vi.hoisted(() => ({
  push: vi.fn(),
  setExpandedItem: vi.fn(),
  setActivePopover: vi.fn(),
  closeActivePopover: vi.fn(),
  cancelClose: vi.fn(),
  expandedItem: null,
  activePopover: null,
  isCollapsed: null,
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({ path: '/current', name: 'current', params: {} }),
  useRouter: () => ({
    push: mocks.push,
    resolve: to => ({ path: `/${to.name}`, meta: {} }),
  }),
}));

vi.mock('../provider', async () => {
  const { ref } = await import('vue');
  mocks.expandedItem = ref(null);
  mocks.activePopover = ref(null);
  mocks.isCollapsed = ref(false);

  return {
    useSidebarContext: () => ({
      expandedItem: mocks.expandedItem,
      setExpandedItem: mocks.setExpandedItem,
      resolvePath: to => `/${to.name}`,
      resolvePermissions: () => [],
      resolveFeatureFlag: () => '',
      isAllowed: () => true,
      isCollapsed: mocks.isCollapsed,
      isResizing: ref(false),
    }),
    usePopoverState: () => ({
      activePopover: mocks.activePopover,
      setActivePopover: mocks.setActivePopover,
      closeActivePopover: mocks.closeActivePopover,
      scheduleClose: vi.fn(),
      cancelClose: mocks.cancelClose,
    }),
  };
});

const PolicyStub = {
  template: '<li><slot /></li>',
};

const SidebarGroupHeaderStub = {
  emits: ['toggle'],
  template: '<button data-test-id="group-header" @click="$emit(\'toggle\')" />',
};

const SidebarCollapsedPopoverStub = {
  name: 'SidebarCollapsedPopover',
  props: [
    'popoverId',
    'triggerId',
    'focusOnOpen',
    'label',
    'children',
    'activeChild',
    'triggerRect',
  ],
  emits: ['close'],
  template: '<div data-test-id="collapsed-popover" />',
};

const mountGroup = (props, options = {}) =>
  mount(SidebarGroup, {
    props: {
      name: 'More',
      label: 'More',
      icon: 'i-lucide-layout-grid',
      children: [
        {
          name: 'Captain',
          label: 'Captain',
          to: { name: 'captain_assistants_index' },
        },
      ],
      ...props,
    },
    global: {
      stubs: {
        Icon: true,
        Policy: PolicyStub,
        SidebarGroupHeader: SidebarGroupHeaderStub,
        SidebarGroupLeaf: true,
        SidebarSubGroup: true,
        SidebarCollapsedPopover: SidebarCollapsedPopoverStub,
      },
    },
    ...options,
  });

describe('SidebarGroup', () => {
  beforeEach(() => {
    mocks.push.mockClear();
    mocks.setExpandedItem.mockClear();
    mocks.setActivePopover.mockClear();
    mocks.closeActivePopover.mockClear();
    mocks.cancelClose.mockClear();
    mocks.expandedItem.value = null;
    mocks.activePopover.value = null;
    mocks.isCollapsed.value = false;
    mocks.setActivePopover.mockImplementation(name => {
      mocks.activePopover.value = name;
    });
    mocks.closeActivePopover.mockImplementation(() => {
      mocks.activePopover.value = null;
    });
  });

  it('toggles a disclosure-only group without navigating', async () => {
    const wrapper = mountGroup({ disclosureOnly: true });

    await wrapper.get('[data-test-id="group-header"]').trigger('click');

    expect(mocks.setExpandedItem).toHaveBeenCalledWith('More');
    expect(mocks.push).not.toHaveBeenCalled();
  });

  it('opens the collapsed disclosure-only flyout without navigating', async () => {
    mocks.isCollapsed.value = true;
    const wrapper = mountGroup({ disclosureOnly: true });
    const trigger = wrapper.get('button');

    await trigger.trigger('click');

    expect(mocks.setActivePopover).toHaveBeenCalledWith('More');
    expect(mocks.cancelClose).toHaveBeenCalled();
    expect(mocks.push).not.toHaveBeenCalled();
    expect(trigger.attributes()).toMatchObject({
      id: 'sidebar-group-more-trigger',
      'aria-controls': 'sidebar-group-more-popover',
      'aria-expanded': 'true',
      'aria-haspopup': 'dialog',
    });
  });

  it('opens the collapsed disclosure flyout for keyboard activation and focuses it', async () => {
    mocks.isCollapsed.value = true;
    const wrapper = mountGroup({ disclosureOnly: true });
    const trigger = wrapper.get('button');

    await trigger.trigger('keydown', { key: 'Enter' });
    await wrapper.vm.$nextTick();

    const popover = wrapper.getComponent(SidebarCollapsedPopoverStub);
    expect(popover.props()).toMatchObject({
      popoverId: 'sidebar-group-more-popover',
      triggerId: 'sidebar-group-more-trigger',
      focusOnOpen: true,
    });
    expect(mocks.push).not.toHaveBeenCalled();
  });

  it('keeps a disclosure flyout open when click follows hover', async () => {
    mocks.isCollapsed.value = true;
    const wrapper = mountGroup({ disclosureOnly: true });

    await wrapper.get('.relative').trigger('mouseenter');
    await wrapper.get('button').trigger('click');

    expect(mocks.closeActivePopover).not.toHaveBeenCalled();
    expect(mocks.activePopover.value).toBe('More');
  });

  it('restores focus to the collapsed trigger when the flyout requests it', async () => {
    mocks.isCollapsed.value = true;
    const wrapper = mountGroup(
      { disclosureOnly: true },
      { attachTo: document.body }
    );
    const trigger = wrapper.get('button');

    await trigger.trigger('click');
    await wrapper
      .getComponent(SidebarCollapsedPopoverStub)
      .vm.$emit('close', { restoreFocus: true });
    await wrapper.vm.$nextTick();

    expect(document.activeElement).toBe(trigger.element);
    wrapper.unmount();
  });

  it('preserves first-child navigation for regular groups', async () => {
    const wrapper = mountGroup({ name: 'Conversation' });

    await wrapper.get('[data-test-id="group-header"]').trigger('click');

    expect(mocks.push).toHaveBeenCalledWith({
      name: 'captain_assistants_index',
    });
    expect(mocks.setExpandedItem).toHaveBeenCalledWith('Conversation');
  });
});
