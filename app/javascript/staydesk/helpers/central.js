// A central de administração do StayDesk: o que se configura e o que se
// acompanha. Fica numa aba própria, com a barra lateral virando o menu dela.
// Reconhece pelo trecho do endereço (segmento inteiro), não por texto: o perfil
// mora em /profile/settings e a entrada das configurações em /settings, sem a
// barra final, e as duas caíam no Hub. Campanhas, central de ajuda e Captain
// ficam desligados no StayDesk, mas se alguém abrir, é tela de administração.
export const CAMINHOS_DA_CENTRAL = [
  'settings',
  'reports',
  'profile',
  'campaigns',
  'portals',
  'captain',
];

const TRECHOS_DA_CENTRAL = new RegExp(
  `/(${CAMINHOS_DA_CENTRAL.join('|')})(/|$|\\?)`
);

export const estaNaCentral = caminho =>
  TRECHOS_DA_CENTRAL.test(String(caminho || ''));

// Para onde o link "Central" do rodapé leva. A Central é organizada em seções,
// então o destino é a home dela; quem não é administrador só entra se alguma
// tela dentro das seções estiver liberada para o papel dele.
const HOME_DA_CENTRAL = 'StaydeskCentralHome';

const folhas = itens =>
  (itens || []).flatMap(item =>
    item.children?.length ? folhas(item.children) : [item]
  );

export const destinoDaCentral = (item, checkPermissions) => {
  if (!item) return null;
  if (item.to) return item.to;

  const filhos = item.children || [];
  const home = filhos.find(filho => filho.name === HOME_DA_CENTRAL && filho.to);
  const liberadas = folhas(filhos).filter(
    folha =>
      folha.to && (!folha.permissions || checkPermissions(folha.permissions))
  );
  if (checkPermissions(['administrator'])) {
    return home?.to || liberadas[0]?.to || null;
  }

  const comPermissao = liberadas.find(folha => folha.permissions);
  if (!comPermissao) return null;

  return home?.to || comPermissao.to;
};
