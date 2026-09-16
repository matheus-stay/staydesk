import { createI18n } from 'vue-i18n';
import { mergeStaydeskMessages } from '../merge';

describe('mergeStaydeskMessages', () => {
  const buildI18n = () =>
    createI18n({
      legacy: false,
      locale: 'en',
      messages: {
        en: { LOGIN: { TITLE: 'Login to Chatwoot', EMAIL: 'Email' } },
        pt_BR: { LOGIN: { TITLE: 'Entrar no Chatwoot' } },
      },
    });

  it('overrides only the keys present in the overrides', () => {
    const i18n = buildI18n();

    mergeStaydeskMessages(i18n, {
      en: { LOGIN: { TITLE: 'Login to StayDesk' } },
      pt_BR: { LOGIN: { TITLE: 'Entrar no StayDesk' } },
    });

    expect(i18n.global.t('LOGIN.TITLE')).toBe('Login to StayDesk');
    expect(i18n.global.t('LOGIN.EMAIL')).toBe('Email');
    expect(i18n.global.getLocaleMessage('pt_BR').LOGIN.TITLE).toBe(
      'Entrar no StayDesk'
    );
  });

  it('keeps the dictionary intact when there are no overrides', () => {
    const i18n = buildI18n();

    mergeStaydeskMessages(i18n, { en: {}, pt_BR: {} });

    expect(i18n.global.t('LOGIN.TITLE')).toBe('Login to Chatwoot');
  });
});
