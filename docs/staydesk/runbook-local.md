# StayDesk — Runbook Local

> Ambiente de avaliação no Mac do Luiz · porta **3020** (3000 estava ocupada)

## Arquivos locais (NÃO versionados)

- `.env` — credenciais locais (gitignored)
- `docker-compose.local.yaml` — cópia do `docker-compose.production.yaml` com porta 3020 e senha do Postgres (excluído via `.git/info/exclude`)

## Subir

```bash
cd ~/Documents/staydesk
docker compose -f docker-compose.local.yaml up -d
```

Primeira vez (prepara o banco):

```bash
docker compose -f docker-compose.local.yaml run --rm rails bundle exec rails db:chatwoot_prepare
```

Acessar: **http://localhost:3020** → tela de onboarding cria a conta admin.

## Parar / resetar

```bash
docker compose -f docker-compose.local.yaml down            # para
docker compose -f docker-compose.local.yaml down -v         # para e APAGA dados
```

## Logs

```bash
docker compose -f docker-compose.local.yaml logs -f rails
```

## Dev frontend (hot-reload — story 1.4, ainda não configurado)

Requisitos: Ruby 3.2.2 (rvm), Node 20, pnpm, PostgreSQL 14+, Redis, ImageMagick (via brew).

```bash
make setup      # bundle + pnpm install
make db         # prepara banco
make run        # overmind: rails :3000 + sidekiq + vite dev
```

## Sync com upstream (Chatwoot oficial)

```bash
git fetch upstream
git checkout develop && git merge upstream/develop   # ou rebase — ver architecture-map.md
```
