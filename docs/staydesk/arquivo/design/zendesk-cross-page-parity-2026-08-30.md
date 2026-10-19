# Auditoria visual cruzada — Zendesk × StayDesk

> Data: 2026-08-30
>
> Escopo: frontend-only
>
> Zendesk Chat legado: fora do escopo
>
> Dados de clientes: não registrados

## Objetivo

Reduzir a estranheza da migração para os agentes de suporte reproduzindo a
geometria, densidade e hierarquia visual das superfícies equivalentes do
Zendesk Support, sem copiar a marca Zendesk e sem modificar funções do
Chatwoot.

## Páginas auditadas no Zendesk

| Zendesk Support | Equivalente StayDesk | Padrão observado |
|---|---|---|
| Início do agente | Caixa de Entrada | Rail global estreita, navegação contextual e área principal plana |
| Views de tickets | Conversas | Lista densa, seleção discreta e divisores de 1 px |
| Ticket | Conversa | Campos à esquerda, histórico/composer no centro e contexto à direita |
| Clientes | Contatos | Cabeçalho de 26/32 px, busca compacta e linhas de aproximadamente 60 px |
| Organizações | Empresas | Página ampla, ações de 32/40 px e tabela plana |
| Métricas do início | Relatórios | Blocos com borda fina, pouca sombra e raio curto |

## Medidas de referência

- Rail global: `56 px`.
- Navegação secundária: `240–330 px`, conforme a superfície.
- Botões de ferramenta: `32 px`.
- Botões principais e filtros maiores: `40 px`.
- Raio de botões, inputs e superfícies operacionais: `4 px`.
- Ticket em viewport útil de aproximadamente `1309 px`: campos `308 px`,
  conversa `516 px` e contexto `428 px`, além da rail.
- Cabeçalhos de Clientes e Organizações: aproximadamente `26/32 px`.
- Tabelas/listas: superfícies contínuas, linhas entre `60–67 px` e divisores de
  `1 px`.

## Tradução para a marca StayCloud

- O azul interativo nativo do Chatwoot foi substituído pelo token StayCloud
  `#545DFF` em CTA, foco, link, seleção e indicadores operacionais.
- Em texto pequeno no dark mode, o acento usa o tom StayCloud `#7E85FF`, que
  alcança contraste aproximado de `5,82:1` contra a superfície `#141517`.
- O azul semântico continua disponível somente para estados informativos que
  realmente precisem comunicar essa semântica.
- Dark mode, tipografia existente e contraste foram preservados.
- A marca Zendesk não foi copiada; somente seu modelo espacial e sua densidade
  de operação foram usados como benchmark.

## Implementação deste corte

- Botões e inputs compartilhados agora usam raio de `4 px` e transições mais
  curtas.
- O painel de contexto usa `360 px` em desktop e `428 px` a partir de `1536 px`,
  evitando esmagar a conversa em notebooks e alcançando a largura do Zendesk
  em monitores de operação.
- A rail de contexto deixou de ser uma cápsula e passou a usar controles
  quadrados de `32 px`, como no ticket Zendesk.
- Contatos e Empresas deixaram os cartões altos de `110 px` e passaram a listas
  planas de aproximadamente `67–70 px`.
- Contatos e Empresas usam cabeçalho amplo, busca delineada, título `24/32 px`
  e largura máxima de `75 rem`.
- Relatórios perderam sombras e raios de `12 px` nas superfícies principais;
  bordas de `1 px` e raio de `4 px` passam a definir a hierarquia.
- Abas, itens não lidos, atalhos da inbox, composer, filtros e links das telas
  operacionais usam o acento StayCloud.

## Fronteira frontend/backend

O corte altera somente `app/javascript/**`, `theme/**` e documentação. Não há
mudança em controllers, models, jobs, services, rotas Rails, banco, API,
webhooks, stores, payloads ou regras de negócio. Nenhuma opção foi criada,
removida ou teve comportamento alterado.

## Evidências

- ESLint direcionado: `0` erros; warnings conhecidos de chaves i18n dinâmicas.
- Vitest direcionado: `2` arquivos e `9` testes aprovados.
- Build Vite de produção: `5.074` módulos transformados.
- Bundle publicado no container local `staydesk-rails-1`.
- QA visual no navegador real: ticket, Contatos e Empresas verificados.
- Empresas medidas com linhas de `67 px`; Contatos, `70 px`. Ambas usam raio `0`
  e padding vertical de `10 px`.
- A revisão não enviou, alterou, resolveu ou reatribuiu tickets no Zendesk.
