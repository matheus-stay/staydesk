# Os números da operação

O StayDesk calcula os indicadores **no servidor**, não na tela. A Central, o
dashboard e o MCP leem a mesma conta, então número de reunião não diverge de
número de relatório.

Tudo sai de `GET staydesk/kpis`, que aceita `since` e `until` em ISO 8601. Sem
período, são os últimos 7 dias.

## O que vem

### CSAT

Da pesquisa de satisfação do produto, no período.

| Campo | O que é |
|---|---|
| `respostas` | Quantas pessoas responderam |
| `satisfeitos` | Notas 4 e 5 |
| `neutros` | Nota 3 |
| `insatisfeitos` | Notas 1 e 2 |
| `percentual` | Satisfeitos sobre o total |
| `media` | Média das notas |
| `por_agente` | O mesmo recorte por responsável da conversa |

A régua de "satisfeito é 4 ou 5" é a da operação.

### Tempos, por canal de trabalho

Chat e ticket não se comparam, então os tempos vêm separados pela
[canal de trabalho](filas-e-distribuicao.md) da caixa:

| Métrica | O que mede |
|---|---|
| `primeira_resposta` | Da abertura até a primeira resposta do agente |
| `resposta` | Entre a mensagem do cliente e a resposta seguinte |
| `resolucao` | Da abertura até a conversa ser resolvida |

Cada uma traz `segundos`, `segundos_no_horario` (só dentro do horário comercial)
e `amostras`, que é quantos casos entraram na média.

### Fila

`total` de conversas abertas sem responsável, `por_fila` separando chat de
ticket, e `espera_mais_antiga_em_segundos`, que é o caso mais velho parado.

### Agentes

Para cada pessoa da conta:

| Campo | O que é |
|---|---|
| `status_atual` | O status do agente agora |
| `online` | Se tem conexão viva neste momento |
| `segundos_por_status` | Tempo em cada status, dentro da janela pedida |
| `segundos_disponivel` | Soma do tempo nos status que atendem |
| `segundos_no_periodo` | Tempo total com algum status |

Período que começou antes da janela entra só pelo pedaço que cai dentro dela, e
período aberto conta até agora. `segundos_online` soma só os status marcados
como "contabiliza tempo online", e `media_diaria_online_segundos` divide pelos
dias em que houve algum tempo online.

### Aceitação

`aceitacao`: convites oferecidos, aceitos, recusados, vencidos e o percentual
(aceitos sobre oferecidos), no total do período; cada agente traz os dele e o
tempo médio para aceitar. Convite vencido ou recusado conta contra o agente,
inclusive quando a mesma conversa volta para ele. Cada agente traz também o
CSAT dele (`csat_respostas`, `csat_percentual`).

### Tempo online médio

`resumo_dos_agentes` é o KPI da equipe: quantos agentes tiveram tempo online no
período, a média do tempo online entre eles e a média por dia trabalhado. Cada
status diz se conta ou não: "Disponível" e "Só chat" contam, "Reunião" e
"Almoço" não, e isso se marca na tela de status.

## Onde aparece

Central › Relatórios › **Indicadores da operação** mostra tudo isto, com o
período escolhido (7, 30 ou 90 dias): os cartões, os tempos por canal de
trabalho, e a tabela de agentes com tempo online, aceitação e CSAT. A home da
Central repete os cartões.

Central › Início mostra CSAT, quantos esperam na fila, quantos agentes estão
online e a primeira resposta de cada fila, com um seletor de 7, 30 ou 90 dias, e
a tabela de tempo por agente.

## Outros números

| Endpoint | O que traz |
|---|---|
| `GET staydesk/agent_loads` | Carga de cada agente agora contra o limite do status |
| `GET staydesk/offer_stats` | Aceitação de chat e WhatsApp por agente |
| `GET staydesk/events` | Linha do tempo das conversas, para o dashboard reconstruir o que quiser |
| `GET staydesk/applied_slas` | SLA por conversa, com alvo, status e vencimento |
| `GET staydesk/agent_status_periods` | Os períodos crus de status, para quem quiser recalcular |
