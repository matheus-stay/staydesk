# Hub e Central

O StayDesk separa o lugar de atender do lugar de configurar, como o Zendesk
separa o espaço do agente da central de administração. A decisão é de 2026-09-18.

## Hub

O espaço de atendimento. O agente entra por ele e vive nas **visualizações**: a
lista da esquerda são as filas que o grupo dele trabalha, e cada uma abre uma
tabela com SLA, status, assunto, contato, caixa, espera e responsável.

A porta de entrada é a **home do Hub**: uma saudação, o status atual com troca
rápida, quantas conversas estão com a pessoa agora e quantas esperam nas filas
que ela vê, a lista das visualizações com contagem e as conversas abertas com
ela para retomar de onde parou. Sem número de gestão: isso é da Central.

- As conversas abertas viram **abas no topo**, com o número do ticket e um aviso
  quando há resposta não enviada. O "x" fecha a aba sem mexer na conversa.
- Ao abrir uma conversa, a barra lateral **encolhe sozinha** para os ícones e
  volta ao tamanho de antes quando se volta para a lista. O botão "Compactar
  barra", no rodapé, faz o mesmo à mão.
- O que aparece na barra, quais colunas a tabela tem e quais campos o painel
  mostra vem da [área de trabalho](area-de-trabalho.md), por time e por papel.
- À esquerda da conversa ficam os dados do ticket e o SLA; à direita, o contato,
  o histórico dele e os aplicativos em iframe.

## Central

O espaço de administração. Abre em aba própria pelo rodapé da barra do Hub, e lá
dentro a barra lateral vira o menu da Central, agrupado por assunto:

| Seção | O que tem |
|---|---|
| Início | A página inicial, com os números da operação |
| Relatórios | Os relatórios do produto |
| Distribuição de trabalho | Canais de trabalho, filas, regras de capacidade, status dos agentes — na ordem em que o trabalho chega a quem atende |
| Atendimento | Status do ticket, visualizações por time, área de trabalho |
| Prazos | Políticas de SLA, calendários |
| Pessoas | Agentes, times, papéis, tokens de API |
| Canais | Caixas de entrada, modelos |
| Regras e automação | Automações, macros, respostas prontas, robôs, etiquetas, campos |
| Conta | Conta, integrações, dados, auditoria, segurança, faturamento |

Cada seção é um **dropdown**: o nome abre a home da seção, que apresenta o que
ela cobre e cada tela dela com uma linha explicando para que serve; a seta
recolhe ou expande a lista. O que a barra deixa recolhido fica guardado por
conta, no navegador.

O que sobrar de novo no produto cai numa seção "Outros", para nenhuma tela sumir
quando o upstream acrescentar uma. O SLA do Chatwoot, que é Enterprise, fica de
fora de propósito: o motor de SLA do StayDesk mora em Prazos.

A barra lateral nasce com 264 pixels de largura, para os títulos da Central
caberem, e compacta para os ícones pelo botão do rodapé, que fica fixo fora da
parte que rola.

De dentro da Central, "Voltar ao Hub" fica no topo da barra. O link para a
Central não aparece quando já se está nela.

## Quem vê o quê

Cada entrada da Central exige a permissão da área, então um papel com "configurar
filas" vê Filas e mais nada; sem nenhuma permissão de configuração, o link para a
Central não aparece. Detalhes em [permissoes.md](permissoes.md).
