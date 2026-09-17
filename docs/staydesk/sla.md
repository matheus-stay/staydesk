# StayDesk — Motor de SLA

O SLA é configurado, calculado e vigiado dentro do StayDesk. O dashboard só lê.

## Modelo

- **Calendário** (`staydesk_calendars`): fuso, horário por dia da semana e feriados. Com calendário, o prazo só
  corre em horário comercial (`Staydesk::Sla::BusinessTime`); sem calendário, relógio de parede.
- **Política** (`staydesk_sla_policies`): condições no formato do filtro avançado (avaliadas pelo mesmo
  `AutomationRules::ConditionsFilterService` das automações), alvos em minutos por prioridade e métrica
  (`first_response`, `next_response`, `resolution`; prioridade sem valor cai em `default`), calendário,
  status que pausam (`pending`, `snoozed`) e fração de aviso (`warning_ratio`, padrão 0,2). A ordem é a
  prioridade de escolha: a primeira ativa que bate com a conversa vale.
- **SLA aplicado** (`staydesk_applied_slas`): prazos e cumprimentos das três métricas, pausa e o que já venceu.

## Motor (`custom/app/services/staydesk/sla`, `listeners`, `jobs`)

- `Staydesk::SlaListener` (registrado em `Custom::AsyncDispatcher`) reage a conversa criada (aplica a
  política), conversa atualizada em caixa, prioridade, time ou atributos (reavalia), status alterado
  (pausa, retoma, reabre, resolve) e mensagem criada (cumpre primeira resposta, reinicia próxima resposta).
- `Staydesk::Sla::CheckJob` roda a cada minuto (cron registrado em `custom/config/initializers/staydesk_cron.rb`):
  marca `warning` e `breached` uma vez por métrica, grava em `staydesk_conversation_events`
  (`staydesk_sla_warning`, `staydesk_sla_breached`) e publica os eventos.
- A conversa recebe os atributos `sla_alvo`, `sla_status` e `sla_vence_em` a cada mudança: o selo e o
  painel de campos leem daí; webhooks e o dashboard também.
- `Staydesk::SlaAutomationListener` (subclasse de `AutomationRuleListener`, que não tem gancho) faz os
  eventos `staydesk_sla_warning`, `staydesk_sla_breached` e `staydesk_sla_met` dispararem regras de
  automação com as mesmas condições e ações de "conversa atualizada". Os eventos entram na tela de
  automação por dois ganchos em `settings/automation/constants.js`.

## API (`/api/v1/accounts/:account_id/staydesk/`)

| Rota | Quem | O que faz |
|---|---|---|
| `calendars` (CRUD) | leitura para todos, escrita admin | Calendários |
| `sla_policies` (CRUD), `PUT sla_policies/reorder` `{ ids }` | leitura para todos, escrita admin | Políticas e ordem |
| `GET conversations/:display_id/sla` | todos | SLA aplicado com as três métricas (204 sem SLA) |
| `GET applied_slas?since=&until=&status=&after_id=&limit=` | admin ou usuário-serviço | Varredura para o dashboard, por `updated_at`, paginada por id |

## Telas (`app/javascript/staydesk/`)

Configurações › Políticas de SLA (`SlaSettings.vue`, `SlaPolicyForm.vue` com o `ConditionRow` do upstream e a
grade de alvos), Configurações › Calendários (`CalendarsSettings.vue`, `CalendarForm.vue`) e o bloco SLA no
painel de campos (`SlaDetail.vue`).
