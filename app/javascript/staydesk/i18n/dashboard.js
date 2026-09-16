import overridesEn from './overrides/dashboard/en.json';
import overridesPtBR from './overrides/dashboard/pt_BR.json';
import messagesEn from './messages/en.json';
import messagesPtBR from './messages/pt_BR.json';

// overrides/: textos do upstream reescritos com a marca (gerados por custom/bin/marca.mjs).
// messages/: textos das telas próprias da camada, sob a chave STAYDESK.
export default {
  en: { ...overridesEn, ...messagesEn },
  pt_BR: { ...overridesPtBR, ...messagesPtBR },
};
