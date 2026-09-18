import { computed, onBeforeUnmount, ref } from 'vue';
import OffersAPI from '../api/offers';

const INTERVALO = 3000;

// Convite de atendimento (SPEC-16): chat e WhatsApp são oferecidos ao agente e ele
// aceita, como no Zendesk. Enquanto houver convite pendente, o relógio corre na tela.
export const useOffers = () => {
  const offer = ref(null);
  const secondsLeft = ref(0);
  let relogio = null;
  let consulta = null;

  const limpar = () => {
    offer.value = null;
    secondsLeft.value = 0;
  };

  const buscar = async () => {
    try {
      const { data } = await OffersAPI.get();
      if (!data || !data.id) {
        limpar();
        return;
      }
      offer.value = data;
      secondsLeft.value = data.seconds_left;
    } catch {
      limpar();
    }
  };

  const contar = () => {
    if (!offer.value) return;
    secondsLeft.value = Math.max(secondsLeft.value - 1, 0);
    if (secondsLeft.value === 0) limpar();
  };

  const start = () => {
    if (consulta) return;
    buscar();
    consulta = setInterval(buscar, INTERVALO);
    relogio = setInterval(contar, 1000);
  };

  const stop = () => {
    clearInterval(consulta);
    clearInterval(relogio);
    consulta = null;
    relogio = null;
  };

  const accept = async () => {
    const atual = offer.value;
    limpar();
    if (atual) await OffersAPI.accept(atual.id);
    return atual;
  };

  const decline = async () => {
    const atual = offer.value;
    limpar();
    if (atual) await OffersAPI.decline(atual.id);
  };

  onBeforeUnmount(stop);

  return {
    offer: computed(() => offer.value),
    secondsLeft: computed(() => secondsLeft.value),
    start,
    stop,
    accept,
    decline,
  };
};
