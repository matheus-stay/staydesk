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
