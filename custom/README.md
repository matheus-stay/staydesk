# custom/ — camada StayDesk (backend)

Tudo que o StayDesk acrescenta ao Chatwoot no backend vive aqui, fora do núcleo e fora de `enterprise/`.
O Chatwoot já prevê esta pasta: `ChatwootApp.custom?` e `ChatwootApp.extensions` (em `lib/chatwoot_app.rb`)
fazem o gancho `prepend_mod_with` / `include_mod_with` procurar módulos `Custom::` além dos `Enterprise::`.
O que faltava era colocar `custom/` nos caminhos de autoload, views, initializers, migrations, tarefas rake e
rotas: é o que `custom/config/boot.rb` faz, chamado por duas linhas de `config/application.rb`.

## Estrutura

| Pasta | O que entra | Namespace |
|---|---|---|
| `app/**/custom/` | Extensões de classe que existe no núcleo (`Custom::Conversation`, `Custom::AccountUser`) | `Custom::` |
| `app/**/staydesk/` | Modelos, serviços e políticas que são só nossos | `Staydesk::` |
| `app/controllers/api/v1/accounts/staydesk/` | API própria, sob `/api/v1/accounts/:account_id/staydesk/` | `Api::V1::Accounts::Staydesk::` |
| `app/dispatchers/custom/` | `Custom::AsyncDispatcher` e `Custom::SyncDispatcher`: acrescentam os listeners da camada aos do núcleo | `Custom::` |
| `app/listeners/staydesk/` | Listeners de eventos do produto (SLA e as automações de SLA) | `Staydesk::` |
| `app/jobs/staydesk/` | Jobs da camada: varredura da fila, vencimento de convite, saída do status, SLA, pesquisa de CSAT | `Staydesk::` |
| `app/mailers/custom/` | Extensões de mailer do núcleo (o layout da marca na resposta ao cliente) | `Custom::` |
| `app/views/` | Partials ERB que sobrepõem as originais (mesmo caminho relativo) | — |
| `config/routes.rb` | Rotas próprias, carregadas junto com as do núcleo | — |
| `config/api_reference.json` | A referência da API que a Central mostra em Documentação da API; um teste confere contra as rotas | — |
| `config/permissions.json` | Catálogo de permissões dos papéis: uma linha aqui já aparece para escolher no papel | — |
| `config/api_scopes.json` | Escopos dos tokens de API, por prefixo de controller | — |
| `config/schemas/` | JSON Schema da área de trabalho por time (`team_workspace.json`) | — |
| `config/initializers/` | Carregados depois dos initializers do núcleo | — |
| `config/locales/` | Textos do backend que sobrepõem os do núcleo | — |
| `db/migrate/` | Migrations aditivas; tabelas com prefixo `staydesk_` | — |
| `lib/` | `Staydesk::VERSION` e utilitários | `Staydesk::` |
| `lib/tasks/` | Tarefas rake (`staydesk:*`) | — |
| `bin/` | Scripts de apoio (gate, ícones, varredura de marca) | — |

Os specs ficam em `spec/staydesk/`, para rodar com o resto da suíte sem configuração extra.

## Regras

- Arquivo do núcleo não se edita. Comportamento muda por módulo `Custom::` no gancho que já existe
  (`grep -rn "prepend_mod_with\|include_mod_with" app lib` lista as classes com gancho).
- Rota nova fica sob `staydesk/`, herda de `Api::V1::Accounts::Staydesk::BaseController` e entra em
  `custom/config/api_reference.json` (e no OpenAPI). O teste
  `spec/staydesk/models/staydesk/api_reference_spec.rb` quebra se uma rota de `staydesk/` ficar sem
  documentação ou se um endpoint documentado não existir.
- Migration só cria; nunca altera coluna do núcleo.
- Configuração da operação é dado em tabela ou `InstallationConfig`, nunca constante no código.
- Toque inevitável em arquivo do núcleo entra em `docs/staydesk/core-touches.md` e passa por
  `node custom/bin/staydesk-gate.mjs`.

## Conferindo

```bash
curl -H "api_access_token: $TOKEN" https://<host>/api/v1/accounts/1/staydesk/ping
# => {"staydesk":"0.1.0","chatwoot":"4.x.y"}
```
