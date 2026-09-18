import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { FERRAMENTAS } from '../../../../custom/mcp/ferramentas.mjs';

// A referência da API cita ferramentas do MCP pelo nome. Se alguém renomear uma
// ferramenta, a página de documentação passaria a mentir: este teste não deixa.
const referencia = JSON.parse(
  readFileSync(
    resolve(__dirname, '../../../../custom/config/api_reference.json'),
    'utf8'
  )
);

const endpoints = referencia.grupos.flatMap(grupo => grupo.endpoints);
const nomesDeFerramenta = new Set(
  FERRAMENTAS.map(ferramenta => ferramenta.nome)
);

describe('referência da API', () => {
  it('cita ferramenta de MCP que existe', () => {
    const citadas = endpoints.map(endpoint => endpoint.mcp).filter(Boolean);

    expect(citadas.length).toBeGreaterThan(0);
    citadas.forEach(nome => expect(nomesDeFerramenta.has(nome)).toBe(true));
  });

  it('descreve todo endpoint com método, caminho, resumo e escopo', () => {
    const incompletos = endpoints.filter(
      endpoint =>
        !endpoint.metodo ||
        !endpoint.caminho ||
        !endpoint.resumo ||
        !endpoint.escopo
    );

    expect(incompletos).toEqual([]);
  });

  it('dá um título e uma chave a cada grupo', () => {
    referencia.grupos.forEach(grupo => {
      expect(grupo.chave).toBeTruthy();
      expect(grupo.titulo).toBeTruthy();
      expect(grupo.endpoints.length).toBeGreaterThan(0);
    });
  });
});
