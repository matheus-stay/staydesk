# StayDesk — mapa técnico do workspace frontend

> 2026-08-28 · Scaffold / squad-design · Vue 3 + Chatwoot v4 · UI/UX somente
> Base: diff atual, árvore real da conversa, handoffs StayDesk e story 3.3.

## 1. Gate de escopo

O redesign pode alterar somente apresentação: classes Tailwind, ordem visual de blocos não interativos, superfícies, bordas, tipografia, densidade, truncamento e estados visuais já existentes. Deve reutilizar exatamente os dados, componentes, props, emits, diretivas e condições atuais.

É proibido alterar ou criar defaults, preferências, breakpoints funcionais, watchers, methods, computeds, foco programático, elementos interativos, rotas, stores, requests, payloads, flags, permissões, persistência, atalhos ou fluxo pós-ação. Acessibilidade que exija nova interação deve ser um corte próprio aprovado, não misturado ao redesign visual.

## 2. Auditoria do diff atual

**Resultado atual: PASS para um corte estritamente visual.** Defaults, fluxo de foco, semântica do checkbox e estrutura funcional da linha expandida foram restaurados ao contrato de `HEAD`.

| Arquivo / hunk auditado | Mudança comportamental encontrada | Resultado |
|---|---|---|
| `ConversationCardExpanded.vue`: `<label>` contextual, `sr-only`, focus ring e alvo de 44 px em torno de `Checkbox` | ampliava alvo, nome acessível e foco | removido; `div @click.stop`, elementos, diretivas e condições originais restaurados |

Para equivalência estrita, `show-empty` de prioridade/status, `v-if`, blocos, conteúdo e ordem do card permanecem idênticos ao baseline. O diff final do componente se limita a classes Tailwind.

### Hunks comportamentais detectados e já retirados

- `provider.js`: default responsivo de largura da sidebar por `window.innerWidth`.
- `globals.js`, `Dashboard.vue`, `ChatListHeader.vue`, `ReplyBox.vue` e `ConversationView.vue`: novo default global `expanded` e seus fallbacks/toggle.
- `ConversationView.vue`: estado, watchers, method e `ref` para foco após navegação.
- `ConversationHeader.vue`: marcador DOM de destino do foco.
- `ConversationCardExpanded.vue`: botão nativo/marcador/`@click.stop` para abertura por teclado.

Não há diff atual em Rails, API, requests, stores, payloads ou `enterprise/`. Os SVGs de marca e documentos são visuais, mas ficam em commit separado porque não pertencem ao corte do workspace.

### Mudanças atuais que são apenas visuais

- Classes de grid, espaçamento, truncamento, pesos, superfícies e estados de hover/selected da linha expandida.
- `text-n-slate-11` no horário e o seletor local `n-slate-9` para a borda vazia do checkbox.
- `UnreadBadge.vue` com `bg-n-slate-12 text-n-surface-1`.
- Classes Tailwind atuais de shell, sidebar, fila, ticket, histórico, compositor e contexto; scripts, eventos e bindings permanecem iguais.
- Assets de marca, desde que entregues fora do diff do workspace.

## 3. Árvore e contratos a preservar

```text
Dashboard.vue
├─ components-next/sidebar/Sidebar.vue
└─ ConversationView.vue
   ├─ ChatList.vue → ChatListHeader.vue → ConversationList.vue (Virtua)
   │  └─ ConversationItem.vue → ConversationCardExpanded.vue | ConversationCard.vue
   ├─ ConversationBox.vue
   │  ├─ ConversationHeader.vue
   │  └─ MessagesView.vue → MessageList.vue
   │     └─ ResizableEditorWrapper.vue → ReplyBox.vue
   └─ ConversationSidebar.vue → ContactPanel.vue
```

- Fila: preservar Virtua, altura medida, paginação, bulk selection, context menu e `ConversationItem.onCardClick`.
- Ticket: preservar `currentChat`, dashboard apps, banners, unread boundary, typing e retry.
- Composer: preservar reply/note, drafts separados, resize, anexos, macros, templates, Copilot e canais.
- Contexto: preservar overlay mobile, largura/persistência, drag, accordions, flags, Linear e Shopify.
- Dados disponíveis continuam `chat.id`, `meta.sender`, `meta.assignee`, `inbox_id`, `priority`, `status`, `applied_sla`, `unread_count`, `labels`, `timestamp` e `getLastMessage(chat)`; nenhum dado derivado novo.

## 4. Menor mapa visual perceptível

Dezesseis seams já existentes cobrem as cinco superfícies sem entrar em lógica. Em todos eles, editar somente atributos `class`/`:class`; não adicionar/remover tags, componentes, diretivas, refs ou bindings.

| Superfície | Arquivos exatos | Classes Tailwind propostas, sem mudar comportamento |
|---|---|---|
| Shell | `Dashboard.vue`, `ConversationView.vue`, `components-next/sidebar/Sidebar.vue` | `bg-n-background`, canvas `bg-n-slate-2`, frame `md:rounded-xl md:border md:shadow-sm`; preservar dimensões, breakpoints, router e resize |
| Lista/frame | `ChatList.vue`, `ConversationList.vue` | `overflow-hidden`, `bg-n-surface-1`, `md:rounded-xl md:border`, transição de cor reduzível; preservar largura, Virtua e overflow funcional |
| Lista/header | `ChatListHeader.vue` | `h-14 border-b border-n-weak bg-n-surface-1 px-4`; título `font-semibold tracking-[-0.01em]` |
| Lista/linha | `components-next/Conversation/ConversationCard/ConversationCardExpanded.vue` | grid denso, `gap-2/3`, `border-n-slate-3`, `hover:bg-n-slate-2`, active/selected com baixa opacidade de `n-brand`, `tabular-nums`, `truncate`, `text-n-slate-11/12`; manter altura aceita pelo Virtua |
| Lista/unread | `components-next/Conversation/ConversationCard/UnreadBadge.vue` | `bg-n-slate-12 text-n-surface-1`, raio e dimensões atuais |
| Conversa | `ConversationBox.vue`, `ConversationHeader.vue`, `MessagesView.vue` | frame `rounded-xl border shadow-sm`, header `bg-n-surface-1 px-4`, canvas `bg-n-slate-2/50`, histórico `px-3 md:px-6`; não tocar tabs/slots/loop |
| Compositor | `ReplyBox.vue`, `WootWriter/ReplyTopPanel.vue`, `WootWriter/ReplyBottomPanel.vue` | wrapper `rounded-xl border-n-strong bg-n-surface-1 shadow-sm`, topo/rodapé com separadores; modo privado conserva tokens amber atuais |
| Contexto | `ConversationSidebar.vue`, `ContactPanel.vue` | `bg-n-surface-1`, `border-n-weak`, `md:rounded-xl md:shadow-sm`; manter width, fixed/static, transform, drag e accordions |

Não entram: `provider.js`, `globals.js`, `ConversationItem.vue`, `ResizableEditorWrapper.vue`, card condensado ou qualquer script. Isso impede que o acabamento altere layout escolhido, navegação, foco, virtualização, resize ou persistência.

## 5. Gate mecânico behavior-preserving

Rodar após retirar os hunks comportamentais. O gate usa `HEAD` como base do working tree; em PR, definir `BASE` para o merge-base.

```bash
set -euo pipefail
BASE="${BASE:-HEAD}"
ALLOW='^(docs/staydesk/.*|app/javascript/dashboard/routes/dashboard/(Dashboard.vue|conversation/(ConversationView|ContactPanel).vue)|app/javascript/dashboard/components/(ChatList|ChatListHeader|ConversationList).vue|app/javascript/dashboard/components-next/sidebar/Sidebar.vue|app/javascript/dashboard/components-next/Conversation/ConversationCard/(ConversationCardExpanded|UnreadBadge).vue|app/javascript/dashboard/components/widgets/conversation/(ConversationBox|ConversationHeader|ConversationSidebar|MessagesView|ReplyBox).vue|app/javascript/dashboard/components/widgets/WootWriter/Reply(Top|Bottom)Panel.vue)$'

changed="$( { git diff --name-only "$BASE"; git ls-files --others --exclude-standard; } | sort -u )"
unexpected="$(printf '%s\n' "$changed" | rg -v "$ALLOW" || true)"
test -z "$unexpected" || { echo "FAIL: arquivo fora da allowlist"; echo "$unexpected"; exit 1; }

contract() {
  tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | rg -o -P '(@[A-Za-z0-9:.-]+|v-[A-Za-z0-9:.-]+|:(?!class=)[A-Za-z0-9:.-]+|ref|aria-[A-Za-z0-9-]+|role|tabindex|href|type|disabled|checked|name)="[^"]*"|</?(button|a|input|label)(?=[ >])' || true
}

for file in $(git diff --name-only "$BASE" -- '*.vue'); do
  before="$(mktemp)"; after="$(mktemp)"
  git show "$BASE:$file" | sed -n '/<script/,/<\/script>/p' > "$before"
  sed -n '/<script/,/<\/script>/p' "$file" > "$after"
  diff -q "$before" "$after" >/dev/null || { echo "FAIL: script mudou: $file"; exit 1; }
  git show "$BASE:$file" | contract > "$before"
  contract < "$file" > "$after"
  diff -q "$before" "$after" >/dev/null || { echo "FAIL: contrato/interação mudou: $file"; exit 1; }
done

forbidden="$(git diff -U0 "$BASE" -- '*.vue' | rg '^\+[^+].*(<style|(:?style)=|#[0-9A-Fa-f]{3,8})' || true)"
test -z "$forbidden" || { echo "FAIL: CSS/inline/hex fora de Tailwind"; echo "$forbidden"; exit 1; }

git diff --check "$BASE"
pnpm exec eslint $(git diff --name-only "$BASE" -- '*.vue')
```

Gate humano complementar: comparar antes/depois e confirmar mesma contagem e ordem de controles, mesmos nomes acessíveis, mesmos `v-if`/`v-show`, props, emits e ações; mouse, teclado, context menu, bulk selection, reply/note, resize e painel lateral devem produzir exatamente os mesmos efeitos.

## 6. Validação visual

- Light/dark, RTL e reduced motion; contraste AA nos estados default, hover, selected, active e disabled.
- 375, 768, 1024, 1440×900, 1536, 1599 e 1600 px, sem alterar os breakpoints atuais.
- Lista com/sem SLA, assignee, labels, unread, prioridade/status e textos longos; sem salto do Virtua.
- Ticket multicanal com banners, dashboard apps, unread boundary e histórico longo.
- Composer reply/note, drafts, anexos, macros/templates/Copilot e resize; contexto aberto/fechado e overlay mobile.
- `pnpm exec vitest run app/javascript/dashboard/components/widgets/conversation/specs/ConversationCard.spec.js --no-cache --no-coverage` e `pnpm exec vite build` antes do handoff final.

## Decisão

O comportamento do checkbox e a lógica estrutural do card foram restaurados. O redesign permanece nas dezesseis seams da allowlist como diff de classes Tailwind. O resultado visual vem de superfícies, hierarquia tipográfica, separadores e estados consistentes; nenhuma capacidade ou fluxo muda.
