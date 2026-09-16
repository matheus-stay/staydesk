#!/usr/bin/env node
/* eslint-disable no-console */
// Gate de toques no núcleo.
//
// Compara HEAD com a base do upstream (merge-base com `develop`, o espelho do
// Chatwoot oficial) e falha quando um arquivo do upstream mudou de um jeito
// que não é permitido ou sem registro em docs/staydesk/core-touches.md.
//
// Formas permitidas de tocar arquivo do upstream:
//   classe   — só classes Tailwind mudam (o restante da linha fica igual)
//   gancho   — uma linha que chama a camada StayDesk, marcada com `staydesk`
//   montagem — import/uso único da camada nos arquivos de entrada
//   view     — partial ERB sobreposta em custom/app/views (o original não muda)
//   legado   — edição no lugar herdada do ramo de UX, a migrar; não é checada
//
// Uso: node custom/bin/staydesk-gate.mjs [--base <ref>] [--worktree]
//   --worktree compara a árvore de trabalho (antes de commitar) em vez de HEAD
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const REGISTRY = 'docs/staydesk/core-touches.md';
const TYPES = new Set(['classe', 'gancho', 'montagem', 'view', 'legado']);
// O que é nosso nunca conta como toque no núcleo.
const OWN_PATHS = [
  /^custom\//,
  /^app\/javascript\/staydesk\//,
  /^docs\/staydesk\//,
  /^spec\/staydesk\//,
  /^swagger\/staydesk\//,
  // Gerado por `rails db:migrate`; as migrations de custom/ entram aqui para o
  // db:chatwoot_prepare de uma instalação nova carregá-las junto com o esquema.
  /^db\/schema\.rb$/,
  /^\.github\/workflows\/staydesk[_-]/,
  /^theme\//,
  /^tailwind\.config\.js$/,
  /^public\/brand-assets\//,
  /^public\/[^/]+\.(png|ico|svg|json|xml|webmanifest)$/,
];

const argBase = process.argv.indexOf('--base');
const upstreamRef =
  argBase > -1
    ? process.argv[argBase + 1]
    : process.env.STAYDESK_UPSTREAM_REF || 'develop';

const target = process.argv.includes('--worktree') ? [] : ['HEAD'];

const git = (...args) => execFileSync('git', args, { encoding: 'utf8' });

const loadRegistry = () => {
  const registry = new Map();
  readFileSync(REGISTRY, 'utf8')
    .split('\n')
    .forEach(line => {
      const match = line.match(/^\|\s*`([^`]+)`\s*\|\s*([a-z]+)\s*\|/);
      if (match && TYPES.has(match[2])) registry.set(match[1], match[2]);
    });
  return registry;
};

const changedFiles = base =>
  git('diff', '--name-status', '-M', base, ...target)
    .trim()
    .split('\n')
    .filter(Boolean)
    .map(line => {
      const parts = line.split('\t');
      return { status: parts[0][0], path: parts[parts.length - 1] };
    })
    .filter(({ path }) => !OWN_PATHS.some(re => re.test(path)));

// Hunks sem contexto: cada um com as linhas removidas e adicionadas.
const hunksOf = (base, path) => {
  const diff = git('diff', '-U0', base, ...target, '--', path);
  const hunks = [];
  let current = null;
  diff.split('\n').forEach(line => {
    if (line.startsWith('@@')) {
      current = { header: line, minus: [], plus: [] };
      hunks.push(current);
    } else if (current && line.startsWith('-') && !line.startsWith('---')) {
      current.minus.push(line.slice(1));
    } else if (current && line.startsWith('+') && !line.startsWith('+++')) {
      current.plus.push(line.slice(1));
    }
  });
  return hunks;
};

const stripClasses = text =>
  text
    .replace(/:?class="[^"]*"/g, '')
    .replace(/:?class='[^']*'/g, '')
    .replace(/\s+/g, '');

const isClassOnly = hunk =>
  hunk.minus.length > 0 &&
  stripClasses(hunk.minus.join('\n')) === stripClasses(hunk.plus.join('\n'));

const isStaydeskLine = line => /staydesk/i.test(line);

// Linha em branco não conta. Um gancho ou é uma troca linha a linha em que toda
// linha nova nomeia a camada, ou um bloco só de linhas novas (uma montagem de
// componente que o prettier quebrou em várias linhas) cuja primeira nomeia a camada.
const isHook = hunk => {
  const added = hunk.plus.filter(line => line.trim() !== '');
  if (!added.length) return false;
  if (hunk.minus.length === 0) return isStaydeskLine(added[0]);
  return (
    added.every(isStaydeskLine) && hunk.minus.length <= hunk.plus.length
  );
};

const checkHunks = (type, hunks) =>
  hunks.filter(hunk => {
    if (type === 'classe') return !isClassOnly(hunk);
    return !(isClassOnly(hunk) || isHook(hunk));
  });

const run = () => {
  const base = git('merge-base', 'HEAD', upstreamRef).trim();
  const registry = loadRegistry();
  const violations = [];
  let legacy = 0;

  changedFiles(base).forEach(({ status, path }) => {
    const type = registry.get(path);
    if (!type) {
      violations.push(`${path}: toque no núcleo sem registro em ${REGISTRY}`);
      return;
    }
    if (type === 'legado') {
      legacy += 1;
      return;
    }
    if (type === 'view') {
      violations.push(
        `${path}: registrado como view; o original não pode mudar`
      );
      return;
    }
    if (status !== 'M') {
      violations.push(
        `${path}: arquivo ${status === 'A' ? 'novo' : 'removido'} em pasta do upstream; mover para custom/ ou app/javascript/staydesk/`
      );
      return;
    }
    checkHunks(type, hunksOf(base, path)).forEach(hunk => {
      violations.push(`${path} ${hunk.header}: mudança fora do tipo "${type}"`);
    });
  });

  const baseShort = base.slice(0, 10);
  if (violations.length) {
    console.error(
      `staydesk-gate: ${violations.length} violação(ões) contra ${upstreamRef} (${baseShort})`
    );
    violations.forEach(v => console.error(`  - ${v}`));
    process.exit(1);
  }
  console.log(
    `staydesk-gate: ok contra ${upstreamRef} (${baseShort}); ${legacy} arquivo(s) legado(s) a migrar`
  );
};

run();
