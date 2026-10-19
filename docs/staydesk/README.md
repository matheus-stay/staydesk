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
| [api-zendesk.md](api-zendesk.md) | A API compatível com o Zendesk que o dashboard consome: caminhos, formatos e de-para |
| [hub-e-central.md](hub-e-central.md) | Os dois espaços, a navegação e a área de trabalho do agente |
| [filas-e-distribuicao.md](filas-e-distribuicao.md) | Filas por canal com grupos principais e secundários, canais de trabalho, regras de capacidade, aceite e varredura, quem atende cada canal (calculado das filas) e diagnóstico da distribuição |
| [campos-do-ticket.md](campos-do-ticket.md) | Campos personalizados da conversa, a regra de obrigatório para resolver e onde mora o assunto do ticket |
| [status-do-ticket.md](status-do-ticket.md) | Catálogo de status por cima dos quatro do Chatwoot, status inicial e o que assume ao atribuir |
| [status-do-agente.md](status-do-agente.md) | O que cada status recebe, status liberados pelas filas, regras de capacidade, saída ao fechar a aba, tempo limite e tempo online |
| [sla.md](sla.md) | Motor de SLA próprio, calendário e alertas |
| [views-por-time.md](views-por-time.md) | Visualizações por grupo, o que cada um vê na fila |
| [area-de-trabalho.md](area-de-trabalho.md) | Menus, colunas, campos e painéis por time e por papel |
| [permissoes.md](permissoes.md) | Papéis com permissão granular e o agente leve |
| [kpis.md](kpis.md) | Os números que a Central mostra e de onde cada um sai |
| [tokens-de-api.md](tokens-de-api.md) | Chaves de integração com escopo de leitura e de escrita |
| [api-e-mcp.md](api-e-mcp.md) | Todos os endpoints e o servidor MCP. A referência navegável fica na Central, em Documentação da API |
| [agente-leve.md](agente-leve.md) | O papel que só lê e escreve nota interna |
| [api-de-eventos.md](api-de-eventos.md) | Linha do tempo das conversas para o dashboard |

## Como a camada é construída

| Documento | O que cobre |
|---|---|
| [guia-do-desenvolvedor.md](guia-do-desenvolvedor.md) | Para quem vai assumir o StayDesk: como está montado, como mexer e onde costuma doer |
| [camada-staydesk.md](camada-staydesk.md) | A convenção: o que pode tocar o núcleo e como |
| [chatwoot-diferencas.md](chatwoot-diferencas.md) | Tudo o que difere do Chatwoot e o que quebra se o upstream mudar |
| [atualizar-do-chatwoot.md](atualizar-do-chatwoot.md) | Como trazer atualizações e correções de segurança do Chatwoot |
| [core-touches.md](core-touches.md) | O registro de cada toque no núcleo, conferido pelo gate |
| [architecture-map.md](architecture-map.md) | Onde cada coisa mora |
| [marca.md](marca.md) | A marca no produto, o e-mail ao cliente e a varredura que confere |
| [edicao-community.md](edicao-community.md) | O que é Enterprise e por que construímos por fora |
| [runbook-local.md](runbook-local.md) | Subir, popular e conferir o ambiente local; testes, gate e sync com o oficial |

## Histórico do projeto

[arquivo/](arquivo/README.md) guarda o planejamento de agosto e setembro de 2026
(brief, análise de lacunas, QA do Zendesk, épicos, histórias, handoffs de
design). Serve de contexto; não reflete o produto atual.

## Configurar a operação de uma vez

A operação inteira entra por um arquivo, sem clicar em tela:

```sh
rails staydesk:configurar ACCOUNT_ID=1 FILE=configuracao.yml
```

Cobre a conta (`conta`: o painel do cliente), times, etiquetas, campos do ticket
(com `obrigatorio_para_resolver`), caixas, status do ticket, filas de carga
(canais de trabalho), status do agente, regras de capacidade
(`regras_de_capacidade`), calendário, políticas de SLA, filas, gatilhos
(`automacoes`), macros (`macros`), visualizações e área de trabalho. É
idempotente: rodar de novo só atualiza o que mudou. Detalhes de cada seção em
[api-e-mcp.md](api-e-mcp.md#configuração-em-arquivo).

O mesmo arquivo entra pela API, sem console, com o token de um administrador:

```sh
curl -X POST -H "api_access_token: sd_seu_token" -H "Content-Type: application/json" \
  --data "$(jq -Rs '{yaml: .}' configuracao.yml)" \
  "https://staydesk.staycloud.com.br/api/v1/accounts/1/staydesk/config_import"
```

Para ver as telas com dados, `rails staydesk:demo RESET=1` popula a conta, e
`rails staydesk:demo SOMENTE=historico` só acrescenta o histórico dos clientes.
