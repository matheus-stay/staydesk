// Botão sem `type` dentro de um formulário envia o formulário: é o padrão do HTML,
// e alguns componentes do produto não declaram o tipo. Sem isto, clicar no seletor
// de valores de uma condição salvava e fechava a tela.
export const SAVE_MARK = 'staydeskSave';

export const fromSaveButton = event => {
  const submitter = event?.submitter;
  if (!submitter) return true;

  return SAVE_MARK in (submitter.dataset || {});
};
