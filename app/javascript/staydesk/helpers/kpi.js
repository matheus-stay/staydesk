// Contas de apresentação dos indicadores, no mesmo espírito do dashboard da
// casa: desvio contra o período anterior e semáforo por faixa.

const numero = (valor, casas = 1) =>
  Number(valor).toFixed(casas).replace('.', ',').replace(/,0$/, '');

// Desvio do período atual contra o anterior. `unidade` "pp" para o que já é
// percentual (CSAT, aceitação), "pct" para o resto. `bomQuando` diz se subir é
// bom ("up"), ruim ("down", tempos) ou indiferente ("none", volumes).
export const desvio = (
  atual,
  anterior,
  { unidade = 'pct', bomQuando = 'up' } = {}
) => {
  if (
    atual === null ||
    atual === undefined ||
    anterior === null ||
    anterior === undefined
  )
    return null;
  let valor;
  if (unidade === 'pp') valor = atual - anterior;
  else if (anterior === 0) valor = atual === 0 ? 0 : null;
  else valor = ((atual - anterior) / anterior) * 100;
  if (valor === null) return null;
  let direcao = 'flat';
  if (valor > 0.05) direcao = 'up';
  if (valor < -0.05) direcao = 'down';
  let bom = null;
  if (direcao !== 'flat' && bomQuando !== 'none') bom = direcao === bomQuando;
  let sinal = '';
  if (valor > 0) sinal = '+';
  if (valor < 0) sinal = '−';
  const texto = `${sinal}${numero(Math.abs(valor))}${unidade === 'pp' ? ' pp' : '%'}`;
  return { valor, direcao, bom, texto };
};

// Semáforo por faixa: [bom, atenção] em ordem decrescente quando maior é melhor.
export const semaforo = (valor, { bom, atencao, maiorMelhor = true }) => {
  if (valor === null || valor === undefined) return 'neutral';
  if (maiorMelhor) {
    if (valor >= bom) return 'good';
    if (valor >= atencao) return 'warn';
    return 'bad';
  }
  if (valor <= bom) return 'good';
  if (valor <= atencao) return 'warn';
  return 'bad';
};

export const percentual = valor =>
  valor === null || valor === undefined ? '—' : `${numero(valor)}%`;
