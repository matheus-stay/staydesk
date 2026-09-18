# API e MCP do StayDesk

Tudo que a Central configura e mostra tem endpoint próprio, sob
`/api/v1/accounts/:account_id/staydesk/`. O MCP em `custom/mcp` fala com esses
mesmos endpoints, então tela, dashboard e agente de IA leem a mesma conta.

## Autenticação

Cabeçalho `api_access_token` com o token do usuário. O token sai do perfil da
pessoa no produto. O que o token pode fazer é o que o papel dela permite: a API
passa pelas mesmas policies da tela, e o MCP não contorna nenhuma.

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

O servidor fica em `custom/mcp`. São 27 ferramentas: as de leitura acima e as de
configuração de filas, filas de carga, status, SLA, calendários, visualizações,
papéis e área de trabalho, além de conversas, times, caixas e agentes do
Chatwoot.

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
