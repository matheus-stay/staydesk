// Gera a chamada em três linguagens a partir do que o painel de teste montou.
const json = valor => JSON.stringify(valor, null, 2);

export const gerarCurl = ({ metodo, url, token, corpo }) => {
  const linhas = [
    `curl -X ${metodo} "${url}" \\`,
    `  -H "api_access_token: ${token}"`,
  ];
  if (corpo) {
    linhas[1] += ' \\';
    linhas.push(`  -H "content-type: application/json" \\`);
    linhas.push(`  -d '${JSON.stringify(corpo)}'`);
  }
  return linhas.join('\n');
};

export const gerarJavascript = ({ metodo, url, token, corpo }) => {
  const opcoes = [
    `  method: "${metodo}"`,
    `  headers: { api_access_token: "${token}"${corpo ? ', "content-type": "application/json"' : ''} }`,
  ];
  if (corpo)
    opcoes.push(
      `  body: JSON.stringify(${json(corpo).replace(/\n/g, '\n  ')})`
    );
  return [
    `const resposta = await fetch("${url}", {`,
    opcoes.join(',\n'),
    `});`,
    `const dados = await resposta.json();`,
  ].join('\n');
};

export const gerarPython = ({ metodo, url, token, corpo }) => {
  const linhas = [
    'import requests',
    '',
    `resposta = requests.request(`,
    `    "${metodo}",`,
    `    "${url}",`,
    `    headers={"api_access_token": "${token}"},`,
  ];
  if (corpo) linhas.push(`    json=${json(corpo).replace(/\n/g, '\n    ')},`);
  linhas.push(')', 'dados = resposta.json()');
  return linhas.join('\n');
};

export const LINGUAGENS = [
  { chave: 'curl', rotulo: 'cURL', gerar: gerarCurl },
  { chave: 'javascript', rotulo: 'JavaScript', gerar: gerarJavascript },
  { chave: 'python', rotulo: 'Python', gerar: gerarPython },
];
