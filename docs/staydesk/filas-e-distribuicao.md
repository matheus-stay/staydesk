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
| Condições | Quando a fila casa. Sem condição, pega o que sobrar |
| Times de transbordo | Quem entra na distribuição além do dono |
| Modo | `sempre` (trabalham a fila junto) ou `quando_faltar` (só quando não há ninguém do dono) |
| Espera | Minutos antes de liberar o transbordo, no modo `quando_faltar` |
| Aceite | Se o agente precisa aceitar antes de a conversa virar dele |
| Tempo para aceitar | Segundos até a conversa voltar para a fila |

A ordem importa: a primeira fila que casar leva. A conversa recebe o grupo na
criação e, se entrou sem grupo, a varredura a encaminha depois.

**Transbordo não troca o grupo.** O que muda é quem pode pegar. O caso continua
sendo do dono, e é isso que mantém o relatório por grupo honesto.

## Filas de carga

Quantas conversas simultâneas o agente aguenta é contado **por fila de carga**, e
é a caixa que diz de qual fila a conversa é. O mapa é da operação, não do
produto: fica em Central e entra pelo arquivo de configuração.

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
alguém muda de status**. Ela pega o que está aberto e sem responsável, mais
antigo primeiro, encaminha quem ficou sem grupo e chama a distribuição. Como a
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
