# StayDesk — handoff visual do workspace do agente

> Status: ready for implementation · 2026-08-28 · Canvas + Axiom / squad-design + squad-artdir
> Escopo: frontend-only, sem novos contratos, mocks, placeholders ou controles não funcionais.

## 1. Direção

O workspace adota o modelo operacional do Zendesk Support sem copiar sua aparência. A familiaridade vem da fila como ponto de partida, da conversa dominante durante o atendimento e do contexto acessível sem abandonar o ticket. A expressão segue StayCloud: neutros predominantes, Geist, superfícies discretas e indigo reservado à ação, foco e seleção real.

Regras do corte:

- A conversa ocupa pelo menos 50% da largura útil em 1440 px.
- Navegação, fila e contexto cedem espaço antes da conversa.
- Preferências salvas pelo agente sempre prevalecem sobre defaults.
- Uma ação primária por tela; envio da resposta é o primary do ticket.
- Estado nunca depende apenas de cor.
- Ausência de dado não gera espaço, conteúdo simulado ou affordance vazia.

## Brand grounding — Gallery/Main 6

Fontes verificadas: [StayGallery — Cores](https://gallery.staycloud.com/#cores), `Main 6/src/app.css`, `src/app.html`, `src/lib/styles/v2.css`, `static/staycloud-{logo,mark}.svg` e o draft de sidebar. Gallery define a marca; os tokens v2 do Main 6 definem sua aplicação em produto. O draft com DM Sans, shell flutuante e sombra dupla é exploração, não padrão a portar.

| Grounding | Contrato exato para o StayDesk |
|---|---|
| Primitivos Gallery | Azul `#545DFF`, grafite `#18181B`, papel `#FFFFFF`, linha editorial `#E7E7EA`, texto suave `#71717A`; uma cor de marca, o resto neutro |
| Produto light / dark | Manter os semânticos do Main 6: `paper #fff/#161616`, `bg #f7f7f5/#0a0a0a`, `bg-2 #f1f1ef/#111`, `bg-3 #e6e6e3/#1f1f1f`, `line #e4e4e7/#262626`; `#E7E7EA` não substitui `line` localmente |
| Brand / estado | `brand #545dff`, `brand-2 #7e85ff`, `brand-deep #2c3bd6`, `ok #1a9f63`, `warn #d97706`, `danger #dc2626`; `theme/colors.js` já ancora o 500 correto |
| Geist | Gallery usa variável 100–900; Main 6 carrega 300/400/500/600/700/800. StayDesk usa Geist self-hosted; `tailwind.config.js` ainda em Inter é dívida futura, não ajuste documental disfarçado |
| Raio, sombra, densidade | Produto operacional: botão 40/8, small 32/8, large 48/12, card 12, modal 14, pill 999; sombras `0 1px 0 line`, depois 8/24 e 16/40; grid 8 com meio passo 4. Não portar o raio 14 e a sombra dupla do draft para o shell |
| Logo light | Mapear `public/brand-assets/logo.svg` para Gallery `assets/logo/staycloud-logo-light.svg`: símbolo `#545DFF` + wordmark `#18181B` |
| Logo dark | Mapear `public/brand-assets/logo_dark.svg` para Gallery `assets/logo/staycloud-logo-dark.svg`: símbolo `#545DFF` + wordmark `#FFFFFF` |
| Thumbnail | Mapear `public/brand-assets/logo_thumbnail.svg` para Gallery `assets/logo/staycloud-symbol.svg` (`#545DFF`); em fundo brand usar a variante `staycloud-symbol-white.svg`, nunca recolorir por filtro |
| Regra de uso | Preservar proporção/viewBox, área livre mínima igual à altura do símbolo, sem contorno, gradiente, sombra ou composição “StayDesk” improvisada |
| Delta | Os três assets públicos foram atualizados neste ciclo com os SVGs oficiais da Gallery. A migração de Inter para Geist e a reconciliação da escala `woot` permanecem como evolução frontend futura, com fonte self-hosted e validação em light/dark |

## 2. Superfícies existentes e limite

| Superfície | Redesign visual | Limite funcional |
|---|---|---|
| Shell | Refinar superfícies, divisores e hierarquia no estado escolhido pelo agente | Sem mudar default, largura, toggle, preferência, navegação, rota ou persistência |
| Fila | Hierarquia dos dados disponíveis: contato, canal, horário, preview, não lidos, prioridade, labels, responsável e SLA existente | Sem dado, filtro, ordenação ou ação nova |
| Ticket | Prioridade visual para header, histórico e composer atuais | Sem nova região, campo, estado ou controle |
| Composer | Resposta/nota, rascunho por conversa e modo, resize e ferramentas já habilitadas | Sem mudança de envio, status, opção ou fluxo |
| Contexto | Refinar o painel e os accordions atuais | Sem nova navegação, conteúdo, integração ou comportamento |

O redesign não cria, remove, renomeia ou reordena opções. Mock, placeholder, botão decorativo e label sem ação são proibidos.

## 3. Shell

### Anatomia

| Região | Especificação | Classes Tailwind aplicáveis |
|---|---|---|
| Navegação global | Ícones monocromáticos; 56 px colapsada, 200 px default e resize atual até 320 px | `h-full flex-shrink-0 bg-n-surface-2 text-n-slate-11`; ativo `bg-n-alpha-2 text-n-slate-12 font-medium` |
| Fila sem ticket | Ocupa toda a área após a navegação | `flex min-w-0 flex-1 flex-col overflow-hidden bg-n-surface-1` |
| Ticket no expandido | Fila sai; ticket recebe a largura livre | `flex min-w-0 flex-1 flex-col bg-n-surface-1` |
| Ticket no condensado salvo | Fila 340 px, ou 412 px em 2xl; ticket dominante | `w-[340px] 2xl:w-[412px] flex-shrink-0 border-e border-n-weak` |
| Contexto | 320/360 px, separado por `line`; drawer abaixo de 768 px | `md:w-[320px] md:min-w-[320px] 2xl:w-[360px] 2xl:min-w-[360px] border-s border-n-weak bg-n-surface-2` |

O estado expandido/condensado, a visibilidade da fila, o botão de voltar e as preferências seguem exatamente a lógica atual do Chatwoot. O redesign somente trata suas superfícies visuais.

### Superfícies

- `bg` no shell; `paper` em ticket, fila, composer, menus e modais.
- `bg-2` em headers auxiliares, contexto e hover; `bg-3` apenas em pressed ou divisor forte.
- `line` separa regiões; `line-2` separa itens. Não usar cards aninhados para estruturar colunas.
- Controles icon-only atuais usam `inline-flex size-8 items-center justify-center rounded-lg text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12 focus-visible:outline-n-brand`; sombras apenas em dropdown, modal e drawer móvel.

## 4. Fila

### Anatomia

1. Header de 52 px: nome da view e contador/status à esquerda; filtros e alternância de layout existentes à direita.
2. Tabs existentes de responsabilidade/participação, com active claro e neutro.
3. Lista contínua, sem aparência de grade de cards.
4. Ações em massa somente durante seleção, preservando ações atuais.

| Faixa do item | Conteúdo e tratamento | Classes Tailwind aplicáveis |
|---|---|---|
| Container | Linha contínua de 56 px, preservando a medida esperada pela lista virtual | `group relative grid h-14 items-center gap-3 border-b border-n-slate-3 px-4` |
| Identidade | Avatar, nome e dados atuais em uma linha escaneável | `min-w-0 truncate font-semibold text-n-slate-12` |
| Metadados | Prioridade, responsável, status, inbox, ID e horário nas posições atuais | `flex items-center gap-2 text-n-slate-11`; horário `tabular-nums` |
| Resumo | Preview atual truncado, sem criar segunda linha | Manter `CardContent` e seu contrato atual |
| Operação | Não lidas, SLA e labels somente quando já presentes | Preservar `CardLabels`, `SLACardLabel` e `UnreadBadge` atuais |

Ordem de leitura: nome → motivo visível de atenção → preview → contexto operacional. Prioridade mantém seu ícone; SLA usa ícone, rótulo e tempo.

### Densidade e estados

- Item de 56 px em linha única para preservar a virtualização e a densidade operacional existente.
- Padding horizontal de 16 px; gaps de 4, 8 ou 12 px. Texto essencial nunca abaixo de 12 px.
- Default `bg-n-surface-1`; hover `hover:bg-n-alpha-1`; focus `focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-[-2px] focus-visible:outline-n-brand`; active `bg-n-brand/5 dark:bg-n-brand/10`; selected `bg-n-brand/10 dark:bg-n-brand/20`.
- Não lido combina peso, contraste e contador. SLA em risco usa `warn` + ícone + texto; violado usa `danger` + ícone + texto.
- Loading inicial usa skeleton da mesma anatomia, `aria-busy` e `inert`. Loading incremental preserva os itens carregados.
- Empty usa mensagem real da view/filtro; CTA somente se uma ação funcional já existir. Erro preserva itens anteriores quando disponíveis.

## 5. Ticket e composer

### Ticket

1. Header: voltar quando aplicável, avatar, contato, ID copiável, inbox, snooze existente, SLA existente, chamada habilitada e menu atual.
2. Histórico flexível: ocupa o espaço entre header e composer, com scroll próprio.
3. Composer ancorado: banner contextual, modo, editor, anexos e barra de ferramentas.
4. Switch atual abre e fecha o contexto.

Nome do contato é L1: `truncate text-sm font-medium text-n-slate-12`. ID, inbox e snooze são L2: `text-xs text-n-slate-11 tabular-nums`. O header usa `flex h-12 min-w-0 items-center gap-3 border-b border-n-weak bg-n-surface-1 px-3`, sem sombra. Ordem, rótulo e função dos controles atuais permanecem intactos.

Mensagens usam largura de leitura confortável. Cliente e agente se distinguem por alinhamento, metadados e diferença sutil de superfície, sem grandes blocos brand. Nota interna preserva o âmbar atual e o label explícito; esse âmbar indica modo, não `warn` de SLA.

### Composer

| Região | Especificação | Classes Tailwind aplicáveis |
|---|---|---|
| Container | Superfície, borda, raio 12 px e margem 8 px; sem sombra | `relative mx-2 mb-2 rounded-xl border border-n-weak bg-n-solid-1` |
| Modos | “Responder” e “Nota interna” textuais; seleção por superfície, posição e label | Toggle `h-8 rounded-full border bg-n-alpha-2 p-1`; selecionado `bg-n-solid-1 text-n-slate-12 shadow-sm` |
| Editor | Resize existente, texto mínimo 14 px, placeholder suave | `min-w-0 px-3 text-sm text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none` |
| Ferramentas | Somente recursos permitidos pelo canal e feature flag | `flex min-w-0 items-center gap-2 p-3 text-n-slate-11`; hover `hover:bg-n-alpha-2 hover:text-n-slate-12` |
| Envio | Texto ao fim; brand na resposta e âmbar na nota; disabled legível | Resposta `bg-n-brand text-white`; nota usa variante amber existente; `disabled:cursor-not-allowed disabled:opacity-50` |

Preservar atalhos atuais de respostas e macros, resize, restrições e rascunhos separados por conversa/modo. Focus within usa ring `brand`; estados de envio, falha e contador apenas recebem tratamento visual, sem qualquer mudança de condição ou comportamento.

## 6. Painel de contexto

O primeiro corte mantém a sidebar atual e sua navegação:

1. Header com título e fechar.
2. Resumo do contato.
3. Accordions existentes: ações, participantes, detalhes, atributos, conversas anteriores, macros, notas e arquivos.
4. Integrações aparecem somente quando configuradas e habilitadas.

Fundo `bg-n-surface-2` e `border-s border-n-weak`; sem sombra no desktop. Header de accordion: `flex min-h-10 w-full items-center justify-between gap-2 px-3 py-2 text-sm font-medium text-n-slate-12 hover:bg-n-alpha-1 focus-visible:outline-n-brand`. Conteúdo aberto usa `border-t border-n-weak px-3 py-4 text-sm text-n-slate-11`; fechado não reserva altura. Evitar um card por accordion. Drag handle aparece apenas onde a ordenação funciona e possui nome acessível.

Fechado ou aberto, o painel mantém largura, drawer, clique externo, Escape e comportamento de foco já implementados. Loading e erro preservam as condições atuais; somente sua hierarquia visual é refinada.

## 7. Tokens semânticos

| Uso | Token | Utilities no Chatwoot |
|---|---|---|
| Fundo global / superfície | `bg` / `paper` | `bg-n-surface-2` / `bg-n-surface-1`, `bg-n-solid-1` |
| Superfícies auxiliares | `bg-2`, `bg-3` | `bg-n-alpha-1`, `bg-n-alpha-2`, `bg-n-slate-3` |
| Texto | `ink`, `ink-2`, `muted`, `muted-2` | `text-n-slate-12`, `text-n-slate-11`, `text-n-slate-10` |
| Bordas | `line`, `line-2` | `border-n-weak`, `border-n-slate-3`, `outline-n-weak` |
| Ação, foco, seleção | `brand`, `brand-tint`, `brand-deep` | `bg-n-brand`, `text-n-brand`, `outline-n-brand`, `bg-n-brand/5 dark:bg-n-brand/10` |
| Sucesso / atenção / erro | `ok`, `warn`, `danger` | Variantes `n-teal`, `n-amber`, `n-ruby`; manter ícone + texto |

Geist é a única família. Título de view: 16/24, weight 500; heading: 14/20, weight 500; texto: 14/20; metadado: 12/16; label auxiliar: 10–11 px, weight 500. Números operacionais usam `tabular-nums`. Sentence case sempre.

Grid base de 8 px, com 4 px apenas dentro de componentes compactos. Escala: 4, 8, 12, 16, 24 e 32 px. Raios: chip 6, input/botão 8, item 10, card/composer 12, modal 14. Transição padrão 120 ms ease; modal 140–160 ms; respeitar `prefers-reduced-motion`.

Dark mode usa `bg` `#0a0a0a` e `paper` `#161616`, sem matiz azul/roxa. Utilities semânticas `n-*` fazem a troca de tema; não duplicar cores hardcoded em `dark:`. Máximo de dois usos indigo visíveis e apenas um CTA primary.

## 8. Responsividade

| Viewport | Comportamento |
|---|---|
| ≥1600 px | Preservar larguras e preferências atuais; ampliar somente a distinção visual das regiões |
| 1440–1599 px | Preservar visibilidade da fila, navegação e contexto conforme lógica atual |
| 1280–1439 px | Preservar breakpoints e alternância atuais; reduzir apenas ruído visual |
| 768–1279 px | Fila e ticket alternam no expandido; header pode quebrar em duas linhas; contexto 320 px |
| <768 px | Fila e ticket exclusivos; back visível; contexto em drawer; sem scroll horizontal global |

Cruzar breakpoint não apaga preferência. Fila, histórico e contexto têm scroll vertical local. Tooltips não substituem labels essenciais. O teclado virtual não pode encobrir editor ou envio.

## 9. Acessibilidade e QA

- Usar `nav`, `main` e `aside`; lista de tickets com semântica de lista e item navegável por teclado.
- Icon-buttons têm `aria-label`; tabs/toggles expõem selected/pressed; accordions usam `aria-expanded` e `aria-controls`.
- Alvo essencial mínimo 44 × 44 px. Focus visible tem contraste 3:1 e não é removido.
- A ordem e o destino de foco, assim como o comportamento de Escape, permanecem idênticos ao Chatwoot atual.
- Loading usa `aria-busy`; conteúdo bloqueado usa `inert`. Erro de envio é anunciado e mantém o rascunho.
- Texto normal atende 4,5:1; ícones e componentes, 3:1. `muted-2` não serve a conteúdo essencial.
- SLA, prioridade, disponibilidade e não lido combinam cor com texto, ícone, forma ou peso.
- Zoom a 200%, dark mode, reduced motion e RTL preservam operação e hierarquia.

## 10. Critério de pronto

O corte está pronto quando o agente parte da fila, abre um ticket prioritário em até duas ações, atende com conversa dominante, alterna claramente entre resposta e nota, consulta o contexto existente e retorna à fila sem perder rascunho ou preferência. Nenhum controle inexistente, dado simulado ou alteração funcional aparece na entrega.
