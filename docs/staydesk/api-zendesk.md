# API compatível com o Zendesk (para o dashboard)

O dashboard da casa popula o banco dele lendo a API do Zendesk. Para a troca
não exigir reescrever o sync, o StayDesk expõe **os mesmos caminhos e formatos**
dos endpoints que ele consome, sobre as conversas do Chatwoot:

```
URL base:  https://<staydesk>/staydesk/zendesk
Caminhos:  os do Zendesk, a partir daí (/api/v2/...)
Auth:      Basic  email/token:<TOKEN>   (como o Zendesk)  ou  cabeçalho api_access_token
TOKEN:     um token de API do StayDesk (Central › Pessoas › Tokens de API), com os
           escopos relatorios:leitura, conversas:leitura e conversas:escrita
```

No cliente do dashboard basta trocar a URL base (hoje derivada do subdomínio) e
a credencial. Token de usuário do produto também serve; nesse caso a conta é a
primeira do usuário, ou a do cabeçalho `X-Account-Id`.

| Endpoint | O que sai |
|---|---|
| `GET /api/v2/incremental/tickets/cursor.json?start_time=&cursor=&include=metric_sets,users,groups&per_page=` | Conversas atualizadas desde `start_time`, por cursor, como tickets; `users` (agentes e os contatos da página), `groups` (times), `ticket_metric_sets`; `after_cursor`, `end_of_stream`, `end_time` |
| `GET /api/v2/incremental/ticket_metric_events.json?start_time=` | Eventos `apply_sla`, `fulfill` e `breach` das métricas `reply_time` (primeira e próxima resposta) e `resolution_time`, a partir do SLA aplicado |
| `GET /api/v2/satisfaction_ratings.json?start_time=&page[size]=` | Avaliações de CSAT, com `meta.has_more` e `links.next` |
| `GET /api/v2/users.json?role[]=admin&role[]=agent` · `GET /api/v2/users/search.json?query=` · `GET /api/v2/users/:id/tickets/requested.json` | Agentes; busca por e-mail (agentes e contatos); tickets de um contato |
| `GET /api/v2/groups` | Times |
| `GET /api/v2/ticket_fields.json` · `/ticket_fields/:id.json` | Atributos personalizados de conversa, com opções |
| `GET /api/v2/agent_availabilities/agent_statuses` · `GET /api/v2/agent_availabilities` | Catálogo de status (com `channels`: support = ticket, messaging = chat) e o status de cada agente agora |
| `GET /api/v2/tickets/:id.json` · `PUT` · `GET .../comments.json` · `PUT`/`POST .../tags.json` | Ler e atualizar (status, prioridade, responsável, grupo, tags, campos, comentário público ou nota interna), comentários, tags |
| `POST /api/v2/uploads.json` | Ainda não: responde 501 |

## De-para

| Zendesk | StayDesk |
|---|---|
| `ticket.id` | `display_id` da conversa |
| `status` `new / open / pending / hold / solved / closed` | aberta sem resposta / aberta / pendente / adiada / resolvida / resolvida com status "Fechado" |
| `priority` `low / normal / high / urgent` | `low / medium / high / urgent` |
| `via.channel` | tipo do canal: `email`, `chat` (site), `whatsapp`, `api`, `sms`, `facebook`, `instagram`… |
| `requester_id` (usuário final) | `1_000_000_000 + contact_id` — contatos e agentes são tabelas diferentes aqui; o deslocamento evita colisão de id |
| `assignee_id` / `group_id` | `assignee_id` / `team_id` |
| `tags` | etiquetas |
| `custom_fields[].id` | id da definição do atributo |
| `satisfaction_rating.score` | `good`/`bad` (4–5 / 1–3), `_with_comment` quando há comentário, `unoffered` sem avaliação |
| `metric_set.reply_time_in_minutes` | evento `first_response` (calendário e horário comercial) |
| `metric_set.*resolution_time_in_minutes` | evento `conversation_resolved` |
| `metric_set.replies` / `reopens` | respostas públicas do agente / voltas de resolvida para aberta |

Os escopos valem como no resto da API: `GET` pede leitura, o resto pede escrita.
Spec de ponta a ponta em `spec/staydesk/requests/staydesk/zendesk_facade_spec.rb`.
