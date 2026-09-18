// Segundos viram tempo que se lê de relance: 2h 15min, 8min, 45s.
export const emDuracao = segundos => {
  if (segundos === null || segundos === undefined) return '—';
  const total = Math.max(0, Math.round(segundos));
  if (total < 60) return `${total}s`;

  const minutos = Math.floor(total / 60);
  if (minutos < 60) return `${minutos}min`;

  const horas = Math.floor(minutos / 60);
  const resto = minutos % 60;
  if (horas < 24) return resto ? `${horas}h ${resto}min` : `${horas}h`;

  const dias = Math.floor(horas / 24);
  const horasRestantes = horas % 24;
  return horasRestantes ? `${dias}d ${horasRestantes}h` : `${dias}d`;
};
