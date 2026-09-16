# StayDesk — Papel de agente leve

Um agente leve lê as conversas dos seus times e caixas de entrada e só escreve nota interna. Não envia
mensagem pública, não muda status, responsável, time, prioridade, etiquetas nem atributos, e não acessa
configurações nem relatórios.

## Como funciona

- Tabela `staydesk_account_user_roles` (`account_user_id`, `kind` = `full` ou `light`), modelo
  `Staydesk::AccountUserRole`. Administração em Configurações › Papéis dos agentes
  (`GET/PUT /staydesk/agent_roles/:user_id`, administrador).
- `Custom::AccountUser` (gancho `prepend_mod_with('AccountUser')`): `staydesk_light?` e
  `permissions` com `staydesk_light` a mais. O front recebe isso no payload do usuário.
- `Custom::Message` (gancho em `Message`): validação na criação; autor leve só cria `private: true`.
- `Custom::Concerns::ApplicationControllerConcern` (gancho em `ApplicationController`): guarda central.
  Requisição de escrita de um leve só passa na lista `LIGHT_WRITE_ALLOWLIST` (mensagem privada, marcar
  como lida, digitando, notificações, pastas pessoais, perfil). O resto responde 403.
- `Staydesk::WorkspaceResolver` devolve `role: light`, então a sobreposição `roles.light` da área de
  trabalho vale para ele e o "Enviar como" some.

A API é a barreira de verdade; a interface só evita o erro. O leve ainda vê os botões de status e
responsável do upstream; a chamada volta 403.
