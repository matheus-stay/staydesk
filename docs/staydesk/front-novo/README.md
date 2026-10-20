# StayDesk: contrato técnico do front novo

**Para quem é:** o designer ou desenvolvedor que vai construir o front novo do
StayDesk e a IA que ele usar para gerar o código. **O que é:** a lista do que o
front precisa **fazer, consumir e respeitar** para encaixar no backend do
StayDesk sem retrabalho. **O que não é:** um guia de design. Layout, componentes,
cores e tipografia são decisão sua. Aqui está só o que o front precisa cumprir
para funcionar com o nosso código.

> Versão de 2026-10-20, revisada depois da bateria de testes de distribuição, escrita
> sobre o backend do ramo `staydesk-revisado`. O que mudou desde a de 2026-10-19 está
> no fim, em "Mudanças desta versão".
> As fontes da verdade, sempre mais atuais que este texto, são:
> - **OpenAPI da API StayDesk:** `swagger/staydesk/openapi.json`, gerado da
>   referência e conferido no CI. É dele que você gera o cliente tipado.
> - **Referência navegável:** `GET /api/v1/accounts/:id/staydesk/api_reference`
>   (JSON), a mesma que a Central mostra em "Documentação da API".
> - **API do produto** (conversas, mensagens, contatos, caixas…): `swagger/swagger.json`,
>   que vem do Chatwoot.
>
> Se algo aqui contradisser essas fontes, valem elas.

---

## 1. O que é o StayDesk, em uma tela de texto

O StayDesk é a central de atendimento da StayCloud: tickets por e-mail e API,
chat do site e WhatsApp. Por baixo é o Chatwoot (Ruby on Rails), com uma camada
própria por cima que reproduz o jeito Zendesk de trabalhar:
- **filas** por canal, com grupos;
- **status do agente** que decide o que ele recebe;
- **convite de atendimento** com aceite;
- **status do ticket** personalizado;
- **campos obrigatórios** para resolver;
- **SLA** com calendário;
- **visualizações** por grupo;
- **macros** e **gatilhos**;
- **números da operação** (KPIs).

O produto tem **três espaços**, cada um com navegação própria:

| Espaço | Quem usa | Para quê |
|---|---|---|
| **Hub** | Agentes (N1, N2, N3…) | Atender: visualizações, conversa, resposta, status, convites |
| **Central** | Coordenação e quem tem permissão | Configurar e acompanhar: filas, status, SLA, visualizações, papéis, números, tokens, documentação da API |
| **Superadministração** | Quem administra a plataforma | Gerar e administrar instâncias (contas) do StayDesk |

## 2. Princípios do contrato (os que não se negociam)

1. **A API é a fonte da verdade.** Toda regra de negócio está no servidor. O
   front **não recalcula** regra: mostra o que a API devolve. Os casos que
   costumam tentar e não podem estão na seção 9.
2. **Tudo é configurável, e a configuração vem da API.** Menu, colunas da lista,
   campos do ticket, ordem dos painéis e quais status o agente pode escolher não
   ficam fixos no front: vêm de `GET staydesk/workspace` e dos catálogos.
3. **Permissão é decidida no servidor.** O front esconde o que a pessoa não
   pode usar (via `can_manage` e `permissions`), mas a segurança é do servidor.
   Trate 401, 403 e 422 com mensagem útil.
4. **Tempo real é obrigatório no Hub.** O agente precisa manter a presença (seção
   5); sem ela, o servidor o tira do status e a fila para de entregar trabalho a ele.
5. **pt-BR primeiro, com i18n desde o início.** Todos os textos passam por
   arquivos de tradução (pt-BR e en). Datas e números no formato do idioma.
6. **Tema claro e escuro, acessível** (WCAG 2.2 AA), responsivo a partir de
   1280 px para o Hub e a Central. O celular é desejável no Hub, e não exigido
   na primeira versão.

## 3. Como o front se pluga no backend

### Arquitetura recomendada

- **SPA estática** (HTML, JS e CSS), num repositório próprio, construída e servida
  **no mesmo domínio** do backend, atrás de um proxy reverso (no Easypanel, por
  exemplo). Assim não há CORS nem cookie entre domínios:

  | Caminho | Vai para |
  |---|---|
  | `/api/*`, `/auth/*`, `/cable`, `/platform/*`, `/public/*`, `/rails/*`, `/super_admin/*`, `/survey/*`, `/widget*`, `/packs/*`, `/vite/*`, `/staydesk/zendesk/*` | backend Rails (o que existe hoje) |
  | todo o resto (`/`, `/app/*`, `/hub/*`, `/central/*`, `/admin/*`…) | o front novo (`index.html` com fallback de SPA) |

- Se o front ficar em **outro domínio**, ligue no backend `ENABLE_API_CORS=true`
  (libera `/api/*` e expõe os cabeçalhos `access-token`, `client`, `uid`, `expiry`).
  `/cable` e `/auth` ficam de fora dessa variável: prefira o mesmo domínio.
- **Variáveis de ambiente do front:** `VITE_API_BASE_URL` (vazio = mesmo domínio),
  `VITE_CABLE_URL` (padrão `/cable`), `VITE_DEFAULT_LOCALE` (`pt-BR`).
- O widget de chat do site, a página pública da pesquisa de satisfação e os
  e-mails continuam servidos pelo backend e **não** fazem parte deste front.

### Cliente da API

Gere o cliente tipado a partir de `swagger/staydesk/openapi.json` (StayDesk) e
`swagger/swagger.json` (produto), com `openapi-typescript` + `openapi-fetch` ou
com `orval`. Não escreva tipos à mão. Quando o backend mudar, regenere.

## 4. Autenticação e sessão

### Login de usuário (Hub e Central)

1. `POST /auth/sign_in` com `{ email, password }`. A resposta traz **nos
   cabeçalhos** `access-token`, `client`, `uid`, `token-type` e `expiry`.
2. Guarde esses cinco valores (cookie `SameSite=Lax` ou armazenamento seguro) e mande
   **os cinco em todo pedido** à API. Quando uma resposta trouxer `access-token`
   novo, substitua o guardado (rotação do devise_token_auth).
3. `GET /api/v1/profile` devolve o usuário, as contas (`accounts[]` com `id`,
   `name`, `role` e `permissions`, já somadas às do papel StayDesk) e o
   `pubsub_token` para o tempo real.
4. `GET /auth/validate_token` confere uma sessão salva; `DELETE /auth/sign_out` sai.
5. **Link de acesso (SSO):** a superadministração e o "entrar como" devolvem uma
   URL com `sso_auth_token`. O front precisa ter uma rota de login que receba
   esse token e o troque pela sessão: `POST /auth/sign_in` com `{ email, sso_auth_token }`
   (os dois vêm na URL do link).
6. Esqueci a senha e confirmação: os fluxos do devise_token_auth em `/auth/password`.

### Conta ativa

Todo endpoint de conta é `/api/v1/accounts/:account_id/...`. Quem tem mais de uma
conta escolhe uma, e o `account_id` vai em todas as URLs. Os endpoints do StayDesk
ficam sob `/api/v1/accounts/:account_id/staydesk/...`.

### Superadministração

Autentica com o **token de um Platform App** no cabeçalho `api_access_token`. O
token é gerado no `/super_admin` atual (seção 8).

## 5. Tempo real

- Conecte no ActionCable em `/cable` e assine o canal `RoomChannel` com
  `{ pubsub_token, account_id, user_id }`. Use `@rails/actioncable` ou outro
  cliente compatível com o protocolo.
- **Presença (obrigatória no Hub):** envie a ação `update_presence` pelo canal a
  cada **20 s ou menos**, ou chame `POST staydesk/presence` no mesmo ritmo. A
  presença vale 20 s. Sem ela, o servidor considera o agente desconectado: ele sai
  do status pelo tempo limite e a fila deixa de entregar.
- **Aba fechada:** no `pagehide`, mande `POST staydesk/agent_status_periods/leave`
  com `fetch(..., { keepalive: true })` e os cabeçalhos de sessão. O servidor
  espera cerca de 45 s e só tira o agente do status se não sobrou nenhuma aba
  conectada, então F5 não derruba.
- Mensagens chegam como `{ event, data }`. Trate pelo menos:

| Evento | O que fazer |
|---|---|
| `conversation.created`, `conversation.updated`, `conversation.status_changed`, `conversation.read` | atualizar a conversa no cache (o payload traz o bloco `staydesk`, seção 7) |
| `message.created`, `message.updated` | inserir ou atualizar a mensagem na conversa aberta |
| `assignee.changed`, `conversation.contact_changed` | atualizar responsável e contato |
| `conversation.typing_on` / `typing_off` | indicador de digitação |
| `presence.update` | quem está online (`users`, `contacts`) |
| `notification.created` / `updated` / `deleted` | central de notificações |
| `staydesk.offer.created` | **convite de atendimento**: mostrar o cartão com contagem regressiva (`seconds_left`/`expires_at`), som e notificação do navegador |
| `staydesk.offer.accepted` / `declined` / `expired` | tirar o cartão; no aceite, abrir a conversa |
| `staydesk.agent_status.changed` | atualizar o status mostrado (o servidor pode trocar sozinho, pelo tempo limite, aba fechada ou convites perdidos) |
| `user:logout`, `page:reload`, `account.cache_invalidated` | sair, recarregar ou invalidar caches |

**Contadores das visualizações:** o número ao lado de cada visualização tem de
bater com a lista, em tempo real. Peça `GET staydesk/team_views/counts` de novo a
cada evento de conversa (`conversation.created`, `conversation.updated`,
`conversation.status_changed`, `assignee.changed`) e ao reconectar o WebSocket,
agrupando rajadas (1 a 2 s). Como rede de segurança, peça também a cada 30 s. O
servidor não guarda cache dessa contagem.

Ainda sem evento próprio, e por isso com consulta periódica: carga e diagnóstico
na tela de números, a cada 15 s.

## 6. Navegação e o que cada pessoa vê

- `GET staydesk/workspace` devolve a **área de trabalho já resolvida** para quem
  chama (produto → conta → grupos → papel):
  - menus do Hub e da Central;
  - colunas e abas da lista, tamanho de página e ordenação;
  - campos do ticket, na ordem;
  - painéis ao lado da conversa;
  - macros e aplicativos visíveis;
  - comportamento do "Enviar como" (`composer.submit_as`, `composer.after_send`).

  O front monta as telas a partir disso. Os nomes dos itens do menu e dos painéis
  vêm de `GET staydesk/team_workspaces/schema`. Mapeie esses nomes para as suas
  telas e não os fixe no código.
- `can_manage` (no mesmo endpoint) diz quais áreas da Central a pessoa pode
  configurar (`filas`, `sla`, `status`, `visualizacoes`, `configuracoes`, ...). O
  menu da Central mostra só as áreas com `true`.
- `accounts[].permissions` do perfil traz as permissões finas (por exemplo
  `report_manage` e `staydesk_report_own`).
- **Agente leve** (devs que só leem e comentam): só pode criar nota privada. O
  servidor recusa o resto com 403, e o front não deve oferecer resposta pública.

## 7. O que o front precisa ter: Hub (atendimento)

Para cada função, o que ela faz e de onde vêm os dados. Os caminhos curtos são
relativos a `/api/v1/accounts/:account_id/`.

### 7.1 Home do Hub
- Saudação, seletor de status do agente, visualizações com contagem e "comigo
  agora" (as conversas abertas atribuídas a mim).
- `GET staydesk/team_views`, `GET staydesk/team_views/counts`,
  `GET staydesk/agent_statuses`, `GET conversations?assignee_type=me&status=open`.

### 7.2 Status do agente
- Menu sempre visível. Mostra só os status com `available_to_me: true` em
  `GET staydesk/agent_statuses`, mais **Offline**. O atual é `current_status_id`;
  nulo é Offline.
- Trocar: `POST staydesk/agent_status_periods` `{ agent_status_id }`. Status não
  liberado volta 422. Ficar offline: `POST staydesk/agent_status_periods/offline`.
- Não use `POST /api/v1/profile/availability` para isso: o status do StayDesk já
  alinha a disponibilidade.

### 7.3 Visualizações e lista de conversas
- A barra lateral do Hub lista as visualizações (`GET staydesk/team_views`) com
  contagem.
- Lista de uma visualização: `GET staydesk/team_views/:id/conversations?page=&sort_by=`.
  O servidor resolve o filtro (inclusive "eu mesmo" e o canal de trabalho) e a
  ordem configurada na visualização (a fila de chat é por ordem de chegada). Não
  use `/conversations/filter` com filtro montado no front. Se precisar do filtro
  pronto, cada visualização traz `resolved_query`, já resolvido para quem chama;
  `query` é a versão de edição, com marcadores que só o servidor entende.
- O número da barra lateral e o total da lista vêm da mesma consulta: se divergirem,
  é cache do front.
- Colunas e abas (minhas, sem responsável, todas) vêm da área de trabalho
  (`list.columns`, `list.tabs`). As colunas possíveis são SLA, status do ticket,
  assunto, contato, canal, aguardando desde e responsável. O **assunto** e o
  **status do ticket** vêm prontos no bloco `staydesk` da conversa (seção 7.6).
- `list.hide_when_open`: com a conversa aberta, a lista some, e o modo é tabela ou lista.

### 7.4 Convite de atendimento (filas com aceite)
- Quando chega `staydesk.offer.created`: cartão no canto com contato, canal,
  assunto e contagem regressiva, botões Aceitar e Recusar, som e notificação do
  navegador (peça permissão). Vários convites ficam empilhados.
- `POST staydesk/offers/:id/accept`, que abre a conversa, e `POST staydesk/offers/:id/decline`.
- Ao abrir o app, ou se o tempo real cair, `GET staydesk/offers` lista os
  pendentes de quem chama.
- Convites chegam também fora da conversa nova, e o front não deve estranhar:
  - quando um agente libera vaga (resolve, põe em espera, transfere), o próximo da
    fila é oferecido em cerca de 2 s;
  - **chat** resolvido que o cliente reabre **perde o responsável** e volta para a
    fila como convite (configurável por canal de trabalho, `reopen_to_queue`). A
    conversa some de "comigo" e chega como `assignee.changed`;
  - **ticket** reaberto pelo cliente continua com quem atendia e volta a "em andamento".

### 7.5 Conversa aberta
- Cabeçalho com contato, canal, número do ticket (`display_id`) e **seletor de
  status do ticket**, no lugar do "Resolver" do Chatwoot: o catálogo vem de
  `GET staydesk/ticket_statuses` e o atual de `staydesk.ticket_status`. Trocar o
  status é `POST staydesk/conversations/:display_id/ticket_status`
  `{ ticket_status_id, snoozed_until? }`.
- Mensagens: `GET conversations/:display_id/messages` (paginação por `before`).
  O tipo de mensagem, os anexos e o e-mail (HTML citado) seguem o formato do
  produto (`swagger/swagger.json`).
- **Painel "Campos do ticket"**, o único lugar onde se editam os campos:
  - Ler e gravar: `GET` e `PATCH staydesk/conversations/:display_id/ticket_fields`.
    O `PATCH` faz merge parcial e a resposta traz valor, tipo, opções e se o
    campo é obrigatório para resolver.
  - Ordem dos campos: vem de `conversation.fields` da área de trabalho.
  - Aviso "Falta preencher para resolver: …": vem de `missing_to_resolve`.
- Ações da conversa: atribuir agente e grupo (`POST conversations/:display_id/assignments`;
  a lista de quem pode receber vem de `GET assignable_agents?inbox_ids[]=`, que no
  StayDesk são **todos os agentes da conta**: transferência livre), prioridade,
  etiquetas, participantes e contato.
- SLA: o selo na lista e o detalhe das três métricas vêm de
  `GET staydesk/conversations/:display_id/sla` (204 = sem SLA). Estados: no prazo,
  vencendo, vencido, cumprido e cumprido com atraso.
- Macros: as visíveis vêm da área de trabalho e se executam com
  `POST macros/:id/execute` `{ conversation_ids }`.
- Aplicativos laterais (iframes): `GET dashboard_apps`. O contexto da conversa vai
  ao iframe por `postMessage`, no formato do Chatwoot (`appContext`).

### 7.6 Responder: "Enviar como <status>"
- Caixa de resposta com resposta pública ou nota privada, anexos, respostas
  prontas (`GET canned_responses`) e editor rico. Para e-mail, mostre os
  destinatários (cc/bcc).
- Botão dividido **"Enviar como <status>"**: a parte grande envia e aplica o
  status escolhido; a seta escolhe outro status. **Com a caixa vazia**, o botão só
  muda o status (resolver sem escrever).
- Use **uma chamada só**: `POST staydesk/conversations/:display_id/reply`
  `{ content?, private?, ticket_status_id?, custom_attributes? }`. Se faltar campo
  obrigatório para resolver, volta 422 com `missing_to_resolve` e **nada é
  gravado** (nem a mensagem): abra a janela pedindo **esses** campos e reenvie com
  `custom_attributes` preenchidos. No sucesso, o servidor grava campos e resposta
  juntos e aplica o status logo em seguida, para que SLA, gatilhos e pesquisa de
  satisfação recebam a mudança de status. Não separe em duas chamadas no front.
- Depois de enviar, o que fazer vem de `composer.after_send`: ficar na conversa,
  abrir a próxima da visualização ou voltar para a lista.

### 7.7 Bloco `staydesk` em toda conversa

Toda conversa (API, listas e eventos em tempo real) traz:

```json
"staydesk": {
  "subject": "Site fora do ar",
  "ticket_status": { "id": 3, "name": "Em andamento", "color": "#0f766e", "base_status": "open" },
  "missing_to_resolve": ["servidor", "classificacao"]
}
```

Use esses campos e **não** recalcule assunto, status atual nem obrigatórios.

### 7.8 Contatos e empresas
- Lista, busca, detalhe, conversas anteriores, notas e atributos do contato, pela
  API do produto (`contacts`, `contacts/:id/conversations`, `contacts/:id/notes`).
  Mesmo comportamento do Chatwoot.

### 7.9 Busca e notificações
- Busca global (`GET search?q=`) e central de notificações (`GET notifications`),
  pela API do produto.

## 8. O que o front precisa ter: Central e superadministração

### 8.1 Central (configuração e acompanhamento)

Toda tela da Central tem listar, criar, editar e excluir (quando a API permite)
e reordenar onde houver `reorder`. Os formulários seguem os campos e validações
do OpenAPI.

| Tela | Endpoints (`staydesk/...`) | Observações |
|---|---|---|
| Home da Central | `kpis` | Cartões com os números principais e atalhos para as seções |
| Números da operação | `kpis` (`since`, `until`, `compare`, `user_id`, `load_queue`, `team_id`), `agent_loads`, `distribution_checks`, `offer_stats` | CSAT, aceitação, fila, tempos (mediana e p90), volumes, FCR, SLA, série diária, **contagem por campo** (`por_campo`), tempo online por agente. Quadro "agora" atualizado a cada 15 s |
| Diagnóstico da distribuição | `distribution_checks` e `distribution_checks?conversation_id=` | Por agente, as 6 condições (sim/não) e os canais que ele não atende. Por conversa, a etapa em que ela para (`para_em`) |
| Filas de encaminhamento | `queues` (+`reorder`), `load_queues` | Grupos principais e secundários, canais, condições, prioridade, aceite (tempo, reoferecer) |
| Canais de trabalho | `load_queues` | Agrupam canais em "chat", "ticket" e outros. `reopen_to_queue`: conversa reaberta pelo cliente volta para a fila (ligado no chat) |
| Regras de capacidade | `capacity_rules` | Quantas conversas de cada canal de trabalho, por agente |
| Status do agente | `agent_statuses` | Disponibilidade, canais de trabalho, cor, tempo limite e destino, conta como online |
| Status do ticket | `ticket_statuses` (+`reorder`) | Catálogo por cima dos 4 status base; um assume ao atribuir |
| Políticas de SLA | `sla_policies` (+`reorder`) | Alvos por prioridade, calendário, condições |
| Calendários | `calendars` | Horário comercial e feriados |
| Visualizações | `team_views` | Filtro, colunas, ordem, grupos que veem, cor e ícone |
| Área de trabalho | `team_workspaces`, `team_workspaces/schema` | Por grupo e padrão da conta. Monte o formulário a partir do schema |
| Papéis e pessoas | `roles`, `agent_roles`, `impersonations` | Papel com permissões por área, agente leve, "entrar como" (devolve link de acesso, seção 4) |
| Tokens de API | `api_tokens` | Criar (o valor aparece uma vez), escopos por grupo, revogar |
| Importar configuração | `config_import` | Colar ou enviar o YAML da operação. Mostra o resumo |
| Documentação da API | `api_reference` | Referência navegável, com "experimentar" |
| Canais (caixas) | API do produto: `inboxes` | Lista agrupada por tipo; a configuração de cada canal segue o produto. **Sem aba de agentes**: quem atende vem das filas |
| Campos do ticket (cadastro) | API do produto: `custom_attribute_definitions` | Inclui `staydesk_required_to_resolve` (obrigatório para resolver) |
| Etiquetas, grupos, agentes, macros, gatilhos, respostas prontas | API do produto: `labels`, `teams`, `agents`, `macros`, `automation_rules`, `canned_responses` | Gatilhos aceitam os eventos `staydesk_sla_warning`, `staydesk_sla_breached` e `staydesk_sla_met`, e as ações `staydesk_set_attribute`, `staydesk_set_ticket_status` e `staydesk_aviso_de_recebimento` |
| Perfil | API do produto: `profile` | Nome, foto, senha, assinatura, preferências de notificação |

### 8.2 Superadministração (gerar instâncias)

Área separada, entrando com o token de um Platform App.

| Função | Endpoint | Observações |
|---|---|---|
| Listar instâncias | `GET /platform/api/v1/staydesk/instances` | Nome, idioma, situação, criação e quantidade de pessoas |
| **Gerar instância nova** | `POST /platform/api/v1/staydesk/instances` | `{ account: {name, locale, support_email}, admin: {name, email, password?}, config_yaml? }`. Cria tudo numa transação e devolve `login_url` (link de acesso do administrador) e o resumo da configuração aplicada |
| Editar instância | `PATCH /platform/api/v1/accounts/:id` | Nome, idioma, situação (ativa ou suspensa), `features` (ligar e desligar recursos) |
| Excluir instância | `DELETE /platform/api/v1/accounts/:id` | Peça confirmação explícita: é irreversível |
| Pessoas da instância | `GET/POST/DELETE /platform/api/v1/accounts/:id/account_users` | Vincular e desvincular usuários (papel administrador ou agente) |
| Usuários | `POST/GET/PATCH/DELETE /platform/api/v1/users`, `GET /platform/api/v1/users/:id/login` | Criar usuário e gerar link de acesso |

**Fora da API por enquanto** (continuam no `/super_admin` atual; o backend expõe em
uma etapa seguinte):
- configurações da instalação (e-mail, marca, chaves de integração);
- criação de Platform Apps e dos seus tokens;
- status da instância (versão, saúde);
- avisos (banners) da plataforma.

Na primeira versão, o front leva um link para o `/super_admin` nesses casos.

## 9. Regras que o front NÃO pode recalcular

| Não faça no front | Use |
|---|---|
| Montar o assunto pela última mensagem ou pelo canal | `staydesk.subject` |
| Descobrir o status do ticket pelo nome em `custom_attributes` | `staydesk.ticket_status` |
| Calcular quais campos faltam para resolver | `staydesk.missing_to_resolve`, ou o 422 do `reply` |
| Filtrar quais status o agente pode escolher | `available_to_me` em `agent_statuses` |
| Montar o filtro e a ordem de uma visualização | `GET staydesk/team_views/:id/conversations` |
| Decidir quais áreas da Central mostrar por permissão | `can_manage` em `staydesk/workspace` |
| Decidir quem atende um canal (aba de agentes) | Não existe: vem das filas, no servidor |
| Resolver a área de trabalho (herança grupo/conta/papel) | `GET staydesk/workspace`, já resolvida |
| Enviar mensagem e status em chamadas separadas | `POST staydesk/conversations/:id/reply` |
| Contar as conversas de uma visualização pela lista carregada | `GET staydesk/team_views/counts`, pedido de novo a cada evento |
| Decidir se a conversa reaberta volta para a fila ou fica com o agente | O servidor decide (`reopen_to_queue` do canal de trabalho) |

## 10. Pendências conhecidas do backend (para não estranhar)

O backend vai resolver estes pontos em seguida. Até lá, o front contorna como indicado:
- **Condições de filas, visualizações, SLA e gatilhos:** não há endpoint que liste
  os atributos, operadores e tipos válidos. Use o formato de `POST conversations/filter`
  do produto (`swagger/swagger.json`) e os atributos de `custom_attribute_definitions`.
- **Faixas do semáforo dos KPIs:** ainda não vêm da API. Use CSAT verde a partir de
  90 e amarelo a partir de 75; aceitação 90/70; fila 0 verde e até 5 amarelo.
- **Eventos de SLA** (vencendo, vencido, cumprido) não chegam por tempo real.
  O selo se atualiza pelo `conversation.updated`.
- **Status do ticket gravado pelo nome:** renomear um status no catálogo solta as
  conversas que estavam nele. Evite oferecer "renomear" sem aviso.
- **Tamanho de página da lista:** `list.page_size` ainda não é aceito por
  `team_views/:id/conversations` (são 25 por página).

## 11. Stack recomendada

A recomendação privilegia o que está **em alta e bem mantido em 2026**, com
componentes bonitos de fábrica e fácil de uma IA gerar bem:

| Camada | Escolha | Por quê |
|---|---|---|
| Linguagem | **TypeScript** (estrito) | Os tipos vêm do OpenAPI, e a IA erra menos com tipos |
| Framework | **React 19** + **Vite** (SPA) | Maior ecossistema e o padrão de mercado. Não precisa de SSR, porque o app é logado e fica atrás do backend |
| Rotas | **TanStack Router** | Rotas tipadas, carregamento de dados por rota, busca na URL tipada |
| Dados do servidor | **TanStack Query** | Cache, revalidação e atualização otimista. Os eventos de tempo real atualizam o cache do Query |
| Cliente HTTP | **openapi-fetch** + **openapi-typescript** (ou **orval**) | Cliente gerado do `openapi.json`, sem tipo à mão |
| UI | **shadcn/ui** (Radix UI por baixo) + **Tailwind CSS v4** | Componentes acessíveis, bonitos e seus (o código fica no projeto), com tema por tokens CSS e claro/escuro nativos |
| Ícones | **Lucide** | Mesmo conjunto do produto hoje, limpo e consistente |
| Animação | **Motion** (antigo Framer Motion) | Transições suaves de painel, cartão de convite e lista |
| Tabelas | **TanStack Table** + **TanStack Virtual** | Lista de conversas grande, colunas configuráveis vindas da API |
| Formulários | **React Hook Form** + **Zod** | Validação com os mesmos limites da API |
| Editor de resposta | **Tiptap** | Editor rico, menções, atalhos e respostas prontas |
| Gráficos | **Recharts** (ou **Tremor**) | KPIs e séries diárias com boa aparência e pouco código |
| Comandos e busca | **cmdk** | Paleta de comandos (Ctrl+K), como no produto atual |
| Notificações na tela | **Sonner** | Toasts discretos e bonitos |
| Tempo real | **@rails/actioncable** | Cliente oficial do protocolo do backend |
| Estado local de UI | **Zustand** (só o necessário) | Abas abertas, preferências. O que é do servidor fica no Query |
| i18n | **i18next** + **react-i18next** (ICU) | pt-BR e en, plurais e datas |
| Datas | **date-fns** (+ `date-fns-tz`) | Leve, com fuso |
| Testes | **Vitest** + **Testing Library**; **Playwright** de ponta a ponta; **MSW** para simular a API | Cobrir os fluxos críticos da seção 13 |
| Qualidade | **ESLint** + **Prettier** (ou **Biome**), **Storybook** para os componentes | Revisão visual dos componentes isolados |

Alternativa, se preferir Vue: **Vue 3** + **Nuxt** em modo SPA + **shadcn-vue**
+ **Pinia** + **TanStack Query for Vue**. O contrato é o mesmo.

Estrutura sugerida de pastas: `src/api` (cliente gerado + wrappers),
`src/realtime` (ActionCable e roteamento de eventos para o cache),
`src/features/{hub,central,superadmin}/...` (uma pasta por função),
`src/components/ui` (shadcn), `src/i18n`, `src/theme` (tokens).

## 12. Requisitos não funcionais

- **Desempenho:** o Hub abre em menos de 2 s numa conexão boa; a lista virtualiza
  acima de 100 itens; nada de consulta periódica abaixo de 15 s, exceto a presença.
- **Acessibilidade:** navegação completa por teclado, foco visível, rótulos e
  contraste AA. O cartão de convite é anunciado a leitores de tela.
- **Segurança:**
  - Nunca guardar senha.
  - Os tokens de sessão ficam em cookie `SameSite=Lax`, ou no armazenamento com
    expiração.
  - Sanitize todo HTML que vier de mensagem de e-mail (DOMPurify) antes de mostrar.
  - Não injetar HTML de usuário sem sanitizar.
- **Resiliência:** se o WebSocket cair, reconectar com espera crescente e, até
  voltar, consultar `GET staydesk/offers` e `GET staydesk/agent_statuses`.
- **Sem telemetria de terceiros** sem aprovação.
- **Marca:** o produto se chama **StayDesk**. Nenhum texto "Chatwoot" aparece para o usuário.

## 13. Critérios de aceite (checklist)

O front está pronto para plugar quando:

- [ ] Login, logout, troca de conta, sessão salva e login por link de acesso (SSO) funcionam.
- [ ] Presença mantida (WebSocket ou `POST staydesk/presence`) e aba fechada avisada.
  Ao fechar a aba, o agente fica offline em até 1 minuto. F5 não derruba.
- [ ] Menu de status mostra só os liberados (`available_to_me`), mais Offline, e
  reflete `staydesk.agent_status.changed`.
- [ ] Convite de atendimento chega em tempo real, com contagem regressiva, som e
  notificação. Aceitar abre a conversa, e recusar ou vencer tira o cartão.
- [ ] Lista da visualização vem de `team_views/:id/conversations`, com colunas,
  abas e a ordem da visualização (a fila de chat mostra o mais antigo primeiro).
- [ ] O número ao lado de cada visualização bate com a lista e muda sozinho em até
  2 a 3 s quando chega, é pega ou é resolvida uma conversa.
- [ ] Chat reaberto pelo cliente some de "comigo" e volta como convite; ticket
  reaberto continua com quem atendia.
- [ ] Assunto, status do ticket e campos que faltam vêm do bloco `staydesk`.
- [ ] "Enviar como" usa `staydesk/conversations/:id/reply`. Com campo obrigatório
  vazio, abre a janela pedindo os campos e resolve depois. Funciona com a caixa vazia.
- [ ] Painel "Campos do ticket" é o único lugar de editar os campos, na ordem da área
  de trabalho, com os obrigatórios marcados.
- [ ] Transferência lista todos os agentes, e quem recebe passa a ver a conversa.
- [ ] Central: todas as telas da tabela 8.1 com CRUD funcionando, menu por `can_manage`.
- [ ] Superadministração: gerar instância nova, com o link de acesso mostrado ao
  final, e listar, editar e suspender instâncias.
- [ ] Tema claro e escuro, pt-BR e en, nenhum "Chatwoot" visível.
- [ ] Testes de ponta a ponta cobrindo: login → ficar disponível → receber convite
  → aceitar → responder e resolver com campo obrigatório.

## 14. Como pedir à sua IA (sugestão)

> Construa o front-end do StayDesk como uma SPA React 19 + TypeScript + Vite, com
> TanStack Router e Query, shadcn/ui + Tailwind v4, seguindo o contrato
> `docs/staydesk/front-novo/README.md`. Gere o cliente da API a partir de
> `swagger/staydesk/openapi.json` e `swagger/swagger.json` com openapi-typescript.
> Implemente nesta ordem:
> 1. autenticação e sessão;
> 2. tempo real e presença;
> 3. Hub: status, visualizações, lista, conversa, "Enviar como", convites;
> 4. Central: na ordem da tabela 8.1;
> 5. superadministração.
>
> Não recalcule nenhuma regra listada na seção 9: use os campos e endpoints
> indicados. Todo texto em i18n (pt-BR padrão). Entregue testes de ponta a ponta
> do fluxo da seção 13.

Dúvidas sobre comportamento: a referência da API (`GET staydesk/api_reference`)
explica cada endpoint em português, com exemplos.

## Mudanças desta versão (2026-10-20)

Depois da bateria de testes de distribuição no staging:

- **Contadores das visualizações** (seção 5 e 7.3): sem cache no servidor; o front
  pede de novo a cada evento de conversa, e o polling caiu de 60 s para 30 s, só
  como rede de segurança. O número tem de bater com a lista.
- **`resolved_query`** em cada visualização (7.3): o filtro pronto para quem chama.
- **Reabertura** (7.4 e 8.1): chat reaberto pelo cliente volta para a fila como
  convite; ticket reaberto fica com quem atendia. Campo novo `reopen_to_queue` no
  canal de trabalho.
- **Vaga liberada** (7.4): convite do próximo da fila em cerca de 2 s.
- **"Enviar como"** (7.6): o contrato da chamada não mudou; o servidor confere os
  campos obrigatórios antes de gravar e aplica o status logo depois da resposta.
- **Critérios de aceite** (13): três itens novos (ordem da visualização, contador
  em tempo real, reabertura).

