# Hub e Central

O StayDesk separa o lugar de atender do lugar de configurar, como o Zendesk
separa o espaço do agente da central de administração. A decisão é de 2026-09-18.

## Hub

O espaço de atendimento. O agente entra por ele e vive nas **visualizações**: a
lista da esquerda são as filas que o grupo dele trabalha, e cada uma abre uma
tabela com SLA, status, assunto, contato, caixa, espera e responsável.

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
| Atendimento | Filas, visualizações por time, área de trabalho |
| Status e prazos | Status do ticket, status do agente, políticas de SLA, calendários |
| Pessoas | Agentes, times, papéis, tokens de API |
| Canais | Caixas de entrada, modelos |
| Regras e automação | Automações, macros, respostas prontas, robôs, etiquetas, campos |
| Conta | Conta, integrações, dados, auditoria, segurança, faturamento |

O que sobrar de novo no produto cai numa seção "Outros", para nenhuma tela sumir
quando o upstream acrescentar uma.

De dentro da Central, "Voltar ao Hub" fica no topo da barra. O link para a
Central não aparece quando já se está nela.

## Quem vê o quê

Cada entrada da Central exige a permissão da área, então um papel com "configurar
filas" vê Filas e mais nada; sem nenhuma permissão de configuração, o link para a
Central não aparece. Detalhes em [permissoes.md](permissoes.md).
