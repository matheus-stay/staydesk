# StayDesk — Gap Analysis: Zendesk → Chatwoot

> Status: Draft v1 (aguardando input do Naldo) · 2026-08-28 · @analyst + @product-lead

## Metodologia

3 colunas de veredito: **✅ Já tem** (Chatwoot MIT) · **🔶 Tem mas é pago/fraco** (enterprise ou precisa melhorar) · **❌ Criar do zero**.
A coluna "Naldo usa?" será preenchida com o questionário abaixo — **nada entra no backlog sem essa validação**.

## Matriz preliminar (baseada no código v4.17.1)

| Capacidade (mundo Zendesk) | Chatwoot | Veredito | Naldo usa? |
|---|---|---|---|
| Tickets / conversas multicanal | Conversations + inboxes | ✅ | ? |
| E-mail (suporte@) | Email channel + IMAP/SMTP | ✅ | ? |
| Chat no site (Zendesk Widget) | Website widget nativo | ✅ | ? |
| WhatsApp / Instagram / Messenger | Canais nativos (todos os planos) | ✅ | ? |
| Macros (respostas prontas) | Canned responses + Macros | ✅ | ? |
| Automações / triggers | Automation rules | ✅ (validar profundidade vs triggers Zendesk) | ? |
| Atribuição por equipe / round-robin | Teams + auto-assignment | ✅ (round-robin avançado = 🔶 `advanced_assignment`) | ? |
| Central de Ajuda (Guide) | Help Center / portal | ✅ (busca semântica = 🔶 enterprise) | ? |
| CSAT | CSAT nativo + relatórios | ✅ (review notes = 🔶) | ? |
| Relatórios (Explore) | Reports: conversas, agentes, times, CSAT, overview | ✅ básico / 🔶 custom reports avançados | ? |
| **SLA** | Existe, mas **enterprise** | 🔶 **decisão de licença** | ? |
| Papéis customizados (roles) | `custom_roles` **enterprise** (MIT: só admin/agent) | 🔶 | ? |
| IA (respostas sugeridas, resumo) | Captain — **enterprise** | 🔶 | ? |
| Busca avançada | `advanced_search` **enterprise** | 🔶 | ? |
| Telefonia / voz (Zendesk Talk) | `channel_voice` **enterprise** (Twilio) | 🔶 | ? |
| SSO corporativo (SAML) | **enterprise** | 🔶 | ? |
| Organizações (empresas B2B) | `companies` **enterprise** | 🔶 | ? |
| White-label (sem marca Chatwoot) | `disable_branding` **premium** | 🔶 | ? |
| Audit logs | **premium** | 🔶 | ? |
| Campos customizados de ticket | Custom attributes | ✅ | ? |
| Labels/tags | Labels | ✅ | ? |
| Integração com painel StayCloud (contexto do cliente: plano, servidor, faturas) | Não existe — mas API + dashboard apps permitem | ❌ **criar** (diferencial vs Zendesk!) | ? |
| Migração de tickets/contatos do Zendesk | Não existe importador nativo | ❌ criar (script via APIs) | ? |

## 📋 Questionário pro Naldo (30 min — responder inline)

### A. Operação atual no Zendesk
1. Quais canais estão ativos hoje? (e-mail, chat do site, WhatsApp, telefone, outro)
2. Quantos agentes usam o Zendesk? Há perfis/permissões diferentes entre eles?
3. Quais **triggers/automações** existem configuradas? (exportar lista se possível)
4. Usam **macros**? Quantas são realmente usadas no dia a dia?
5. Existe **SLA formal** (tempo de primeira resposta / resolução)? É cobrado em relatório?
6. Quais **relatórios** você olha semanalmente/mensalmente? (prints ajudam)
7. Usam a Central de Ajuda (artigos)? Quantos artigos ativos?
8. Usam CSAT? Como avaliam a satisfação hoje?

### B. Dores no Zendesk
9. O que te irrita no Zendesk hoje? (top 3)
10. O que falta que você já pediu e o Zendesk não entrega (ou cobra caro)?

### C. Sonhos pro StayDesk
11. Se o agente pudesse ver dados do cliente StayCloud (plano, servidores, faturas, status) dentro do ticket, o que seria mais valioso?
12. Alguma automação com o painel StayCloud? (ex.: abrir ticket vira alerta, suspensão gera aviso)
13. O que NÃO pode quebrar na migração? (deal-breakers)

## Handoff

- Respostas do Naldo → @product-lead preenche coluna "Naldo usa?" → matriz vira **backlog priorizado** em `epics/`
- Itens 🔶 alimentam a **decisão de licenciamento** (architecture-map § Licenciamento)
