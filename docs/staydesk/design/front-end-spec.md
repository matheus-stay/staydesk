# StayDesk — Front-end Spec v1

> 2026-08-28 · @design (Nexus) + FABLE CTO · Base: Guardian tokens + Chatwoot `components-next` + IA do Zendesk Agent Workspace
> Companion: [staydesk-tokens.md](staydesk-tokens.md) · [architecture-map.md](../architecture-map.md)

## Princípio-guia

> O agente de CS não quer um app bonito. Quer **fechar mais tickets com menos ruído**.
> Herdamos a mentalidade do Guardian: mais cinza que cor, mais espaço que decoração, indigo é assinatura.

---

## 1. Diagnóstico estrutural: workspace do Zendesk vs Chatwoot

**Zendesk Agent Workspace com ticket aberto:**

```
┌──────┬─────────────────────────────────────────────────────┐
│ Rail │ Abas persistentes de tickets                        │
├──────┼──────────────┬──────────────────────┬───────────────┤
│ Nav  │ Campos       │ Conversa + composer  │ Context panel │
│      │ redimens.    │ redimensionável      │ + apps        │
└──────┴──────────────┴──────────────────────┴───────────────┘
```

**Chatwoot hoje:**

```
┌──────┬───────────────┬────────────────────┬──────────────┐
│ Nav  │ Lista de      │ Conversa +         │ Contact      │
│ icon │ conversas     │ composer           │ panel        │
└──────┴───────────────┴────────────────────┴──────────────┘
```

**Achado central do QA real:** o diferencial não é a quantidade estática de colunas. Ao abrir um ticket, o Zendesk remove a fila e usa abas persistentes para manter os tickets em trabalho. O Chatwoot mantém a lista ao lado da conversa por padrão e, em 1440px, reduz demais a área útil do atendimento.

### Decisão de arquitetura visual (ADR-002)

| # | Decisão | Racional |
|---|---|---|
| 1 | **Preservar o layout atual e a preferência salva** | O primeiro corte é visual-only: nenhum default, toggle ou comportamento de fila muda |
| 2 | **Preservar largura, resize e colapso atuais da navegação** | `useSidebarResize` permanece intacto; a IA pode aplicar divulgação progressiva sobre as mesmas rotas e gates |
| 3 | **Abas persistentes de tickets** | Preservam memória de trabalho, rascunhos e alternância em uma ação |
| 4 | **Unificar o painel direito num Context Panel com abas** (Cliente · StayCloud · Ferramentas · Notas) | Reproduz o papel dos apps operacionais do Zendesk e abre espaço para dados StayCloud no ticket |
| 5 | **Conversa é a região dominante**, com mínimo de 50% da largura útil | Métrica objetiva de sucesso do redesign |
| 6 | Sem 5ª coluna | Anti-padrão do Guardian: mais espaço que decoração |

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
| **3.2** | Shell: densidade visual da sidebar e logo StayDesk, sem mudar colapso/default | Luiz | 🟡 Médio |
| **3.3** | Lista de conversas: hierarquia, badges, densidade | Luiz | 🟡 Médio |
| **3.4** | Conversa + composer: proporção, bolhas, ações rápidas | Luiz + dev | 🟠 Alto |
| **3.5** | Context panel com abas (prepara EPIC-004) | dev | 🟠 Alto |
| **3.6** | Widget rebrand | dev | 🟢 Baixo |
| **3.7** | IA da navegação: primários frequentes, “Mais” e Configurações separada, sem remover destinos | Luiz + squad-design | 🟡 Médio |

**Ordem inegociável:** 3.1a antes de tudo. Trocar a paleta re-branda o produto inteiro num PR só — é o maior retorno visual por linha de código do projeto.

### Fluxo de trabalho do Luiz (hot-reload)

Depende da story **1.4** (ambiente dev nativo). Sem ela, cada ajuste de CSS exige rebuild de container — inviável pra design. **1.4 é pré-requisito de 3.1b em diante.**

---

## 5. Trilha Claude Design / Figma (opcional, recomendada em S4-S5)

Para S1-S3 (tokens, shell, lista) **não vale mockar** — é mais rápido ajustar direto no Histoire com hot-reload.
Para **S4 (conversa)** e **S5 (context panel)** vale mockar antes: são mudanças estruturais com muitas variações possíveis (onde ficam as ações, o que entra em cada aba). Mockup evita refazer código.

---

## 6. QA do Zendesk real concluído

O QA inicial foi executado em 2026-08-28 no Zendesk Support e no Agent Workspace da StayCloud, em modo somente leitura. O produto legado Zendesk Chat foi explicitamente excluído do escopo.

O levantamento validou a estrutura do workspace e registrou as customizações operacionais: views, abas, campos, status, macros, gatilhos, automações, SLA e aplicativos de contexto. O relatório sanitizado está em [qa-zendesk-agent-workspace.md](../qa-zendesk-agent-workspace.md).

Correções trazidas pelo QA:

- A fila não permanece visível quando um ticket abre; abas persistentes sustentam o trabalho paralelo.
- Status e comportamento pós-envio são controles separados.
- O Context Panel funciona como uma plataforma de aplicativos operacionais.
- A fila precisa evidenciar SLA, prioridade, colisão e motivo de atenção.
- A migração de macros deve priorizar o pequeno núcleo de uso frequente.

## Auditoria de release

A consolidação pré-commit do redesign está registrada em
`docs/staydesk/design/frontend-release-audit-2026-08-30.md`, incluindo fronteira
frontend/backend, evidências automatizadas e riscos residuais de homologação.
