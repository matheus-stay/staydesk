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

Nove grupos, cada um com `leitura` e `escrita`: `conversas`, `contatos`,
`relatorios`, `operacao`, `canais`, `equipe`, `automacao`, `central_de_ajuda` e
`conta`. O que cada um cobre, e como acrescentar, está em
[tokens-de-api.md](tokens-de-api.md).

```sh
curl -H "api_access_token: sd_..." \
  "https://staydesk.staycloud.com.br/api/v1/accounts/1/staydesk/kpis"
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
| Campos do ticket | `staydesk/ticket_fields` e `custom_attribute_definitions` | Catálogo de campos e a marcação de obrigatório para resolver |
| Campos de uma conversa | `staydesk/conversations/:numero/ticket_fields` | Lê os valores e o que falta para resolver; `PATCH` preenche |

`GET staydesk/ping` responde se a camada StayDesk está no ar, para monitoração.

## MCP

O servidor fica em `custom/mcp`. São 35 ferramentas, a mesma API por baixo.

| Ferramenta | O que faz |
|---|---|
| `staydesk_kpis` | Números da operação no período: CSAT, tempos de primeira resposta e resolução por fila, quem espera na fila e o tempo de cada agente em cada status. |
| `staydesk_filas_listar` | Filas de encaminhamento: para qual grupo cada demanda vai, transbordo e aceite. |
| `staydesk_filas_criar` | Cria uma fila de encaminhamento. |
| `staydesk_filas_atualizar` | Altera uma fila de encaminhamento. |
| `staydesk_filas_de_carga_listar` | Filas de carga: que canal e que caixa contam como chat e como ticket. |
| `staydesk_filas_de_carga_atualizar` | Altera uma fila de carga. |
| `staydesk_status_do_ticket_listar` | Catálogo de status do ticket da conta. |
| `staydesk_status_do_ticket_criar` | Cria um status de ticket. |
| `staydesk_status_do_ticket_atualizar` | Altera um status de ticket. |
| `staydesk_status_do_agente_listar` | Status de disponibilidade do agente e a carga de cada um. |
| `staydesk_status_do_agente_criar` | Cria um status de agente. |
| `staydesk_status_do_agente_atualizar` | Altera um status de agente. |
| `staydesk_carga_dos_agentes` | Quantas conversas cada agente atende agora em cada fila, contra o limite do status dele. |
| `staydesk_politicas_de_sla_listar` | Políticas de SLA: alvos por prioridade, pausa e aviso. |
| `staydesk_politicas_de_sla_criar` | Cria uma política de SLA. |
| `staydesk_calendarios_listar` | Calendários de horário comercial e feriados. |
| `staydesk_visualizacoes_listar` | Visualizações por time: o que cada grupo vê na fila. |
| `staydesk_papeis_listar` | Papéis com permissões granulares e o catálogo de permissões disponível. |
| `staydesk_papeis_criar` | Cria um papel de agente. |
| `staydesk_area_de_trabalho` | Área de trabalho resolvida para quem chama: menus, colunas da lista, campos e painéis da conversa. |
| `staydesk_aceitacao_dos_agentes` | Aceitação de chat e WhatsApp por agente: quantos convites recebeu, aceitou, recusou e deixou expirar. |
| `staydesk_eventos_das_conversas` | Linha do tempo das conversas: mudanças de status, de responsável, de grupo e de prioridade. |
| `staydesk_slas_aplicados` | SLA aplicado a cada conversa, com alvo, status e quando vence. |
| `staydesk_conversas` | Conversas da conta, com os filtros da API do Chatwoot (status, inbox_id, team_id, assignee_type, page). |
| `staydesk_campos_do_ticket_listar` | Catálogo de campos do ticket da conta, com tipo, valores da lista e quais são obrigatórios para resolver. |
| `staydesk_campos_do_ticket_criar` | Cria um campo do ticket. `attribute_display_type` aceita text, number, currency, percent, link, date, list e checkbox; `attribute_values` são as opções quando for lista. |
| `staydesk_campos_do_ticket_atualizar` | Altera um campo do ticket, inclusive marcar ou desmarcar como obrigatório para resolver. |
| `staydesk_campos_da_conversa` | Campos do ticket de uma conversa, com o valor de cada um e a lista do que falta preencher para poder resolver. |
| `staydesk_campos_da_conversa_preencher` | Preenche campos do ticket numa conversa. Manda só o que quer mudar; o resto fica como está. |
| `staydesk_tokens_de_api_listar` | Tokens de API da conta, com os escopos de cada um e o catálogo de escopos possíveis. |
| `staydesk_tokens_de_api_criar` | Cria um token de API com escopo próprio. O valor em claro volta uma única vez nesta resposta. |
| `staydesk_tokens_de_api_atualizar` | Suspende ou reativa um token de API. |
| `staydesk_times_listar` | Grupos da conta. |
| `staydesk_caixas_listar` | Caixas de entrada da conta, com o tipo de canal de cada uma. |
| `staydesk_agentes_listar` | Agentes da conta e o papel de cada um. |

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
