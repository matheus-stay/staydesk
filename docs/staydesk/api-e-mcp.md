# API e MCP do StayDesk

Tudo que a Central configura e mostra tem endpoint próprio, sob
`/api/v1/accounts/:account_id/staydesk/`. O MCP em `custom/mcp` fala com esses
mesmos endpoints, então tela, dashboard e agente de IA leem a mesma conta.

## Autenticação

Cabeçalho `api_access_token`. Vale o token pessoal do usuário, que carrega tudo
que a pessoa pode, ou um **token de API com escopo próprio**, criado em
Central › Tokens de API, que é o recomendado para integração.

O token de API age em nome de um agente e só alcança os escopos marcados: o
escopo estreita, nunca amplia o que essa pessoa pode. Endpoint fora do escopo
responde `403` dizendo qual escopo falta; endpoint que nenhum grupo cobre também
não passa, porque a regra é permissão explícita, não lista de bloqueio.

O valor aparece uma única vez, na criação. O banco guarda só o resumo (SHA-256) e
os quatro últimos caracteres, então token perdido se revoga e se cria outro.

### Escopos

Cada grupo tem `leitura` (GET e HEAD) e `escrita` (o resto), no formato
`grupo:acao`. O grupo de um endpoint é o do prefixo mais específico que casa com
o caminho do controller, então `conta` funciona como guarda-chuva sem engolir os
outros.

| Grupo | Cobre |
|---|---|
| `conversas` | conversas e mensagens |
| `contatos` | contatos |
| `relatorios` | relatórios do produto, `staydesk/kpis`, eventos, SLAs aplicados, carga e aceitação |
| `operacao` | o resto de `staydesk/`: filas, status, SLA, calendários, visualizações, papéis, tokens |
| `cadastros` | times, caixas, agentes, etiquetas, atributos, respostas prontas, macros, automações |
| `conta` | o que sobra da conta e o perfil |

O catálogo é o arquivo `custom/config/api_scopes.json`: acrescentar um grupo ou um
prefixo é editar esse arquivo, sem mexer em código.

```sh
curl -H "api_access_token: sd_..."   "https://staydesk.staycloud.com.br/api/v1/accounts/1/staydesk/kpis"
```

### Gerenciar tokens

| Endpoint | O que faz |
|---|---|
| `GET staydesk/api_tokens` | lista os tokens da conta, com escopos, dono, último uso e o catálogo de escopos |
| `POST staydesk/api_tokens` | cria e devolve o valor em claro uma única vez |
| `PATCH staydesk/api_tokens/:id` | suspende, reativa ou troca os escopos |
| `DELETE staydesk/api_tokens/:id` | revoga de vez |

Criar e revogar exige a permissão da área de papéis, ou ser administrador.

```sh
curl -H "api_access_token: SEU_TOKEN" \
  "https://staydesk.staycloud.com.br/api/v1/accounts/1/staydesk/kpis?since=2026-09-01T00:00:00Z"
```

## Números da operação

| Endpoint | O que devolve |
|---|---|
| `GET staydesk/kpis` | CSAT (respostas, satisfeitos, percentual, média e por agente), tempos de primeira resposta, resposta e resolução **por fila de carga**, quem está esperando na fila e há quanto tempo, e o tempo de cada agente em cada status com quem está conectado agora. Aceita `since` e `until` em ISO 8601; sem eles, os últimos 7 dias. |
| `GET staydesk/agent_loads` | Quantas conversas cada agente atende agora em cada fila, contra o limite do status dele. |
| `GET staydesk/offer_stats` | Aceitação de chat e WhatsApp por agente: oferecidos, aceitos, recusados, expirados, taxa e tempo médio de resposta. |
| `GET staydesk/events` | Linha do tempo das conversas: mudanças de status, responsável, grupo e prioridade. |
| `GET staydesk/applied_slas` | SLA aplicado a cada conversa, com alvo, status e vencimento. |
| `GET staydesk/agent_status_periods` | Períodos de status de cada agente, para quem quiser recalcular tempo por conta própria. |
| `GET staydesk/conversations/:conversation_id/sla` | O SLA de uma conversa específica. |

## Configuração da operação

Todas seguem o mesmo desenho: `GET` lista, `POST` cria, `PUT`/`PATCH` altera,
`DELETE` remove, e algumas têm `PUT .../reorder` para trocar a ordem.

| Recurso | Endpoint | Para que serve |
|---|---|---|
| Filas de encaminhamento | `staydesk/queues` | Para qual grupo cada demanda vai, transbordo e aceite obrigatório |
| Filas de carga | `staydesk/load_queues` | Que canal e que caixa contam como chat e como ticket |
| Status do ticket | `staydesk/ticket_statuses` | Catálogo de status, qual é o padrão de cada base e qual assume ao atribuir |
| Status do agente | `staydesk/agent_statuses` | Disponibilidade e limite de conversas simultâneas por fila |
| Políticas de SLA | `staydesk/sla_policies` | Alvos por prioridade, pausa, aviso e calendário |
| Calendários | `staydesk/calendars` | Horário comercial e feriados |
| Visualizações por time | `staydesk/team_views` | O que cada grupo vê na fila, com colunas e ordenação |
| Área de trabalho | `staydesk/workspace` e `staydesk/team_workspaces/:team_id` | Menus, colunas, campos e painéis de quem atende |
| Papéis do agente | `staydesk/roles` e `staydesk/agent_roles/:user_id` | Permissões granulares e a quem cada papel está dado |
| Entrar como | `staydesk/impersonations` | Acompanhar o trabalho de um agente pela conta dele |
| Convites de atendimento | `staydesk/offers` | Convites pendentes de quem está atendendo |

`GET staydesk/ping` responde se a camada StayDesk está no ar, para monitoração.

## MCP

O servidor fica em `custom/mcp`. São 30 ferramentas: as de leitura acima e as de
configuração de filas, filas de carga, status, SLA, calendários, visualizações,
papéis, tokens de API e área de trabalho, além de conversas, times, caixas e
agentes do Chatwoot.

O recomendado é dar ao MCP um token de API com os escopos do que ele precisa, em
vez do token pessoal de alguém.

```sh
pnpm --dir custom/mcp install --ignore-workspace
```

```json
{
  "mcpServers": {
    "staydesk": {
      "command": "node",
      "args": ["/caminho/para/staydesk/custom/mcp/servidor.mjs"],
      "env": {
        "STAYDESK_URL": "https://staydesk.staycloud.com.br",
        "STAYDESK_TOKEN": "...",
        "STAYDESK_ACCOUNT_ID": "1"
      }
    }
  }
}
```

O catálogo de ferramentas é uma tabela em `custom/mcp/ferramentas.mjs`:
acrescentar um endpoint é acrescentar uma linha, sem escrever código. Detalhes em
`custom/mcp/README.md`.

## Configuração em arquivo

Fora da API, a operação inteira entra de uma vez por um YAML:

```sh
rails staydesk:configurar ACCOUNT_ID=1 FILE=configuracao.yml
```

O arquivo cobre times, etiquetas, atributos, caixas, status do ticket, filas de
carga, status do agente, calendário, políticas de SLA, filas, visualizações e
área de trabalho. É idempotente: rodar de novo só atualiza o que mudou.
