# StayDesk × Chatwoot — o que é diferente e por quê

Este documento é o mapa para quem mantém o StayDesk: **de qual Chatwoot ele parte,
tudo o que a camada StayDesk sobrescreve ou acrescenta, e o que quebra se o
Chatwoot mudar**. É a leitura obrigatória antes de puxar qualquer atualização do
upstream; o passo a passo da atualização está em
[atualizar-do-chatwoot.md](atualizar-do-chatwoot.md).

> Levantado em 2026-10-19 a partir do repositório (ramo `staydesk-revisado`,
> commit `39a9507`). Os números de atraso em relação ao upstream valem para o
> último `git fetch upstream` (~2026-09-24); refazer a conta antes de decidir.
> Ao mudar a camada (novo `Custom::`, novo toque no núcleo, nova migration),
> atualize a tabela correspondente aqui e em [core-touches.md](core-touches.md).

Como a camada entra em linhas gerais: [camada-staydesk.md](camada-staydesk.md).
Registro de cada arquivo do núcleo tocado: [core-touches.md](core-touches.md).

---

## 1. Base exata do upstream

| Item | Valor |
|---|---|
| `git merge-base staydesk-revisado develop` | `e16d8f2fa4bd00c65747de0b8363f0e05092e36c` |
| Commit da base | 2026-09-16 06:52 -0700 — `fix(voice): answer WhatsApp calls from the conversation when the call is not in the store (#15795)` |
| Versão na base | `package.json` e `config/app.yml` = **4.17.1** (develop pós-4.17.1, pré-4.18.0; `git describe` = `v4.11.2-925-ge16d8f2fa4`, não há tag exata) |
| `develop` local = `origin/develop` | ambos em `e16d8f2` (espelho parado na base) |
| `upstream/develop` (último fetch) | `cdfaa25`, 2026-09-23, versão **4.18.0** |
| Atraso `develop..upstream/develop` | **54 commits** (1.543 arquivos, +47.481/−6.205) — e isso só até o último fetch; o upstream real deve estar ~4 semanas mais à frente |
| Última release | `v4.18.0` (= `upstream/master` `9f920b5`, 2026-09-17). A base está contida nela; 31 commits entre base e tag; 38 commits em develop depois da tag |
| Ramo de trabalho | 79 commits à frente de `develop`, 0 atrás. 668 arquivos, +39.542/−395 |
| Versão própria | `custom/VERSION` = 0.1.0 |

### Correções de segurança do upstream que o StayDesk ainda NÃO tem

| Commit | O quê | Onde está |
|---|---|---|
| `4218dc6793` | sanitização XSS em HTML/markdown (`HTMLSanitizer.js`, `base_markdown_renderer.rb`, `markdown_renderer_url_sanitizer.rb`) (#14050) | **v4.18.0** |
| `778fc6fa37` | escape de rótulos de menção e do painel de diff de artigo (#15965) | só develop |
| `7b3c928bf1` | rate-limit de autenticação lendo corpo JSON (`rack_attack.rb`) (#15939) | só develop |
| `8aa1fafe20` | token de API aceito como `Authorization: Bearer` (`access_token_auth_helper.rb`, `api/base_controller.rb`, `rack_attack.rb`) (#15941) | só develop |
| `910f5e2f49` | verificação de dispositivo no login (cloud/enterprise; quase tudo em `enterprise/`) (#15879) | só develop |

Ou seja: **já existe pendência de segurança hoje**, mesmo sem novo fetch.

### Simulação de merge (em memória, `git merge-tree`)

- `staydesk-revisado` + `v4.18.0` → **4 conflitos**: `SidebarCollapsedPopover.vue`, `SidebarGroup.vue`, `SidebarGroupHeader.vue`, `ChatListHeader.vue`.
- `staydesk-revisado` + `upstream/develop` → **8 conflitos**: os 4 acima + `MessagesView.vue`, `ReplyBox.vue`, `ConversationView.vue`, `db/schema.rb`.

Todos os conflitos estão em arquivos `legado` ou no `schema.rb`. Nenhum arquivo `gancho` de backend conflita.

---


---

## 2. Inventário das diferenças, por mecanismo

### Como a camada entra

- `config/application.rb` (+3 linhas, depois dos initializers do enterprise): `require_relative '../custom/config/boot'` e `StaydeskBoot.configure(config)`.
- `custom/config/boot.rb`:
  - **Prepend em `ChatwootApp.extensions`**: o núcleo devolve `%w[enterprise custom]` só porque `custom/` existe; a camada faz devolver `%w[custom]` quando `ChatwootApp.enterprise?` é falso. É isso que faz `prepend_mod_with` procurar `Custom::X` e NÃO `Enterprise::X`.
  - Autoload de `custom/lib` e `custom/app/*`; `custom/app/views` na frente de todos os caminhos de view; remove `enterprise/app/views` dos caminhos quando não é enterprise.
  - Rotas (`custom/config/routes.rb`, tudo sob `/api/v1/accounts/:id/staydesk/`), migrations (`custom/db/migrate`), rake (`custom/lib/tasks`), locales (`custom/config/locales`, depois dos do núcleo, para vencer), initializers de `custom/config/initializers`.
  - Observação: `config/application.rb` do núcleo continua dando `require` em `enterprise/config/initializers/*` (hoje só `omniauth_saml.rb`) antes do boot, mesmo com `DISABLE_ENTERPRISE`.

### (a) Módulos `Custom::` — o que sobrescrevem e o que muda

Ponto de gancho: "nativo" = `prepend_mod_with`/`include_mod_with` já existe no upstream; "gancho próprio" = a linha foi acrescentada pelo StayDesk no arquivo do núcleo (registrada como `gancho` em `core-touches.md`).

| Módulo (arquivo em `custom/app/...`) | Classe/método do upstream | Gancho | Mudança de comportamento |
|---|---|---|---|
| `models/custom/inbox.rb` | `Inbox#add_members` | nativo | Ignora quem já é membro (não falha ao reenviar a lista inteira) |
| idem | `Inbox#auto_assignment_v2_enabled?` | nativo | **Forçado `false`**: toda caixa usa a distribuição legada (síncrona), mesmo com a flag `assignment_v2` ligada. A v2 do upstream fica morta |
| idem | `Inbox#member_ids_with_assignment_capacity` | nativo | Interseção com quem está **online agora** (`OnlineStatusTracker`) e depois filtro de capacidade (`Staydesk::AgentLoadService#with_capacity`) |
| `models/custom/inbox_agent_availability.rb` | `InboxAgentAvailability#available_agents` | nativo | Remove quem está num status de agente que não atende esta caixa (SPEC-09) e quem bateu o limite de conversas simultâneas (SPEC-11) |
| `models/custom/conversation.rb` | `Conversation` (callbacks) + `AutoAssignmentHandler#team_member_ids_with_capacity` | nativo | Ver detalhe abaixo |
| `models/custom/account_user.rb` | `AccountUser#permissions` (+ `has_one :staydesk_role`) | nativo | Soma as permissões do papel StayDesk ao payload; adiciona `staydesk_light?`, `staydesk_can?` |
| `models/custom/message.rb` | `Message` (validação nova) | nativo | Agente "leve" só cria nota privada (validação `on: :create`) |
| `models/custom/macro.rb` | `Macro#json_actions_format` (privado) | **gancho próprio** em `app/models/macro.rb` | Aceita `staydesk_set_attribute` e `staydesk_set_ticket_status` além das ações do produto. Reescreve a validação inteira (não chama `super`) |
| `models/custom/automation_rule.rb` | `AutomationRule#actions_attributes` | nativo | Soma as duas ações acima + `staydesk_aviso_de_recebimento` |
| `models/custom/team.rb` | `Team#name=`, `run_validations!` + validação | **gancho próprio** em `app/models/team.rb` | Nome do grupo preservado como digitado (o produto força minúsculas); unicidade passa a ignorar caixa |
| `services/custom/action_service.rb` | `ActionService` (include) | nativo | Novas ações `staydesk_set_attribute` (grava/limpa custom attribute) e `staydesk_set_ticket_status` (aplica status do catálogo e alinha o status base) — valem para macro e automação |
| `services/custom/automation_rules/action_service.rb` | `AutomationRules::ActionService` | **gancho próprio** | Ação `staydesk_aviso_de_recebimento`: cria mensagem de saída marcada `staydesk_aviso: 'recebimento'` (o e-mail vira cartão do chamado) |
| `services/custom/auto_assignment/agent_assignment_service.rb` | `AutoAssignment::AgentAssignmentService#find_assignee`, `#perform` | **gancho próprio** em `app/services/auto_assignment/agent_assignment_service.rb` | Fila com aceite (SPEC-16): em vez de atribuir, guarda o escolhido em `conversation.staydesk_convidar` e devolve `nil`; `perform` lança o convite (`Staydesk::OfferService`). Conversa com convite pendente não é redistribuída |
| `services/custom/auto_assignment/assignment_service.rb` | `AutoAssignment::AssignmentService#assign_conversation`, `#filter_agents_by_team` | nativo | Caminho v2 (hoje inativo por causa do `false` acima): convida em vez de atribuir e aplica transbordo da fila. Código mantido mas não exercitado em produção |
| `controllers/custom/api/v1/accounts/assignable_agents_controller.rb` | `AssignableAgentsController#index` | nativo | Lista de "atribuíveis" vira **todos os usuários da conta** (upstream: interseção dos membros das caixas + admins). Permite transferir para fora da fila |
| `controllers/custom/api/v1/accounts/custom_attribute_definitions_controller.rb` | `#permitted_payload` (privado) | **gancho próprio** | Permite `staydesk_required_to_resolve`. Reescreve a lista de permit inteira (se o upstream acrescentar campo, ele some aqui) |
| `controllers/custom/access_token_auth_helper.rb` | `AccessTokenAuthHelper#ensure_access_token`, `#authenticate_access_token!` | **gancho próprio** | Aceita token de API StayDesk (`Staydesk::ApiToken`) com escopos; age como um usuário da conta, guarda escopo por `controller_path`+método |
| `controllers/custom/concerns/application_controller_concern.rb` | `ApplicationController` (include) | nativo | Dois `before_action` globais: agente leve só lê + nota privada (allowlist); papel "só meus números" só pede relatório de si mesmo |
| `policies/custom/account_policy.rb` | `AccountPolicy#update?`, `#show?` | nativo | Permissão `staydesk_settings_manage` abre configurações da conta sem ser admin |
| `policies/custom/report_policy.rb` | `ReportPolicy#view?` | nativo | `report_manage` ou `staydesk_report_own` abre relatórios |
| `dispatchers/custom/async_dispatcher.rb` | `AsyncDispatcher#listeners` | nativo | Soma `Staydesk::SlaListener` e `SlaAutomationListener`; inscrição única |
| `dispatchers/custom/sync_dispatcher.rb` | `SyncDispatcher` | nativo | Só a inscrição única (`Staydesk::InscricaoUnica`) |
| `listeners/custom/csat_survey_listener.rb` | `CsatSurveyListener#conversation_status_changed` | **gancho próprio** | Pesquisa de satisfação sai por job com atraso configurável por canal (padrão 5 min) em vez de imediata. Não chama `super` |
| `mailers/custom/conversation_reply_mailer.rb` | `ConversationReplyMailer#choose_layout`, `#prepare_mail` (do helper) | **gancho próprio** | Layout `mailer/staydesk`, assinatura de quem respondeu, logo por URL absoluta, idioma da conta |
| `jobs/custom/internal/check_new_versions_job.rb` | `Internal::CheckNewVersionsJob#perform` | nativo | Com `DISABLE_TELEMETRY` definido, não liga para `hub.2.chatwoot.com` |

**Detalhe — `Custom::Conversation` (o módulo mais acoplado):**
- `before_create :staydesk_route_to_queue_inline` — define o time pela fila antes do INSERT (para a distribuição do produto, que roda no mesmo save, já enxergar o time).
- `before_create :staydesk_status_inicial` — grava o status de ticket inicial em `custom_attributes`.
- `before_save :staydesk_assunto_unico` — copia `assunto` para `additional_attributes.mail_subject`.
- `validate :staydesk_required_ticket_fields` — bloqueia resolver (só usuário humano) sem os campos obrigatórios.
- `after_create_commit :staydesk_route_to_queue` e `:staydesk_lancar_convite!` (ordem inversa importa).
- `after_update_commit :staydesk_after_update` — despacho único: dá acesso ao canal a quem recebe a conversa (cria `inbox_members` na hora!), move a conversa para o time do responsável, status ao atribuir, eventos (`staydesk_conversation_events`), alinha status do ticket, lança convite.
- `team_member_ids_with_capacity` — transbordo da fila (`Staydesk::QueueOverflow`).
- Depende de: ordem de callbacks do Rails, `saved_changes`, `AutoAssignmentHandler`, `Conversation#team`, `inbox.inbox_members`.

**Uso direto de internals do núcleo pela camada (sem override, mas quebra se mudar):**
`OnlineStatusTracker` (8 usos), `Redis::Alfred::ROUND_ROBIN_AGENTS` (`staydesk/distribution_trace.rb`), `AutomationRules::ConditionsFilterService` com um "shim" de regra (`staydesk/queue_router.rb`, `staydesk/sla/policy_matcher.rb`), `Conversations::FilterService` (`team_views_controller.rb`), `Conversations::SortService::SORT_OPTIONS` (`staydesk/team_view.rb`), `AutoAssignment::AgentAssignmentService.new(...).perform` (`offer_service.rb`, `queues/sweep_job.rb`), `Rails.configuration.dispatcher.dispatch` (`sla/check_job.rb`), `Administrate::ApplicationHelper` (initializer).

### (b) Arquivos do upstream editados no lugar

Total fora de `custom/`, `app/javascript/staydesk/`, `docs/staydesk/`, `spec/staydesk/`: **~165 arquivos**, dos quais ~60 são binários/JSON de marca em `public/` e o resto código.

**Gate hoje:** `node custom/bin/staydesk-gate.mjs` → `ok contra develop (e16d8f2fa4); 72 arquivo(s) legado(s) a migrar`. Nenhum arquivo de código sem registro.

| Grupo | Arquivos | Tipo | Registrado? |
|---|---|---|---|
| Montagem backend | `config/application.rb` | montagem | sim |
| Montagem front | `vite.shared.ts`, `entrypoints/dashboard.js`, `widget.js`, `survey.js`, `dashboard/routes/index.js` | montagem | sim |
| Ganchos Ruby (1 linha `prepend_mod_with` ao fim do arquivo) | `app/models/macro.rb`, `app/models/team.rb`, `app/services/auto_assignment/agent_assignment_service.rb`, `app/services/automation_rules/action_service.rb`, `app/listeners/csat_survey_listener.rb`, `app/mailers/conversation_reply_mailer.rb`, `app/controllers/concerns/access_token_auth_helper.rb`, `app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb` | gancho | sim |
| Gancho Ruby (2 linhas) | `lib/current.rb` (`thread_mattr_accessor :staydesk_api_token` + reset) | gancho | sim |
| Ganchos Vue/JS | `App.vue` (cartão de convite), `MoreActions.vue` (seletor de status no lugar de Resolver), `useConversationRequiredAttributes.js` (campos obrigatórios mesmo sem a feature paga), `settings/automation/constants.js` (eventos de SLA), `settings/inbox/Settings.vue` (some a aba Colaboradores), `Macros/List.vue`, `SidebarProfileMenuStatus.vue`, `ContactInfo.vue`, `provider.js`, `survey/views/Response.vue`, `tailwind.config.js` | gancho | sim |
| Formulário de atributo | `settings/attributes/AddAttribute.vue`, `EditAttribute.vue` | montagem | sim |
| Legado do ramo de UX | 72 arquivos (Contacts, Companies, Conversation cards, message bubbles, sidebar, ChatList/ChatListHeader/ConversationList, ReplyBox, MessagesView, ConversationBox/Header/Sidebar, reports, `globalConfig.js`, `i18n/locale/en/chatlist.json`, 4 specs novos em pasta do upstream) | legado | sim, **não checados** |
| Tokens/marca | `theme/colors.js`, `public/brand-assets/*`, `public/fonts/geist/*`, ícones/manifesto em `public/` | — | ignorados pelo gate por regra (`OWN_PATHS`) |
| Esquema | `db/schema.rb` | — | ignorado pelo gate por regra |
| CI | `.github/workflows/staydesk_gate.yml`, `staydesk_image.yml` | — | ignorados por regra |
| API | `swagger/staydesk/openapi.json` | — | próprio |

**Achados sobre o registro e o gate**

1. **Gate engolido por entrada duplicada.** O gate monta um `Map` caminho→tipo e a última linha vence. `Sidebar.vue`, `SidebarGroup.vue`, `SidebarSubGroup.vue` e `ContactPanel.vue` aparecem como `gancho`/`montagem`/`classe` e de novo como `legado` na tabela final → na prática **não são checados**. Sidebar.vue tem 8 registros diferentes.
2. **Overlays de e-mail fora do registro e fora do alcance do gate.** `custom/app/views/conversation_reply_mailer/email_reply.html.erb` e `reply_without_summary.html.erb` substituem `app/views/mailers/conversation_reply_mailer/*.html.erb` do upstream (o mailer acrescenta `app/views/mailers` ao fim dos caminhos e `custom/app/views` vem primeiro). São **cópias reescritas** — inclusive com `.html_safe` sobre conteúdo da mensagem. Se o upstream corrigir escape/XSS nesses templates, a correção **não chega** ao StayDesk. Não estão em `core-touches.md` (o gate só olha o original, que não muda).
3. **Legados que deveriam migrar primeiro** (conflitam já no próximo sync ou carregam ganchos escondidos): `SidebarCollapsedPopover.vue`, `SidebarGroup.vue`, `SidebarGroupHeader.vue`, `ChatListHeader.vue` (conflitam com v4.18.0); `ReplyBox.vue`, `MessagesView.vue`, `ConversationView.vue` (conflitam com develop); `ChatList.vue`, `ConversationBox.vue`, `ContactPanel.vue`, `Sidebar.vue` (têm linhas `staydesk:hook` dentro de arquivo legado — o gancho fica invisível ao gate). Também `i18n/locale/en/chatlist.json` (JSON do upstream editado; deveria ir para as sobreposições de `app/javascript/staydesk/i18n/overrides`).
4. **`db/schema.rb` com cabeçalho `Schema[7.2]`** (Rails do Gemfile é 7.2.3.1), enquanto o upstream ainda grava `Schema[7.1]`: conflito garantido na linha 13 a cada sync, além da linha `version:`.

### (c) Views sobrepostas (`custom/app/views`)

| Overlay | Original do upstream | Registrado? |
|---|---|---|
| `super_admin/devise/sessions/new.html.erb` | `app/views/super_admin/devise/sessions/new.html.erb` | sim (view) |
| `super_admin/application/_navigation.html.erb` | idem | sim |
| `installation/onboarding/index.html.erb` | idem | sim |
| `mailers/administrator_notifications/account_compliance_mailer/account_deleted.liquid` | idem | sim |
| `mailers/administrator_notifications/account_notification_mailer/account_deletion_user_initiated.liquid` | idem | sim |
| `mailers/administrator_notifications/account_notification_mailer/account_deletion_for_inactivity.liquid` | idem | sim |
| `api/v1/models/_custom_attribute_definition.json.jbuilder` | idem (acrescenta `staydesk_required_to_resolve`) | sim |
| `conversation_reply_mailer/email_reply.html.erb` | `app/views/mailers/conversation_reply_mailer/email_reply.html.erb` | **não** |
| `conversation_reply_mailer/reply_without_summary.html.erb` | `app/views/mailers/conversation_reply_mailer/reply_without_summary.html.erb` | **não** |

Novos (sem original): `layouts/mailer/staydesk.html.erb`, `conversation_reply_mailer/_staydesk_csat.html.erb`, `_staydesk_recebimento.html.erb`, 13 partials `api/v1/models/_staydesk_*.json.jbuilder`, todas as views de `api/v1/accounts/staydesk/**`.

Atenção: `EmailTemplate.resolver` (templates do banco) é `prepend_view_path` no `ApplicationMailer` e continua vencendo os overlays.

### (d) Migrations (`custom/db/migrate`, 34 arquivos, 2026-09-16 a 2026-09-18)

Tabelas criadas (todas `staydesk_`): `account_user_roles`, `agent_statuses`, `agent_status_periods`, `api_tokens`, `applied_slas`, `calendars`, `capacity_rules`, `conversation_events`, `impersonations`, `load_queues`, `offers`, `queues`, `roles`, `sla_policies`, `team_views`, `team_workspaces`, `ticket_statuses`.

Mexem em tabela do upstream (contrariam a regra "migration só cria" do `custom/README.md`):
- `20260918100000_add_staydesk_required_to_resolve_to_custom_attribute_definitions.rb` — `add_column :custom_attribute_definitions, :staydesk_required_to_resolve, :boolean, default: false, null: false`. Coluna prefixada, baixo risco de colisão, mas se o upstream recriar/renomear a tabela o conflito é nosso.
- `20260918700000_everyone_serves_every_channel.rb` — **migration de dados** em `inbox_members`: insere todo `account_user` em toda `inbox` da conta. `down` vazio (irreversível). Rodou uma vez; em instalação nova roda de novo sobre base vazia (inócua).

Ordem de versões: o upstream já tem `20260917000000_add_device_trust_version_to_users` intercalado com as nossas (`20260917100000…`). Não colide, mas `schema.rb` muda nas duas pontas.


### Regras que mudaram depois desta migration

- `20260918700000_everyone_serves_every_channel.rb` punha todo agente em todo
  canal. A regra saiu em 2026-10-19: os membros de cada canal agora são
  calculados das filas por `Staydesk::QueueMembership` (a cada minuto, ao salvar
  fila e na importação). A migration fica no histórico; em instalação nova ela
  roda sobre base vazia e a sincronização das filas acerta os membros depois.

### (e) Initializers e cron (`custom/config/initializers`)

| Arquivo | O que faz | Acoplamento |
|---|---|---|
| `audited.rb` | `after_initialize`: `Audited.config.audit_class = 'Audited::Audit'` (o núcleo aponta para `Enterprise::AuditLog`) | gem `audited` + `config/initializers/audited.rb` do núcleo |
| `staydesk_cron.rb` | 3 `Sidekiq::Cron::Job` de minuto em `scheduled_jobs`: `Staydesk::Sla::CheckJob`, `Staydesk::Queues::SweepJob`, `Staydesk::AgentStatuses::DisconnectJob` (fora do `schedule.yml`) | sidekiq-cron; nome da fila `scheduled_jobs` |
| `super_admin_branding.rb` | `module_eval` em `Administrate::ApplicationHelper#application_title` → "StayDesk" | monkeypatch na gem Administrate |

### (f) Flags e variáveis de ambiente

| Item | Valor/efeito | Onde |
|---|---|---|
| `DISABLE_ENTERPRISE=true` | Edição community; com o fix de `ChatwootApp.extensions`, nenhum `Enterprise::` entra | ambiente (Easypanel); não está no `docker/` |
| `DISABLE_TELEMETRY` | Zera o job de versão. Atenção: `ENV.fetch('DISABLE_TELEMETRY', false)` trata **qualquer** valor (inclusive `"false"`) como ligado | `check_new_versions_job.rb` |
| `auto_assignment_v2_enabled?` | forçado `false` em código (ignora a flag `assignment_v2` da conta) | `custom/models/inbox.rb` |
| `conversation_required_attributes` (feature paga) | contornada no front: com a feature desligada, o composable devolve os obrigatórios StayDesk | `useConversationRequiredAttributes.js` |
| `rails staydesk:setup` | liga `disable_branding`; desliga `campaigns` e `help_center` nas contas e no `ACCOUNT_LEVEL_FEATURE_DEFAULTS`; grava `INSTALLATION_NAME`, `BRAND_NAME`, `BRAND_URL`, `WIDGET_BRAND_URL`, `TERMS_URL`, `PRIVACY_URL` em `InstallationConfig`; cria 2 papéis prontos | `custom/app/services/staydesk/setup_service.rb` |
| `STAYDESK_BRAND_URL`, `STAYDESK_TERMS_URL`, `STAYDESK_PRIVACY_URL`, `FRONTEND_URL` | marca e logo do e-mail | setup_service, mailer |

### (g) Specs do upstream que divergem (por grep, nenhum executado)

| Spec do upstream | Por que diverge | Causa |
|---|---|---|
| `spec/models/team_spec.rb:13` `'downcases the name'` | o nome agora fica como digitado | `Custom::Team` |
| `spec/controllers/api/v1/accounts/assignable_agents_controller_spec.rb` ("returns all assignable inbox members along with administrators") | a lista vira todos os usuários da conta; passa só se a fixture tiver exatamente esses 2 usuários | `Custom::...::AssignableAgentsController` |
| `spec/enterprise/models/inbox_spec.rb`, `spec/services/auto_assignment/assignment_service_spec.rb`, `spec/jobs/auto_assignment/periodic_assignment_job_spec.rb`, `spec/models/account_spec.rb` (trechos de `assignment_v2`) | v2 desligada à força | `Custom::Inbox#auto_assignment_v2_enabled?` |
| specs de auto-atribuição legada (`spec/models/conversation_spec.rb`, `spec/services/auto_assignment/agent_assignment_service_spec.rb`, `inbox_spec`) | exige agente online (`OnlineStatusTracker`) e com capacidade; specs que não marcam presença ficam sem candidato | `Custom::Inbox#member_ids_with_assignment_capacity`, `Custom::InboxAgentAvailability` |
| `spec/listeners/csat_survey_listener_spec.rb` | `conversation_status_changed` vira job com atraso (o trecho de `message_updated` continua igual) | `Custom::CsatSurveyListener` |
| `spec/models/macro_spec.rb:20` | mensagem de erro igual, mas a validação foi reescrita | `Custom::Macro` |
| `spec/models/inbox_spec.rb` (add_members) | duplicado não falha mais | `Custom::Inbox#add_members` |
| specs de mailer de resposta (`spec/mailers/conversation_reply_mailer_spec.rb`) | layout, templates e locale trocados | overlays + `Custom::ConversationReplyMailer` |
| specs Enterprise em geral (`spec/enterprise/**`) | `Enterprise::` não é carregado sem enterprise | `boot.rb` |

Não há lista de specs do upstream sabidamente vermelhos documentada no repo — recomendação: rodar uma vez a suíte completa e gravar a lista de referência (ex.: `docs/staydesk/specs-divergentes.md`) para distinguir "quebrou no sync" de "sempre foi diferente".

---


---

## 3. Mapa de risco para atualizações do upstream (do mais ao menos perigoso)

| # | Área do upstream | Por que quebra o StayDesk | Sinal de alerta no sync |
|---|---|---|---|
| 1 | **Auto-atribuição** — `app/services/auto_assignment/agent_assignment_service.rb`, `assignment_service.rb`, `app/models/concerns/auto_assignment_handler.rb`, `inbox_agent_availability.rb`, `Inbox#member_ids_with_assignment_capacity`, `#auto_assignment_v2_enabled?`, `Redis::Alfred::ROUND_ROBIN_AGENTS` | Filas, aceite (convites), capacidade e transbordo dependem de assinatura e semântica de `find_assignee`, `perform`, `team_member_ids_with_capacity`. Se o upstream remover o caminho legado (a v2 é o futuro deles), a distribuição inteira para — **sem erro**, a conversa fica sem responsável | Qualquer diff nesses arquivos; remoção do legado; mudança de nome de método |
| 2 | **`app/models/conversation.rb`** e callbacks (`AutoAssignmentHandler`, `AssignmentHandler`, ordem de `after_commit`) | 7 callbacks StayDesk dependem de ordem e de `saved_changes`; `bot_handoff!` já mudou em develop | Diff em `conversation.rb`, novos `after_*_commit`, mudanças em `custom_attributes`/`additional_attributes` |
| 3 | **Autenticação de API** — `access_token_auth_helper.rb`, `api/base_controller.rb`, `platform_controller.rb`, `rack_attack.rb`, `lib/current.rb` | O token StayDesk entra por cima de `ensure_access_token`/`authenticate_access_token!`. Develop já trouxe Bearer + `skip_before_action :set_current_user`: o merge é limpo, mas o token StayDesk continua só no cabeçalho `api_access_token` (via Bearer cai em 401) e `staydesk_token_do_cabecalho` duplica `legacy_access_token` | Diff nesses arquivos = revisar `Custom::AccessTokenAuthHelper` e os specs `spec/staydesk/requests/**api_tokens*` |
| 4 | **Templates de e-mail** `app/views/mailers/conversation_reply_mailer/*`, `ConversationReplyMailer`, `ConversationReplyMailerHelper#prepare_mail`, `layouts/mailer/base.liquid` | Overlays são cópias: correção de segurança (escape) ou campo novo do upstream não chega; `prepare_mail` é sobrescrito com `super` dentro de `I18n.with_locale` | `git diff ORIG..NOVO -- app/views/mailers/conversation_reply_mailer app/mailers` não vazio = portar à mão |
| 5 | **Filtros e condições** — `app/services/filter_service.rb`, `automation_rules/conditions_filter_service.rb`, `conversations/filter_service.rb`, `Filters::*Helper`, `Conversations::SortService` | Roteamento de filas e matcher de SLA usam `ConditionsFilterService` com um *shim* de regra; views por time usam `Conversations::FilterService`. Develop já reescreveu `filter_service.rb` (filtros de data com fuso) | Diff em `filter_service.rb` ou mudança do construtor/atributos lidos da regra |
| 6 | **Frontend de conversa** — `ReplyBox.vue`, `MessagesView.vue`, `ConversationView.vue`, `ChatList.vue`, `ChatListHeader.vue`, `ConversationBox.vue`, `MoreActions.vue`, `ContactPanel.vue` | Arquivos legado com ganchos escondidos; 3 já conflitam com develop. Upstream mexe neles quase toda release | Conflito de merge |
| 7 | **Barra lateral** — `Sidebar.vue`, `SidebarGroup*.vue`, `SidebarSubGroup.vue`, `SidebarCollapsedPopover.vue`, `provider.js` | Muitas edições no lugar; 3 conflitam já com v4.18.0 | Conflito de merge |
| 8 | **Automação e macro** — `AutomationRule#actions_attributes`, `Macro#json_actions_format`, `ACTIONS_ATTRS`, `ActionService`, `settings/automation/constants.js` | `Custom::Macro` reescreve a validação sem `super`; mudanças de nome/forma de `ACTIONS_ATTRS` quebram silenciosamente | Diff em `macro.rb`, `automation_rule.rb`, `action_service.rb`, `constants.js` |
| 9 | **Campos obrigatórios** — `useConversationRequiredAttributes.js`, `ConversationResolveAttributesModal.vue`, `CustomAttributeDefinitionsController#permitted_payload`, `_custom_attribute_definition.json.jbuilder` | O permit é reescrito inteiro; o jbuilder é cópia | Campo novo no upstream some da API StayDesk |
| 10 | **Infra da camada** — `lib/chatwoot_app.rb` (`extensions`, `enterprise?`, `custom?`), `config/application.rb`, `prepend_mod_with`/`include_mod_with` (`config/initializers/01_inject_enterprise_edition_module.rb`), `ApplicationMailer` view paths | Se mudar a forma de injeção, **todos** os `Custom::` param de carregar | Diff nesses arquivos = parar e revisar o boot |
| 11 | **Componentes-next usados pela camada** — `Button.vue` (22 imports), `Select`, `Switch`, `Input`, `Dialog`, `TagMultiSelectComboBox`, `SettingsLayout.vue`, `BaseSettingsHeader.vue`, `filter/provider`, `ConditionRow.vue`, store (`agents/`, `teams/`, `inboxes/`, `attributes/`, `getSelectedChat`, `updateConversation`, `toggleStatus`) | Mudança de props/getters quebra telas StayDesk; vitest pega parte | Diff nesses componentes/módulos de store |
| 12 | **Status de presença** — `OnlineStatusTracker` | Base do "quem está conectado" em distribuição, KPIs e status de agente | Diff em `lib/online_status_tracker.rb` |
| 13 | **Gems** — Administrate, audited, sidekiq-cron | Monkeypatch e configuração por initializer | `Gemfile.lock` mudando versão delas |
| 14 | **`db/schema.rb`** | Conflito garantido (cabeçalho 7.2, versão, tabelas novas nas duas pontas) | Sempre; resolver regenerando |
| 15 | **Dicionários i18n** | Textos com "Chatwoot" novos aparecem até rodar `marca.mjs gerar` | `marca.mjs varredura` falha |

---

