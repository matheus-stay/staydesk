# StayDesk — reauditoria final do redesign visual-only

> Beacon / squad-design · 2026-08-28 · WCAG 2.2 AA · comparação com `HEAD`

## Verdict

**PASS.** Os dois achados visuais do gate anterior foram corrigidos somente por classes. Não restam regressões bloqueantes de contraste, foco visível, reflow, reduced motion ou legibilidade no escopo auditado.

Os contratos interativos continuam preservados: nenhum foco, teclado, DOM interativo, ARIA, evento ou função foi adicionado ou alterado. Este verdict é restrito ao diff visual-only e não recertifica problemas preexistentes fora desse escopo.

## Escopo e método

Comparação do redesign Vue com `HEAD`, com reauditoria específica de:

- estado persistente active/selected em `ConversationCardExpanded.vue`;
- altura e reflow do header em `ConversationHeader.vue`;
- contratos de interação, contrastes textuais, foco visível existente, reduced motion, RTL e legibilidade já verificados no gate anterior.

O gate automatizado e a inspeção do diff confirmam que scripts, bindings, elementos interativos, conteúdo, condições, handlers e ordem do DOM permanecem idênticos ao `HEAD`; as mudanças estão limitadas a `class` e `:class`.

## Achados revalidados

### ALTO-01 — Indicador persistente da conversa ativa

**CORRIGIDO.** `ConversationCardExpanded.vue:73-80` mantém o tint e adiciona `!border-s-2 !border-s-n-brand` aos estados active e selected.

| Tema | Indicador | Contraste contra `n-surface-1` | Gate 1.4.11 |
|---|---|---:|---:|
| Light | `n-brand` | **3,75:1** | PASS ≥ 3:1 |
| Dark | `n-brand` | **4,83:1** | PASS ≥ 3:1 |

A borda lógica de 2 px é persistente, não depende da animação removida e funciona no inline-start em LTR e RTL. A compilação Tailwind em memória confirma a ordem efetiva: `border-color` geral é emitido antes de `border-inline-start-color`, portanto a borda brand prevalece apesar de ambos usarem `!important`.

Resultado: atende WCAG 2.2 **1.4.11 — Non-text Contrast** nos dois temas.

### ALTO-02 — Reflow do header abaixo de `xl`

**CORRIGIDO.** `ConversationHeader.vue:113` substitui a altura fixa abaixo de `xl` por `h-auto min-h-28`; em `xl`, preserva a variante de uma linha com `xl:h-16 xl:min-h-0`.

- Altura mínima necessária das duas linhas: 109 px.
- Nova altura mínima abaixo de `xl`: 112 px.
- `h-auto` permite crescimento adicional com zoom/text resize ou conteúdo maior.
- Em `xl`, 64 px com `py-3` deixa 40 px internos para controles de 32 px; `border` e `pt-2` são removidos nessa variante.

Não há mais compressão forçada das duas linhas dentro de 96 px. Resultado: sem regressão estática de WCAG 2.2 **1.4.10 — Reflow** ou **1.4.4 — Resize Text**.

## Matriz final

| Área | Resultado | Evidência |
|---|---|---|
| Contratos interativos | **PASS** | Behavior-preserving Vue gate; scripts, bindings e elementos interativos idênticos ao `HEAD` |
| Active/selected | **PASS** | Borda lógica brand: 3,75:1 light e 4,83:1 dark |
| Reflow do header | **PASS** | `h-auto min-h-28` abaixo de `xl`; `h-16 min-h-0` em `xl` |
| Texto principal | **PASS** | `n-slate-12`: 15,58:1 light e 15,74:1 dark nos fundos auditados |
| Texto secundário | **PASS** | `n-slate-11` sobre `n-surface-1`: 5,89:1 light e 8,77:1 dark |
| Badge de não lidas | **PASS** | `UnreadBadge.vue:20`: 16,25:1 light e 15,74:1 dark |
| Foco visível | **SEM REGRESSÃO** | Nenhum `outline-none` novo; props, ordem de foco e focáveis idênticos ao `HEAD` |
| Clipping de foco | **SEM REGRESSÃO ESTÁTICA** | Focáveis internos mantêm gutters; nenhum focável foi deslocado para borda com overflow |
| Reduced motion | **PASS** | Transições novas usam `motion-reduce:transition-none`; animação do card foi removida |
| Legibilidade | **PASS** | Pesos tipográficos e `tabular-nums` não reduzem tamanho, line-height ou conteúdo |
| RTL | **PASS** | Indicador usa inline-start; utilitários lógicos existentes foram preservados |

## Checks executados

- `pnpm exec eslint` direcionado às duas correções: **0 erros, 2 warnings preexistentes** de raw text no header.
- Gate automatizado de preservação Vue: **PASS**.
- Suíte direcionada: **95 testes PASS**.
- Build Vite: **PASS**.
- Compilação Tailwind em memória das classes de borda: **PASS**; width e color lógicas geradas com `!important` na ordem correta.
- Contraste WCAG 2 calculado com `#2781F6` e os valores light/dark efetivos de `_next-colors.scss`.
- QA 1280×720 anterior: sem overflow global (`document` 1280/1280, `main` 1046/1046, conversa 680/680).
- `git diff --check HEAD`: **PASS**.

## Gate de release

O redesign visual-only está aprovado. A implementação pode seguir sem qualquer ampliação para foco, teclado, DOM interativo, ARIA, evento ou função.
