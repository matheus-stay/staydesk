import { mount } from '@vue/test-utils';
import { ref } from 'vue';
import SidebarGroupHeader from '../SidebarGroupHeader.vue';

vi.mock('dashboard/composables/store.js', () => ({
  useMapGetter: () => ref(0),
}));

const RouterLinkStub = {
  props: ['to'],
  template: '<a><slot /></a>',
};

const mountHeader = props =>
  mount(SidebarGroupHeader, {
    props: {
      name: 'More',
      label: 'More',
      icon: 'i-lucide-layout-grid',
      ...props,
    },
    global: {
      stubs: {
        Icon: true,
        RouterLink: RouterLinkStub,
      },
    },
  });

describe('SidebarGroupHeader', () => {
  it('renders expandable groups as semantic buttons', () => {
    const wrapper = mountHeader({ expandable: true });
    const button = wrapper.get('button');

    expect(button.attributes('type')).toBe('button');
    expect(button.attributes('aria-expanded')).toBe('false');
    expect(button.classes()).toContain('focus-visible:outline-n-brand');
    expect(button.find('.i-lucide-chevron-down').exists()).toBe(true);
  });

  it('exposes the open state and rotates the chevron', () => {
    const wrapper = mountHeader({ expandable: true, isExpanded: true });
    const button = wrapper.get('button');

    expect(button.attributes('aria-expanded')).toBe('true');
    expect(button.get('.i-lucide-chevron-down').classes()).toContain(
      'rotate-180'
    );
  });

  it('renders direct destinations as router links', () => {
    const wrapper = mountHeader({ to: { name: 'inbox_view' } });

    expect(wrapper.find('a').exists()).toBe(true);
    expect(wrapper.find('button').exists()).toBe(false);
  });
});
