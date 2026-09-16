import en from './overrides/widget/en.json';
import pt_BR from './overrides/widget/pt_BR.json';
import { mergeStaydeskMessages } from './merge';

const overrides = { en, pt_BR };

export const mergeStaydeskWidgetMessages = i18n =>
  mergeStaydeskMessages(i18n, overrides);
