import { formatDistanceToNow, fromUnixTime } from 'date-fns';
import { ptBR, enUS, es, fr } from 'date-fns/locale';

// O helper de tempo do upstream formata sempre em inglês. Aqui o tempo relativo
// sai no idioma da conta, que é o que o agente vê na lista em tabela.
const LOCALES = { pt_BR: ptBR, pt: ptBR, es, fr, en: enUS };

export const tempoRelativo = (unixSeconds, locale = 'en') => {
  if (!unixSeconds) return '';

  return formatDistanceToNow(fromUnixTime(unixSeconds), {
    addSuffix: true,
    locale: LOCALES[locale] || enUS,
  });
};
