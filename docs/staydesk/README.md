# StayDesk

O StayDesk é o Chatwoot com a camada da StayCloud por cima: o que a operação de
suporte precisa e o community não tem. Backend em `custom/`, frontend em
`app/javascript/staydesk/`, e o núcleo tocado só nos quatro jeitos que
`camada-staydesk.md` descreve, registrados em `core-touches.md`.

O produto tem dois espaços, com nome próprio:

- **Hub** — onde se atende. Tickets, chat e WhatsApp, pelas visualizações.
- **Central** — onde se administra e se acompanha. Configuração e relatórios, em
  aba própria, com navegação própria.

## Por onde começar

| Documento | O que cobre |
|---|---|
| [hub-e-central.md](hub-e-central.md) | Os dois espaços, a navegação e a área de trabalho do agente |
| [filas-e-distribuicao.md](filas-e-distribuicao.md) | Filas de encaminhamento por canal e grupo, filas de carga, transbordo, aceite e varredura |
| [campos-do-ticket.md](campos-do-ticket.md) | Campos personalizados da conversa e a regra de obrigatório para resolver |
| [status-do-ticket.md](status-do-ticket.md) | Catálogo de status por cima dos quatro do Chatwoot |
| [status-do-agente.md](status-do-agente.md) | Disponibilidade e limite de conversas simultâneas |
| [sla.md](sla.md) | Motor de SLA próprio, calendário e alertas |
| [views-por-time.md](views-por-time.md) | Visualizações por grupo, o que cada um vê na fila |
| [area-de-trabalho.md](area-de-trabalho.md) | Menus, colunas, campos e painéis por time e por papel |
| [permissoes.md](permissoes.md) | Papéis com permissão granular e o agente leve |
| [kpis.md](kpis.md) | Os números que a Central mostra e de onde cada um sai |
| [tokens-de-api.md](tokens-de-api.md) | Chaves de integração com escopo de leitura e de escrita |
| [api-e-mcp.md](api-e-mcp.md) | Todos os endpoints e o servidor MCP |
| [agente-leve.md](agente-leve.md) | O papel que só lê e escreve nota interna |
| [api-de-eventos.md](api-de-eventos.md) | Linha do tempo das conversas para o dashboard |

## Como a camada é construída

| Documento | O que cobre |
|---|---|
| [camada-staydesk.md](camada-staydesk.md) | A convenção: o que pode tocar o núcleo e como |
| [core-touches.md](core-touches.md) | O registro de cada toque no núcleo, conferido pelo gate |
| [architecture-map.md](architecture-map.md) | Onde cada coisa mora |
| [marca.md](marca.md) | A marca no produto e a varredura que confere |
| [edicao-community.md](edicao-community.md) | O que é Enterprise e por que construímos por fora |
| [runbook-local.md](runbook-local.md) | Subir, popular e conferir o ambiente local |

## Configurar a operação de uma vez

A operação inteira entra por um arquivo, sem clicar em tela:

```sh
rails staydesk:configurar ACCOUNT_ID=1 FILE=configuracao.yml
```

Cobre times, etiquetas, campos do ticket, caixas, status do ticket, filas de
carga, status do agente, calendário, políticas de SLA, filas, visualizações e
área de trabalho. É idempotente: rodar de novo só atualiza o que mudou.

Para ver as telas com dados, `rails staydesk:demo RESET=1` popula a conta, e
`rails staydesk:demo SOMENTE=historico` só acrescenta o histórico dos clientes.
