# StayDesk — Área de trabalho do agente por time

O que cada time enxerga na área do agente (menu, lista, campos do ticket, seções laterais, apps, macros
e caixa de resposta) é configuração, resolvida por usuário. O padrão do produto vale para todos; o
admin sobrepõe por conta e por time.

## Backend (`custom/`)

- Tabela `staydesk_team_workspaces`: `team_id` (nulo = padrão da conta) e `config` (jsonb), validado
  contra `custom/config/schemas/team_workspace.json` com `json_schemer`.
- `Staydesk::WorkspaceResolver`: padrão do produto → padrão da conta → times do usuário (listas em
  união, ordem do primeiro time; escalares do último) → sobreposição por papel (`roles.<papel>`).
  Devolve também `role` e `team_ids`.
- API sob `/api/v1/accounts/:account_id/staydesk/`:

| Rota | Quem | O que faz |
|---|---|---|
| `GET workspace` | todos | A configuração resolvida para quem chama |
| `GET team_workspaces`, `GET/PUT team_workspaces/:team_id` | admin | Manutenção; `default` para o padrão da conta; corpo `{ config }` |
| `GET team_workspaces/schema` | admin | O JSON Schema, para a tela validar |

## Frontend (`app/javascript/staydesk/`)

- `store/workspace.js` e `composables/useWorkspace.js`: até a resposta chegar, nada é escondido.
- `components/ConversationTable.vue`: a lista em tabela, com as colunas da configuração, SLA pela
  `SlaBadge`, clique abre a conversa. Entra no `ChatList.vue` por dois ganchos (`v-if` na lista de
  cartões e a montagem da tabela).
- `components/TicketFieldsPanel.vue`: painel de propriedades com responsável, time e prioridade
  (bloco do upstream) e os atributos personalizados na ordem de `conversation.fields`, editáveis pelo
  `CustomAttribute` do upstream; no cabeçalho, o selo de SLA e o "Avançar".
- `components/SubmitAs.vue`: "Enviar como <status>", montado abaixo da caixa de resposta por um gancho
  no `ReplyBox.vue`; depois de enviar, fica, abre a próxima (`useNextConversation`) ou volta à lista,
  conforme `composer.after_send`.
- `pages/WorkspaceSettings.vue`: administração por time. Listas vazias herdam; sobreposição por papel
  só pela API por enquanto.
- Ganchos de uma linha: `Sidebar.vue` (menu principal e "mais"), `ContactPanel.vue` (seções),
  `ConversationBox.vue` (Dashboard Apps), `Macros/List.vue` (`v-show` por macro), `ReplyBox.vue`
  (montagem do Enviar como), `ChatList.vue` (tabela).

## Limites conhecidos

- A ordem dos campos e das seções é a ordem canônica marcada na tela; reordenar livremente fica
  para uma próxima iteração (o esquema já aceita a ordem).
- A tabela carrega mais linhas por botão, não por rolagem infinita.
