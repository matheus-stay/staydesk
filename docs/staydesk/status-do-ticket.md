# Status personalizado do ticket (SPEC-10)

O Chatwoot tem quatro status fixos de conversa: `open`, `pending`, `snoozed` e `resolved`. Tudo no núcleo depende deles (distribuição, SLA, relatórios, filtros). O StayDesk coloca um **catálogo de status** por cima, como no Zendesk, sem tocar nessa coluna.

## Como funciona

- O admin cadastra os status em **Configurações › Status dos tickets** (`Staydesk::TicketStatus`): nome, descrição, cor, ordem, ativo e o **status base** a que corresponde. Um status por base pode ser o **padrão**.
- O status escolhido fica no atributo de conversa `custom_attributes.staydesk_status`. O modelo mantém uma **definição de atributo de lista** (`CustomAttributeDefinition` com chave `staydesk_status`) com os nomes ativos, então filtros avançados, visualizações por time e automações usam o status personalizado sem código novo.
- `Staydesk::TicketStatusService#apply` grava o atributo e o status base numa operação só (`snoozed_until` quando a base é `snoozed`).
- Quando o status base muda por outro caminho (botão do upstream, automação, bot, resolução automática), `Custom::Conversation` chama `align_with_base!` e o atributo passa ao padrão da base nova. Sem padrão cadastrado, o primeiro ativo daquela base; sem nenhum, o atributo é removido.

## API

| Método | Rota | Quem |
|---|---|---|
| `GET` | `/api/v1/accounts/:id/staydesk/ticket_statuses` | qualquer agente |
| `POST` / `PATCH` / `DELETE` | `.../ticket_statuses(/:id)` | administrador |
| `PUT` | `.../ticket_statuses/reorder` `{ ids: [] }` | administrador |
| `POST` | `.../conversations/:display_id/ticket_status` `{ ticket_status_id, snoozed_until? }` | quem pode ver a conversa |

O `POST` na conversa devolve a conversa no formato padrão da API.

## Frontend

- `TicketStatusPicker.vue` substitui o botão Resolver do cabeçalho quando a conta tem catálogo ativo (gancho de uma linha em `MoreActions.vue`). Sem catálogo, o upstream fica como está.
- "Enviar como" (`SubmitAs.vue`) lista os status personalizados quando existem.
- A coluna de status da tabela (`ConversationTable.vue`) mostra o nome personalizado.
- Estado em `store/ticketStatus.js` (Pinia), API em `api/ticketStatuses.js`.

## Limites conhecidos

- Status com base `snoozed` aplicado pelo seletor adia "até a próxima resposta" (sem prazo). Para adiar com prazo, o menu de adiar do upstream continua disponível pelo atalho.
- O status personalizado não entra nos relatórios do Chatwoot, que continuam pelos quatro status base.
