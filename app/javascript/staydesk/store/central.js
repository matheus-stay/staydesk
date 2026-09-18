import { defineStore } from 'pinia';

// O mapa da Central, como a barra lateral o montou: seções e o que cada uma
// contém, já filtrado pelo que a pessoa pode ver. As páginas de home da Central
// e de cada seção leem daqui, então tela e menu nunca divergem.
export const useCentralStore = defineStore('staydeskCentral', {
  state: () => ({ secoes: [] }),

  getters: {
    secao: state => chave =>
      state.secoes.find(item => item.chave === chave) || null,
  },

  actions: {
    registrar(secoes) {
      this.secoes = secoes;
    },
  },
});
