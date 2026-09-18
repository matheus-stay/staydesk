# Permissões

O Chatwoot community tem dois papéis: administrador e agente. A operação precisa
de mais: quem atende, quem coordena, quem só vê os próprios números, quem
configura uma área sem ser dono da conta.

## Papéis

Em **Central › Pessoas › Papéis dos agentes** se cria um papel, marcam-se as
permissões e ele se dá a quem for. Dá para conceder e revogar a qualquer momento,
sem mexer no papel do Chatwoot.

| Permissão | O que abre |
|---|---|
| `report_manage` | Relatórios de todo o time |
| `staydesk_report_own` | Só os próprios números |
| `staydesk_settings_manage` | Toda a configuração da Central |
| `staydesk_queues_manage` | Filas e transbordo |
| `staydesk_sla_manage` | Políticas de SLA e calendários |
| `staydesk_statuses_manage` | Status do ticket e do agente |
| `staydesk_views_manage` | Visualizações e área de trabalho |
| `staydesk_roles_manage` | Papéis, tokens de API e entrar como outro agente |
| `staydesk_light` | Agente leve: lê e só escreve nota interna |

O catálogo é `custom/config/permissions.json`. Acrescentar uma permissão é
acrescentar uma linha, com a `area` que ela abre.

## Como a permissão vale

Em três lugares, e os três precisam concordar:

1. **A rota** da tela, que decide se a página abre.
2. **A policy** no servidor, que decide se o pedido passa. Toda policy de área
   pergunta por `Staydesk::AreaDeConfiguracao`: administrador, ou a permissão
   geral de configurar, ou a permissão daquela área.
3. **O menu**, que só mostra o que a pessoa alcança.

Esconder na tela nunca é a única barreira: o servidor barra do mesmo jeito.

## Agente leve

O agente leve lê as conversas dos times e caixas dele e só escreve nota interna.
A lista do que ele pode escrever está no guarda da aplicação. Detalhes em
[agente-leve.md](agente-leve.md).

## Entrar como

Quem tem a permissão de papéis pode entrar na conta de um agente para acompanhar
o trabalho dele. A sessão vale cinco minutos e fica registrada: quem entrou, em
quem e quando.

## Tokens de API

Integração tem escopo próprio, que estreita o que o token alcança sem mudar o
papel de ninguém. Ver [tokens-de-api.md](tokens-de-api.md).
