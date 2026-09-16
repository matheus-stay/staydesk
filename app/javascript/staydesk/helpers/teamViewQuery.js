import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';

// As mesmas colunas aceitas por Staydesk::TeamView no backend.
export const TEAM_VIEW_COLUMNS = [
  'sla',
  'status',
  'subject',
  'contact',
  'inbox',
  'created_at',
  'waiting_since',
  'assignee',
  'team',
  'priority',
  'labels',
];

export const DEFAULT_COLUMNS = [
  'sla',
  'status',
  'subject',
  'contact',
  'waiting_since',
  'assignee',
];

const SELECT_INPUTS = ['multiSelect', 'searchSelect', 'asyncSearchSelect'];

export const newConditionRow = () => ({
  attributeKey: 'status',
  filterOperator: 'equal_to',
  values: [],
  queryOperator: 'and',
});

const optionFor = (type, value) =>
  type?.options?.find(option => String(option.id) === String(value)) || {
    id: value,
    name: String(value),
  };

// query.payload guardado (snake_case, valores crus) -> linhas do ConditionRow
// (camelCase, selects com objetos { id, name }).
export const payloadToRows = (payload = [], filterTypes = []) =>
  payload.map(item => {
    const type = filterTypes.find(
      filterType => filterType.attributeKey === item.attribute_key
    );
    const values = Array.isArray(item.values) ? item.values : [item.values];
    return {
      attributeKey: item.attribute_key,
      filterOperator: item.filter_operator,
      queryOperator: item.query_operator || 'and',
      customAttributeType: item.custom_attribute_type,
      values: SELECT_INPUTS.includes(type?.inputType)
        ? values.map(value => optionFor(type, value))
        : (values[0] ?? ''),
    };
  });

// Linhas do ConditionRow -> { payload } no formato de POST /conversations/filter,
// pelo mesmo gerador que as pastas usam.
export const rowsToQuery = rows =>
  filterQueryGenerator(useSnakeCase(JSON.parse(JSON.stringify(rows))));
