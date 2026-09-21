// A nota que o cliente escolheu no e-mail vem na URL da pesquisa (?rating=4):
// ele clica na carinha no e-mail e a pesquisa abre com a nota já marcada, em
// vez de pedir que ele escolha de novo. Só aceita 1 a 5.
export const ratingFromSearch = search => {
  const nota = Number.parseInt(
    new URLSearchParams(search || '').get('rating'),
    10
  );

  return nota >= 1 && nota <= 5 ? nota : null;
};

// Aplica essa nota na tela da pesquisa, sem sobrescrever resposta já dada.
export const preselecionarNota = (
  pesquisa,
  search = window.location.search
) => {
  const nota = ratingFromSearch(search);
  if (!nota || pesquisa.isFeedbackSubmitted || pesquisa.selectedRating)
    return false;

  pesquisa.selectRating(nota);
  return true;
};
