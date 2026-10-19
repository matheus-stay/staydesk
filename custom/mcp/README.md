# MCP do StayDesk

Servidor MCP que expõe a API da conta como ferramentas: ler os números da
operação e configurar filas, SLA, status, papéis e área de trabalho sem abrir a
tela. É o mesmo cálculo que a Central mostra, então número de MCP e número de
tela não divergem.

## Instalar

```sh
pnpm --dir custom/mcp install --ignore-workspace
```

## Configurar

Três variáveis de ambiente:

| Variável | O que é |
|---|---|
| `STAYDESK_URL` | endereço da instalação, por exemplo `https://staydesk.staycloud.com.br` |
| `STAYDESK_TOKEN` | token de API com escopo (Central › Pessoas › Tokens de API), só com os escopos de que o MCP precisa. O token pessoal (Perfil › Token de acesso) também funciona, mas carrega tudo que a pessoa pode |
| `STAYDESK_ACCOUNT_ID` | id da conta, que aparece em Central › Conta |

No cliente MCP:

```json
{
  "mcpServers": {
    "staydesk": {
      "command": "node",
      "args": ["/caminho/para/staydesk/custom/mcp/servidor.mjs"],
      "env": {
        "STAYDESK_URL": "https://staydesk.staycloud.com.br",
        "STAYDESK_TOKEN": "...",
        "STAYDESK_ACCOUNT_ID": "1"
      }
    }
  }
}
```

## O que dá para fazer

`staydesk_kpis` traz CSAT, tempo de primeira resposta e de resolução por canal
de trabalho, quem está esperando e o tempo de cada agente em cada status. As
demais leem e escrevem configuração: filas, canais de trabalho (filas de carga),
regras de capacidade, status do ticket e do agente, políticas de SLA,
calendários, visualizações, papéis, campos do ticket e tokens de API.
`staydesk_diagnostico_da_distribuicao` diz por que cada agente recebe ou não
cada fila, e `staydesk_configurar` aplica o YAML da operação inteira. Há ainda
as conversas, times, caixas e agentes do Chatwoot. A lista completa está em
`docs/staydesk/api-e-mcp.md`.

O diagnóstico por conversa (`distribution_checks?conversation_id=`) ainda não
tem ferramenta: só pela API.

O que o token pode fazer é o que o papel da pessoa permite: o MCP não contorna
permissão, ele usa a mesma API e as mesmas policies.

## Acrescentar uma ferramenta

Uma linha em `ferramentas.mjs`. O servidor monta o esquema, a rota e o corpo a
partir da tabela; não há código por endpoint.
