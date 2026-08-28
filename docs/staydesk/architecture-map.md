# StayDesk — Mapa de Arquitetura (Chatwoot v4.17.1)

> Status: v1 · 2026-08-28 · FABLE CTO · Base: auditoria direta do código do fork

## Stack

| Camada | Tecnologia |
|---|---|
| Backend | Ruby on Rails (Ruby 3.2.2), Sidekiq (jobs), ActionCable (websockets) |
| Frontend | **Vue 3 + Vite + Tailwind CSS**, Vitest (testes), Histoire (component playground) |
| Banco | PostgreSQL 16 + pgvector (embeddings p/ IA) |
| Cache/filas | Redis |
| Dev runner | Overmind/Foreman (`Procfile.dev`: rails :3000 + sidekiq + vite dev) |

## Estrutura do frontend (`app/javascript/`) — território do Luiz

| Pasta | O que é | Relevância |
|---|---|---|
| `dashboard/` | App principal dos agentes (a "cara" do helpdesk) | ⭐ Principal alvo do redesign |
| `dashboard/components-next/` | **Design refresh em andamento pelo upstream** — componentes novos (Conversation, Inbox, Contacts, Settings...) | ⭐⭐ Construir em cima disso, não do legado |
| `dashboard/components/` | Componentes legados | Evitar investir aqui |
| `design-system/` | Tokens/estilos base + Histoire | Ponto de entrada pro design system StayDesk |
| `widget/` | Chat widget embedado nos sites dos clientes | Rebrand fase 2 |
| `portal/` | Help Center público | Rebrand fase 2 |
| `v3/`, `survey/`, `superadmin_pages/` | Superfícies auxiliares | Baixa prioridade |
| `tailwind.config.js` (raiz) | Config Tailwind | Customizar tokens de marca aqui |

**Implicação estratégica:** o upstream está no meio de um redesign (`components-next`). O redesign StayDesk deve (a) usar os componentes-next como base, (b) concentrar identidade visual em tokens Tailwind + design-system, minimizando conflito de merge com upstream.

## ⚠️ Licenciamento — decisão obrigatória

O repo contém **duas licenças**:

- Raiz: **MIT** (livre, é o Chatwoot Community Edition)
- `enterprise/`: **Chatwoot Enterprise License** (proprietária — usar essas features em produção exige licença paga)

### Features premium/enterprise (flags em `config/features.yml`)

`sla` · `captain_integration` (IA) · `advanced_search` · `custom_roles` · `saml` · `companies` · `channel_voice` · `audit_logs` · `disable_branding` · `csat_review_notes` · `advanced_assignment` · `conversation_required_attributes` · `custom_tools` · `help_center_embedding_search`

### Opções (decidir no gate 3)

| Opção | Prós | Contras |
|---|---|---|
| A. Ficar só no MIT (community) | Zero custo, zero risco legal | Sem SLA nativo, sem Captain AI, branding Chatwoot |
| B. Licenciar Chatwoot (paid self-hosted) | Tudo liberado, suporte | Custo recorrente (avaliar vs Zendesk) |
| C. Construir o que faltar por fora do `enterprise/` | Controle total | Esforço dev; não copiar código enterprise (violação) |

**Recomendação preliminar CTO:** validar com o Naldo o que o CS *realmente* usa. Se SLA formal for indispensável → comparar custo B vs esforço C. `disable_branding` (white-label) provavelmente importa pro StayDesk → pesa a favor de B ou C.

### ✅ Decisão 2026-08-28 (Luiz) — ADR-001

- **Fase de avaliação (local):** usar TODAS as features, incluindo enterprise. Legal: a Enterprise License permite explicitamente uso em *development and testing* sem assinatura.
- **Como foi ativado localmente:** `InstallationConfig` → `INSTALLATION_PRICING_PLAN=enterprise`, `INSTALLATION_PRICING_PLAN_QUANTITY=100` + premium flags habilitadas na conta (via rails runner). Só vale pro ambiente local.
- **Gate pendente (bloqueia produção):** antes do go-live (story 6.4), decidir **pagar licença** ou **remover/substituir** as features enterprise. Produção sem licença = violação — não é opção.

## Modelo de fork (anti-drift)

```
upstream (chatwoot/chatwoot) ──rebase periódico──▶ develop (staydesk)
                                                      │
                              customizações StayDesk ─┴─ branches feature → PR → develop
```

Regras:
1. Nunca commitar direto em `develop` — sempre branch + PR
2. Customização visual concentrada em tokens/design-system (merge barato)
3. Features novas em módulos próprios (`app/javascript/dashboard/staydesk/` ou similar) quando possível
4. Sync com upstream: mensal, ou por release de segurança

## Ambientes

| Ambiente | Como roda | Uso |
|---|---|---|
| **Avaliação local** | `docker compose -f docker-compose.local.yaml` → `localhost:3020` | Naldo/Luiz explorarem o produto |
| **Dev frontend** | `make setup` + `overmind start -f Procfile.dev` (Ruby 3.2.2, Node 20, pnpm, PG14+, Redis) | Luiz desenvolver com hot-reload Vite |
| Produção | (fase posterior — VPS StayCloud, provavelmente compose ou k8s) | — |
