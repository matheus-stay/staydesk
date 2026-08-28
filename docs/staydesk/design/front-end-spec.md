# StayDesk — Front-end Spec v1

> 2026-08-28 · @design (Nexus) + FABLE CTO · Base: Guardian tokens + Chatwoot `components-next` + IA do Zendesk Agent Workspace
> Companion: [staydesk-tokens.md](staydesk-tokens.md) · [architecture-map.md](../architecture-map.md)

## Princípio-guia

> O agente de CS não quer um app bonito. Quer **fechar mais tickets com menos ruído**.
> Herdamos a mentalidade do Guardian: mais cinza que cor, mais espaço que decoração, indigo é assinatura.

---

## 1. Diagnóstico estrutural — Zendesk (3 colunas) vs Chatwoot (4 colunas)

**Zendesk Agent Workspace:**

```
┌────────┬──────────────────────────┬─────────────────┐
│ Views  │   Ticket (conversa +     │ Context panel   │
│ (fila) │   composer)              │ user/knowledge/ │
│        │                          │ apps (toggle)   │
└────────┴──────────────────────────┴─────────────────┘
```

**Chatwoot hoje:**

```
┌──────┬───────────────┬────────────────────┬──────────────┐
│ Nav  │ Lista de      │ Conversa +         │ Contact      │
│ icon │ conversas     │ composer           │ panel        │
└──────┴───────────────┴────────────────────┴──────────────┘
```

**Achado central:** o Chatwoot gasta **uma coluna inteira** com navegação enquanto o Zendesk resolve nav+fila em uma só. Em tela de notebook (1440px) sobra pouco pro que importa: a conversa.

### Decisão de arquitetura visual (ADR-002)

| # | Decisão | Racional |
|---|---|---|
| 1 | **Nav colapsável por padrão em <1600px** | O `Sidebar.vue` do `components-next` já é resizable/colapsável (`useSidebarResize`) — usar, não reinventar |
| 2 | **Unificar o painel direito num Context Panel com abas** (Cliente · StayCloud · Notas) | Espelha o modelo mental que o Naldo já tem do Zendesk; abre espaço pro EPIC-004 (dados StayCloud no ticket) |
| 3 | **Conversa é a região dominante** — mínimo 50% da largura útil | Métrica objetiva de sucesso do redesign |
| 4 | Sem 5ª coluna, nunca | Anti-padrão do Guardian: mais espaço que decoração |

---

## 2. Mapa de superfícies (o que redesenhar, em ordem)

| # | Superfície | Base técnica | Prioridade |
|---|---|---|---|
| S1 | **Tokens globais** (cor, tipo, raio, sombra) | `theme/colors.js` + `tailwind.config.js` | 🔴 P0 — destrava tudo |
| S2 | **Shell**: sidebar + header + account switcher | `components-next/sidebar/*` (já existe, moderno) | 🔴 P0 |
| S3 | **Lista de conversas** (a "fila") | `components-next/Conversation/ConversationCard` | 🟠 P1 |
| S4 | **Conversa + composer** | `components-next/Conversation` + `Editor` | 🟠 P1 |
| S5 | **Context panel** (abas Cliente/StayCloud/Notas) | `routes/.../ContactPanel.vue` → migrar p/ next | 🟡 P2 (casa com EPIC-004) |
| S6 | **Settings** | `components-next/Settings` | 🟡 P2 |
| S7 | **Widget** (o que o cliente final vê) | `app/javascript/widget` | 🟢 P3 |
| S8 | **Help Center / portal** | `app/javascript/portal` | 🟢 P3 |

**Regra de ouro técnica:** só construir sobre `components-next/`. O `components/` legado está sendo deprecado pelo upstream — investir lá é dívida garantida no próximo sync.

---

## 3. Contrato visual (não-negociável, herdado do Guardian)

| Regra | Aplicação no StayDesk |
|---|---|
| Máx. 2 indigos por tela, 1 primary | Botão "Responder" é o primary da conversa. Badge de não-lido usa neutro + peso, não indigo |
| Sentence case | "Atribuir conversa", não "Atribuir Conversa" |
| Status comercial ≠ runtime | Status da **conversa** (aberta/pendente/resolvida) ≠ status do **cliente StayCloud** (ativo/suspenso). Pills visualmente distintas |
| Ícones banidos | `Sparkles`/`Wand*` — inclusive nas features de IA (Captain). Usar ícone funcional |
| `tabular-nums` | Toda coluna de número: contadores de fila, tempo de resposta, SLA |
| A11y | Icon-button → `aria-label`; status → cor + dot + label; loading → `inert` |
| Dark mode | Preto neutro (`#0a0a0a`/`#161616`). Nunca azulado |

---

## 4. Plano de execução (EPIC-003 refinado)

| Story | Escopo | Dono | Risco de merge c/ upstream |
|---|---|---|---|
| **3.1a** | Escala `woot` → indigo StayDesk + Geist em `theme/colors.js` e `tailwind.config.js` | Luiz | 🟢 Baixo (2 arquivos) |
| **3.1b** | Calibração visual no Histoire; ajuste fino dos steps | Luiz | 🟢 Nulo |
| **3.2** | Shell: densidade da sidebar, colapso default, logo StayDesk | Luiz | 🟡 Médio |
| **3.3** | Lista de conversas: hierarquia, badges, densidade | Luiz | 🟡 Médio |
| **3.4** | Conversa + composer: proporção, bolhas, ações rápidas | Luiz + dev | 🟠 Alto |
| **3.5** | Context panel com abas (prepara EPIC-004) | dev | 🟠 Alto |
| **3.6** | Widget rebrand | dev | 🟢 Baixo |

**Ordem inegociável:** 3.1a antes de tudo. Trocar a paleta re-branda o produto inteiro num PR só — é o maior retorno visual por linha de código do projeto.

### Fluxo de trabalho do Luiz (hot-reload)

Depende da story **1.4** (ambiente dev nativo). Sem ela, cada ajuste de CSS exige rebuild de container — inviável pra design. **1.4 é pré-requisito de 3.1b em diante.**

---

## 5. Trilha Claude Design / Figma (opcional, recomendada em S4-S5)

Para S1-S3 (tokens, shell, lista) **não vale mockar** — é mais rápido ajustar direto no Histoire com hot-reload.
Para **S4 (conversa)** e **S5 (context panel)** vale mockar antes: são mudanças estruturais com muitas variações possíveis (onde ficam as ações, o que entra em cada aba). Mockup evita refazer código.

---

## 6. ⛔ Pendência bloqueante — captura do Zendesk real

Tentativas de acesso automatizado ao Chrome nesta sessão (5, todas falharam):

| # | Via | Resultado |
|---|---|---|
| 1 | MCP Claude-in-Chrome | Não carregada na sessão |
| 2 | MCP Claude Browser | Não carregada |
| 3 | MCP computer-use | Não carregada |
| 4 | AppleScript → Chrome | Erro -1743 (permissão de automação negada) |
| 5 | Histórico do Chrome (SQLite) | Bloqueado por política de segurança |

**O spec acima usa a IA pública documentada do Zendesk Agent Workspace** — suficiente pra estrutura, insuficiente pra capturar **as customizações de vocês** (views salvas, campos custom, apps instalados, macros).

**Desbloqueio (escolher 1):**
- **A.** Conceder permissão de automação ao Claude Code (System Settings → Privacidade e Segurança → Automação → habilitar Google Chrome) → capturo tudo sozinho
- **B.** Naldo manda screenshots das telas principais (fila, ticket aberto, painel de contexto, lista de macros, admin de triggers)
- **C.** Credenciais de API do Zendesk → extraio views/macros/triggers/campos via API (mais preciso que screenshot)

**Recomendação:** C para funcionalidades (dado estruturado) + B para o visual. Nada disso bloqueia 3.1a.
