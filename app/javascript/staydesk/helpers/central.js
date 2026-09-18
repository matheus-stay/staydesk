// A central de administração do StayDesk: o que se configura e o que se
// acompanha. Fica numa aba própria, com a barra lateral virando o menu dela.
export const CAMINHOS_DA_CENTRAL = ['/settings/', '/reports'];

export const estaNaCentral = caminho =>
  CAMINHOS_DA_CENTRAL.some(trecho => String(caminho || '').includes(trecho));
