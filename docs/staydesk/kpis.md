# Os números da operação

O StayDesk calcula os indicadores **no servidor**, não na tela. A Central, o
dashboard e o MCP leem a mesma conta, então número de reunião não diverge de
número de relatório.

Tudo sai de `GET staydesk/kpis`, que aceita `since` e `until` em ISO 8601. Sem
período, são os últimos 7 dias.

## Recortes e comparação

| Parâmetro | O que faz |
|---|---|
| `user_id` | Só o que é daquele agente |
| `load_queue` | Só as caixas daquele canal de trabalho, pela chave (`chat`, `ticket`) |
| `team_id` | Só as conversas daquele grupo |
| `compare=1` | Traz também o período anterior, de mesma duração, em `anterior` |

A janela vai até 366 dias; pedido maior é cortado no começo. Cada número
respeita o recorte que faz sentido para ele: a fila de espera, por exemplo, não
tem agente. O `anterior` traz só o que se compara (CSAT, tempos, tempo online,
aceitação, volumes e SLA), sem a fila, que é "agora", e sem a lista de agentes.

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
e `amostras`, que é quantos casos entraram na média. Traz também
`mediana_segundos` e `p90_segundos`, porque a média engana quando um ticket
velho entra na conta.

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
| `resolvidas` | Quantas o agente resolveu no período |
| `primeira_resposta_segundos`, `resolucao_segundos` | Tempos médios dele |

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

### Volumes e FCR

`volumes`, com os mesmos recortes:

| Campo | O que é |
|---|---|
| `criadas` | Conversas criadas no período |
| `resolvidas` | Resoluções no período |
| `abertas_agora` | O que está aberto, pendente ou adiado agora, sem olhar a data de criação: a fila real |
| `esperando_suporte` | Das abertas agora, as que estão com o status base aberto |
| `vencidas_agora` | Das abertas agora, quantas já estouraram algum prazo de SLA |
| `reabertas` | Quantas voltaram de resolvida para aberta no período |
| `fcr_percentual`, `fcr_base` | Resolução no primeiro contato e sobre quantas resolvidas foi calculada |

A régua do **FCR**: entre as conversas resolvidas no período, resolveu de
primeira a que teve no máximo uma resposta pública do agente e nunca foi
reaberta.

### SLA

`sla`: o percentual dentro do prazo de primeira resposta e de resolução,
cada um com a `base`. Entram só as conversas que tiveram aquele prazo e já
foram atendidas; quem ainda não respondeu não conta nem a favor nem contra.

### Série por dia

`por_dia`: para cada dia da janela, `criadas`, `resolvidas` e
`csat_respostas`. É o que desenha a tendência.

### Por campo do ticket

`por_campo`: para cada campo de conversa do tipo **lista** (Tipo de Demanda,
Tipo de Produto, Classificação…), quantos tickets **criados no período** há
por valor. Respeita os recortes de canal e grupo. É o número que hoje sai das
views e relatórios do Zendesk.

```json
{
  "tipo_de_demanda": {
    "nome": "Tipo de Demanda",
    "total": 120,
    "valores": { "Financeiro": 50, "Técnico": 40, "sem_valor": 30 }
  }
}
```

`total` é o de tickets criados no período com o recorte; `sem_valor` é quem não
tem o campo preenchido. Só pela API: a tela de indicadores não mostra.

### Tempo online médio

`resumo_dos_agentes` é o KPI da equipe: quantos agentes tiveram tempo online no
período, a média do tempo online entre eles e a média por dia trabalhado. Cada
status diz se conta ou não: "Disponível" e "Só chat" contam, "Reunião" e
"Almoço" não, e isso se marca na tela de status.

## Onde aparece

Central › Relatórios › **Indicadores da operação** mostra tudo isto, com o
período escolhido (7, 30 ou 90 dias), filtro por canal de trabalho e por grupo
e a chave **comparar** (o período anterior, ligada por padrão): os cartões, os
tempos por canal de trabalho, e a tabela de agentes com tempo online, aceitação
e CSAT. A home da
Central repete os cartões.

Central › Início mostra CSAT, quantos esperam na fila, quantos agentes estão
online e a primeira resposta de cada fila, com um seletor de 7, 30 ou 90 dias, e
a tabela de tempo por agente.

## Outros números

| Endpoint | O que traz |
|---|---|
| `GET staydesk/agent_loads` | Carga de cada agente agora contra o teto da regra de capacidade (zero se o status atual não recebe o canal) |
| `GET staydesk/offer_stats` | Aceitação de chat e WhatsApp por agente |
| `GET staydesk/events` | Linha do tempo das conversas, para o dashboard reconstruir o que quiser |
| `GET staydesk/applied_slas` | SLA por conversa, com alvo, status e vencimento |
| `GET staydesk/agent_status_periods` | Os períodos crus de status, para quem quiser recalcular |
