#!/usr/bin/env node
// Servidor MCP do StayDesk: expõe a API da conta como ferramentas, para ler os
// números da operação e configurar filas, SLA, status, papéis e área de trabalho
// sem abrir a tela. O catálogo está em ferramentas.mjs; aqui só o encanamento.
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { Api } from './api.mjs';
import { FERRAMENTAS } from './ferramentas.mjs';

const porNome = new Map(FERRAMENTAS.map(item => [item.nome, item]));

const esquema = ferramenta => ({
  name: ferramenta.nome,
  description: ferramenta.descricao,
  inputSchema: {
    type: 'object',
    properties: ferramenta.argumentos,
    required: ferramenta.rota.includes('{id}') ? ['id'] : [],
  },
});

// Query para GET, corpo para o resto; `id` sempre vai no caminho.
const montar = (ferramenta, argumentos = {}) => {
  const { id, ...resto } = argumentos;
  const rota = ferramenta.rota.replace('{id}', id);
  if (ferramenta.metodo === 'GET') return { rota, query: resto };

  const dados = Object.fromEntries(
    Object.entries(resto).filter(([, valor]) => valor !== undefined)
  );
  return { rota, corpo: ferramenta.corpoEm ? { [ferramenta.corpoEm]: dados } : dados };
};

const servidor = new Server(
  { name: 'staydesk', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

servidor.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: FERRAMENTAS.map(esquema),
}));

servidor.setRequestHandler(CallToolRequestSchema, async pedido => {
  const ferramenta = porNome.get(pedido.params.name);
  if (!ferramenta) {
    return {
      isError: true,
      content: [{ type: 'text', text: `Ferramenta desconhecida: ${pedido.params.name}` }],
    };
  }

  try {
    const api = Api.doAmbiente();
    const { rota, query, corpo } = montar(ferramenta, pedido.params.arguments);
    const resposta = await api.chamar({ metodo: ferramenta.metodo, rota, query, corpo });
    return { content: [{ type: 'text', text: JSON.stringify(resposta, null, 2) }] };
  } catch (erro) {
    return { isError: true, content: [{ type: 'text', text: erro.message }] };
  }
});

await servidor.connect(new StdioServerTransport());
