# QA de UX: Zendesk Agent Workspace para Staydesk

> Status: QA funcional inicial concluído na instância StayCloud, em modo somente leitura. O produto legado Zendesk Chat foi excluído do escopo. Atualizado em 2026-08-28.

## Objetivo

Reproduzir no Staydesk o modelo operacional que a equipe já domina no Zendesk, sem copiar a aparência do produto. A navegação, a velocidade de triagem e os atalhos devem ser familiares. Cores, tipografia, superfícies e microcopy seguem o Guardian da StayCloud.

## Fontes verificadas

- [Agent Workspace](https://support.zendesk.com/hc/en-us/articles/4408821259930-About-the-Zendesk-Agent-Workspace)
- [Painel de contexto](https://support.zendesk.com/hc/en-us/articles/4408836526362-Using-the-context-panel)
- [Abas de tickets](https://support.zendesk.com/hc/en-us/articles/4408844108826-Using-ticket-tabs-to-manage-conversations)
- [Composer e rascunhos por canal](https://support.zendesk.com/hc/en-us/articles/4408831849882-Composing-messages-in-the-Zendesk-Agent-Workspace)
- [Macros no composer](https://support.zendesk.com/hc/en-us/articles/4408887656602-Using-macros-to-update-tickets)
- [Atalhos de teclado](https://support.zendesk.com/hc/en-us/articles/4408832849946-Viewing-and-deactivating-keyboard-shortcuts)
- [Filas e roteamento omnichannel](https://support.zendesk.com/hc/en-us/articles/4409149119514-About-omnichannel-routing)

## Princípios de tradução

1. Copiar o modelo mental, não os pixels do Zendesk.
2. A conversa ocupa pelo menos 50% da largura útil.
3. Navegação e contexto cedem espaço quando não estão em uso.
4. Uma ação primária por tela. Indigo apenas em ação, foco ou estado realmente selecionado.
5. Preferências de largura, painel e modo de resposta persistem por agente.
6. Fluxos frequentes devem funcionar por teclado, sem esconder a alternativa visual.

## Resultado do QA na operação StayCloud

### Escopo e higiene de dados

- O levantamento foi feito no Zendesk Support e no Agent Workspace.
- O produto legado acessível por `/chat/agent` não é usado pela equipe e não entra no benchmark.
- Nenhum ticket foi enviado, alterado, resolvido ou reatribuído durante o QA.
- Nomes, e-mails, domínios, IDs de clientes, mensagens e URLs privadas não foram registrados neste documento.

### Shell, views e fila

- A navegação global é uma rail estreita de ícones. A navegação secundária muda conforme a superfície ativa.
- A operação possui 24 views compartilhadas ativas, com filas principais e recortes de acompanhamento por status, canal, SLA e tipo de demanda.
- As views são tabelas densas, não apenas cards de conversa. As colunas úteis incluem colisão de agentes, grupo, SLA, status, satisfação, assunto, solicitante, data, responsável e ações.
- O SLA aparece na fila com hierarquia visual forte, inclusive para itens vencidos.
- Ao abrir um ticket, a fila sai de cena. O espaço é entregue aos campos, à conversa e ao contexto.
- O modo guiado e a ação de avançar reduzem o custo de escolher manualmente o próximo ticket.

### Workspace do ticket

- Tickets abertos viram abas persistentes no topo, com assunto, ID e fechamento. Alternar entre dois tickets exige uma ação.
- Em 1440 x 900, o ticket usa três regiões redimensionáveis: campos à esquerda, conversa e composer no centro, contexto à direita.
- A região central mostra assunto, canal, SLA, ações do ticket, resumo do Copilot, histórico e composer.
- Os campos operacionais realmente presentes incluem marca, solicitante, responsável, seguidores, formulário, tags, classificação, tipo de demanda, tipo de produto, servidor, habilidades e referências do sistema financeiro.
- Existem dois formulários ativos e cinco estados operacionais: novo, aberto, em andamento, pendente e resolvido.

### Composer e conclusão do trabalho

- Resposta pública e nota interna são modos explícitos do mesmo composer.
- O composer é redimensionável e inclui formatação, anexos, links, voz e assistência de escrita.
- Macros são descobertas por um seletor no rodapé. O atalho `/` não abriu a lista para o usuário auditado, então o Staydesk não deve depender apenas do atalho.
- Status e comportamento após o envio são decisões separadas. O agente escolhe o status e, independentemente, escolhe entre fechar a aba, abrir o próximo ticket da view ou permanecer no ticket.
- Essa separação é superior a um botão genérico de resolver e deve ser preservada no Staydesk.

### Contexto e aplicativos

- A rail de contexto alterna cliente, conversas paralelas, tickets relacionados, aprovações, tarefas e aplicativos.
- O estado do painel de aplicativos é preservado ao alternar entre tickets.
- A operação usa aplicativos para áudio de WhatsApp, apoio do StayCopilot, controle da assistente e consulta do cliente no sistema financeiro.
- O aplicativo financeiro concentra conta, serviços, faturas, status, escalonamento e links operacionais. No Staydesk, a aba StayCloud deve absorver esse papel sem expor detalhes de infraestrutura ao agente.
- O Context Panel deve ser uma plataforma extensível para ferramentas, não apenas um cartão estático de contato.

### Macros, regras e SLA

- O Zendesk Support possui 57 macros compartilhadas ativas. Destas, 20 foram usadas nos últimos 7 dias e 37 não tiveram uso no período.
- As seis macros mais usadas concentraram 597 de 639 aplicações no período, ou 93,4%. A migração deve começar por esse núcleo e revisar o restante antes de importar.
- Existem 52 gatilhos ativos, agrupados em notificações, segregação de marca, SLA, roteamento e ações.
- Existem cinco automações ativas baseadas em tempo. Elas cobrem fechamento pós-resolução, CSAT, acompanhamento de pendência e alerta preventivo de SLA.
- Existem quatro políticas de SLA. A política principal de tickets diferencia prioridade baixa, normal, alta e urgente.
- Metas observadas na política principal: primeira resposta de 5 h, 2 h 30 min, 1 h e 30 min; atualização de 4 h 30 min, 2 h 30 min, 1 h 10 min e 50 min; resolução total de 48 h, 12 h, 4 h e 3 h.

### Achado de segurança fora do escopo visual

- Foi observada uma URL com credencial temporária exposta no histórico de um ticket. O valor não foi copiado.
- Antes de migrar histórico, é necessário definir sanitização de segredos e mascaramento de URLs sensíveis no importador e na interface.

## Matriz inicial de paridade

| Capacidade | Zendesk | Staydesk atual | Decisão | Prioridade |
|---|---|---|---|---|
| Conversa como área dominante | A fila sai de cena ao abrir o ticket; campos, conversa e contexto são redimensionáveis | Navegação, fila, conversa e contato competem por largura | Nesta fase, melhorar somente separação e hierarquia visual; mudanças de default ficam para uma story funcional futura | P0 |
| Várias conversas abertas | Abas persistentes com canal, assunto, ID e atividade | Uma conversa ativa por rota | Criar uma barra de trabalho com tickets abertos, overflow e rascunho pendente | P0 |
| Fila operacional | 24 views ativas em tabelas densas, com prioridade, SLA, status e colisão | Folders, filtros, times, inboxes e ordenação já existem | Melhorar hierarquia, contadores, SLA, motivo de atenção e densidade antes de criar nova lógica | P0 |
| Responder e avançar | Status e destino pós-envio são controles independentes | Próximo/anterior existe no Inbox, mas não é o fluxo principal da lista | Adicionar status e comportamento pós-envio configurável, incluindo próximo item da fila | P0 |
| Rascunho público e nota | Rascunhos separados por canal e persistentes | Já existem rascunhos por conversa e por modo reply/note | Preservar. Tornar o estado de rascunho visível na fila e nas futuras abas | P0 |
| Composer ajustável | Altura redimensionável, persistida entre tickets | `ResizableEditorWrapper` já cobre o redimensionamento | Preservar e validar foco, limite e persistência | P0 |
| Macros rápidas | Seletor visual no rodapé; 93,4% do uso concentrado em seis macros | `/` abre respostas prontas e `#` abre macros | Destacar frequentes, preservar busca visual e manter atalhos como aceleração | P1 |
| Contexto do cliente | Rail alterna cliente, apps, tickets relacionados, tarefas e conversas paralelas | Painel fixo de 320/360 px com accordions | Criar Context Panel único com Cliente, StayCloud, Ferramentas, Notas e Base | P1 |
| Largura do contexto | Painel redimensionável e preferência preservada | Largura fixa | Adicionar resize com limites e persistência por agente | P1 |
| Histórico e páginas vistas | Perfil, interações, dispositivo e navegação recente | Perfil, conversas anteriores, atributos e arquivos | Agrupar por relevância e incluir dados StayCloud sem expor infraestrutura interna | P1 |
| Conhecimento no ticket | Busca, sugestão, link e citação sem sair do ticket | Help Center existe fora do fluxo principal | Integrar busca e inserção no Context Panel | P2 |
| Atalhos globais | Navegação, ticket e macros configuráveis por agente | Command bar e atalhos de conversa já existem | Mapear diferenças e oferecer preset familiar ao time StayCloud | P2 |
| Status operacionais | Novo, aberto, em andamento, pendente e resolvido | Estados de conversa do Chatwoot não têm equivalência completa | Preservar semântica e mapear estados na migração | P0 |
| SLA | Políticas por prioridade, visíveis na fila e no ticket | Recurso enterprise disponível no ambiente de avaliação | Reproduzir metas e alertas antes do go-live | P0 |
| Regras de negócio | 52 gatilhos e 5 automações sustentam o fluxo atual | Automations existem, mas a equivalência ainda não foi validada | Fazer inventário e teste de paridade regra a regra antes da migração | P0 |

## Achados no código do Chatwoot

### Aproveitar sem reescrever

- `components-next/sidebar/Sidebar.vue` já tem resize, colapso e persistência.
- `ReplyBox.vue` mantém rascunhos separados por conversa e modo de resposta.
- `ResizableEditorWrapper.vue` já permite ajustar a altura do composer.
- `WootWriter/Editor.vue` já abre respostas prontas com `/` e macros com `#`.
- Folders, inboxes, labels, teams e custom views já formam a base das Views do Zendesk.
- O command bar já concentra atribuição, prioridade, status, labels e macros.

### Gaps de UX, não de backend

- Não há memória visual de várias conversas abertas.
- A fila não mostra com clareza o motivo de cada ticket precisar de atenção.
- O painel de contato usa uma sequência longa de accordions e largura fixa.
- Recursos existentes têm baixa descoberta: macros, atalhos, filtros e layout expandido.
- O fluxo principal não incentiva resolver e seguir para o próximo item da fila.

## Roteiro de regressão na instância StayCloud

Executar com uma conta de agente comum e, depois, com uma conta de administrador.

### Fluxo 1: começar o turno

1. Identificar onde o agente vê trabalho novo, pendente e próximo do SLA.
2. Registrar quais views são usadas e em qual ordem.
3. Medir cliques até abrir o primeiro ticket prioritário.
4. Verificar contadores, filtros persistidos e status do agente.

### Fluxo 2: atender um ticket

1. Abrir um ticket real de cada canal ativo.
2. Localizar assunto, solicitante, organização, prioridade, SLA e responsável.
3. Responder, alternar para nota interna e voltar para resposta pública.
4. Aplicar uma macro frequente.
5. Alterar status, responsável e campos obrigatórios.
6. Resolver e seguir para o próximo ticket.

### Fluxo 3: trabalhar em paralelo

1. Abrir três tickets de canais diferentes.
2. Alternar entre eles e confirmar preservação de rascunhos.
3. Identificar alertas de nova mensagem e digitação.
4. Reordenar ou fechar abas sem perder o contexto da fila.

### Fluxo 4: entender o cliente

1. Abrir perfil, organização, histórico e apps instalados.
2. Registrar quais campos realmente ajudam a resolver o chamado.
3. Separar dados úteis de ruído administrativo.
4. Mapear o equivalente StayCloud: plano, serviços, faturas, incidentes e saúde da conta.

### Fluxo 5: administrar o fluxo

1. Listar views, macros, triggers, automações e campos ativos.
2. Registrar volume e uso recente de cada macro.
3. Identificar regras de SLA e roteamento que alteram a ordem da fila.
4. Capturar somente nomes e estruturas. Não registrar tickets, mensagens ou dados pessoais no documento.

## Métricas de aceitação de UX

| Métrica | Meta inicial |
|---|---|
| Abrir o próximo ticket prioritário | Até 2 ações a partir da fila |
| Alternar entre três tickets ativos | 1 ação, sem perder rascunho |
| Aplicar macro frequente | Até 3 teclas mais busca |
| Trocar resposta pública por nota | 1 ação, com distinção visual inequívoca |
| Consultar plano StayCloud | 1 ação no painel de contexto |
| Resolver e seguir | 1 ação configurável |
| Largura da conversa em 1440 px | Pelo menos 50% da área útil |

## Sequência de implementação

1. Shell e largura da conversa.
2. Abas de trabalho e indicador de rascunho.
3. Status e comportamento pós-envio, incluindo seguir para a próxima conversa.
4. Hierarquia e densidade da fila.
5. Context Panel com Cliente, StayCloud, Notas e Base.
6. Atalhos e descoberta de macros.
7. Polimento visual, estados vazios, loading, erro, teclado e dark mode.

O QA real alterou a ordem original: depois do shell, abas e comportamento pós-envio têm precedência sobre o polimento da lista. A paridade de regras e SLA continua sendo um gate funcional separado do redesign visual.

### Primeiro corte implementado nesta branch

- A navegação mantém colapso, largura e preferência exatamente como no Chatwoot atual; nesta fase muda apenas a apresentação.
- O layout de conversa mantém o default e a alternância atuais; mudanças de comportamento ficam explicitamente adiadas.
- Preferências já salvas continuam tendo precedência.
