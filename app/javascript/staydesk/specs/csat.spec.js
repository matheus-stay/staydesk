import { ratingFromSearch, preselecionarNota } from '../helpers/csat';

describe('ratingFromSearch', () => {
  it('reads the rating the customer clicked in the e-mail', () => {
    expect(ratingFromSearch('?rating=4')).toBe(4);
  });

  it('ignores anything that is not a rating from one to five', () => {
    expect(ratingFromSearch('?rating=9')).toBeNull();
    expect(ratingFromSearch('?rating=abc')).toBeNull();
    expect(ratingFromSearch('')).toBeNull();
  });
});

describe('preselecionarNota', () => {
  const pesquisa = extra => ({
    selectedRating: null,
    isFeedbackSubmitted: false,
    selectRating(nota) {
      this.selectedRating = nota;
    },
    ...extra,
  });

  it('marks the rating that came from the link', () => {
    const tela = pesquisa();

    expect(preselecionarNota(tela, '?rating=5')).toBe(true);
    expect(tela.selectedRating).toBe(5);
  });

  it('keeps an answer the customer already gave', () => {
    const tela = pesquisa({ selectedRating: 2 });

    expect(preselecionarNota(tela, '?rating=5')).toBe(false);
    expect(tela.selectedRating).toBe(2);
  });

  it('does nothing when the survey is already closed', () => {
    const tela = pesquisa({ isFeedbackSubmitted: true });

    expect(preselecionarNota(tela, '?rating=5')).toBe(false);
  });
});
