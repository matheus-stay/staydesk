# StayDesk — Epics & Backlog Inicial

> Status: Draft v1 · 2026-08-28 · Plano FABLE CTO · Prioridade: P0 (agora) → P3 (depois)

## EPIC-001 — Ambiente & Fundação (P0)

| # | Story | Dono | Status |
|---|---|---|---|
| 1.1 | Fork `stay-cloud-br/staydesk` + clone + upstream remote | devops | ✅ Done |
| 1.2 | Subir Chatwoot local via Docker (`localhost:3020`) para avaliação | devops | 🔄 In progress |
| 1.3 | Criar conta admin + workspace de teste, tour guiado com Naldo | Naldo + Luiz | ⬜ |
| 1.4 | Ambiente dev frontend nativo (Ruby 3.2.2 + Node 20 + pnpm + overmind, hot-reload Vite) | devs | ⬜ |
| 1.5 | CI básico no fork (lint + vitest no GitHub Actions, sem herdar workflows pesados do upstream) | devops | ⬜ |
| 1.6 | Protocolo de sync com upstream documentado e testado (1º rebase) | devs | ⬜ |

## EPIC-002 — Discovery & Decisão (P0)

| # | Story | Dono | Status |
|---|---|---|---|
| 2.1 | Naldo responde questionário (`gap-analysis-zendesk.md`) | Naldo | ⬜ **bloqueador do resto** |
| 2.2 | Matriz de gap validada + priorizada (MoSCoW) | product | ⬜ |
| 2.3 | Decisão de licenciamento enterprise (MIT-only vs pagar vs construir) | CTO + Luiz | 🔶 **Parcial** — decisão 28/08: avaliação local usa TUDO (dev/teste é permitido pela licença sem pagar). Decisão pagar-vs-construir adiada pro gate de go-live (6.4) |
| 2.4 | Auditoria de automações/triggers do Zendesk atual (export) | Naldo + analyst | ⬜ |

## EPIC-003 — Frontend StayDesk (P1 — trilha do Luiz)

| # | Story | Notas |
|---|---|---|
| 3.1 | Design tokens StayCloud no `tailwind.config.js` + `design-system/` (cores, tipografia, radius) | Base de tudo; merge barato com upstream |
| 3.2 | Explorar `components-next/` no Histoire e mapear superfícies do redesign | Upstream já está migrando — surfar essa onda |
| 3.3 | Redesign do shell do dashboard (sidebar, header, conversa) | Maior impacto visual diário |
| 3.4 | Rebrand do widget de chat (cara StayCloud nos sites) | Visível pro cliente final |
| 3.5 | Rebrand do Help Center/portal | |
| 3.6 | Login/onboarding com identidade StayDesk | Ver flag `disable_branding` (premium) — decisão 2.3 |

## EPIC-004 — Integração StayCloud (P1/P2 — diferencial vs Zendesk)

| # | Story | Notas |
|---|---|---|
| 4.1 | Sidebar de contexto do cliente no ticket (plano, servidores, status, faturas via API do painel) | Chatwoot suporta Dashboard Apps (iframe) — caminho rápido |
| 4.2 | Identificação automática do contato (e-mail ↔ conta StayCloud) | |
| 4.3 | Ações rápidas no ticket (ex.: link mágico de login, reiniciar serviço) | Requer API painel + permissões |
| 4.4 | Webhooks StayCloud → conversa (alerta de servidor, suspensão, churn risk) | |

## EPIC-005 — Migração Zendesk (P2 — só após gate 2.2)

| # | Story | Notas |
|---|---|---|
| 5.1 | Importador de contatos/organizações (API Zendesk → API Chatwoot) | |
| 5.2 | Importar artigos da Central de Ajuda | |
| 5.3 | Estratégia de cutover (rodar em paralelo, redirecionar canais, congelar Zendesk) | |
| 5.4 | Importar histórico de tickets (avaliar custo/benefício — talvez só arquivo consultável) | |

## EPIC-006 — Produção (P3)

| # | Story | Notas |
|---|---|---|
| 6.1 | Deploy em VPS StayCloud (compose hardened, backups PG, SSL) | |
| 6.2 | E-mail transacional (SMTP) + inbound email | |
| 6.3 | Monitoramento + alertas | |
| 6.4 | Gate de go-live com Naldo (checklist de paridade) | **Inclui decisão obrigatória de licença enterprise: pagar ou remover/substituir features enterprise antes de produção** |

## Sequência crítica

```
1.2 ──▶ 1.3 ──▶ 2.1 ──▶ 2.2 ──▶ 2.3 ─┬─▶ EPIC-003 (Luiz, paralelo)
                                      ├─▶ EPIC-004 (devs)
                                      └─▶ EPIC-005 ──▶ EPIC-006
```
