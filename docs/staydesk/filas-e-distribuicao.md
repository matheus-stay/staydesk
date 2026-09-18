# Filas e distribuição

A fila é por **canal**: o que entra por chat e WhatsApp vai para uns grupos, o
que entra por e-mail e WHMCS vai para outros. Dentro do grupo, o que cada agente
recebe é decidido pelo status dele.

## Fila de encaminhamento

Uma fila diz **o que entra** nela (canal, caixa, condições) e **para quais
grupos** vai: primeiro os principais; sem ninguém disponível neles, os
secundários. É o desenho das filas de encaminhamento omnichannel do Zendesk.
Fica em Central › Atendimento › Filas.

| Campo | O que faz |
|---|---|
| Grupos principais | Quem recebe primeiro. A conversa entra no primeiro da lista e, quando alguém pega, fica no grupo desse agente |
| Canais | Um campo só: o canal de trabalho pelo nome ("Chat e WhatsApp"), o tipo inteiro ("Todo WhatsApp") ou canais específicos (o número StayCloud WPP). Vazio é "todos" |
| Condições | Afinam o resto (etiqueta, prioridade, campo do ticket). Opcional |
| Grupos secundários | Só entram quando nenhum principal tem alguém disponível. Opcional |
| Espera | Minutos sem ninguém disponível nos principais antes de os secundários entrarem. Em branco, na hora |
| Prioridade | Em que ordem a fila entrega: `chegada` (mais antigo primeiro) ou `sla` (mais perto de vencer primeiro) |
| Aceite | Se o agente precisa aceitar antes de a conversa virar dele |
| Tempo para aceitar | Segundos até a conversa voltar para a fila |

A entrada se configura num campo só de **canais**: o canal de trabalho pelo
nome ("Chat e WhatsApp" junta chat do site e WhatsApp, que é como o N1 pensa),
o tipo inteiro ou o canal específico, como a fila do Zendesk (*Canal é
WhatsApp*, *Nome do canal é StayCloud WPP*). No arquivo: `canais_de_trabalho`,
`canais` e `caixas`. Deixar os dois
vazios faz a fila recolher o que as filas acima não pegaram. As condições avançadas ficam
para o que o canal não resolve, como etiqueta, prioridade ou campo do ticket.

A ordem importa: a primeira fila que casar leva. A conversa recebe o grupo na
criação e, se entrou sem grupo, a varredura a encaminha depois.

**A conversa fica no grupo de quem pegou**, como no Zendesk. Ela entra no
primeiro grupo principal; se quem a recebeu é de outro principal ou de um
secundário, passa para o grupo dele. Quem já está no grupo em que ela entrou não
muda nada. Assim o relatório por grupo mostra quem de fato atendeu.

Vários grupos principais é o jeito de dois grupos trabalharem a mesma fila
juntos (o N3 que pega ticket do N2 no tempo livre); grupo secundário é o
transbordo clássico, para quando o principal está sem gente. O canal que cada
agente recebe continua vindo do status dele: um agente do N2 em "Só tickets" não
recebe chat mesmo que o N2 seja principal da fila de chat.

## Canais de trabalho

São outra coisa, e vale separar. A **fila de encaminhamento** decide para quais
grupos o trabalho vai. O **canal de trabalho** decide se a conversa é chat ou
ticket: é a caixa (ou o tipo de canal) que diz. É por canal de trabalho que o
status do agente diz o que ele recebe e a regra de capacidade diz quanto, como
os canais Mensagens e E-mail do Zendesk. Ficam em Central › Distribuição de
trabalho › Canais de trabalho; na API e no arquivo continuam sendo
`load_queues` / `filas_de_carga`.

| Campo | O que faz |
|---|---|
| Chave | `chat`, `ticket`, o que a operação definir. É o que aparece no status e na regra de capacidade |
| Canais | O tipo inteiro ou canais específicos, no mesmo campo. O canal específico vence o tipo |
| Pega o que sobrar | O coringa: fica com os canais que nenhum outro pegou |

Sem nenhum configurado, vale o padrão do produto: chat pega tudo e e-mail é
ticket.

## Regras de capacidade

Quantas conversas de cada canal de trabalho o agente aguenta ao mesmo tempo,
como no Zendesk: uma regra **padrão** da conta e regras **atribuídas a
agentes** (cada agente tem uma só; entrar numa tira das outras). Chave ausente é
sem limite; zero é não receber. Ficam em Central › Distribuição de trabalho ›
Regras de capacidade; API `staydesk/capacity_rules`; no arquivo, a seção
`regras_de_capacidade`.

A conta é: o agente recebe uma conversa se o **status** dele recebe aquele canal,
a **regra de capacidade** dele ainda tem vaga nesse canal, ele está num **grupo**
da fila (principal, ou secundário liberado), é **membro da caixa** e está
**conectado**. Grupo decide de quem é o trabalho; status decide que tipo ele
pega agora; capacidade decide quanto.

## Canal, não caixa

O Chatwoot chama de **caixa de entrada** cada instância de canal (o número do
WhatsApp, o e-mail do suporte, o chat do site) e exige que o agente seja
**membro** dela para receber e enxergar conversas. O Zendesk não tem isso: quem
está no grupo atende o canal que a fila mandar. O StayDesk segue o Zendesk:

- Na tela tudo se chama **canal**: a lista de canais fica agrupada por tipo em
  Central › Canais, e nas filas e canais de trabalho há um campo só, *Canais*,
  com o tipo inteiro e cada canal.
- **Todo agente atende todos os canais**, sempre. Agente novo entra em todos;
  canal novo nasce com todos (`Staydesk::ChannelMembership`, ganchos em
  `AccountUser` e `Inbox`; a importação e uma migração fecham o que faltava). A
  aba "Colaboradores" da caixa some.
- Quem recebe o quê é grupo + status + capacidade + conexão. O que o agente vê é
  das visualizações por grupo e dos papéis.

Na API e no arquivo de configuração os nomes do Chatwoot continuam (`inbox_ids`,
`caixas`), porque são ids e nomes de canal específico.

## Quem pode receber agora

A conta é, nesta ordem:

1. Quem está no canal (todo agente está em todos, ver abaixo).
2. Quem está **conectado de verdade**, não só marcado como online no banco.
3. Quem está num status que **recebe** o canal de trabalho daquela caixa.
4. Quem ainda tem vaga nesse canal pela **regra de capacidade** dele.
5. Quem é de um grupo principal da fila. Faltando gente, entram os grupos
   secundários, depois da espera configurada.

O passo 2 existe porque sem ele o grupo principal parece cheio de gente, os
secundários nunca entram e a conversa espera por quem não está atendendo.

Quando alguém "coloca online e não cai nada", a resposta está em Central ›
Distribuição de trabalho › Status dos agentes › **Quem recebe o quê**: para cada
agente e cada fila, se a distribuição entrega e, se não, qual condição falta
(conexão, status, canal de trabalho, vaga ou grupo). Pela API é `GET staydesk/distribution_checks`. Nove em dez vezes
é grupo: o agente precisa estar num grupo principal ou secundário da fila.

## Aceite

Chat, WhatsApp e ticket podem ser **oferecidos**, por fila: a distribuição
escolhe o agente do mesmo jeito (rodízio entre quem está no grupo, no status
certo, com vaga e conectado), mas em vez de atribuir, **convida**. A conversa
fica na fila, sem responsável, com a vaga do agente reservada; o convite aparece
na tela dele com relógio, som e aviso do navegador; **aceitar é o que atribui**
(e é aí que o status vai para "em andamento"). Recusar ou deixar vencer manda
para o próximo disponível, sem quem não pegou.

Regras da fila, todas configuráveis: `exige aceite`, `tempo para aceitar`, e o
que fazer quando não há mais ninguém — `oferecer de novo ao mesmo agente` (na
hora ou depois de N segundos) ou deixar na fila. Atribuição manual não passa por
convite.

A aceitação vira número: Central › Status dos agentes mostra, por agente, quantos
convites recebeu, aceitou, recusou, deixou vencer e em quanto tempo respondeu.
A taxa é aceitos sobre oferecidos; cada convite vencido ou recusado conta contra
o agente, inclusive quando a mesma conversa volta para ele.

## Varredura da fila

O Chatwoot só distribui quando a conversa nasce ou recebe mensagem. Quem entrou
antes de o agente ficar disponível ficaria esperando para sempre.

A varredura (`Staydesk::Queues::SweepJob`) roda **a cada minuto** e **assim que
alguém muda de status**. Ela pega o que está aberto e sem responsável, encaminha
quem ficou sem grupo e chama a distribuição, na ordem que cada fila manda: fila
de cima primeiro; dentro dela, `chegada` entrega o mais antigo e `sla` entrega
quem está mais perto de vencer, olhando a métrica ainda aberta mais próxima.
Um urgente que acabou de entrar com 5 minutos de alvo passa na frente de um
antigo a que faltam 10. Como a
elegibilidade já considera transbordo e espera, a mesma varredura resolve o
transbordo por tempo.

## Endpoints

| Endpoint | O que faz |
|---|---|
| `GET staydesk/queues` | Lista as filas de encaminhamento |
| `staydesk/capacity_rules` | Regras de capacidade (CRUD) |
| `POST/PATCH/DELETE staydesk/queues` | Cria, altera e remove |
| `GET staydesk/load_queues` | Lista as filas de carga |
| `PATCH staydesk/load_queues/:id` | Altera canais e caixas de uma fila de carga |
| `GET staydesk/agent_loads` | Carga de cada agente agora, contra o limite |
| `GET staydesk/offers` | Convites pendentes de quem está atendendo |
| `GET staydesk/offer_stats` | Aceitação por agente no período |
