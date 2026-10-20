# StayDesk

A central de atendimento da StayCloud: tickets por e-mail e API, chat do site e
WhatsApp, num só lugar, com o jeito Zendesk de trabalhar.

Por baixo é o [Chatwoot](https://github.com/chatwoot/chatwoot) (Ruby on Rails e
Vue), edição community, com uma **camada própria** por cima. O núcleo fica o mais
intocado possível: tudo o que é do StayDesk mora em pastas próprias, e cada toque
no código do Chatwoot é registrado e conferido no CI. Assim dá para trazer as
correções de segurança do Chatwoot sem refazer o produto.

## O produto

Dois espaços, com nome próprio:

- **Hub**, onde se atende: visualizações por grupo, convite de atendimento com
  aceite, status do agente, conversa com campos do ticket e "Enviar como <status>".
- **Central**, onde se administra e se acompanha: filas, canais de trabalho,
  capacidade, status, SLA, visualizações, área de trabalho, papéis, indicadores e
  a documentação da API.

O que a camada acrescenta ao Chatwoot:

| Função | Como funciona |
|---|---|
| Filas e distribuição | Filas por canal e por assunto, com grupos principais e secundários (transbordo). Convite com aceite, rodízio, capacidade por canal de trabalho, convites perdidos e varredura da fila. Chat por ordem de chegada, ticket por prazo de SLA |
| Status do agente | O status diz o que o agente recebe (chat, ticket ou nada), liberado conforme as filas dos grupos dele. Sai sozinho ao fechar a aba e pelo tempo limite |
| Status do ticket | Catálogo próprio por cima dos quatro status do Chatwoot ("Novo", "Em andamento", "Pendente", "Em espera", "Resolvido"…) |
| Campos do ticket | Campos de lista com obrigatório para resolver. O assunto segue a regra do Zendesk |
| Reabertura | Chat reaberto pelo cliente volta para a fila; ticket reaberto fica com quem atendia. Configurável por canal de trabalho |
| SLA | Motor próprio, com calendário comercial, alvos por prioridade, pausa, aviso e violação |
| Visualizações e área de trabalho | Por grupo e por papel, com contagem em tempo real |
| Papéis e permissões | Papéis com permissão por área, agente leve (só nota interna) e "entrar como" |
| Indicadores | CSAT, aceitação de convites, tempos, volumes, FCR, SLA, tempo online e contagem por campo |
| Integrações | API própria com tokens de escopo, API compatível com o Zendesk (para o dashboard), servidor MCP e geração de instância nova pela Platform API |
| Configuração em arquivo | A operação inteira (times, campos, filas, SLA, gatilhos, macros, visualizações…) entra por um YAML, pela API ou pelo console |

## Onde está cada coisa

| Caminho | O quê |
|---|---|
| `custom/` | Backend da camada: modelos, serviços, controllers, jobs, migrations, rotas, textos e o servidor MCP |
| `app/javascript/staydesk/` | Frontend da camada: telas da Central, componentes do Hub, stores e clientes de API |
| `spec/staydesk/` | Testes da camada (RSpec); os do front ficam em `app/javascript/staydesk/**/specs/` (Vitest) |
| `docs/staydesk/` | Toda a documentação do StayDesk |
| `swagger/staydesk/openapi.json` | OpenAPI da API do StayDesk, gerado da referência e conferido no CI |

## Documentação

Comece por [docs/staydesk/README.md](docs/staydesk/README.md), que é o índice. Os
principais:

- [Guia do desenvolvedor](docs/staydesk/guia-do-desenvolvedor.md): como a camada se
  encaixa, a receita para acrescentar uma função e onde costuma doer.
- [Runbook local](docs/staydesk/runbook-local.md): subir, popular e conferir o
  ambiente.
- [Diferenças do Chatwoot](docs/staydesk/chatwoot-diferencas.md) e
  [atualizar do Chatwoot](docs/staydesk/atualizar-do-chatwoot.md).
- [API e MCP](docs/staydesk/api-e-mcp.md): os endpoints e o formato do arquivo de
  configuração. A referência navegável fica na Central, em "Documentação da API".
- [Contrato do front novo](docs/staydesk/front-novo/README.md): o que um front
  novo precisa fazer, consumir e respeitar para plugar no backend.

## Rodar localmente

```bash
cp .env.example .env          # com DISABLE_ENTERPRISE=true e DISABLE_TELEMETRY=true
docker compose up -d          # rails, sidekiq, vite, postgres, redis e mailhog
```

O app sobe em http://localhost:3000. Para ter dados nas telas,
`rails staydesk:demo RESET=1` popula a conta. Detalhes e problemas comuns no
[runbook local](docs/staydesk/runbook-local.md).

> O Postgres de desenvolvimento guarda os dados num volume anônimo:
> `docker compose down` e `docker volume prune` apagam o banco.

## Testes e verificações

O Ruby roda no contêiner:

```bash
docker compose run --rm -T -e RAILS_ENV=test rails bundle exec rspec spec/staydesk
docker compose run --rm -T rails bundle exec rubocop <arquivos>
npx vitest run app/javascript/staydesk
node custom/bin/staydesk-gate.mjs --worktree    # antes de commitar
```

O **gate** confere que nenhum arquivo do Chatwoot foi alterado fora do que está
registrado em [core-touches.md](docs/staydesk/core-touches.md).

## Ramos, remotos e deploy

- O trabalho vai no ramo **`staydesk-revisado`**. `develop` é espelho do Chatwoot:
  nunca se commita nele.
- `origin` é `stay-cloud-br/staydesk`, de onde o staging constrói. Dê push também
  no espelho de trabalho.
- O staging (Easypanel) constrói o ramo e roda as migrations a cada deploy. A
  primeira build do dia, sem cache, leva mais de 20 minutos e passa tempo sem
  escrever no log: não dispare outro deploy por cima, porque isso mata a build em
  andamento.
- O CI publica a imagem no GHCR a cada push.

## Configurar a operação

```sh
rails staydesk:configurar ACCOUNT_ID=1 FILE=configuracao.yml
```

ou `POST /api/v1/accounts/:id/staydesk/config_import` com o mesmo YAML. É
idempotente, e cada seção é opcional. O arquivo real da operação não fica no
repositório, porque traz nomes e e-mails da equipe. O formato está em
[api-e-mcp.md](docs/staydesk/api-e-mcp.md#configuração-em-arquivo).

## Licença

O StayDesk é derivado do Chatwoot, distribuído sob a licença MIT
([LICENSE](LICENSE)), que continua valendo para o código de origem. O StayDesk
roda na edição community (`DISABLE_ENTERPRISE=true`) e não usa o código de
`enterprise/`.
