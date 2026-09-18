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

// "O próprio agente" nas condições de responsável: é o que faz uma visualização
// compartilhada mostrar só o que é de quem está olhando, como no Zendesk. O valor
// `me` é trocado no servidor pelo id de quem pede.
export const CURRENT_AGENT_VALUE = 'me';
const USER_ATTRIBUTES = ['assignee_id', 'created_by_id'];

export const withCurrentAgentOption = (filterTypes, label) =>
  (filterTypes || []).map(type => {
    if (!USER_ATTRIBUTES.includes(type.attributeKey)) return type;
    if ((type.options || []).some(option => option.id === CURRENT_AGENT_VALUE))
      return type;
    return {
      ...type,
      options: [
        { id: CURRENT_AGENT_VALUE, name: label },
        ...(type.options || []),
      ],
    };
  });

// A lista de conversas manda o filtro da visualização direto para o servidor, que
// não conhece o marcador. Aqui ele vira o id de quem está olhando, antes de sair.
export const resolveCurrentAgent = (payload, userId) =>
  (payload || []).map(row => {
    if (!USER_ATTRIBUTES.includes(row.attribute_key)) return row;
    const values = (row.values || []).map(value =>
      String(value) === CURRENT_AGENT_VALUE ? userId : value
    );
    return { ...row, values };
  });
