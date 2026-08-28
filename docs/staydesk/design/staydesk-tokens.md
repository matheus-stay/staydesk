# StayDesk — Design Tokens (portados do StayCloud UI Guardian)

> Status: v1 · 2026-08-28 · Fonte da verdade: skill `staycloud-ui-guardian` do painel (`references/brand-tokens.md`)
> Regra de ouro herdada: **mais cinza que cor, mais espaço que decoração, indigo é assinatura, não enchimento.**

## Cores — sistema (light / dark)

| Token | Light | Dark | Uso |
|---|---|---|---|
| `paper` | `#ffffff` | `#161616` | Card, modal, dropdown |
| `bg` | `#f7f7f5` | `#0a0a0a` | Fundo principal |
| `bg-2` | `#f1f1ef` | `#111111` | Header de tabela, footer |
| `bg-3` | `#e6e6e3` | `#1f1f1f` | Track de progress, divisor pesado |
| `ink` | `#18181b` | `#fafafa` | Texto principal |
| `ink-2` | `#27272a` | `#e4e4e7` | Texto secundário forte |
| `muted` | `#71717a` | `#a1a1aa` | Texto secundário |
| `muted-2` | `#a1a1aa` | `#71717a` | Texto terciário, label uppercase |
| `line` | `#e4e4e7` | `#262626` | Border hairline |
| `line-2` | `#ededed` | `#1f1f1f` | Divisor interno |

**Dark = preto neutro tipo Vercel/Linear. NUNCA azulado/roxeado.**

## Cores — brand (indigo)

| Token | Valor | Uso |
|---|---|---|
| `brand` | `#545dff` | CTA primário, link, foco |
| `brand-2` | `#7e85ff` | Hover |
| `brand-deep` | `#2c3bd6` | Active/pressed |
| `brand-tint` | `color-mix(in oklab, #545dff 8%, white)` | Fundo de ícone, pill |
| `brand-soft` | `color-mix(in oklab, #545dff 14%, white)` | Hover de área indigo |

## Cores — semântica (SÓ estas)

| Token | Valor | Uso |
|---|---|---|
| `ok` | `#1a9f63` | Sucesso, online |
| `warn` | `#d97706` | Atenção, expira |
| `danger` | `#dc2626` | Erro, vencido |

## Tipografia

**Família única: Geist** (Google Fonts `Geist:wght@300;400;500;600;700;800`). Destaque com weight 500 (não 700). `tabular-nums` em todo número de coluna. Labels uppercase 10-11px com tracking `+0.06em`.

## Raio / Sombra / Motion

- Raio: chip 6 · input/botão 8 · item lista 10 · card 12 · modal 14 · pill/avatar 999
- Sombras: `0 1px 0 line` (sm) → `+ 8px 24px -10px rgb(0 0 0/.08)` (md) → `+ 16px 40px -12px .12` (lg)
- Transição padrão `0.12s ease`; modal 0.14-0.16s; **NUNCA** bounce, parallax, confetti, pulse >2s; respeitar `prefers-reduced-motion`

## As 10 regras absolutas (herdadas do Guardian — valem no StayDesk)

1. Máximo **2 indigos visíveis por tela**; 1 botão primary
2. Ícones banidos: `Sparkles`, `Wand`, `Wand2`, `WandSparkles`; sem emojis decorativos
3. Componentes do design system são obrigatórios (sem `<select>` nativo)
4. Mock/placeholder não vai pra produção
5. Zero vazamento de infra user-facing
6. Sem container duplo (max-width só no layout pai)
7. **Sentence case sempre**; sem "!", sem hype
8. Status comercial ≠ status runtime (pills diferentes)
9. Estrutura canônica: eyebrow + h1 + (tabs?) + content
10. A11y: `aria-label` em icon-button, cor+dot+label em status, `inert` em loading

---

# Mapeamento → Chatwoot (plano de implementação)

O Chatwoot centraliza cor de marca na paleta `woot` ([theme/colors.js](../../../theme/colors.js), hoje = Radix blue) consumida pelo [tailwind.config.js](../../../tailwind.config.js). **Trocar a escala `woot` re-branda o dashboard inteiro.**

## Escala `woot` → indigo StayDesk (draft — calibrar visualmente no Histoire)

| Step | Hex | Nota |
|---|---|---|
| 25 | `#f5f6ff` | |
| 50 | `#eef0ff` | ~brand-tint |
| 75 | `#e3e6ff` | |
| 100 | `#d6daff` | |
| 200 | `#b3b9ff` | |
| 300 | `#8b93ff` | ~brand-2 |
| 400 | `#6a72ff` | |
| 500 | `#545dff` | **brand** |
| 600 | `#4149e6` | |
| 700 | `#2c3bd6` | brand-deep |
| 800 | `#232fa8` | |
| 900 | `#1a2378` | |

## Demais mapeamentos

| Chatwoot | StayDesk |
|---|---|
| `fontFamily.inter` / `interDisplay` | Geist (self-host woff2 — sem Google Fonts em produção) |
| Paleta `slate` (Radix) | Manter Radix slate na v1 (próxima do neutro Guardian); avaliar override fino na v2 |
| `green`/`yellow`/`red` | Apontar 500 pra `ok`/`warn`/`danger` do Guardian |
| Dark mode (`darkMode: 'class'`) | Conferir fundos escuros → neutros puros (`#0a0a0a`/`#161616`), nunca azulados |
| Animações `wiggle`/`shake` | Manter (feedback funcional, permitido pelo Guardian) |

## Ordem de ataque (EPIC-003)

1. **3.1a** — Escala `woot` + fontes Geist em `theme/colors.js` + `tailwind.config.js` (1 PR, impacto global)
2. **3.1b** — Validação visual no Histoire + telas principais; calibrar steps da escala
3. **3.2+** — Shell (sidebar/header), conversa, widget — conforme `front-end-spec.md`
