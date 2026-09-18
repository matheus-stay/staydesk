// O suficiente para a documentação: parágrafos, negrito e código inline. Tudo
// escapado antes, então o texto da referência nunca vira HTML por acidente.
const escapar = texto =>
  String(texto)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');

const formatar = linha =>
  escapar(linha)
    .replace(
      /`([^`]+)`/g,
      '<code class="rounded bg-n-alpha-2 px-1 py-0.5 font-mono text-[12.5px]">$1</code>'
    )
    .replace(
      /\*\*([^*]+)\*\*/g,
      '<strong class="font-medium text-n-slate-12">$1</strong>'
    );

export const paraHtml = texto =>
  String(texto || '')
    .split(/\n{2,}/)
    .map(paragrafo => paragrafo.trim())
    .filter(Boolean)
    .map(paragrafo => `<p>${formatar(paragrafo).replace(/\n/g, '<br>')}</p>`)
    .join('');
