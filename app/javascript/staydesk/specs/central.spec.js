import { destinoDaCentral, estaNaCentral } from '../helpers/central';

const central = {
  name: 'Settings',
  children: [
    {
      name: 'StaydeskCentralHome',
      to: '/app/accounts/1/settings/staydesk/central',
    },
    {
      name: 'CentralPessoas',
      to: '/app/accounts/1/settings/staydesk/central/pessoas',
      children: [
        { name: 'Settings Agents', to: '/app/accounts/1/settings/agents/list' },
        {
          name: 'StaydeskAgentRolesSettings',
          permissions: ['staydesk_roles_manage'],
          to: '/app/accounts/1/settings/staydesk/roles',
        },
      ],
    },
  ],
};

describe('destinoDaCentral', () => {
  it('sends the administrator to the Central home even with sections in between', () => {
    const admin = permissions => permissions.includes('administrator');

    expect(destinoDaCentral(central, admin)).toBe(
      '/app/accounts/1/settings/staydesk/central'
    );
  });

  it('opens the Central for an agent whose role unlocks a screen inside a section', () => {
    const agente = permissions => permissions.includes('staydesk_roles_manage');

    expect(destinoDaCentral(central, agente)).toBe(
      '/app/accounts/1/settings/staydesk/central'
    );
  });

  it('hides the link from an agent with nothing unlocked', () => {
    expect(destinoDaCentral(central, () => false)).toBeNull();
  });

  it('keeps a direct destination when the item has one', () => {
    expect(destinoDaCentral({ to: '/x' }, () => false)).toBe('/x');
  });
});

describe('estaNaCentral', () => {
  it('recognizes settings and reports paths', () => {
    expect(estaNaCentral('/app/accounts/1/settings/agents/list')).toBe(true);
    expect(estaNaCentral('/app/accounts/1/reports')).toBe(true);
    expect(estaNaCentral('/app/accounts/1/staydesk/hub')).toBe(false);
  });

  it('recognizes the profile and the settings entry without a trailing slash', () => {
    expect(estaNaCentral('/app/accounts/1/profile/settings')).toBe(true);
    expect(estaNaCentral('/app/accounts/1/settings')).toBe(true);
    expect(estaNaCentral('/app/accounts/1/campaigns/ongoing')).toBe(true);
  });

  it('keeps the attendance screens in the Hub', () => {
    [
      '/app/accounts/1/dashboard',
      '/app/accounts/1/conversations/10',
      '/app/accounts/1/staydesk/views/2',
      '/app/accounts/1/contacts/5',
      '/app/accounts/1/inbox/3',
      '/app/accounts/1/team/6',
    ].forEach(caminho => expect(estaNaCentral(caminho)).toBe(false));
  });
});
