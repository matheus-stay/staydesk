# StayDesk — Runbook local

Subir, popular e conferir o ambiente local. Tudo roda pelo `docker-compose.yaml`
da raiz, o mesmo do Chatwoot: rails, sidekiq, vite, postgres, redis e mailhog.

## Antes de começar

- Repositório fora de pasta sincronizada (iCloud, OneDrive, Dropbox) e clone
  completo, sem `--filter`. Em agosto, um clone parcial dentro de pasta
  sincronizada corrompeu o packfile do git: o download preguiçoso de blobs
  estourava o tempo no meio do `push` e deixava o pack truncado.
- O ramo de trabalho é `staydesk-revisado`. `develop` é o espelho do oficial
  ([architecture-map.md](architecture-map.md)).
- `.env` na raiz, a partir do `.env.example`, com `DISABLE_ENTERPRISE=true` e
  `DISABLE_TELEMETRY=true` ([edicao-community.md](edicao-community.md)).

## Subir

```bash
docker compose up -d
```

- App: **http://localhost:3000** · Vite dev server: 3036 · Mailhog (e-mails de teste): http://localhost:8025
- O diretório local é montado no container (`./:/app`): editar `.vue`, CSS ou
  Ruby reflete na hora, sem rebuild.
- Primeira vez (banco): `docker compose run --rm rails bundle exec rails db:chatwoot_prepare`
- Marca nas contas: `docker compose exec rails bundle exec rails staydesk:setup`

## Parar e voltar

```bash
docker compose stop      # para tudo, mantém os containers
docker compose up -d     # volta
docker compose logs -f rails
```

**Nunca rodar `docker compose down` nem `docker volume prune`.** O compose
monta o volume nomeado `postgres` em `/data/postgres`, mas o Postgres grava em
`/var/lib/postgresql/data`. Os dados de verdade ficam num **volume anônimo**
criado pela imagem, preso ao container. `down` apaga o container e o próximo
`up` cria outro com um volume anônimo novo, vazio; `volume prune` apaga o
antigo de vez. Para parar, `stop`; para voltar, `up -d`.

Para fixar o volume e não depender do container, um
`docker-compose.override.yml` local aponta o caminho certo para um volume com
nome. Ele fica fora do git pelo `.git/info/exclude` (não pelo `.gitignore`, que
é compartilhado):

```yaml
services:
  postgres:
    volumes:
      - pgdados:/var/lib/postgresql/data
volumes:
  pgdados:
    external: true
    name: <nome do volume anônimo que hoje guarda os dados>
```

O nome sai de `docker inspect <container do postgres> --format '{{json .Mounts}}'`.
Com o override no lugar, o banco sobrevive a recriar o container.

## Testes e conferências

```bash
# specs da camada (banco de teste dentro do container)
docker compose run --rm -T -e RAILS_ENV=test rails bundle exec rspec spec/staydesk

# estilo do Ruby, dentro do container
docker compose run --rm -T rails bundle exec rubocop custom spec/staydesk

# specs do frontend da camada
npx vitest run app/javascript/staydesk

# toques no núcleo, contra develop, antes de commitar
node custom/bin/staydesk-gate.mjs --worktree

# nenhum texto visível diz Chatwoot
node custom/bin/marca.mjs varredura
```

O gate sem `--worktree` confere o que já está commitado (`HEAD`). Com ele,
confere a árvore de trabalho, que é o que interessa antes do commit.

## Sync com o oficial (Chatwoot)

```bash
git fetch upstream
git checkout develop && git merge --ff-only upstream/develop
git checkout staydesk-revisado && git merge develop
```

`develop` só avança por fast-forward: nada nosso entra nele. Os conflitos se
resolvem no merge para `staydesk-revisado`, mantendo a lógica do upstream e as
classes e ganchos da camada. Depois do merge, rodar o gate e os specs.

## Dados fictícios para ver as telas

```bash
docker compose exec rails bundle exec rails staydesk:demo RESET=1
```

Popula a conta (`ACCOUNT_ID=1` por padrão) com o que as telas do StayDesk precisam para fazer sentido: quatro agentes com times, quatro caixas (dois chats e dois e-mails), etiquetas, catálogo de status do ticket, catálogo de status do agente com carga por fila, calendário e duas políticas de SLA, três visualizações por time, área de trabalho em tabela, vinte contatos e 45 conversas espalhadas por fila, status, responsável e prioridade, com mensagens.

- `RESET=1` apaga as conversas e os contatos fictícios antes; sem ele, as conversas são somadas às existentes.
- `SOMENTE=historico` só acrescenta o histórico dos clientes.
- Não roda em produção (use `FORCE=1` por sua conta e risco).
- Agentes criados: `ana@`, `bruno@`, `carla@`, `diego@staydesk.test`, senha `Staydesk#2026`. Entrar como um deles mostra a área de trabalho do time, diferente da visão do administrador.

## Configurar a operação

```bash
docker compose exec rails bundle exec rails staydesk:configurar ACCOUNT_ID=1 FILE=configuracao.yml
```

O que o arquivo cobre está em [api-e-mcp.md](api-e-mcp.md#configuração-em-arquivo).
