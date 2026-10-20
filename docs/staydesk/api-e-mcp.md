# API e MCP do StayDesk

> A referência completa, com parâmetros e exemplos por endpoint, está **dentro do
> produto**: Central › Conta › Documentação da API. Ela é gerada de
> `custom/config/api_reference.json`, e um teste confere esse arquivo contra as
> rotas do servidor, então a página não desatualiza sem quebrar o build.

### Acrescentar um endpoint à referência

Rota nova em `custom/config/routes.rb` entra também em
`custom/config/api_reference.json`, no grupo certo, com `metodo`, `caminho`
(sem o prefixo da conta), `titulo`, `resumo`, `detalhes`, `escopo` (um escopo
que `custom/config/api_scopes.json` conhece), `respostas` e um exemplo de
`resposta`. O teste `spec/staydesk/models/staydesk/api_reference_spec.rb`
quebra nos três casos que importam: endpoint documentado sem rota, rota de
`staydesk/` sem documentação e escopo desconhecido. `PUT` e `PATCH` contam como
o mesmo. Em desenvolvimento o arquivo é relido a cada pedido, então a página
`ApiDocs.vue` mostra a mudança na hora.

Tudo que a Central configura e mostra tem endpoint próprio, sob
`/api/v1/accounts/:account_id/staydesk/`. O MCP em `custom/mcp` fala com esses
mesmos endpoints, então tela, dashboard e agente de IA leem a mesma conta.

## Autenticação

Cabeçalho `api_access_token`. Vale o token pessoal do usuário, que carrega tudo
que a pessoa pode, ou um **token de API com escopo próprio**, criado em
Central › Tokens de API, que é o recomendado para integração.

O token de API age em nome de um agente e só alcança os escopos marcados: o
escopo estreita, nunca amplia o que essa pessoa pode. Endpoint fora do escopo
responde `403` dizendo qual escopo falta; endpoint que nenhum grupo cobre também
não passa, porque a regra é permissão explícita, não lista de bloqueio.

O valor aparece uma única vez, na criação. O banco guarda só o resumo (SHA-256) e
os quatro últimos caracteres, então token perdido se revoga e se cria outro.

### Escopos

Nove grupos, cada um com `leitura` e `escrita`: `conversas`, `contatos`,
`relatorios`, `operacao`, `canais`, `equipe`, `automacao`, `central_de_ajuda` e
`conta`. O que cada um cobre, e como acrescentar, está em
[tokens-de-api.md](tokens-de-api.md).

```sh
curl -H "api_access_token: sd_..." \
  "https://staydesk.staycloud.com.br/api/v1/accounts/1/staydesk/kpis"
```

### Gerenciar tokens

| Endpoint | O que faz |
|---|---|
| `GET staydesk/api_tokens` | lista os tokens da conta, com escopos, dono, último uso e o catálogo de escopos |
| `POST staydesk/api_tokens` | cria e devolve o valor em claro uma única vez |
| `PATCH staydesk/api_tokens/:id` | suspende, reativa ou troca os escopos |
| `DELETE staydesk/api_tokens/:id` | revoga de vez |

Criar e revogar exige a permissão da área de papéis, ou ser administrador.

```sh
curl -H "api_access_token: SEU_TOKEN" \
  "https://staydesk.staycloud.com.br/api/v1/accounts/1/staydesk/kpis?since=2026-09-01T00:00:00Z"
```

## Números da operação

| Endpoint | O que devolve |
|---|---|
| `GET staydesk/kpis` | CSAT (respostas, satisfeitos, percentual, média e por agente), tempos de primeira resposta, resposta e resolução **por canal de trabalho**, com média, mediana e p90, quem está esperando na fila e há quanto tempo, o tempo de cada agente em cada status com quem está conectado agora e a produção dele, mais volumes (criadas, resolvidas, abertas, reabertas, FCR), SLA dentro do prazo, aceitação dos convites, série por dia e contagem por campo do ticket (`por_campo`). Aceita `since` e `until` em ISO 8601; sem eles, os últimos 7 dias, e a janela vai até 366 dias. Filtros: `user_id`, `load_queue`, `team_id`; `compare=1` traz o período anterior em `anterior`. Detalhes em [kpis.md](kpis.md). |
| `GET staydesk/agent_loads` | Quantas conversas cada agente atende agora em cada canal de trabalho, contra o teto da regra de capacidade (zero se o status atual não recebe o canal). |
| `GET staydesk/offer_stats` | Aceitação de chat e WhatsApp por agente: oferecidos, aceitos, recusados, expirados, taxa e tempo médio de resposta. |
| `GET staydesk/events` | Linha do tempo das conversas: mudanças de status, responsável, grupo e prioridade. |
| `GET staydesk/applied_slas` | SLA aplicado a cada conversa, com alvo, status e vencimento. |
| `GET staydesk/agent_status_periods` | Períodos de status de cada agente, para quem quiser recalcular tempo por conta própria. |
| `POST staydesk/agent_status_periods` | O agente troca o próprio status (`agent_status_id`). Responde 422 se o status recebe canal que as filas dos grupos dele não atendem. |
| `POST staydesk/agent_status_periods/offline` | O agente sai de qualquer status e fica offline até escolher outro. |
| `POST staydesk/agent_status_periods/leave` | A aba fechou. Responde 202; 45 s depois, se não sobrou aba conectada, o agente sai do status. |
| `GET staydesk/conversations/:conversation_id/sla` | O SLA de uma conversa específica. |

## Configuração da operação

Todas seguem o mesmo desenho: `GET` lista, `POST` cria, `PUT`/`PATCH` altera,
`DELETE` remove, e algumas têm `PUT .../reorder` para trocar a ordem.

| Recurso | Endpoint | Para que serve |
|---|---|---|
| Filas de encaminhamento | `staydesk/queues` | Para qual grupo cada demanda vai, transbordo e aceite obrigatório |
| Canais de trabalho | `staydesk/load_queues` | Que canal e que caixa contam como chat e como ticket |
| Regras de capacidade | `staydesk/capacity_rules` | Quantas conversas de cada canal de trabalho o agente aguenta ao mesmo tempo |
| Status do ticket | `staydesk/ticket_statuses` | Catálogo de status, qual é o padrão de cada base e qual assume ao atribuir |
| Status do ticket de uma conversa | `POST staydesk/conversations/:numero/ticket_status` | Aplica um status do catálogo à conversa (`ticket_status_id`, `snoozed_until` opcional) |
| Status do agente | `staydesk/agent_statuses` | Disponibilidade, canais de trabalho que recebe, tempo limite e `available_to_me` |
| Diagnóstico da distribuição | `GET staydesk/distribution_checks` | Quem recebe o quê e o que falta; com `conversation_id`, em que etapa aquela conversa para |
| Configuração em arquivo | `POST staydesk/config_import` | Aplica o YAML da operação inteira (ver abaixo) |
| Referência da API | `GET staydesk/api_reference` | O conteúdo de `custom/config/api_reference.json`, que a Central desenha em Documentação da API |
| Políticas de SLA | `staydesk/sla_policies` | Alvos por prioridade, pausa, aviso e calendário |
| Calendários | `staydesk/calendars` | Horário comercial e feriados |
| Visualizações por time | `staydesk/team_views` | O que cada grupo vê na fila, com colunas e ordenação |
| Área de trabalho | `staydesk/workspace` e `staydesk/team_workspaces/:team_id` | Menus, colunas, campos e painéis de quem atende |
| Papéis do agente | `staydesk/roles` e `staydesk/agent_roles/:user_id` | Permissões granulares e a quem cada papel está dado |
| Entrar como | `staydesk/impersonations` | Acompanhar o trabalho de um agente pela conta dele |
| Convites de atendimento | `staydesk/offers` | Convites pendentes de quem está atendendo |
| Campos do ticket | `staydesk/ticket_fields` e `custom_attribute_definitions` | Catálogo de campos e a marcação de obrigatório para resolver |
| Campos de uma conversa | `staydesk/conversations/:numero/ticket_fields` | Lê os valores e o que falta para resolver; `PATCH` preenche |

`GET staydesk/ping` responde se a camada StayDesk está no ar, para monitoração.

## MCP

O servidor fica em `custom/mcp`. São 40 ferramentas, a mesma API por baixo.

| Ferramenta | O que faz |
|---|---|
| `staydesk_kpis` | Números da operação no período: CSAT, tempos de primeira resposta e resolução por canal de trabalho, quem espera na fila e o tempo de cada agente em cada status. |
| `staydesk_configurar` | Aplica a configuração da operação inteira de uma vez, a partir do YAML de `rails staydesk:configurar`. Idempotente. |
| `staydesk_filas_listar` | Filas de encaminhamento: para qual grupo cada demanda vai, transbordo e aceite. |
| `staydesk_filas_criar` | Cria uma fila de encaminhamento. |
| `staydesk_filas_atualizar` | Altera uma fila de encaminhamento. |
| `staydesk_filas_de_carga_listar` | Canais de trabalho: que canal e que caixa contam como chat e como ticket. |
| `staydesk_filas_de_carga_atualizar` | Altera um canal de trabalho. |
| `staydesk_regras_de_capacidade_listar` | Regras de capacidade: quantas conversas de cada canal de trabalho o agente aguenta ao mesmo tempo, a padrão e as atribuídas. |
| `staydesk_regras_de_capacidade_criar` | Cria uma regra de capacidade. |
| `staydesk_regras_de_capacidade_atualizar` | Altera uma regra de capacidade. |
| `staydesk_status_do_ticket_listar` | Catálogo de status do ticket da conta. |
| `staydesk_status_do_ticket_criar` | Cria um status de ticket. |
| `staydesk_status_do_ticket_atualizar` | Altera um status de ticket. |
| `staydesk_status_do_agente_listar` | Status de disponibilidade do agente: o que cada um recebe (chat, ticket) e o atual de quem chama. |
| `staydesk_status_do_agente_criar` | Cria um status de agente. |
| `staydesk_status_do_agente_atualizar` | Altera um status de agente. |
| `staydesk_diagnostico_da_distribuicao` | Por que cada agente recebe ou não recebe cada fila: conexão, disponibilidade, canal, vaga, grupo e canal de que é membro. O caminho de uma conversa específica (`conversation_id`) só existe pela API. |
| `staydesk_carga_dos_agentes` | Quantas conversas cada agente atende agora em cada canal de trabalho, contra o teto da regra de capacidade. |
| `staydesk_politicas_de_sla_listar` | Políticas de SLA: alvos por prioridade, pausa e aviso. |
| `staydesk_politicas_de_sla_criar` | Cria uma política de SLA. |
| `staydesk_calendarios_listar` | Calendários de horário comercial e feriados. |
| `staydesk_visualizacoes_listar` | Visualizações por time: o que cada grupo vê na fila. |
| `staydesk_papeis_listar` | Papéis com permissões granulares e o catálogo de permissões disponível. |
| `staydesk_papeis_criar` | Cria um papel de agente. |
| `staydesk_area_de_trabalho` | Área de trabalho resolvida para quem chama: menus, colunas da lista, campos e painéis da conversa. |
| `staydesk_aceitacao_dos_agentes` | Aceitação de chat e WhatsApp por agente: quantos convites recebeu, aceitou, recusou e deixou expirar. |
| `staydesk_eventos_das_conversas` | Linha do tempo das conversas: mudanças de status, de responsável, de grupo e de prioridade. |
| `staydesk_slas_aplicados` | SLA aplicado a cada conversa, com alvo, status e quando vence. |
| `staydesk_conversas` | Conversas da conta, com os filtros da API do Chatwoot (status, inbox_id, team_id, assignee_type, page). |
| `staydesk_campos_do_ticket_listar` | Catálogo de campos do ticket da conta, com tipo, valores da lista e quais são obrigatórios para resolver. |
| `staydesk_campos_do_ticket_criar` | Cria um campo do ticket. `attribute_display_type` aceita text, number, currency, percent, link, date, list e checkbox; `attribute_values` são as opções quando for lista. |
| `staydesk_campos_do_ticket_atualizar` | Altera um campo do ticket, inclusive marcar ou desmarcar como obrigatório para resolver. |
| `staydesk_campos_da_conversa` | Campos do ticket de uma conversa, com o valor de cada um e a lista do que falta preencher para poder resolver. |
| `staydesk_campos_da_conversa_preencher` | Preenche campos do ticket numa conversa. Manda só o que quer mudar; o resto fica como está. |
| `staydesk_tokens_de_api_listar` | Tokens de API da conta, com os escopos de cada um e o catálogo de escopos possíveis. |
| `staydesk_tokens_de_api_criar` | Cria um token de API com escopo próprio. O valor em claro volta uma única vez nesta resposta. |
| `staydesk_tokens_de_api_atualizar` | Suspende ou reativa um token de API. |
| `staydesk_times_listar` | Grupos da conta. |
| `staydesk_caixas_listar` | Caixas de entrada da conta, com o tipo de canal de cada uma. |
| `staydesk_agentes_listar` | Agentes da conta e o papel de cada um. |

O recomendado é dar ao MCP um token de API com os escopos do que ele precisa, em
vez do token pessoal de alguém.

```sh
pnpm --dir custom/mcp install --ignore-workspace
```

```json
{
  "mcpServers": {
    "staydesk": {
      "command": "node",
      "args": ["/caminho/para/staydesk/custom/mcp/servidor.mjs"],
      "env": {
        "STAYDESK_URL": "https://staydesk.staycloud.com.br",
        "STAYDESK_TOKEN": "...",
        "STAYDESK_ACCOUNT_ID": "1"
      }
    }
  }
}
```

O catálogo de ferramentas é uma tabela em `custom/mcp/ferramentas.mjs`:
acrescentar um endpoint é acrescentar uma linha, sem escrever código. Detalhes em
`custom/mcp/README.md`.

## Configuração em arquivo

Fora da API, a operação inteira entra de uma vez por um YAML:

```sh
rails staydesk:configurar ACCOUNT_ID=1 FILE=configuracao.yml
```

O arquivo cobre a conta (`conta`: o painel do cliente), times, etiquetas,
atributos, caixas, status do ticket, filas de carga (canais de trabalho),
status do agente, regras de capacidade (`regras_de_capacidade`), calendário,
políticas de SLA, filas, visualizações e área de trabalho, mais os **gatilhos**
(seção `automacoes`) e as **macros** (seção `macros`). É idempotente: rodar de
novo só atualiza o que mudou. Ao fim, os membros de cada canal são recalculados
pelas filas, e o resumo traz `canais: {adicionados, removidos}`.

```yaml
conta:
  painel_do_cliente: https://painel.exemplo.com.br/chamados
```

O endereço do painel do cliente vai no botão do e-mail de aviso de recebimento,
para o cliente acompanhar os chamados dele.

O mesmo arquivo entra pela API, sem console, com o token de um administrador:

```sh
curl -X POST -H "api_access_token: sd_seu_token" -H "Content-Type: application/json" \
  --data "$(jq -Rs '{yaml: .}' configuracao.yml)" \
  "https://staydesk.staycloud.com.br/api/v1/accounts/1/staydesk/config_import"
```

### Pôr muita gente em muitos grupos

A seção `times` aceita o grupo só pelo nome ou com quem está nele:

```yaml
times:
  - Administradores
  - nome: Suporte N1
    agentes: [ana@staycloud.com, bruno@staycloud.com]
  - nome: Suporte N2
    agentes: [carla@staycloud.com]
    agentes_exatos: true
```

`agentes` acrescenta quem falta e não tira ninguém. `agentes_exatos: true`
deixa o grupo igual à lista, removendo quem não está nela. Quem não tem conta
na conta do StayDesk aparece no resumo da importação em vez de quebrar a carga.
O mesmo vale pelo MCP, com a ferramenta `staydesk_configurar`.

### Gatilhos e variáveis

A seção `automacoes` cria os gatilhos do produto a partir do mesmo arquivo:

```yaml
automacoes:
  - nome: Confirmação de recebimento
    evento: conversation_created
    canais: ['Channel::Email', 'Channel::Api']
    acoes:
      - tipo: send_message
        valores:
          - "Olá! O seu ticket #{{conversation.display_id}} já foi recebido."
```

`canais` e `caixas` viram condição por caixa (`inbox_id`); sem nenhum dos dois,
o gatilho vale para toda conversa aberta. Diferente da política de SLA, que
resolve o canal na hora, o gatilho guarda os ids das caixas que existiam na
importação: caixa nova pede reimportar a seção `automacoes`. O texto aceita as
variáveis do produto (`conversation.display_id`, `contact.name`, `agent.name`,
`inbox.name`, `account.name`), resolvidas no envio. Mensagem de gatilho não
conta como primeira resposta no SLA nem nos indicadores.

Várias `condicoes` se ligam por E; a linha com `query_operator: OR` liga à
seguinte por OU. O assunto do ticket (`mail_subject`) vale para e-mail e para o
ticket que chega pela API: o `assunto` gravado pela API é copiado para lá,
quando `mail_subject` está vazio. Nas
ações, `assign_team` aceita o nome do grupo, `assign_agent` o e-mail do agente e
`staydesk_set_ticket_status` o nome do status; `staydesk_set_attribute` recebe
`[chave, valor]`. Nome de grupo, e-mail ou status que não existe na conta é
ignorado sem derrubar a importação: a ação fica de fora.

### Macros

```yaml
macros:
  - nome: Devolver pra fila (N2)
    acoes:
      - { tipo: assign_team, valor: Suporte N2 }
      - { tipo: staydesk_set_ticket_status, valor: Aberto }
      - { tipo: send_message, valor: "Olá {{contact.first_name}}, ..." }
```

Entram como macros da conta, visíveis a todos, reconhecidas pelo nome (importar
de novo atualiza). Ações: as do produto (`send_message`, `add_private_note`,
`add_label`, `change_priority`, `resolve_conversation`…) mais as do StayDesk.

Na tela, a macro roda como qualquer macro do produto, num clique, e as ações do
StayDesk fazem o que o Zendesk faz e o community não: `staydesk_set_attribute`
escreve num campo do ticket (valor vazio limpa) e `staydesk_set_ticket_status`
aplica um status do catálogo, alinhando o status base. As duas valem também nos
gatilhos. Por dentro: `Custom::Macro` aceita as ações (gancho em `macro.rb`) e
`Custom::ActionService` as executa. O gatilho tem uma ação a mais,
`staydesk_aviso_de_recebimento`, que não existe na macro, porque é disparada
pela chegada do chamado (ver [marca.md](marca.md#6-e-mail-ao-cliente)).

### Campo obrigatório para resolver

Na seção `atributos`, `obrigatorio_para_resolver: true` trava o encerramento do
ticket enquanto o campo estiver vazio. Sem a chave, fica o que está marcado na tela.


## Para um front que consome a API

### Bloco `staydesk` na conversa

Toda conversa devolvida pela API do produto (`GET /api/v1/accounts/:id/conversations/:display_id`,
listas, filtro, visualizações) e todo evento em tempo real ou webhook de conversa
traz um bloco `staydesk`. Ele existe para o front **não recalcular regra**:

```json
"staydesk": {
  "subject": "Site fora do ar",
  "ticket_status": { "id": 3, "name": "Em andamento", "color": "#0f766e", "base_status": "open" },
  "missing_to_resolve": ["servidor", "classificacao"]
}
```

- `subject`: no ticket (e-mail e API), o assunto do chamado; no chat e no WhatsApp,
  "Chat com <cliente>". A regra está em `Staydesk::ConversationSubject`.
- `ticket_status`: o status do ticket atual, já resolvido pelo catálogo. Sem status
  gravado, vem o padrão do status base.
- `missing_to_resolve`: as chaves dos campos obrigatórios ainda vazios. Lista vazia
  quer dizer que o ticket pode ser resolvido.

### Responder e definir status numa chamada só

`POST staydesk/conversations/:display_id/reply` grava os campos, manda a resposta
(ou nota) e aplica o status do ticket, tudo ou nada. Se faltar campo obrigatório
para resolver, nada é gravado e a resposta 422 lista `missing_to_resolve`. Sem
`content`, só grava os campos e o status, que é o caso de resolver sem escrever.

### Presença por HTTP

`POST staydesk/presence` registra que o agente está conectado e deve ser chamado a
cada 20 s ou menos. Ele faz o mesmo que o `update_presence` do WebSocket. Sem sinal
de vida, o tempo limite do status e a saída ao fechar a aba tiram o agente do status.

### Eventos em tempo real

O StayDesk publica no mesmo canal que o produto já usa: o `pubsub_token` do
agente, assinado no `RoomChannel` do ActionCable (`/cable`). O formato é o do
produto, `{ event, data }`.

| Evento | Quando | `data` |
|---|---|---|
| `staydesk.offer.created` | um convite de atendimento chega ao agente | `id`, `status`, `seconds_left`, `expires_at`, `conversation_id` (display_id), `contact_name`, `inbox_name`, `channel_type`, `subject` |
| `staydesk.offer.accepted` / `.declined` / `.expired` | o convite foi aceito, recusado ou venceu | o mesmo |
| `staydesk.agent_status.changed` | o status do agente mudou: por ele, pelo tempo limite, pela aba fechada ou pela regra de convites perdidos | `account_id`, `current_status_id`, `name`, `availability` |

Os eventos do produto (`conversation.created`, `conversation.updated`,
`message.created`, `presence.update`…) continuam valendo e passam a levar o bloco
`staydesk` nas conversas.

### O que a pessoa pode configurar

`GET staydesk/workspace` devolve, além da área de trabalho, `can_manage`: um mapa
`área → true/false` com as áreas da Central que quem chama pode configurar, pela
mesma regra que o servidor aplica. Use-o para montar o menu da Central.

### Lista de uma visualização

`GET staydesk/team_views/:id/conversations` aceita `page` e `sort_by`. O `sort_by`
precisa ser uma das ordens do produto (`Conversations::SortService::SORT_OPTIONS`);
sem ele, vale a ordem da visualização.

## Superadministração: gerar instâncias

A instância nova (uma conta do StayDesk) se cria pela Platform API, com o token de
um **Platform App** gerado no super admin (`/super_admin`, Platform Apps), no
cabeçalho `api_access_token`. É o mesmo mecanismo da Platform API do produto
(`/platform/api/v1/accounts`, `users`, `account_users`), que continua valendo para
administrar contas e usuários depois.

| Método | Caminho | O quê |
|---|---|---|
| `POST` | `/platform/api/v1/staydesk/instances` | Cria a conta no padrão StayDesk (sem a marca do produto, sem campanhas e central de ajuda, com os papéis prontos), o administrador e, se vier, aplica a configuração da operação |
| `GET` | `/platform/api/v1/staydesk/instances` | Lista as instâncias que o Platform App administra |

Corpo do `POST`:

```json
{
  "account": { "name": "Cliente X", "locale": "pt_BR", "support_email": "suporte@clientex.com" },
  "admin": { "name": "Ana", "email": "ana@clientex.com", "password": "opcional" },
  "config_yaml": "times:\n  - Suporte N1\n..."
}
```

`config_yaml` (texto YAML) ou `config` (o mesmo em JSON) é o arquivo da operação,
o mesmo do `config_import`. Quem já tem usuário com aquele e-mail é só vinculado
como administrador. A resposta traz `account`, `admin`, `login_url` (link de
acesso de uso único: sem `password`, é por ele que o administrador entra e define
a senha) e `configuration` (o resumo da importação). Tudo acontece numa transação:
se a configuração falhar, nada é criado.
