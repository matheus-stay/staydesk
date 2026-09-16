// Mescla os textos StayDesk por cima dos dicionários do upstream numa instância
// vue-i18n já criada. Só as chaves presentes nos overrides mudam; o resto do
// dicionário (e o que o Crowdin sobrescreve a cada sync) segue intacto.
export const mergeStaydeskMessages = (i18n, overrides) => {
  Object.entries(overrides).forEach(([locale, messages]) => {
    i18n.global.mergeLocaleMessage(locale, messages);
  });
};
