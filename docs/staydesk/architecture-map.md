# StayDesk — Onde cada coisa mora

O StayDesk é o Chatwoot **community** (MIT) com a camada da StayCloud por cima.
Este mapa diz em que pasta cada coisa está e por quê. A regra de como tocar o
núcleo está em [camada-staydesk.md](camada-staydesk.md); o que é Enterprise e
por que não usamos, em [edicao-community.md](edicao-community.md).

## Stack

| Camada | Tecnologia |
|---|---|
| Backend | Ruby on Rails (Ruby da `.ruby-version`, hoje 3.4.4), Sidekiq (jobs), ActionCable (websockets) |
| Frontend | Vue 3 + Vite + Tailwind CSS, Vitest nos testes. Node da `.nvmrc` |
| Banco | PostgreSQL 16 com pgvector (imagem `pgvector/pgvector:pg16` no compose) |
| Cache e filas | Redis |
| Ambiente local | `docker compose` (ver [runbook-local.md](runbook-local.md)) |

## Edição

Roda a edição community: `DISABLE_ENTERPRISE=true`, nada de `enterprise/`
executa, e o que a operação precisava do Enterprise (SLA, papéis, campo
obrigatório para resolver, white-label) foi construído na camada. A pasta
`enterprise/` continua no repositório só porque o sync com o oficial precisa
dela. Detalhes em [edicao-community.md](edicao-community.md).

## A camada StayDesk

| Pasta | O que é |
|---|---|
| `custom/` | Todo o backend da camada: modelos, serviços, jobs, listeners, controllers, rotas, migrations, tarefas rake e a referência da API. Estrutura em `custom/README.md` |
| `custom/mcp/` | Servidor MCP que expõe a API da conta como ferramentas |
| `custom/bin/` | Gate dos toques no núcleo, varredura da marca e gerador de ícones |
| `app/javascript/staydesk/` | Todo o frontend da camada: páginas, componentes, composables, stores, API, helpers, textos e rotas |
| `spec/staydesk/` | Specs do backend da camada |
| `app/javascript/staydesk/**/specs/` | Specs do frontend da camada |
| `docs/staydesk/` | Esta documentação. O histórico de planejamento fica em `arquivo/` |
| `swagger/staydesk/` | OpenAPI da camada. A referência que a Central mostra é `custom/config/api_reference.json` |
| `theme/`, `tailwind.config.js`, `public/brand-assets/` | Tokens e marca, pelos pontos de extensão que o próprio Chatwoot oferece ([marca.md](marca.md)) |

Fora disso, o núcleo do Chatwoot só é tocado nas formas que
[camada-staydesk.md](camada-staydesk.md) descreve, e cada toque fica registrado
em [core-touches.md](core-touches.md), conferido por
`node custom/bin/staydesk-gate.mjs`.

## Frontend do núcleo (`app/javascript/`)

| Pasta | O que é |
|---|---|
| `dashboard/` | O app dos agentes. A camada entra por ganchos de uma linha e pela montagem das rotas (`withStaydeskRoutes`) |
| `dashboard/components-next/` | Os componentes novos do upstream. Quando a camada compõe com o núcleo, compõe com estes |
| `dashboard/components/` | Componentes legados do upstream |
| `widget/`, `portal/`, `survey/` | Widget de chat, central de ajuda pública e pesquisa de satisfação. O que a camada muda aqui está em `core-touches.md` |

## Ramos (modelo de fork)

```
upstream (chatwoot/chatwoot) ──▶ develop (espelho do oficial, sem nada nosso)
                                      │
                                      └─ merge ─▶ staydesk-revisado (o ramo de trabalho)
```

- `develop` é cópia fiel do `develop` do oficial. É contra ele que o gate
  compara: o que difere de `develop` fora da camada é toque no núcleo e precisa
  estar em `core-touches.md`.
- O trabalho vive em `staydesk-revisado`. O sync traz o oficial para `develop`
  e depois faz merge de `develop` no ramo de trabalho, resolvendo os conflitos
  com a lógica do upstream e mantendo as classes e os ganchos da camada.
- Comandos do sync em [runbook-local.md](runbook-local.md).

## Ambientes

| Ambiente | Como roda |
|---|---|
| Local | `docker compose up -d`, app em `http://localhost:3000` ([runbook-local.md](runbook-local.md)) |
| Produção | Imagem construída pelo CI a cada push em ramo `staydesk-*` (`.github/workflows/staydesk_image.yml`). Deploy e staging ficam fora deste mapa |
