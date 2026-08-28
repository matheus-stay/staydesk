# StayDesk — Project Brief

> Status: Draft v1 · 2026-08-28 · Autor: FABLE CTO (orquestração SINAPSE)

## Visão

StayDesk é o helpdesk da StayCloud, construído como **fork do Chatwoot v4.17.1** ([stay-cloud-br/staydesk](https://github.com/stay-cloud-br/staydesk)). Objetivo: **substituir o Zendesk** com uma ferramenta self-hosted, customizável e sem custo por agente, evoluindo o frontend para o padrão visual StayCloud.

## Por que sair do Zendesk

| Driver | Detalhe |
|---|---|
| Custo | Zendesk cobra por agente (~$55+/agente/mês); Chatwoot self-hosted é grátis (MIT) |
| Controle | Dados de clientes na nossa infra (LGPD, soberania) |
| Customização | Frontend Vue 3 próprio — podemos moldar a UX ao fluxo do CS da StayCloud |
| Integração | API aberta → integração futura com painel StayCloud, checkout, billing |

## Papéis

| Quem | Responsabilidade |
|---|---|
| **Luiz** | Frontend — redesign visual, UX, design system StayDesk |
| **Devs** | Backend, infra, integrações, features novas |
| **Naldo** (Coord. CS) | Dono dos requisitos — configurou o Zendesk atual, valida paridade funcional |

## Escopo (IN)

1. Rodar Chatwoot local (Docker) → ambiente de avaliação
2. Gap analysis: Zendesk (uso real do Naldo) vs Chatwoot OSS
3. Ambiente de dev frontend (Vite + Vue 3) pro Luiz
4. Roadmap de melhorias de frontend + features CS
5. Migração progressiva do Zendesk (dados e operação) — fase posterior

## Fora de escopo (OUT) — por enquanto

- Deploy em produção (depende do gate de validação do Naldo)
- Uso de features **enterprise** do Chatwoot sem decisão de licenciamento (ver `architecture-map.md` § Licenciamento)
- Migração de histórico do Zendesk (avaliar na fase 2)

## Riscos principais

| Risco | Severidade | Mitigação |
|---|---|---|
| SLA/relatórios avançados são código enterprise (não-MIT) | **Alta** | Decidir: licenciar Chatwoot vs construir features próprias vs validar se CS precisa mesmo |
| Divergência do upstream (fork drift) | Média | Manter `upstream` remote, rebase periódico, customizações isoladas |
| Requisitos do Naldo ainda não formalizados | Alta | Questionário estruturado em `gap-analysis-zendesk.md` — **primeira ação** |

## Próximos gates

1. ✅ Fork + ambiente local no ar
2. ⬜ Naldo responde questionário → gap analysis vira matriz validada
3. ⬜ Decisão de licenciamento enterprise (CTO + Luiz)
4. ⬜ Backlog priorizado → sprints
