# StayDesk — Visualizações por time

Views compartilhadas: o admin cria uma consulta (a mesma do filtro avançado), escolhe os times que a
enxergam, colunas e ordenação; o agente vê as views dos seus times na barra lateral, com contagem ao vivo.

## Backend (`custom/`)

- Tabela `staydesk_team_views` (migration em `custom/db/migrate`): `name`, `description`, `color`, `icon`,
  `query` (jsonb, `{ payload: [...] }` no formato de `POST /conversations/filter`), `columns` (jsonb),
  `sort_by` (chaves de `Conversations::SortService::SORT_OPTIONS`), `position`, `team_ids` (array;
  vazio = conta inteira), `created_by_id`.
- Modelo `Staydesk::TeamView`; política `Staydesk::TeamViewPolicy` (leitura para todos, escrita para
  administrador); `Staydesk::TeamView.visible_to(user, account)` resolve a visibilidade por time.
- Marcadores resolvidos na hora da consulta (`TeamView#payload`): `me` em `assignee_id` vira quem pede, e a
  linha `staydesk_load_queue` (valores: chaves de canal de trabalho, como `chat` e `ticket`) vira as caixas
  daquele canal, pela mesma regra da distribuição. Caixa criada depois entra sozinha na view certa. No YAML
  da operação, `canais_de_trabalho: [chat]` na visualização gera essa linha; é o jeito preferido de separar
  chat de ticket (`caixas` e `caixas_exceto` congelam os ids da importação).
- API, sob `/api/v1/accounts/:account_id/staydesk/team_views`:

| Rota | Quem | O que faz |
|---|---|---|
| `GET /` | todos | Views visíveis ao usuário, em ordem (admin vê todas) |
| `POST /`, `PATCH /:id`, `DELETE /:id` | admin | Manutenção; corpo em `team_view` |
| `GET /:id/conversations?page=` | todos | Lista da view pelo `Conversations::FilterService`, mesma resposta de `conversations/filter` |
| `GET /counts` | todos | `{ counts: { id: n } }` para as views do usuário; cache de 30 s por usuário |

- Importação em lote: `rails staydesk:team_views:importar ACCOUNT_ID=1 FILE=views.yml`
  (`Staydesk::TeamViewImportService`); o YAML é uma lista de `name`, `description`, `color`, `icon`,
  `sort_by`, `columns`, `teams` (nomes) e `query`. Nome existente atualiza em vez de duplicar.

## Frontend (`app/javascript/staydesk/`)

- `api/teamViews.js`, `store/teamViews.js` (Pinia) e `composables/useTeamViews.js` (carga, contagens a
  cada 60 s, `asFolder`).
- `composables/useStaydeskSidebar.js`: o grupo "Visualizações" na barra de conversas e a entrada em
  Central › Atendimento. `Sidebar.vue` os recebe por spread em dois ganchos de uma linha.
- Rotas `staydesk_view_conversations` e `staydesk_view_conversation` (`/staydesk/views/:id`) reaproveitam a
  `ConversationView` passando `foldersId = staydesk-<id>`. No `ChatList.vue`, um gancho faz a view valer
  como pasta ativa (mesmo fluxo de busca por `conversations/filter`) e outro esconde as ações de pasta
  pessoal (editar, excluir) para ela.
- `pages/TeamViewsSettings.vue` e `components/TeamViewForm.vue`: administração, com as condições montadas
  pelo `ConditionRow` do upstream (composição) e o mesmo gerador de consulta das pastas.

## Limites conhecidos

- A ordenação da view (`sort_by`) é aplicada pela API da view (`team_views/:id/conversations`); na tela,
  que busca pelo mesmo fluxo das pastas, vale a ordenação escolhida pelo usuário na lista.
- A lista em tabela da SPEC-04 já existe (`ConversationTable.vue`), mas as colunas dela vêm da
  [área de trabalho](area-de-trabalho.md), por time e por papel. O `columns` da view fica guardado e
  volta na API, sem uso na tela.
