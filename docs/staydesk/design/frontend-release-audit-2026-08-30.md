# Auditoria de release — redesign StayDesk frontend

> Data: 2026-08-30
> Branch: `codex/feat-staydesk-ux`
> Base: `4b1abc47b`
> Resultado: **PASS — sem achados críticos ou maiores**

## Escopo auditado

- Shell e densidade do workspace do agente.
- Lista e cards de conversas.
- Cabeçalho, histórico de mensagens e composer.
- Abas de conversas e indicador de rascunho.
- Painel de campos do ticket e painel de contexto.
- Reorganização do menu lateral com o grupo “Mais”.
- Logos públicos StayCloud e documentação de produto/UX.

## Fronteira frontend/backend

O diff foi validado por caminho. Todas as mudanças estão restritas a:

- `app/javascript/**`
- `public/brand-assets/**`
- `docs/staydesk/**`

Não há mudanças em Rails, controllers, models, jobs, services, banco, rotas de API,
webhooks, Sidekiq ou arquivos Enterprise. Também não foram adicionados requests
HTTP, endpoints, mutations Vuex ou contratos de payload.

As abas usam `sessionStorage`, isolado por conta, e apenas navegam entre rotas já
existentes. Fechar uma aba não fecha, resolve ou altera a conversa no servidor.

## Resultado da revisão

- Nenhuma regressão crítica ou maior encontrada no diff final.
- Rotas, permissões, feature flags e condições de instalação do menu continuam
  derivadas dos objetos originais do Chatwoot.
- O grupo “Mais” não navega para um filho arbitrário e permanece operável por
  clique, Enter, Espaço e Escape.
- O foco retorna ao gatilho ao fechar o flyout pelo teclado.
- O composer preserva os fluxos existentes de resposta, nota, anexos, áudio,
  templates, rascunhos e envio.
- A documentação da Story 3.3 foi atualizada para refletir o escopo final aprovado,
  incluindo abas e o painel de campos frontend-only.

## Evidências automatizadas

| Verificação | Resultado |
|---|---|
| `git diff --check` | PASS |
| Gate mecânico de caminhos frontend-only | PASS |
| ESLint direcionado | PASS — 0 erros; 8 warnings de i18n conhecidos |
| Navegação, menu e abas | PASS — 6 arquivos, 37 testes |
| Regressão do composer | PASS — 1 arquivo, 92 testes |
| Build Vite de produção | PASS — 5.074 módulos |

Os avisos de source map do pacote `@chatwoot/prosemirror-schema`, atualização do
`caniuse-lite` e tamanho de chunks já pertencem ao ambiente/dependências atuais e
não bloqueiam o build.

## QA manual já executado

- Bundle publicado no container local `staydesk-rails-1`.
- Workspace validado em `http://localhost:3020`.
- Menu compacto e expandido verificados com mouse e teclado.
- Abertura do grupo “Mais”, subgrupos, manutenção da URL e retorno de foco
  confirmados no navegador real.
- Shell com rail, painel de ticket, conversa e contexto verificado sem overflow
  horizontal no viewport desktop auditado.

## Riscos residuais

- O drawer móvel e a largura de 320 px ainda precisam de uma rodada visual completa
  em dispositivo real.
- As abas têm cobertura do composable; uma futura rodada pode adicionar teste de
  componente para navegação por setas conforme o padrão ARIA de tablist.
- A validação com diferentes combinações de cargo, permissões e recursos deve ser
  repetida antes do go-live.

Esses riscos não afetam a fronteira frontend-only nem bloqueiam a revisão atual em
ambiente local, mas permanecem como gates de homologação antes da migração.
