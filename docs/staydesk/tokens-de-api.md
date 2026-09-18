# Tokens de API

Integração não usa o token pessoal de ninguém. Usa uma chave própria, com escopo
próprio, criada em **Central › Pessoas › Tokens de API**.

## Como funciona

O token **age em nome de um agente** e **só alcança os escopos marcados**. As
permissões dessa pessoa continuam valendo por cima: o escopo estreita, nunca
amplia. Um token que age por um agente comum não vira administrador por ter o
escopo de configuração marcado.

A checagem roda logo depois da autenticação, para todo endpoint, o do produto e o
nosso. Fora do escopo, a resposta é `403` dizendo qual escopo falta. Endpoint que
nenhum grupo cobre também não passa: a regra é permissão explícita, não lista de
bloqueio. É por isso que as APIs de plataforma, de widget e a pública não
respondem a token de conta.

O valor aparece **uma única vez**, na criação. O banco guarda só o resumo SHA-256
e os quatro últimos caracteres. Token perdido se revoga e se cria outro.

## Escopos

Cada grupo tem `leitura` (GET e HEAD) e `escrita` (o resto), no formato
`grupo:acao`. O grupo de um endpoint é o do prefixo mais específico que casa com
o caminho do controller.

| Grupo | Cobre |
|---|---|
| `conversas` | Conversas, mensagens, busca e ações em massa |
| `contatos` | Contatos, empresas e vínculo com caixas |
| `relatorios` | Relatórios do produto, CSAT, `staydesk/kpis`, eventos, SLAs aplicados, carga e aceitação |
| `operacao` | O resto de `staydesk/`: filas, status, SLA, calendários, visualizações, papéis, tokens |
| `canais` | Caixas de entrada, membros, canais e modelos |
| `equipe` | Agentes, times, papéis, robôs e políticas de atribuição |
| `automacao` | Automações, macros, respostas prontas, campanhas, etiquetas, campos, integrações e webhooks |
| `central_de_ajuda` | Portais, artigos e categorias |
| `conta` | Conta, perfil, notificações e o que sobrar |

O catálogo é `custom/config/api_scopes.json`. Acrescentar um grupo, ou cobrir um
endpoint novo, é editar esse arquivo: não há código por endpoint.

## Criar e usar

Na tela: nome, escopos, em nome de quem o token age e, se quiser, uma data de
vencimento. A lista mostra os quatro últimos caracteres, o último uso, e permite
suspender, reativar e revogar.

```sh
curl -H "api_access_token: sd_..." "$URL/api/v1/accounts/1/staydesk/kpis"
```

| Endpoint | O que faz |
|---|---|
| `GET staydesk/api_tokens` | Lista os tokens, com escopos, dono e último uso, mais o catálogo de escopos |
| `POST staydesk/api_tokens` | Cria e devolve o valor em claro uma única vez |
| `PATCH staydesk/api_tokens/:id` | Suspende, reativa ou troca os escopos |
| `DELETE staydesk/api_tokens/:id` | Revoga de vez |

Criar e revogar exige ser administrador ou ter a permissão da área de papéis.

## Recomendação

Um token por integração, com o mínimo de escopo. O dashboard lê números: basta
`relatorios:leitura`. O MCP que só consulta: `relatorios:leitura` e
`operacao:leitura`. Escrita só onde a integração precisa mesmo escrever.
