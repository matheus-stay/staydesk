import { fromSaveButton } from '../form';

describe('fromSaveButton', () => {
  const botao = dataset => ({ submitter: { dataset } });

  it('accepts the submit that came from the save button', () => {
    expect(fromSaveButton(botao({ staydeskSave: '' }))).toBe(true);
  });

  it('accepts the keyboard submit, which has no submitter', () => {
    expect(fromSaveButton({ submitter: null })).toBe(true);
    expect(fromSaveButton(undefined)).toBe(true);
  });

  it('refuses a submit fired by any other button inside the form', () => {
    expect(fromSaveButton(botao({}))).toBe(false);
    expect(fromSaveButton(botao({ somethingElse: '1' }))).toBe(false);
  });
});
