# StayDesk — roadmap de UX do workspace Zendesk

> Direção aprovada em 2026-08-28 · foco do projeto: experiência frontend do agente

## Objetivo

Fazer o atendimento no StayDesk ter o mesmo modelo mental e a mesma fluidez visual do Zendesk usado hoje pela operação, aplicando a identidade StayCloud e preservando as funções existentes do Chatwoot.

Este roadmap não é uma frente de migração, API ou integração. Esses temas aparecem somente quando bloqueiam uma decisão de interface e devem ser encaminhados ao Matheus e aos desenvolvedores.

## Decisão de produto

O ticket aberto deixa de parecer uma conversa dentro da fila e passa a ser um workspace de atendimento:

```text
┌──────────────────────────────────────────────────────────────────────┐
│ Produto │ ticket(s) aberto(s)                      busca · agente    │
├────┬─────────────────────────────────────────────────────────────────┤
│    │ identificação do ticket e ações existentes                     │
│ R  ├─────────────────┬──────────────────────┬────────────────────────┤
│ A  │ Campos e dados  │ Assunto e histórico │ Contexto e apps atuais │
│ I  │ já disponíveis  │ em formato de artigo│                        │
│ L  │                 ├──────────────────────┤                        │
│    │                 │ Composer acoplado    │                        │
├────┴─────────────────┴──────────────────────┴────────────────────────┤
│ macro existente                         enviar / status existente    │
└──────────────────────────────────────────────────────────────────────┘
```

A fila passa a ser uma tela de Visualizações e, durante o atendimento, pode ser acessada por retorno ou drawer. Ela não deve continuar ocupando permanentemente a coluna esquerda do ticket.

## O que vamos reproduzir do Zendesk

### 1. Workspace do ticket

- Rail global estreito e discreto.
- Ticket como superfície principal após ser aberto.
- Painel esquerdo para dados e campos que já existem no Chatwoot.
- Histórico no centro, com leitura vertical documental em vez de grandes bolhas de chat.
- Contexto e aplicativos atuais na lateral direita.
- Cada painel com rolagem própria e largura redimensionável quando a base atual permitir.
- Geometria desktop de referência: `56 px / 310 px / flex / 360 px`.

### 2. Cabeçalho

- Identificação do ticket, contato, canal, tempo e metadados em uma hierarquia compacta.
- Ações atuais agrupadas e com menor ruído visual.
- Área central dedicada ao assunto e ao histórico.
- Abas persistentes de vários tickets só entram quando houver suporte funcional; não serão simuladas como botões decorativos.

### 3. Histórico

- Mensagens apresentadas como artigos da linha do tempo.
- Autor, canal, destinatário e horário no cabeçalho de cada item.
- Resposta pública em superfície neutra.
- Nota interna em superfície âmbar, sempre acompanhada de rótulo e ícone.
- Eventos, bot, anexos e mensagens do agente diferenciados por estrutura, não apenas por cor.
- Conteúdo com largura confortável e densidade semelhante à do Zendesk.

### 4. Composer

- Editor acoplado ao rodapé do painel central, não um cartão flutuante.
- Separador arrastável e estados recolhido/expandido usando o resize existente.
- Linha superior com `Resposta pública / Nota interna` e destinatário quando já disponível.
- Corpo do editor sem bordas internas excessivas.
- Toolbar compacta com as ferramentas atuais do Chatwoot.
- Macros e envio visualmente integrados ao rodapé quando a ação atual puder ser reaproveitada.
- Superfície inteira do editor muda para âmbar na nota interna.
- Atalhos, rascunhos, anexos, emoji, áudio, IA, templates e respostas prontas existentes são preservados.

Não serão criadas opções falsas de “permanecer no ticket”, novos status ou envio atômico apenas para completar a aparência. Esses itens entram no handoff funcional.

## Sequência de trabalho

| Etapa | Entrega | Validação |
|---|---|---|
| **UX-1 — Estrutura** | Fila como Visualizações/drawer; ticket com campos, histórico e contexto | Comparação lado a lado em 1280 e 1440 px |
| **UX-2 — Histórico** | Linha do tempo documental, metadados e estados público/interno | Cinco agentes identificam cada tipo de item sem orientação |
| **UX-3 — Composer** | Geometria, hierarquia, resize, modos, toolbar e rodapé no padrão Zendesk | Responder, inserir nota, anexar, usar macro e enviar sem perda de capacidade |
| **UX-4 — Responsivo** | Conversa prioritária; campos e contexto viram drawers progressivamente | Sem faixa estreita de conversa em 768, 1024 e 1280 px |
| **UX-5 — Polimento** | Teclado, foco, contraste, estados e consistência StayCloud | QA com Head de CS e checklist de acessibilidade |

## Breakpoints esperados

| Largura | Comportamento |
|---|---|
| `>= 1200 px` | Campos, histórico e contexto visíveis |
| `900–1199 px` | Campos + histórico; contexto em drawer |
| `768–899 px` | Histórico principal; campos e contexto em drawers exclusivos |
| `< 768 px` | Uma superfície por vez: Visualizações, ticket ou contexto |

Nunca exibir fila e contexto ao mesmo tempo se isso reduzir o histórico a uma faixa estreita. Não deve existir scroll horizontal na página.

## Critérios de aceite

- Ao abrir um ticket, a fila não ocupa a coluna destinada aos campos.
- Assunto, histórico, composer e ações de envio ficam visíveis na mesma superfície.
- O composer permanece preso ao rodapé e pode ser redimensionado.
- Resposta pública e nota interna são inequívocas antes do envio.
- Nenhuma capacidade atual do Chatwoot desaparece ou muda de resultado.
- Nenhum endpoint, payload, modelo Rails, job, serviço, rota ou banco é alterado nesta trilha.
- Nenhum controle sem ação real é exibido.
- A conversa mantém largura útil em 768, 1024, 1280 e 1440 px.
- Fluxos principais funcionam por teclado, com foco visível e `Escape` previsível.
- Head de CS aprova a comparação lado a lado com o Zendesk.
- Cinco agentes completam abrir, responder, inserir nota, usar macro e resolver sem assistência.

## Handoff para Matheus e desenvolvimento

Esta lista não faz parte da execução de UX, mas evita que a interface prometa algo que ainda não existe:

- abas persistentes com vários tickets e rascunho por aba;
- estados adicionais e comportamento pós-envio;
- operação atômica de enviar, aplicar macro e mudar status;
- campos condicionais e validações novas;
- macros avançadas e variáveis externas;
- colisão entre agentes, SLA ampliado e aplicativos com escrita.

O time de UX define a experiência, os estados visuais e o comportamento esperado. O time de desenvolvimento decide e implementa os contratos necessários em stories próprias.

## Próximo ciclo recomendado

Começar por **UX-1 e UX-3 em protótipo frontend**, usando apenas dados e ações já existentes. A validação deve ocorrer no mesmo monitor, alternando entre Zendesk e StayDesk, antes de polir cores ou avançar para qualquer funcionalidade nova.
