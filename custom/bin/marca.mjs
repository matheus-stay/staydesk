#!/usr/bin/env node
/* eslint-disable no-console */
// Marca StayDesk nos textos: gera as sobreposições e confere que nada visível ainda diz "Chatwoot".
//
//   node custom/bin/marca.mjs gerar      regrava app/javascript/staydesk/i18n/overrides/** a partir
//                                        dos dicionários do upstream (rodar depois de cada sync)
//   node custom/bin/marca.mjs varredura  falha se sobrar texto visível com "Chatwoot" sem sobreposição
//                                        (dicionários do front, config/locales e views ERB/Liquid)
//
// Identificadores de código nunca mudam: SDK do widget, cookies, módulos Ruby, pacotes.
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const BRAND = 'StayDesk';
const LOCALES = ['en', 'pt_BR'];
const OVERRIDES_DIR = 'app/javascript/staydesk/i18n/overrides';
const SURFACES = {
  dashboard: locale => `app/javascript/dashboard/i18n/locale/${locale}`,
  widget: locale => `app/javascript/widget/i18n/locale/${locale}.json`,
  survey: locale => `app/javascript/survey/i18n/locale/${locale}.json`,
};
// Código, URL, nome de fora ou fallback de configuração: não é texto visível.
const IDENTIFIER =
  /[Cc]hatwoot(Settings|SDK|Config|WebChannel|Hub|App|ExceptionTracker|MarkdownRenderer)|\$chatwoot|@chatwoot|chatwoot\.(com|help|dev)|github\.com\/chatwoot|Chatwoot\.config|Chatwoot::|chatwoot_|chatwoot:ready|chatwootPubsubToken|CHATWOOT_[A-Z_]+|cw_conversation|\|\|\s*'Chatwoot'|assign brand_name = 'Chatwoot'/g;
const VISIBLE = /chatwoot/i;
// Não troca dentro de placeholders como {latestChatwootVersion}.
const NAME_OUTSIDE_PLACEHOLDERS = /Chatwoot(?![^{]*\})/g;

const readJson = path => JSON.parse(readFileSync(resolve(root, path), 'utf8'));

// Tira identificadores, fallbacks de configuração e placeholders como
// {latestChatwootVersion}; o que sobrar com "chatwoot" é texto visível.
const visibleText = value =>
  value.replace(IDENTIFIER, '').replace(/\{[^}]*\}/g, '');

const isVisibleChatwoot = value =>
  typeof value === 'string' && VISIBLE.test(visibleText(value));

// Dicionário do dashboard: um objeto por locale, mesclando os JSON como locale/<l>/index.js faz.
const loadSurface = (surface, locale) => {
  const path = SURFACES[surface](locale);
  if (surface !== 'dashboard') return readJson(path);
  return readdirSync(resolve(root, path))
    .filter(file => file.endsWith('.json'))
    .reduce((all, file) => ({ ...all, ...readJson(join(path, file)) }), {});
};

// Percorre o dicionário e devolve só as folhas visíveis com "Chatwoot", já reescritas.
const overridesFor = messages => {
  const walk = node =>
    Object.entries(node).reduce((acc, [key, value]) => {
      if (value && typeof value === 'object') {
        const child = walk(value);
        if (Object.keys(child).length) acc[key] = child;
      } else if (isVisibleChatwoot(value)) {
        acc[key] = value.replace(NAME_OUTSIDE_PLACEHOLDERS, BRAND);
      }
      return acc;
    }, {});
  return walk(messages);
};

const leaves = (node, path = []) =>
  Object.entries(node).flatMap(([key, value]) =>
    value && typeof value === 'object'
      ? leaves(value, [...path, key])
      : [[[...path, key].join('.'), value]]
  );

const getPath = (node, path) =>
  path.split('.').reduce((acc, key) => (acc ? acc[key] : undefined), node);

const gerar = () => {
  Object.keys(SURFACES).forEach(surface => {
    LOCALES.forEach(locale => {
      const overrides = overridesFor(loadSurface(surface, locale));
      const target = resolve(root, OVERRIDES_DIR, surface, `${locale}.json`);
      writeFileSync(target, `${JSON.stringify(overrides, null, 2)}\n`);
      console.log(
        `${relative(root, target)}: ${leaves(overrides).length} texto(s)`
      );
    });
  });
};

// YAML do backend: subconjunto simples (mapas por indentação), o bastante para config/locales.
const yamlLeaves = path => {
  const stack = [];
  const found = [];
  readFileSync(resolve(root, path), 'utf8')
    .split('\n')
    .forEach(line => {
      const match = line.match(/^(\s*)([\w-]+):(.*)$/);
      if (!match) return;
      const depth = match[1].length / 2;
      stack.splice(depth);
      stack[depth] = match[2];
      if (match[3].trim())
        found.push([stack.slice(0, depth + 1).join('.'), match[3].trim()]);
    });
  return found;
};

const varredura = () => {
  const problems = [];

  Object.keys(SURFACES).forEach(surface => {
    LOCALES.forEach(locale => {
      const overrides = readJson(`${OVERRIDES_DIR}/${surface}/${locale}.json`);
      leaves(loadSurface(surface, locale))
        .filter(([, value]) => isVisibleChatwoot(value))
        .forEach(([path]) => {
          const override = getPath(overrides, path);
          if (!override || isVisibleChatwoot(override))
            problems.push(`${surface}/${locale}: ${path}`);
        });
    });
  });

  LOCALES.forEach(locale => {
    const overridePath = `custom/config/locales/${locale}.yml`;
    const covered = new Set(
      existsSync(resolve(root, overridePath))
        ? yamlLeaves(overridePath).map(([key]) => key)
        : []
    );
    yamlLeaves(`config/locales/${locale}.yml`)
      .filter(([, value]) => isVisibleChatwoot(value))
      .forEach(([key]) => {
        if (!covered.has(key))
          problems.push(`config/locales/${locale}.yml: ${key}`);
      });
  });

  const views = dir =>
    readdirSync(resolve(root, dir), { withFileTypes: true }).flatMap(entry => {
      const path = join(dir, entry.name);
      if (entry.isDirectory()) return views(path);
      return /\.(erb|liquid)$/.test(entry.name) ? [path] : [];
    });
  // widget_tests só existe fora de produção (config/routes.rb); a faixa de
  // "premium changes" do super admin é do Enterprise e nunca renderiza na community.
  const SKIPPED_VIEWS = [
    'app/views/widget_tests/',
    'app/views/super_admin/settings/show.html.erb',
  ];
  views('app/views')
    .filter(path => !SKIPPED_VIEWS.some(skipped => path.startsWith(skipped)))
    .forEach(path => {
      const text = readFileSync(resolve(root, path), 'utf8')
        .split('\n')
        .filter(line => !/^\s*(<%#|#|{%-?\s*comment)/.test(line))
        .join('\n');
      if (!isVisibleChatwoot(text)) return;
      if (!existsSync(resolve(root, 'custom', path)))
        problems.push(`${path}: sem sobreposição em custom/${path}`);
    });

  if (problems.length) {
    console.error(
      `varredura-marca: ${problems.length} texto(s) visível(is) ainda dizem Chatwoot`
    );
    problems.forEach(problem => console.error(`  - ${problem}`));
    process.exit(1);
  }
  console.log('varredura-marca: nenhum texto visível diz Chatwoot');
};

const command = process.argv[2];
if (command === 'gerar') gerar();
else if (command === 'varredura') varredura();
else {
  console.error('uso: node custom/bin/marca.mjs gerar | varredura');
  process.exit(2);
}
