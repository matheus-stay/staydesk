import {
  withCurrentAgentOption,
  resolveCurrentAgent,
  CURRENT_AGENT_VALUE,
} from '../teamViewQuery';

describe('withCurrentAgentOption', () => {
  const tipos = [
    {
      attributeKey: 'assignee_id',
      options: [{ id: 7, name: 'Ana' }],
    },
    { attributeKey: 'status', options: [{ id: 'open', name: 'Aberta' }] },
  ];

  it('offers the agent themselves as the first value of the assignee field', () => {
    const [responsavel] = withCurrentAgentOption(tipos, 'O próprio agente');

    expect(responsavel.options[0]).toEqual({
      id: CURRENT_AGENT_VALUE,
      name: 'O próprio agente',
    });
    expect(responsavel.options).toHaveLength(2);
  });

  it('leaves the other fields untouched', () => {
    const [, status] = withCurrentAgentOption(tipos, 'O próprio agente');

    expect(status.options).toEqual([{ id: 'open', name: 'Aberta' }]);
  });

  it('does not add it twice', () => {
    const uma = withCurrentAgentOption(tipos, 'O próprio agente');
    const duas = withCurrentAgentOption(uma, 'O próprio agente');

    expect(duas[0].options).toHaveLength(2);
  });
});

describe('resolveCurrentAgent', () => {
  it('turns the marker into the id of whoever is looking', () => {
    const payload = [
      { attribute_key: 'assignee_id', values: ['me'] },
      { attribute_key: 'status', values: ['open'] },
    ];

    const resolvido = resolveCurrentAgent(payload, 7);

    expect(resolvido[0].values).toEqual([7]);
    expect(resolvido[1].values).toEqual(['open']);
  });

  it('leaves a real agent id alone', () => {
    const payload = [{ attribute_key: 'assignee_id', values: [12] }];

    expect(resolveCurrentAgent(payload, 7)[0].values).toEqual([12]);
  });
});
