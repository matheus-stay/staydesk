# StayDesk — UX visual handoff do ticket

> Escopo reaberto em 2026-08-28 · Compass / squad-design · **ticket-only, visual-only**

## Decisão de escopo

Este handoff substitui integralmente a direção anterior. O objetivo agora é aproximar a clareza visual do ticket do Zendesk Support usando **somente os componentes, controles, dados e estados que já existem na conversa StayDesk**.

São permitidos apenas ajustes de hierarquia tipográfica, densidade, espaçamento, alinhamento, superfícies, bordas, raios, contraste e tratamento visual dos estados já emitidos.

Não faz parte deste trabalho:

- adicionar, remover, ocultar, renomear ou reordenar controles e opções;
- criar campos, abas, ações, atalhos, tooltips, estados ou mensagens;
- mudar fluxo, navegação, condição de exibição, breakpoint ou comportamento responsivo;
- mudar eventos, foco, teclado, resize, drag, persistência, props, emits, stores, requests ou rotas;
- representar visualmente capacidades futuras ou dados que o StayDesk não possui hoje.

A ordem de DOM, os rótulos/i18n, os `v-if`, a sequência dos accordions e a divisão entre cabeçalho, histórico, composer e contexto são invariantes. “Agrupamento” neste documento significa reforço visual por proximidade, gap, divisor ou superfície entre elementos **já adjacentes**, nunca deslocamento funcional.

## Método e evidência

A comparação usa a observação sanitizada do Zendesk Support Agent Workspace registrada em `qa-zendesk-agent-workspace.md` e a inspeção do frontend StayDesk atual. A evidência existente foi suficiente; não houve novo acesso a tickets nem uso de dados pessoais.

O Zendesk é referência de princípios — hierarquia central forte, chrome secundário discreto, composer ancorado e contexto separado — e não um inventário a copiar. Sua coluna de campos, assunto, estado operacional, SLA, Copilot, apps e ações próprias não autorizam equivalentes novos no StayDesk.

## Inventário imutável do ticket atual

| Região | Componentes e controles existentes | Comportamento a preservar |
|---|---|---|
| Estrutura central | `ConversationBox.vue`: `ConversationHeader`, tabs de dashboard apps quando existentes, `MessagesView`, `EmptyState`, `DashboardAppFrame` | Alternância, seleção e condições atuais |
| Cabeçalho | `ConversationHeader.vue`: `BackButton`, avatar, nome, alerta de contato não verificado, ID copiável, inbox condicional, snooze, SLA condicional, chamada e `MoreActions` | Ordem, conteúdo, clique, foco e responsividade atuais |
| Histórico | `MessagesView.vue`: banners existentes, `MessageList`, referência, `UnreadBadge`, sugestão de label, typing e loading | Ordem cronológica, alinhamento, scroll e estados atuais |
| Composer | `ResizableEditorWrapper.vue` + `ReplyBox.vue`: resize, modo, editor, anexos/ferramentas e envio | Modos, rascunho, resize, teclado e envio atuais |
| Modo de envio | `EditorModeToggle.vue`: Reply / Private note | Mesmos dois rótulos, mesma alternância e mesmo destino |
| Ferramentas e CTA | `ReplyTopPanel.vue` + `ReplyBottomPanel.vue`: ferramentas condicionais existentes, expandir e botão de envio | Mesma disponibilidade, ordem, ação e condição |
| Contexto | `ConversationSidebar.vue` + `ContactPanel.vue`: contato e accordions existentes | Mesma largura/show-hide, ordem arrastável e estado salvo |
| Alternador lateral | `SidepanelSwitch.vue`: contato e Copilot quando disponível | Mesmos itens, condição e seleção |

## Matriz competitiva visual

| Dimensão | Lição visual do Zendesk Support | Leitura do StayDesk atual | Direção visual-only | Destino existente | Limite obrigatório |
|---|---|---|---|---|---|
| **Hierarquia — página** | O histórico domina; header, composer e contexto funcionam como moldura | A estrutura já separa essas quatro regiões, mas superfícies próximas podem competir | Dar maior peso tonal ao plano do histórico; usar header/composer/contexto como superfícies delimitadoras discretas | `ConversationBox.vue`, `MessagesView.vue`, `ConversationSidebar.vue` | Não mudar largura, ordem, tabs, painel ou fluxo |
| **Hierarquia — header** | Identidade e metadados precedem ações secundárias | Nome, ID e inbox já formam um bloco; SLA e ações já formam outro | Tornar nome o nível 1, ID/inbox/snooze o nível 2 e ações o nível 3 por tamanho, peso e contraste | Elementos já existentes em `ConversationHeader.vue` | Não incluir assunto, status, prioridade, responsável ou qualquer dado novo |
| **Hierarquia — histórico** | Mensagens permanecem protagonistas e o chrome recua | Banners, mensagens, não lido, sugestões e typing compartilham a coluna | Preservar mensagens com maior contraste de conteúdo; reduzir apenas o contraste estrutural de containers auxiliares | `MessageList` e estados já renderizados por `MessagesView.vue` | Não mudar ordem, agrupamento lógico, conteúdo ou alinhamento por remetente |
| **Hierarquia — composer** | A área de resposta é uma unidade visual ancorada, com modo e envio reconhecíveis | O StayDesk já tem wrapper, painel superior, editor, ferramentas e CTA | Tratar o composer como uma única superfície: topo/editor/rodapé relacionados por borda e espaçamento; CTA mantém maior ênfase | `ResizableEditorWrapper.vue`, `ReplyBox.vue`, `ReplyTopPanel.vue`, `ReplyBottomPanel.vue` | Não mudar resize, ferramentas, envio, expansão ou posição dos controles |
| **Densidade — header** | Alta densidade com níveis claros e pouco ruído decorativo | Header já é compacto no desktop e empilha no breakpoint atual | Manter alturas e breakpoints; usar peso/contraste para separar identidade, metadados e ações sem acrescentar linhas | `ConversationHeader.vue` | Não alterar altura funcional, wrap, breakpoint ou visibilidade |
| **Densidade — histórico** | Gutter previsível e ritmo compacto facilitam varredura | A lista ocupa bem a coluna, com estados intercalados | Normalizar somente padding lateral e ritmo vertical existentes; manter largura e geometria das bolhas | `MessagesView.vue`, `MessageList.vue` e bolhas existentes | Não criar agrupamento temporal, limite de largura ou regra de compactação nova |
| **Densidade — contexto** | A lateral reúne informação densa em blocos escaneáveis | O painel já tem largura fixa e accordions arrastáveis | Reduzir ruído entre containers e reforçar títulos/divisores dos accordions com os tokens atuais | `ConversationSidebar.vue`, `ContactPanel.vue` | Preservar 320/360 px, ordem, abertura, drag e conteúdo |
| **Espaçamento — macro** | As regiões se distinguem mais por gutters e divisores do que por decoração | Header, histórico, composer e painel já têm fronteiras | Usar escala coerente: gap curto dentro do controle, médio dentro do bloco, maior somente entre regiões existentes | Wrappers já existentes nas quatro regiões | Não inserir wrappers funcionais nem deslocar regiões |
| **Espaçamento — composer** | Modo, texto e ferramentas parecem uma sequência única | Os três níveis já existem, mas podem parecer cartões separados | Alinhar paddings esquerdo/direito do painel superior, editor e rodapé; manter o respiro externo atual | `ReplyBox.vue`, `ReplyTopPanel.vue`, `ReplyBottomPanel.vue` | Não alterar hit area, tab order ou resize handle |
| **Agrupamento — header** | Identidade fica de um lado; ações ficam juntas do outro | A estrutura atual já oferece esses dois grupos | Reforçar proximidade dentro de cada grupo e separação por espaço, sem mover nenhum item | Blocos existentes em `ConversationHeader.vue` | Mesma ordem e mesmas condições |
| **Agrupamento — composer** | Modo pertence ao conteúdo; ferramentas pertencem ao envio | A estrutura já expressa topo/editor/rodapé | Usar uma borda externa e divisores suaves apenas onde já há transição de painel | `ReplyBox.vue` e painéis existentes | Nenhuma ferramenta nova, removida ou realocada |
| **Agrupamento — contexto** | Seções têm cabeçalhos consistentes e conteúdo subordinado | ContactInfo e accordions já são sequenciais | Repetir o mesmo tratamento de título, borda e padding em accordions existentes; contato continua no topo | `ContactPanel.vue` | Não criar tabs, categorias ou nova ordenação |
| **Estados — Reply/Private note** | Destino do envio tem tratamento visual persistente | Toggle e superfície âmbar da nota já comunicam o modo | Manter texto atual e reforçar simultaneamente seleção, borda e superfície; Reply usa brand, Private note usa amber | `EditorModeToggle.vue`, `ReplyBox.vue`, CTA existente | Não renomear, duplicar ou mudar alternância/destino |
| **Estados — feedback** | Loading, alertas e separadores não competem com a conversa | Banners, spinner, unread, label suggestion e typing já existem | Dar a cada estado existente um nível visual estável: alerta > não lido > sugestão/typing > loading | `MessagesView.vue`, `UnreadBadge.vue` e componentes já chamados | Não criar copy, severidade, ação ou estado novo |
| **Estados — tabs/apps** | Seleção de superfície é evidente | Tabs aparecem somente quando dashboard apps existem | Uniformizar contraste de default/hover/focus/selected nas tabs atuais | `ConversationBox.vue` e `woot-tabs` existente | Não criar tab, mover app para lateral ou mudar seleção |
| **Estados — contexto** | Alternador lateral deixa a superfície ativa reconhecível | Contato e Copilot já possuem estado selecionado | Aplicar a mesma gramática de default/hover/focus/selected aos botões existentes | `SidepanelSwitch.vue` | Não incluir item, label ou condição nova |

## Sistema visual aplicável

### Hierarquia e tokens

- Usar somente a paleta semântica `n-*` já disponível: superfícies `n-surface-*`, texto `n-slate-12/11/10`, borda `n-weak`/`n-slate-3`, ação/foco `n-brand` e nota privada `n-amber`.
- O conteúdo da mensagem e o nome do contato têm maior contraste; metadados e chrome usam níveis secundários, nunca opacidade arbitrária.
- Preservar a fonte e a escala tipográfica do produto. Não introduzir fonte, ícone, ilustração ou linguagem visual externa do Zendesk.
- Preferir borda de 1 px e diferença de superfície a sombras novas. Raio deve seguir o componente atual; não transformar todas as regiões em cards.
- Cor nunca deve substituir o rótulo, ícone ou forma que o controle já possui. O trabalho visual apenas reforça sinais existentes.

### Ritmo e densidade

Aplicar a escala já expressa pelas utilities atuais, sem medidas arbitrárias novas:

| Relação | Ritmo desejado | Componentes existentes |
|---|---|---|
| Ícone + rótulo/metadado | curto, equivalente a `gap-1`/`gap-1.5` | Header, toggle, ferramentas, alternador lateral |
| Itens do mesmo grupo | compacto, equivalente a `gap-2` | Identidade e ações do header, ferramentas do composer |
| Conteúdo dentro da região | médio, equivalente a `p-3`/`p-4` conforme já usado | Header, composer, ContactInfo e accordions |
| Fronteira entre regiões | uma borda ou gutter existente, não ambos em excesso | Header/histórico, histórico/composer, conversa/contexto |

As alturas responsivas do header, a largura 320/360 px do contexto, o respiro externo do composer e a geometria das mensagens permanecem os atuais. O ganho vem da consistência, não da compressão de controles.

## Matriz de estados visuais

| Estado já existente | Tratamento visual esperado | Componente/controle atual | Não mudar |
|---|---|---|---|
| Default | Superfície e texto no nível mais baixo que preserve leitura | Todos os controles inventariados | Conteúdo e disponibilidade |
| Hover | Mudança sutil de superfície/borda, sem deslocamento | Botões do header, ferramentas, tabs, alternador | Clique ou hit area |
| Focus visible | Anel `n-brand` claramente separado de selected/active | Todos os controles focáveis existentes | Ordem, destino ou lógica de foco |
| Active/pressed | Contraste momentâneo sem animação ornamental | Botões existentes | Evento e duração funcional |
| Selected | Superfície + texto/ícone, sem depender só da cor | Tabs, `SidepanelSwitch`, `EditorModeToggle` | Seleção e rótulo |
| Reply | Brand nos elementos já associados ao modo | Toggle, superfície/CTA existentes | Envio público e rascunho |
| Private note | Amber + rótulo já visível + borda/superfície | Toggle, `ReplyBox`, CTA existente | Nota interna e rascunho |
| Disabled/restricted | Contraste reduzido com sinal existente preservado | Composer e ferramentas quando já desabilitados | Regra de habilitação |
| Warning/error banner | Maior saliência da coluna, com copy/ícone atuais | Banners já renderizados em `MessagesView.vue` | Severidade, texto e ação |
| Unread | Divisor/badge reconhecível, abaixo de alertas e acima de metadados | `UnreadBadge.vue` | Contagem e posição |
| Typing/suggestion | Baixa saliência, legível e estável | Typing e label suggestion atuais | Conteúdo e duração |
| Loading | Indicador atual visível sem criar skeleton | Spinner existente | Ciclo de carregamento |
| Empty | Estado atual centralizado na superfície disponível | `EmptyState` existente | Copy e ação |
| Context open/selected | Botão selecionado corresponde à superfície aberta | `SidepanelSwitch.vue`, `ConversationSidebar.vue` | Show/hide e item ativo |
| Dashboard app selected | Tab ativa distingue-se de hover/focus | Tabs existentes em `ConversationBox.vue` | Apps, ordem e conteúdo |

Light e dark devem manter a mesma ordem de saliência, usando tokens do tema em vez de cores literais. Estados de foco permanecem visíveis nos dois temas. Nenhuma animação, transição ou comportamento de `prefers-reduced-motion` será adicionado ou alterado neste corte; efeitos existentes apenas não devem ser ampliados.

## Referência Zendesk: adotar × não copiar

| Adotar como princípio visual | Não copiar para o StayDesk |
|---|---|
| Conversa como foco principal | Coluna de campos do ticket |
| Header compacto com níveis claros | Assunto, status, prioridade, responsável ou SLA onde não existem |
| Composer como unidade ancorada | Novas opções de envio ou pós-envio |
| Resposta e nota com estado persistente | Novos rótulos, botões ou toggle |
| Contexto separado e escaneável | Novas tabs, apps, resumo ou Copilot |
| Chrome secundário discreto | Ícones, fonte, cores ou aparência proprietária do Zendesk |

## Critérios de aceite visual-only

- [ ] Inventário de controles, rótulos, ícones, opções e conteúdo é idêntico antes/depois.
- [ ] Ordem de DOM, tab order, foco, eventos e caminhos de teclado são idênticos.
- [ ] `v-if`, feature flags, permissões, breakpoints e regras de show/hide não mudam.
- [ ] Props, emits, stores, requests, rotas, persistência, resize e drag não mudam.
- [ ] Header preserva somente identidade, metadados e ações já existentes, com três níveis visuais claros.
- [ ] Histórico é a região de maior prioridade; banners e estados auxiliares mantêm sua posição atual.
- [ ] Composer continua sendo uma única unidade visual, sem alterar modo, ferramentas ou envio.
- [ ] Reply e Private note continuam inequívocos por rótulo, forma/seleção e cor.
- [ ] Contexto preserva largura, ordem e estado dos accordions; nenhuma tab ou categoria nova.
- [ ] Default, hover, focus visible, active, selected e disabled são distinguíveis em light/dark.
- [ ] Nenhuma redução de ruído oculta controle ou enfraquece informação necessária.
- [ ] A comparação final usa apenas o ticket aberto; fila, navegação global e capacidades futuras ficam fora.

## Handoff para execução visual

Canvas pode produzir estados light/dark do ticket atual em 1440×900 e no breakpoint já suportado, mantendo o inventário 1:1. Scaffold deve limitar o diff a classes/utilities visuais nos componentes mapeados acima e recusar qualquer alteração de template que mude conteúdo, ordem, condição ou interação. A validação final compara lado a lado: hierarquia, densidade, spacing, agrupamento e estados — nunca paridade funcional com o Zendesk.
