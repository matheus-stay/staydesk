# StayDesk — API de eventos por conversa

Para o dashboard sincronizar só pela API: primeira resposta, tempo de resposta, resolução e handoff
(os `reporting_events` que a community guarda mas não expõe) e as mudanças de status, responsável, time
e prioridade (gravadas pela camada).

- Tabela `staydesk_conversation_events` (`kind` = `status_changed`, `assignee_changed`, `team_changed`,
  `priority_changed`; `from_value`, `to_value`, `user_id`, `created_at`), preenchida por
  `Custom::Conversation` (`after_update_commit` sobre `saved_changes`). Começa a valer no deploy.
- `GET /api/v1/accounts/:account_id/staydesk/events` (administrador ou usuário-serviço): parâmetros
  `since`, `until`, `conversation_id` (display_id), `kind`, `after_reporting_id`, `after_event_id`,
  `limit` (até 500). Resposta `{ reporting_events: [...], conversation_events: [...] }`, cada lista em
  ordem de id; para varrer, repita com o último id de cada lista.

Contrato em `swagger/staydesk/openapi.yml`.
