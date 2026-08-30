import { flushPromises, mount } from '@vue/test-utils';
import { ref } from 'vue';
import SidebarCollapsedPopover from '../SidebarCollapsedPopover.vue';

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ref(false),
}));

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: vi.fn() }),
}));

vi.mock('../provider', () => ({
  useSidebarContext: () => ({
    isAllowed: () => true,
    sidebarWidth: ref(64),
  }),
}));

const SidebarSortMenuStub = {
  name: 'SidebarSortMenu',
  props: {
    label: { type: String, default: 'Sort' },
  },
  template:
    '<button type="button" data-test-id="sort-menu">{{ label }}</button>',
};

const children = [
  {
    name: 'Captain',
    label: 'Captain',
    icon: 'i-lucide-sparkles',
    sortOptions: ['created_desc'],
    children: [
      {
        name: 'Assistants',
        label: 'Assistants',
        to: { name: 'captain_assistants_index' },
      },
    ],
  },
  {
    name: 'Companies',
    label: 'Companies',
    to: { name: 'companies_index' },
  },
];

const mountPopover = props =>
  mount(SidebarCollapsedPopover, {
    attachTo: document.body,
    props: {
      popoverId: 'sidebar-group-more-popover',
      triggerId: 'sidebar-group-more-trigger',
      label: 'More',
      children,
      ...props,
    },
    global: {
      stubs: {
        Icon: true,
        SidebarSortMenu: SidebarSortMenuStub,
        TeleportWithDirection: {
          template: '<div><slot /></div>',
        },
      },
    },
  });

describe('SidebarCollapsedPopover', () => {
  it('uses one labelled disclosure button per subgroup with a separate sort menu', async () => {
    const wrapper = mountPopover();
    const popover = wrapper.get('#sidebar-group-more-popover');
    const header = wrapper.get(
      '[aria-controls="sidebar-group-more-popover-captain"]'
    );
    const sortMenu = wrapper.get('[data-test-id="sort-menu"]');

    expect(popover.attributes()).toMatchObject({
      role: 'dialog',
      'aria-labelledby': 'sidebar-group-more-trigger',
    });
    expect(header.text()).toContain('Captain');
    expect(header.attributes('aria-expanded')).toBe('false');
    expect(header.find('.i-lucide-chevron-down').exists()).toBe(true);
    expect(header.element.contains(sortMenu.element)).toBe(false);
    expect(
      wrapper.findAll('button').every(button => button.text().trim().length > 0)
    ).toBe(true);

    await header.trigger('click');

    expect(header.attributes('aria-expanded')).toBe('true');
    expect(wrapper.find('#sidebar-group-more-popover-captain').exists()).toBe(
      true
    );
    wrapper.unmount();
  });

  it('focuses the first flyout item when opened from the keyboard', async () => {
    const wrapper = mountPopover({ focusOnOpen: true });

    await flushPromises();

    expect(document.activeElement).toBe(
      wrapper.get('[data-sidebar-popover-focusable]').element
    );
    wrapper.unmount();
  });

  it('keeps keyboard focus inside the flyout', async () => {
    const wrapper = mountPopover({ focusOnOpen: true });
    await flushPromises();
    const focusableItems = wrapper.findAll('[data-sidebar-popover-focusable]');
    const firstItem = focusableItems[0];
    const lastItem = focusableItems[focusableItems.length - 1];

    lastItem.element.focus();
    await wrapper
      .get('#sidebar-group-more-popover')
      .trigger('keydown', { key: 'Tab' });

    expect(document.activeElement).toBe(firstItem.element);
    wrapper.unmount();
  });

  it('requests close and focus restoration on Escape', async () => {
    const wrapper = mountPopover({ focusOnOpen: true });
    await flushPromises();

    document.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })
    );
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('close')).toContainEqual([{ restoreFocus: true }]);
    wrapper.unmount();
  });
});
