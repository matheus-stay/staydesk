# Status personalizado do ticket (SPEC-10)

O Chatwoot tem quatro status fixos de conversa: `open`, `pending`, `snoozed` e `resolved`. Tudo no núcleo depende deles (distribuição, SLA, relatórios, filtros). O StayDesk coloca um **catálogo de status** por cima, como no Zendesk, sem tocar nessa coluna.

## Como funciona

- O admin cadastra os status em **Central › Atendimento › Status do ticket** (`Staydesk::TicketStatus`): nome, descrição, cor, ordem, ativo e o **status base** a que corresponde. Um status por base pode ser o **padrão**.
- O status escolhido fica no atributo de conversa `custom_attributes.staydesk_status`. O modelo mantém uma **definição de atributo de lista** (`CustomAttributeDefinition` com chave `staydesk_status`) com os nomes ativos, então filtros avançados, visualizações por time e automações usam o status personalizado sem código novo.
- `Staydesk::TicketStatusService#apply` grava o atributo e o status base numa operação só (`snoozed_until` quando a base é `snoozed`).
- A conversa **nasce com o status padrão da base** (`Custom::Conversation#staydesk_status_inicial`), como o "Novo" do Zendesk. Sem isso o caso recém-chegado ficava sem status e sumia da visualização que filtra por ele.
- O status marcado **assume ao atribuir** (`apply_on_assign`) entra sozinho quando alguém pega a conversa (`TicketStatusService#follow_assignment!`); na fila com aceite, no aceite, que é quando a conversa vira do agente.
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

- `TicketStatusPicker.vue` substitui o botão Resolver do cabeçalho quando a conta tem catálogo ativo (gancho de uma linha em `MoreActions.vue`). Sem catálogo, o upstream fica como está. Status que resolve, com campo obrigatório vazio, abre a janela que pede os campos (ver [campos-do-ticket.md](campos-do-ticket.md)); se o servidor recusar, o aviso mostra a mensagem dele.
- "Enviar como" (`SubmitAs.vue`) lista os status personalizados quando existem. Sem texto na caixa, só muda o status: dá para resolver sem escrever, como no Zendesk. A seta de escolher o status fica sempre disponível; só o editor travado desliga.
- A coluna de status da tabela (`ConversationTable.vue`) mostra o nome personalizado.
- Estado em `store/ticketStatus.js` (Pinia), API em `api/ticketStatuses.js`.

## Limites conhecidos

- Status com base `snoozed` aplicado pelo seletor adia "até a próxima resposta" (sem prazo). Para adiar com prazo, o menu de adiar do upstream continua disponível pelo atalho.
- O status personalizado não entra nos relatórios do Chatwoot, que continuam pelos quatro status base.
