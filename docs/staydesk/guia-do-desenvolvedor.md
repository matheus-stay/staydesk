# Guia do desenvolvedor do StayDesk

Para quem vai assumir o StayDesk: o que é, como está montado, como mexer sem
quebrar e onde costuma doer. Leia nesta ordem:

1. este guia;
2. [camada-staydesk.md](camada-staydesk.md), que explica as regras da camada;
3. [chatwoot-diferencas.md](chatwoot-diferencas.md), com tudo o que difere do Chatwoot;
4. [runbook-local.md](runbook-local.md), para subir o ambiente;
5. os documentos de cada função, listados no [README](README.md).

## O que é

O StayDesk é o **Chatwoot com uma camada da StayCloud por cima**. O núcleo do
Chatwoot fica o mais intocado possível, e tudo o que é nosso mora em pastas
próprias. Por isso dá para puxar correções de segurança do Chatwoot sem refazer
o produto ([atualizar-do-chatwoot.md](atualizar-do-chatwoot.md)).

| Onde | O quê |
|---|---|
| `custom/` | Backend da camada: modelos, serviços, controllers da API, jobs, políticas, migrations, rotas, textos e o servidor MCP (`custom/mcp/`) |
| `app/javascript/staydesk/` | Frontend da camada: páginas da Central, componentes do Hub, stores (Pinia), clientes de API, textos |
| `docs/staydesk/` | Esta documentação |
| `spec/staydesk/` | Testes da camada (RSpec) |
| `custom/config/api_reference.json` | Referência da API, mostrada na Central em "Documentação da API" e testada para não ficar rota sem documentação |
| `docs/staydesk/core-touches.md` | Registro de **cada** arquivo do Chatwoot que o StayDesk altera |

Edição: **community**, sem licença Enterprise (`DISABLE_ENTERPRISE=true`), como
explica [edicao-community.md](edicao-community.md). O que a operação precisa e é
pago no Chatwoot (SLA, papéis, campos obrigatórios) foi construído na camada.

## Versões

- Ruby: 3.4.4, conforme `.ruby-version`.
- Node: 24.x; pnpm: 10.x, conforme `package.json`.
- Rails: 7.2.
- Chatwoot de base: 4.17.1. A base exata e o atraso estão em [chatwoot-diferencas.md](chatwoot-diferencas.md).
- Versão própria: `custom/VERSION`, também devolvida por `GET /api/v1/accounts/:id/staydesk/ping`.

## Como a camada se encaixa

- **Backend.** Duas linhas em `config/application.rb` carregam `custom/config/boot.rb`.
  O boot põe `custom/` no autoload, nas views, nas rotas, nas migrations e nos textos.
- **Módulos `Custom::`.** Estendem classes do núcleo pelo `prepend_mod_with`, que o
  Chatwoot já usa para o Enterprise. Ficam em `custom/app/**/custom/`.
- **Classes `Staydesk::`.** É o que é só nosso. Ficam em `custom/app/**/staydesk/`.
- **API própria.** Fica em `/api/v1/accounts/:account_id/staydesk/...`
  (`custom/config/routes.rb`, controllers em `custom/app/controllers/api/v1/accounts/staydesk/`).
- **Views sobrepostas.** Ficam em `custom/app/views/`, no mesmo caminho relativo do
  original, e vencem a original.
- **Frontend.** O plugin `app/javascript/staydesk/index.js` é montado em
  `entrypoints/dashboard.js`. As telas do Chatwoot chamam a camada por
  **ganchos de uma linha** marcados com `staydesk:hook`.

Os jeitos permitidos de tocar um arquivo do Chatwoot são cinco: montagem, gancho,
classe, view e legado. Cada toque vai para `core-touches.md`. O **gate**
(`node custom/bin/staydesk-gate.mjs`) roda no CI e localmente e barra o toque que
não estiver registrado ou que fugir do tipo. O tipo `legado` é dívida: edições no
lugar herdadas do ramo de UX, que não são checadas e devem ser migradas, como
mostra o mapa de risco.

## Acrescentar uma funcionalidade (receita)

1. **Modelo e migration.** A tabela nova leva o prefixo `staydesk_`, em
   `custom/db/migrate/`. Migration da camada só cria; se precisar de coluna em
   tabela do Chatwoot, ela leva o prefixo `staydesk_` e vai registrada em
   [chatwoot-diferencas.md](chatwoot-diferencas.md).
2. **Regra de negócio.** Fica num serviço `Staydesk::` em `custom/app/services/staydesk/`,
   **nunca** no frontend. O front vai ser trocado (ver [front-novo/](front-novo/)),
   e tudo o que for regra precisa estar disponível pela API.
3. **API.**
   - Controller em `custom/app/controllers/api/v1/accounts/staydesk/`, herdando de
     `Api::V1::Accounts::Staydesk::BaseController`.
   - Política em `custom/app/policies/staydesk/` e rota em `custom/config/routes.rb`.
   - View jbuilder em `custom/app/views/api/v1/accounts/staydesk/`.
4. **Documentar a rota em `custom/config/api_reference.json`.** O spec
   `spec/staydesk/models/staydesk/api_reference_spec.rb` falha se ficar rota sem
   documentação. Edite o JSON pontualmente (indentação de 1 espaço): reserializar
   o arquivo inteiro gera um diff de milhares de linhas.
5. **Escopo do token de API.** Confira em `custom/config/api_scopes.json` que o
   prefixo da rota cai no escopo certo ([tokens-de-api.md](tokens-de-api.md)).
6. **MCP.** Se a função for útil a um agente de IA, acrescente a ferramenta em
   `custom/mcp/ferramentas.mjs`.
7. **Configurável pelo arquivo da operação.** A regra é "tudo configurável": tela,
   arquivo YAML (`Staydesk::ConfigImportService`, `POST staydesk/config_import`,
   `rails staydesk:configurar`) ou variável de ambiente. Seção nova no YAML vai
   documentada em [api-e-mcp.md](api-e-mcp.md).
8. **Frontend.** Cliente de API em `app/javascript/staydesk/api/`, store Pinia em
   `store/`, tela em `pages/` ou componente em `components/`. Se precisar aparecer
   numa tela do Chatwoot, use um gancho de uma linha com `staydesk:hook` e registre-o.
9. **Testes.** RSpec em `spec/staydesk/` (o arquivo segue o nome da classe) e
   Vitest em `app/javascript/staydesk/**/specs/`.
10. **Documentação.** Atualize o documento da função e o [README](README.md).

## Rodar os testes e as verificações

O Ruby não está no host: tudo roda no contêiner.

```bash
docker compose run --rm -T -e RAILS_ENV=test rails bundle exec rspec spec/staydesk
docker compose run --rm -T rails bundle exec rubocop <arquivos>
npx vitest run app/javascript/staydesk
npx eslint --fix <arquivos>
node custom/bin/staydesk-gate.mjs --worktree    # antes de commitar
```

O hook de commit (lint-staged) avisa `xargs: bundle: Arquivo ou diretório
inexistente` porque tenta rodar o rubocop no host. O aviso é esperado: o rubocop
roda no contêiner, como acima.

## Remotos, ramos e deploy

| Remoto | O que é |
|---|---|
| `upstream` | chatwoot/chatwoot |
| `origin` | `stay-cloud-br/staydesk`, o repositório da organização. **O staging constrói daqui.** |
| `pessoal` | fork pessoal, espelho de trabalho |

- `develop` é espelho puro do Chatwoot: nunca se commita nele.
- O trabalho vai no ramo `staydesk-revisado`. Dê push nos dois remotos
  (`origin` e `pessoal`).
- **Staging:** o Easypanel constrói o ramo `staydesk-revisado` do `origin` e o deploy
  é disparado pelo gatilho do painel. A build completa leva de 5 a 25 minutos e pode
  morrer por falta de memória na VPS no passo do Vite. Nesse caso, dispare de novo.
  O workflow `staydesk_image.yml` já publica a imagem no GHCR; trocar o staging
  para baixar essa imagem é o próximo passo de infraestrutura.
- As migrations rodam no comando do serviço (`db:chatwoot_prepare`) a cada deploy.

## Configuração da operação

A operação inteira (times, etiquetas, campos, status, filas, SLA, gatilhos,
macros, visualizações, área de trabalho) cabe num YAML e entra por
`POST /api/v1/accounts/:id/staydesk/config_import` ou por `rails staydesk:configurar`.
A importação é idempotente e cada seção é opcional, então dá para aplicar uma
seção só. O arquivo real da operação **não fica no repositório**, porque pode ter
nomes e e-mails da equipe. Formato e exemplos estão em [api-e-mcp.md](api-e-mcp.md).

## Onde costuma doer

- **Distribuição sem erro e sem convite.** Comece pelo diagnóstico por conversa:
  `GET staydesk/distribution_checks?conversation_id=N`. Ele mostra em que etapa a
  conversa para ([filas-e-distribuicao.md](filas-e-distribuicao.md)).
- **Membros do canal.** Os membros são calculados das filas a cada minuto. Mexer
  na mão não adianta: mude a fila ou o grupo.
- **A distribuição v2 do Chatwoot está desligada à força.** O aceite de convite vive
  no caminho legado. Se o Chatwoot aposentar esse caminho, a distribuição para sem
  erro. É o risco número 1 em [chatwoot-diferencas.md](chatwoot-diferencas.md).
- **Ordem dos callbacks de `Conversation`.** Os `after_commit` rodam em ordem
  inversa, e há um despacho único (`staydesk_after_update`) por causa disso.
- **`Message` tem `default_scope { order(created_at) }`.** Agrupamento por mensagem
  precisa de `reorder(nil)`, senão o Postgres recusa. Já derrubou os KPIs uma vez.
- **Banco local.** O Postgres de desenvolvimento guarda os dados num volume
  anônimo. `docker compose down` ou `docker volume prune` fazem o banco "sumir"
  ([runbook-local.md](runbook-local.md)).
- **`db/schema.rb`.** O cabeçalho é `Schema[7.2]` e o do upstream é `[7.1]`, o que
  dá conflito em toda atualização. Regenere em vez de resolver na mão.
