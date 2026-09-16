import dashboardOverrides from './i18n/dashboard';
import { mergeStaydeskMessages } from './i18n/merge';

// Plugin da camada StayDesk para o dashboard. Montado uma vez, em
// entrypoints/dashboard.js: app.use(StayDesk, { i18n }).
export default {
  install(app, { i18n }) {
    mergeStaydeskMessages(i18n, dashboardOverrides);
  },
};
