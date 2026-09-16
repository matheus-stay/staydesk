import en from './overrides/survey/en.json';
import pt_BR from './overrides/survey/pt_BR.json';
import { mergeStaydeskMessages } from './merge';

const overrides = { en, pt_BR };

export const mergeStaydeskSurveyMessages = i18n =>
  mergeStaydeskMessages(i18n, overrides);
