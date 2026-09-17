# StayDesk — Status personalizado do agente

O agente escolhe no menu de disponibilidade o que atende agora (tudo, só chat, só tickets, ausente).
A distribuição automática respeita o status e o dashboard soma o tempo em cada um.

- `staydesk_agent_statuses`: catálogo da conta (nome, cor, `availability` = `online` ou `busy`, `inbox_ids`
  que o status atende; vazio = todas). Configurações › Status dos agentes.
- `staydesk_agent_status_periods`: início e fim de cada status por agente; o atual é o sem `ended_at`.
- `Staydesk::AgentStatusService#change_to`: fecha o período aberto, abre o novo e alinha a disponibilidade
  do Chatwoot (`online` ou `busy`).
- `Custom::InboxAgentAvailability#available_agents` (gancho em `InboxAgentAvailability`): a distribuição
  automática pula quem está num status que não atende a caixa.
- API: `agent_statuses` (CRUD, escrita admin; `GET` devolve também `current_status_id`),
  `POST agent_status_periods { agent_status_id }` (o agente troca o próprio status),
  `GET agent_status_periods?since=&until=&user_id=&after_id=&limit=` (dashboard, admin).
- Front: `useAgentStatus` substitui a lista fixa do `SidebarProfileMenuStatus.vue` quando a conta tem status
  (dois ganchos: lista e troca); página `AgentStatusesSettings.vue`.

## Carga de atendimento simultâneo (SPEC-11)

O Chatwoot community não limita quantas conversas a distribuição automática entrega a um agente: o limite por caixa de entrada é recurso Enterprise. Aqui o limite mora no status do agente, separado por fila.

- **Filas**: conversas de caixas de e-mail contam como `ticket`; todas as demais como `chat`. As duas contam separado, como no roteamento omnicanal do Zendesk.
- **Limite**: cada status guarda `capacity`, por exemplo `{"chat": 4, "ticket": 12}`. Em branco é sem limite; `0` tira o agente daquela fila.
- **Carga**: conta as conversas atribuídas ao agente com status base **aberto**, em todas as caixas daquela fila. O que está esperando o cliente (pendente, adiado) ou resolvido não ocupa vaga.
- **Onde entra**: `Custom::Inbox#member_ids_with_assignment_capacity` (distribuição legada, a padrão) e `Custom::InboxAgentAvailability#available_agents` (distribuição nova, atrás do recurso `assignment_v2`). Os dois usam `Staydesk::AgentLoadService`, e os dois já eram ganchos do upstream: nenhum toque novo no núcleo.
- **Limite conhecido**: vale só para a distribuição automática. Atribuição manual por um administrador não é bloqueada.

O painel **Carga agora**, no fim da página de status, mostra cada agente com o status atual e a carga contra o limite nas duas filas. API: `GET staydesk/agent_loads` (administrador).
