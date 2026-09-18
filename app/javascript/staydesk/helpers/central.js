// A central de administração do StayDesk: o que se configura e o que se
// acompanha. Fica numa aba própria, com a barra lateral virando o menu dela.
export const CAMINHOS_DA_CENTRAL = ['/settings/', '/reports'];

export const estaNaCentral = caminho =>
  CAMINHOS_DA_CENTRAL.some(trecho => String(caminho || '').includes(trecho));

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
