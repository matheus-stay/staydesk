# Atualizar o StayDesk a partir do Chatwoot (inclusive correções de segurança)

O StayDesk é um fork: as correções de segurança do Chatwoot **não chegam
sozinhas**. Este é o procedimento para trazê-las sem quebrar a camada StayDesk.
Antes de começar, leia o mapa de risco em
[chatwoot-diferencas.md](chatwoot-diferencas.md) (seção 3): ele diz o que revisar
mesmo quando o merge não dá conflito.

Remotos: `upstream` = chatwoot/chatwoot · `origin` = stay-cloud-br/staydesk (o
staging constrói daqui, ramo `staydesk-revisado`) · `pessoal` = fork pessoal.
O ramo `develop` é **espelho puro** do upstream: nunca se commita nele.

## Pendências conhecidas (2026-10-19)

Correções de segurança do upstream que o StayDesk ainda **não** tem:

| Commit | O quê | Onde está |
|---|---|---|
| `4218dc6793` | sanitização XSS em HTML/markdown (`HTMLSanitizer.js`, `base_markdown_renderer.rb`, `markdown_renderer_url_sanitizer.rb`) (#14050) | **v4.18.0** |
| `778fc6fa37` | escape de rótulos de menção e do painel de diff de artigo (#15965) | só develop |
| `7b3c928bf1` | rate-limit de autenticação lendo corpo JSON (`rack_attack.rb`) (#15939) | só develop |
| `8aa1fafe20` | token de API aceito como `Authorization: Bearer` (`access_token_auth_helper.rb`, `api/base_controller.rb`, `rack_attack.rb`) (#15941) | só develop |
| `910f5e2f49` | verificação de dispositivo no login (cloud/enterprise; quase tudo em `enterprise/`) (#15879) | só develop |

Ou seja: **já existe pendência de segurança hoje**, mesmo sem novo fetch.


## Procedimento

Hoje o único roteiro existente é uma linha em `docs/staydesk/runbook-local.md` ("Sync com upstream": `git fetch upstream && git checkout develop && git merge upstream/develop`). Não há script de sync em `custom/bin/` (lá só há `staydesk-gate.mjs`, `marca.mjs`, `icones/`). O workflow do gate já escuta ramos `sync/**`, o que sugere o padrão de ramo abaixo.

**Decisão de base:** para correção de segurança, preferir a **tag de release** (`vX.Y.Z`, que é o `master` do upstream) em vez do topo de `develop` do upstream — menos mudança e menos conflito (hoje: 4 conflitos contra `v4.18.0` vs 8 contra `upstream/develop`). Se a correção só existir em develop (caso atual de `#15939` rate-limit, `#15941` Bearer e `#15965` escape), avaliar `cherry-pick` dos commits de segurança sobre um ramo de sync, documentando-os.

### Passo a passo

1. **Preparar e medir**
   ```bash
   cd ~/repos/staydesk
   git status                       # árvore limpa
   git fetch upstream --tags
   git fetch origin
   ALVO=v4.18.1                     # tag da release de segurança (ou upstream/develop)
   BASE=$(git merge-base staydesk-revisado develop)
   git log --oneline develop..$ALVO | wc -l
   git log --oneline develop..$ALVO | grep -iE 'secur|xss|ssrf|csrf|auth|sanitiz|escape|cve|ghsa'
   ```
2. **Prever o estrago antes de mexer**
   ```bash
   git merge-tree --write-tree --name-only --no-messages staydesk-revisado $ALVO   # lista de conflitos
   # o que mudou no upstream nas áreas que a camada sobrescreve:
   git diff --stat develop $ALVO -- app/services/auto_assignment app/models/concerns/auto_assignment_handler.rb \
     app/models/concerns/inbox_agent_availability.rb app/models/inbox.rb app/models/conversation.rb \
     app/models/macro.rb app/models/automation_rule.rb app/models/team.rb app/models/account_user.rb app/models/message.rb \
     app/services/action_service.rb app/services/automation_rules app/services/filter_service.rb \
     app/controllers/concerns/access_token_auth_helper.rb app/controllers/api/base_controller.rb \
     app/controllers/api/v1/accounts/assignable_agents_controller.rb app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb \
     app/controllers/application_controller.rb app/policies/account_policy.rb app/policies/report_policy.rb \
     app/dispatchers app/listeners/csat_survey_listener.rb app/mailers app/views/mailers/conversation_reply_mailer \
     app/views/super_admin app/views/installation app/views/api/v1/models/_custom_attribute_definition.json.jbuilder \
     lib/chatwoot_app.rb lib/current.rb lib/online_status_tracker.rb config/application.rb config/initializers
   ```
   Tudo que aparecer aqui é revisão obrigatória, mesmo sem conflito (risco de quebra silenciosa — ver seção 3).
3. **Atualizar o espelho `develop`** (nunca commitar nele):
   ```bash
   git checkout develop
   git merge --ff-only $ALVO          # tag é descendente da base; se não for ff, parar e investigar
   git push origin develop            # o CI do gate faz `git fetch origin develop:develop`
   ```
   Se for usar o topo de develop do upstream: `git merge --ff-only upstream/develop`.
4. **Ramo de sync e merge** (merge, não rebase: preserva o histórico publicado de `staydesk-revisado`)
   ```bash
   git checkout -b sync/$ALVO staydesk-revisado
   git merge --no-ff develop -m "sync: Chatwoot $ALVO (segurança)"
   ```
5. **Resolver conflitos — hotspots e regra**
   - `db/schema.rb`: aceitar o do upstream (`git checkout --theirs db/schema.rb`), depois `bundle exec rails db:migrate` num banco local com as migrations `custom/` aplicadas e commitar o `schema.rb` regenerado (conferir se as 17 tabelas `staydesk_*` e a coluna `custom_attribute_definitions.staydesk_required_to_resolve` continuam lá).
   - Arquivos `legado` da barra lateral, `ChatListHeader.vue`, `ReplyBox.vue`, `MessagesView.vue`, `ConversationView.vue`: partir da versão do upstream e reaplicar só o que for nosso (classe Tailwind / linha `staydesk:hook`). Oportunidade de rebaixar o arquivo de `legado` para `classe`/`gancho` e atualizar `core-touches.md`.
   - Arquivos `gancho`: o conflito costuma ser só a linha final `prepend_mod_with`; manter a do upstream + a nossa.
   - `README.md` da raiz: é o do StayDesk. Em conflito, manter o nosso (`git checkout --ours README.md`).
   - Nunca resolver aceitando "o nosso" em bloco num arquivo do upstream que traz correção de segurança.
6. **Portar à mão o que o merge não mostra**
   - Templates de e-mail sobrepostos: `git diff $BASE $ALVO -- app/views/mailers/conversation_reply_mailer app/views/layouts/mailer` → aplicar as mudanças equivalentes em `custom/app/views/conversation_reply_mailer/*`.
   - Overlays registrados como `view`: `git diff $BASE $ALVO -- <cada original>` → portar para a cópia em `custom/app/views`.
   - `permitted_payload` de `CustomAttributeDefinitionsController`: conferir se o upstream acrescentou campo.
   - Textos: `node custom/bin/marca.mjs gerar` e depois `node custom/bin/marca.mjs varredura`.
7. **Gate e lint**
   ```bash
   node custom/bin/staydesk-gate.mjs          # contra o develop novo
   bundle exec rubocop custom spec/staydesk config/application.rb lib/current.rb
   pnpm eslint
   ```
8. **Testes**
   ```bash
   bundle exec rspec spec/staydesk
   # upstream em volta das áreas tocadas:
   bundle exec rspec spec/services/auto_assignment spec/models/inbox_spec.rb spec/models/conversation_spec.rb \
     spec/models/macro_spec.rb spec/models/automation_rule_spec.rb spec/models/team_spec.rb spec/models/account_user_spec.rb \
     spec/services/automation_rules spec/services/filter_service_spec.rb spec/services/conversations/filter_service_spec.rb \
     spec/listeners/csat_survey_listener_spec.rb spec/mailers/conversation_reply_mailer_spec.rb \
     spec/controllers/api/v1/accounts/assignable_agents_controller_spec.rb spec/controllers/api/base_controller_spec.rb \
     spec/controllers/api/v1/accounts/custom_attribute_definitions_controller_spec.rb spec/policies
   # + os specs que o próprio commit de segurança trouxe (git show --stat <commit> | grep spec/)
   pnpm exec vitest --no-watch app/javascript/staydesk
   pnpm exec vitest --no-watch app/javascript/dashboard/components-next/sidebar app/javascript/shared/helpers
   ```
   Comparar falhas do upstream com a lista de referência (seção 2g): só falha nova é regressão.
9. **Subir e publicar no staging**
   ```bash
   git checkout staydesk-revisado && git merge --ff-only sync/$ALVO
   git push origin staydesk-revisado           # dispara gate (staydesk_gate.yml) e a imagem GHCR (staydesk_image.yml)
   git push pessoal staydesk-revisado
   ```
   Deploy do staging: o Easypanel constrói o ramo `staydesk-revisado` do `origin` (não do `pessoal`), disparado pelo gatilho de implantação do painel. A build completa leva de 5 a 25 minutos (gems e assets compilados na VPS). As migrations rodam no comando do serviço (`db:chatwoot_prepare`); se a release mexer em flags de conta, rodar `bundle exec rails staydesk:setup`.
10. **Smoke test no staging**
    - `GET /api/v1/accounts/1/staydesk/ping` devolve a versão nova do Chatwoot em `chatwoot`.
    - Login do agente e do super admin (título StayDesk, sem "Chatwoot").
    - `GET /enterprise/api/v1/...` → 404; super admin mostra plano `community`; nada para `hub.2.chatwoot.com`.
    - Conversa nova de e-mail e de chat: entra na fila certa (time), ganha status de ticket inicial, recebe aviso de recebimento com cartão.
    - Fila com aceite: convite aparece no cartão do canto para um agente online; aceitar atribui; recusar/expirar reoferece; agente offline/sem capacidade não recebe.
    - Transferir para agente fora da fila (lista de atribuíveis mostra a conta toda) e ele passa a enxergar a conversa.
    - Resolver sem campo obrigatório é bloqueado; com o campo preenchido, resolve; CSAT chega depois da resposta (atraso do canal).
    - Seletor de status do ticket no lugar de Resolver; macro com "definir campo"/"status do ticket".
    - Token de API StayDesk com escopo: endpoint permitido 200, fora do escopo 403; token pessoal do Chatwoot continua funcionando (incluindo Bearer, se a release trouxer).
    - Agente leve: só nota privada (mensagem pública → 403).
    - Relatório "só meus números" bloqueia o dos outros.
    - Status de agente e SLA: cron de minuto rodando (`staydesk_sla_check_job`, `staydesk_queue_sweep_job`, `staydesk_agent_disconnect_job` no Sidekiq Cron).
    - E-mail de resposta ao cliente com layout da marca, assinatura e idioma pt-BR.
    - A correção de segurança específica da release (reproduzir o caso do advisory/GHSA, se público).
11. **Registrar**: atualizar `docs/staydesk/architecture-map.md` (versão base), `core-touches.md` (legados migrados) e a lista de specs divergentes.

### Melhorias recomendadas (para tornar o sync barato)

1. Escrever `custom/bin/staydesk-sync.mjs` (ou `.sh`) com os passos 1–2 e 7–8: fetch, `merge-tree` de previsão, diff das áreas sobrescritas, diff dos originais de cada overlay, gate, marca.
2. Corrigir o gate para **não aceitar caminho duplicado** no `core-touches.md` (ou acumular tipos e aplicar o mais restrito) e para checar overlays cujo caminho difere do original (mailer).
3. Registrar os dois overlays de e-mail em `core-touches.md`; idealmente trocá-los por um partial/gancho em vez de cópia integral.
4. Prioridade de migração dos legados: os 7 arquivos que já conflitam (seção 1) e os 4 que escondem `staydesk:hook` (`Sidebar.vue`, `ChatList.vue`, `ConversationBox.vue`, `ContactPanel.vue`, `ReplyBox.vue`).
5. Alinhar o cabeçalho do `schema.rb` com o upstream (ou aceitar o conflito como passo fixo do procedimento).
6. Planejar a saída da distribuição legada: o StayDesk está apoiado no caminho que o upstream tende a aposentar (v2 é assíncrona). Teste de fumaça de distribuição deve ser obrigatório em todo sync.
7. Aplicar já a pendência atual: v4.18.0 (XSS #14050) e, por cherry-pick ou próximo release, #15939 (rate-limit), #15941 (Bearer) e #15965 (escape de menção).
