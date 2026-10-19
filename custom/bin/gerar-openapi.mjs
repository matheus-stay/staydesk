#!/usr/bin/env node
// Gera swagger/staydesk/openapi.json a partir de custom/config/api_reference.json.
//
// A referência é a fonte: ela aparece na Central, é testada para não ficar rota
// sem documentação, e daqui sai o OpenAPI que um front (ou a IA de quem o
// constrói) usa para gerar o cliente tipado da API. Rodar depois de mexer na
// referência:  node custom/bin/gerar-openapi.mjs   (--conferir só verifica)
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const referencia = JSON.parse(readFileSync(resolve(raiz, 'custom/config/api_reference.json'), 'utf8'));
const versao = readFileSync(resolve(raiz, 'custom/VERSION'), 'utf8').trim();
const destino = resolve(raiz, 'swagger/staydesk/openapi.json');

const TIPOS = [
  [/^lista de inteiro/i, { type: 'array', items: { type: 'integer' } }],
  [/^lista/i, { type: 'array', items: { type: 'string' } }],
  [/data-hora|iso 8601/i, { type: 'string', format: 'date-time' }],
  [/^data/i, { type: 'string', format: 'date' }],
  [/inteiro|n[úu]mero/i, { type: 'integer' }],
  [/booleano/i, { type: 'boolean' }],
  [/objeto|hash/i, { type: 'object' }],
];
const esquema = tipo => {
  const achado = TIPOS.find(([padrao]) => padrao.test(String(tipo || '')));
  return achado ? { ...achado[1] } : { type: 'string' };
};

const caminhoCompleto = endpoint => {
  const base = endpoint.base || referencia.base;
  return `${base}/${endpoint.caminho}`.replace(/\/+/g, '/');
};

const parametrosDoCaminho = caminho =>
  [...caminho.matchAll(/\{(\w+)\}/g)].map(([, nome]) => ({
    name: nome, in: 'path', required: true, schema: { type: nome === 'id' || nome.endsWith('_id') ? 'integer' : 'string' },
  }));

const operacao = (endpoint, grupo) => {
  const op = {
    tags: [grupo.titulo],
    summary: endpoint.titulo,
    description: [endpoint.resumo, endpoint.detalhes, endpoint.escopo ? `Escopo do token de API: \`${endpoint.escopo}\`.` : '']
      .filter(Boolean).join('\n\n'),
    parameters: [
      ...parametrosDoCaminho(caminhoCompleto(endpoint)),
      ...(endpoint.query || []).map(q => ({
        name: q.nome, in: 'query', required: Boolean(q.obrigatorio), description: q.descricao,
        schema: { ...esquema(q.tipo), ...(q.exemplo !== undefined ? { example: q.exemplo } : {}) },
      })),
    ],
    responses: Object.fromEntries((endpoint.respostas || [{ codigo: 200, descricao: 'ok' }])
      .map(r => [String(r.codigo), { description: r.descricao }])),
  };
  if (endpoint.escopo) op['x-staydesk-escopo'] = endpoint.escopo;
  if (endpoint.mcp) op['x-staydesk-mcp'] = endpoint.mcp;
  if (endpoint.corpo || endpoint.payload) {
    const propriedades = Object.fromEntries((endpoint.corpo || []).map(c => [c.nome, {
      ...esquema(c.tipo), description: c.descricao, ...(c.exemplo !== undefined ? { example: c.exemplo } : {}),
    }]));
    const obrigatorios = (endpoint.corpo || []).filter(c => c.obrigatorio).map(c => c.nome);
    op.requestBody = {
      content: {
        'application/json': {
          schema: { type: 'object', properties: propriedades, ...(obrigatorios.length ? { required: obrigatorios } : {}) },
          ...(endpoint.payload ? { example: endpoint.payload } : {}),
        },
      },
    };
  }
  return op;
};

const paths = {};
for (const grupo of referencia.grupos) {
  for (const endpoint of grupo.endpoints || []) {
    const caminho = caminhoCompleto(endpoint);
    paths[caminho] ||= {};
    paths[caminho][endpoint.metodo.toLowerCase()] = operacao(endpoint, grupo);
  }
}

const documento = {
  openapi: '3.1.0',
  info: {
    title: 'StayDesk — API',
    version: versao,
    description: 'API que a camada StayDesk acrescenta ao Chatwoot. Gerada de custom/config/api_reference.json por custom/bin/gerar-openapi.mjs: não editar à mão. Os endpoints do produto (conversas, mensagens, contatos, caixas…) estão na referência do Chatwoot em swagger/swagger.json.',
  },
  servers: [{ url: 'https://staydesk-staging.staycloud.com.br', description: 'staging' }],
  security: [{ sessao: [] }, { tokenDeApi: [] }],
  components: {
    securitySchemes: {
      sessao: { type: 'apiKey', in: 'header', name: 'access-token', description: 'Sessão de usuário (devise_token_auth): mandar access-token, client, uid e token-type recebidos no login (POST /auth/sign_in).' },
      tokenDeApi: { type: 'apiKey', in: 'header', name: 'api_access_token', description: 'Token de API do StayDesk (sd_…, com escopo) ou token pessoal. Na superadministração (/platform/...), o token de um Platform App.' },
    },
  },
  tags: referencia.grupos.map(g => ({ name: g.titulo, description: g.texto || g.descricao || '' })),
  paths,
};

const texto = `${JSON.stringify(documento, null, 2)}\n`;
if (process.argv.includes('--conferir')) {
  let atual = '';
  try { atual = readFileSync(destino, 'utf8'); } catch { /* ainda não existe */ }
  if (atual !== texto) {
    console.error('openapi.json desatualizado: rode node custom/bin/gerar-openapi.mjs');
    process.exit(1);
  }
  console.log('openapi.json em dia');
} else {
  writeFileSync(destino, texto);
  console.log(`openapi.json: ${Object.keys(paths).length} caminhos, ${referencia.grupos.reduce((n, g) => n + (g.endpoints || []).length, 0)} operações`);
}
