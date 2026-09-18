# Filas e distribuição

A operação é por **grupo**, nunca por canal. Todo chat nasce no grupo de primeiro
nível; todo ticket nasce no de segundo. O canal não decide o grupo: decide o que
o agente recebe, pelo status dele.

## Fila de encaminhamento

Uma fila diz **para qual grupo** a demanda vai e **quem pode ajudar** quando o
grupo dono não dá conta. Fica em Central › Atendimento › Filas.

| Campo | O que faz |
|---|---|
| Time | O grupo dono. A conversa fica com ele e não troca |
| Canais | Quais canais entram nesta fila. Vazio é "todos" |
| Caixas de entrada | Caixas específicas, para quando o canal não basta. A caixa vence o canal |
| Condições | Afinam o resto (etiqueta, prioridade, campo do ticket). Opcional |
| Times de transbordo | Quem entra na distribuição além do dono |
| Modo | `sempre` (trabalham a fila junto) ou `quando_faltar` (só quando não há ninguém do dono) |
| Espera | Minutos antes de liberar o transbordo, no modo `quando_faltar` |
| Prioridade | Em que ordem a fila entrega: `chegada` (mais antigo primeiro) ou `sla` (mais perto de vencer primeiro) |
| Aceite | Se o agente precisa aceitar antes de a conversa virar dele |
| Tempo para aceitar | Segundos até a conversa voltar para a fila |

A entrada se configura por **canal** e por **caixa**, que é como a operação
pensa: "chat e WhatsApp caem no N1, e-mail cai no N2". Deixar os dois vazios faz
a fila recolher o que as filas acima não pegaram. As condições avançadas ficam
para o que o canal não resolve, como etiqueta, prioridade ou campo do ticket.

A ordem importa: a primeira fila que casar leva. A conversa recebe o grupo na
criação e, se entrou sem grupo, a varredura a encaminha depois.

**Transbordo não troca o grupo.** O que muda é quem pode pegar. O caso continua
sendo do dono, e é isso que mantém o relatório por grupo honesto.

## Filas de carga

São outra coisa, e o nome parecido confunde. A **fila de encaminhamento** decide
o grupo dono do trabalho. A **fila de carga** decide em qual balde a conversa
conta para o limite do agente. Ficam em Central › Atendimento › Filas de carga.

Quantas conversas simultâneas o agente aguenta é contado **por fila de carga**, e
é a caixa que diz de qual fila a conversa é.

```yaml
filas_de_carga:
  - { chave: chat, nome: Chat e WhatsApp, coringa: true, canais: [] }
  - { chave: ticket, nome: Tickets, canais: ['Channel::Email'], caixas: ['WHMCS'] }
```

Uma fila reivindica **canais** e **caixas**; a caixa vence o canal, porque o
mesmo tipo de canal serve a coisas diferentes (a API atende tanto WhatsApp quanto
chamado aberto por integração). A fila marcada como coringa fica com o que
ninguém reivindicou. Sem nenhuma configurada, vale o padrão: chat pega tudo,
e-mail é ticket.

Os limites de cada fila moram no [status do agente](status-do-agente.md): o
status "Só chat" pode ter 6 de chat e 0 de ticket, e aí a distribuição não
entrega ticket para quem está nele.

## Quem pode receber agora

A conta é, nesta ordem:

1. Quem é membro da caixa.
2. Quem está **conectado de verdade**, não só marcado como online no banco.
3. Quem ainda tem vaga na fila de carga daquela caixa, pelo status atual.
4. Quem é do grupo dono. Faltando gente, entram os grupos de transbordo conforme
   o modo e a espera da fila.

O passo 2 existe porque sem ele o grupo dono parece cheio de gente, o transbordo
nunca abre e a conversa espera por quem não está atendendo.

Quando alguém "coloca online e não cai nada", a resposta está em Central › Status
dos agentes › **Quem recebe o quê**: para cada agente e cada fila, se a
distribuição entrega e, se não, qual condição falta (conexão, status, vaga,
grupo ou caixa). Pela API é `GET staydesk/distribution_checks`. Nove em dez vezes
é grupo ou caixa: o agente precisa estar no grupo dono da fila, ou num grupo que
ajuda, **e** ser membro de uma caixa que a fila pega.

## Aceite

Chat e WhatsApp são **oferecidos**: a conversa é atribuída, o agente recebe o
convite na tela e tem o tempo da fila para aceitar. Sem resposta, a conversa
volta para a fila e é oferecida a outro agente disponível, sem o que recusou.
Ticket normalmente não passa por aceite.

A aceitação vira número: Central › Status dos agentes mostra, por agente, quantos
convites recebeu, aceitou, recusou, deixou expirar e em quanto tempo respondeu.

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
| `POST/PATCH/DELETE staydesk/queues` | Cria, altera e remove |
| `GET staydesk/load_queues` | Lista as filas de carga |
| `PATCH staydesk/load_queues/:id` | Altera canais e caixas de uma fila de carga |
| `GET staydesk/agent_loads` | Carga de cada agente agora, contra o limite |
| `GET staydesk/offers` | Convites pendentes de quem está atendendo |
| `GET staydesk/offer_stats` | Aceitação por agente no período |
