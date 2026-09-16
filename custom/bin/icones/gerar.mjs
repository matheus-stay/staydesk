#!/usr/bin/env node
/* eslint-disable no-console */
// Gera todos os ícones do StayDesk a partir de public/brand-assets/icon.svg:
// favicon, favicon-badge (com o ponto de mensagem nova), Apple, Android e Microsoft.
// Uso (da raiz do repositório):
//   pnpm --dir custom/bin/icones install --ignore-workspace && node custom/bin/icones/gerar.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { Resvg } = require('@resvg/resvg-js');

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const publicDir = resolve(root, 'public');
const source = readFileSync(
  resolve(publicDir, 'brand-assets/icon.svg'),
  'utf8'
);

// O ponto vermelho do badge ocupa o canto superior direito, como no ícone original do Chatwoot.
const badgeSource = source.replace(
  '</svg>',
  '<circle cx="104" cy="24" r="20" fill="#E5484D" stroke="#FFFFFF" stroke-width="6"/></svg>'
);

const ICONS = [
  ...[16, 32, 96, 512].map(size => [`favicon-${size}x${size}.png`, size]),
  ...[16, 32, 96].map(size => [
    `favicon-badge-${size}x${size}.png`,
    size,
    badgeSource,
  ]),
  ...[36, 48, 72, 96, 144, 192].map(size => [
    `android-icon-${size}x${size}.png`,
    size,
  ]),
  ...[57, 60, 72, 76, 114, 120, 144, 152, 180].map(size => [
    `apple-icon-${size}x${size}.png`,
    size,
  ]),
  ['apple-icon.png', 192],
  ['apple-icon-precomposed.png', 192],
  ['apple-touch-icon.png', 180],
  ['apple-touch-icon-precomposed.png', 180],
  ...[70, 144, 150, 310].map(size => [`ms-icon-${size}x${size}.png`, size]),
];

ICONS.forEach(([file, size, svg = source]) => {
  const png = new Resvg(svg, { fitTo: { mode: 'width', value: size } })
    .render()
    .asPng();
  writeFileSync(resolve(publicDir, file), png);
  console.log(`${file} (${size}px)`);
});
