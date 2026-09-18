import { computed, onBeforeUnmount, ref } from 'vue';
import OffersAPI from '../api/offers';

const INTERVALO = 3000;
const SOM = '/audio/dashboard/ding.mp3';

// Convite de atendimento (SPEC-16): chat e WhatsApp são oferecidos ao agente e
// ele aceita, como no Zendesk. Quando caem vários de uma vez (até a capacidade
// dele), cada um vira um cartão com o próprio relógio; convite novo toca e avisa.
export const useOffers = () => {
  const offers = ref([]);
  let relogio = null;
  let consulta = null;
  let aoChegar = () => {};

  const tocar = () => {
    try {
      new Audio(SOM).play().catch(() => {});
    } catch {
      // sem áudio (aba sem interação ainda): o cartão e o aviso bastam
    }
  };

  const buscar = async () => {
    try {
      const { data } = await OffersAPI.get();
      const lista = Array.isArray(data) ? data : [];
      const conhecidos = new Set(offers.value.map(item => item.id));
      const novos = lista.filter(item => !conhecidos.has(item.id));
      offers.value = lista.map(item => ({
        ...item,
        secondsLeft: item.seconds_left,
      }));
      if (novos.length) {
        tocar();
        novos.forEach(item => aoChegar(item));
      }
    } catch {
      offers.value = [];
    }
  };

  const contar = () => {
    offers.value = offers.value
      .map(item => ({
        ...item,
        secondsLeft: Math.max(item.secondsLeft - 1, 0),
      }))
      .filter(item => item.secondsLeft > 0);
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

  const tirar = id => {
    const atual = offers.value.find(item => item.id === id);
    offers.value = offers.value.filter(item => item.id !== id);
    return atual;
  };

  const accept = async id => {
    const atual = tirar(id);
    if (atual) await OffersAPI.accept(atual.id);
    return atual;
  };

  const decline = async id => {
    const atual = tirar(id);
    if (atual) await OffersAPI.decline(atual.id);
  };

  // Quem monta o cartão decide o que fazer quando chega convite (aviso do navegador).
  const onArrive = callback => {
    aoChegar = callback;
  };

  onBeforeUnmount(stop);

  return {
    offers: computed(() => offers.value),
    start,
    stop,
    accept,
    decline,
    onArrive,
  };
};
