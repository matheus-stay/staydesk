import { payloadToRows, rowsToQuery } from '../teamViewQuery';

const filterTypes = [
  {
    attributeKey: 'status',
    inputType: 'multiSelect',
    options: [
      { id: 'open', name: 'Open' },
      { id: 'pending', name: 'Pending' },
    ],
  },
  {
    attributeKey: 'team_id',
    inputType: 'searchSelect',
    options: [{ id: 3, name: 'N1' }],
  },
  { attributeKey: 'created_at', inputType: 'date' },
];

describe('teamViewQuery', () => {
  it('turns a stored payload into editable rows', () => {
    const rows = payloadToRows(
      [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: ['open', 'pending'],
          query_operator: 'and',
        },
        { attribute_key: 'team_id', filter_operator: 'equal_to', values: [3] },
        {
          attribute_key: 'created_at',
          filter_operator: 'is_greater_than',
          values: ['2026-09-01'],
        },
      ],
      filterTypes
    );

    expect(rows[0].values).toEqual([
      { id: 'open', name: 'Open' },
      { id: 'pending', name: 'Pending' },
    ]);
    expect(rows[1]).toMatchObject({
      values: [{ id: 3, name: 'N1' }],
      queryOperator: 'and',
    });
    expect(rows[2].values).toBe('2026-09-01');
  });

  it('turns rows back into the filter payload', () => {
    const rows = payloadToRows(
      [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: ['open'],
          query_operator: 'and',
        },
        { attribute_key: 'team_id', filter_operator: 'equal_to', values: [3] },
      ],
      filterTypes
    );

    expect(rowsToQuery(rows)).toEqual({
      payload: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: ['open'],
          query_operator: 'and',
        },
        {
          attribute_key: 'team_id',
          filter_operator: 'equal_to',
          values: [3],
          query_operator: undefined,
        },
      ],
    });
  });
});
