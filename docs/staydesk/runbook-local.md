# StayDesk — Runbook Local

> ⚠️ **Local do repo: `~/dev/staydesk`** — NÃO usar `~/Documents/staydesk` (ver ADR-003 abaixo).

## ADR-003 — Por que o repo saiu de `~/Documents`

`~/Documents` sincroniza com iCloud Drive. Combinado com um clone parcial (`--filter=blob:none`), isso corrompeu o packfile do git em 28/08: operações de `git add`/`push` disparavam download preguiçoso de blobs, estouravam timeout, eram mortas no meio e deixavam pack truncado (`pack ... is far too short to be a packfile`).

**Regra:** repositórios git ficam em `~/dev/`, fora de pastas sincronizadas. Clone sempre completo (sem `--filter`).

---

## Dois ambientes

| Ambiente | Compose | App | Pra quê |
|---|---|---|---|
| **Avaliação** (produção-like) | `docker-compose.local.yaml` | http://localhost:3020 | Naldo e Luiz explorarem o produto com dados reais |
| **Dev** (hot-reload) | `docker-compose.dev.local.yaml` | http://localhost:3021 | Luiz mexer no frontend e ver a mudança na hora |

Portas separadas de propósito — os dois podem rodar ao mesmo tempo.

### Avaliação

```bash
cd ~/dev/staydesk && docker compose -f docker-compose.local.yaml up -d
```

Primeira vez (banco): `docker compose -f docker-compose.local.yaml run --rm rails bundle exec rails db:chatwoot_prepare`

### Dev com hot-reload

```bash
cd ~/dev/staydesk && docker compose -p staydesk-dev -f docker-compose.dev.local.yaml up -d
```

- App: **http://localhost:3021** · Vite dev server: 3036 · Mailhog (e-mails de teste): http://localhost:8026
- O diretório local é montado no container (`./:/app`) — **editar `.vue`/CSS reflete na hora**, sem rebuild
- Primeira vez (banco do dev): `docker compose -p staydesk-dev -f docker-compose.dev.local.yaml run --rm rails bundle exec rails db:chatwoot_prepare`

## Parar / logs / reset

```bash
docker compose -f docker-compose.local.yaml down
docker compose -f docker-compose.local.yaml logs -f rails
docker compose -f docker-compose.local.yaml down -v   # APAGA os dados
```

(trocar por `-p staydesk-dev -f docker-compose.dev.local.yaml` para a stack de dev)

## Features enterprise no ambiente local

Ativadas em 28/08 (legal para dev/teste — ver ADR-001 em `architecture-map.md`):

```bash
docker compose -f docker-compose.local.yaml exec rails bundle exec rails runner "InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN').update!(value: 'enterprise'); InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY').update!(value: 100); GlobalConfig.clear_cache; Account.find_each { |a| a.enable_features!('sla','custom_roles','audit_logs','disable_branding','companies','captain_integration','advanced_search') }"
```

## Arquivos locais (não versionados)

`.env` · `docker-compose.local.yaml` · `docker-compose.dev.local.yaml`

## Sync com upstream (Chatwoot oficial)

```bash
git fetch upstream && git checkout develop && git merge upstream/develop
```

## Dados fictícios para ver as telas

```bash
docker compose exec rails bundle exec rails staydesk:demo RESET=1
```

Popula a conta (`ACCOUNT_ID=1` por padrão) com o que as telas do StayDesk precisam para fazer sentido: quatro agentes com times, quatro caixas (dois chats e dois e-mails), etiquetas, catálogo de status do ticket, catálogo de status do agente com carga por fila, calendário e duas políticas de SLA, três visualizações por time, área de trabalho em tabela, vinte contatos e 45 conversas espalhadas por fila, status, responsável e prioridade, com mensagens.

- `RESET=1` apaga as conversas e os contatos fictícios antes; sem ele, as conversas são somadas às existentes.
- Não roda em produção (use `FORCE=1` por sua conta e risco).
- Agentes criados: `ana@`, `bruno@`, `carla@`, `diego@staydesk.test`, senha `Staydesk#2026`. Entrar como um deles mostra a área de trabalho do time, diferente da visão do administrador.
