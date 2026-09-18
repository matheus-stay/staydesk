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
| `STAYDESK_TOKEN` | token de acesso do usuário (Perfil › Token de acesso) |
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

`staydesk_kpis` traz CSAT, tempo de primeira resposta e de resolução por fila,
quem está esperando e o tempo de cada agente em cada status. As demais leem e
escrevem configuração: filas, filas de carga, status do ticket e do agente,
políticas de SLA, calendários, visualizações, papéis, além das conversas, times,
caixas e agentes do Chatwoot.

O que o token pode fazer é o que o papel da pessoa permite: o MCP não contorna
permissão, ele usa a mesma API e as mesmas policies.

## Acrescentar uma ferramenta

Uma linha em `ferramentas.mjs`. O servidor monta o esquema, a rota e o corpo a
partir da tabela; não há código por endpoint.
