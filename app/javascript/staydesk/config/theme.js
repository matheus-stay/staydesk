import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

// O StayDesk nasce no tema claro. O Chatwoot, sem preferência guardada, segue
// o sistema operacional ("auto"); aqui a primeira visita grava "light" e a
// escolha do usuário (Perfil › Aparência, ou o atalho) continua valendo.
export const STAYDESK_DEFAULT_COLOR_SCHEME = 'light';

export const applyDefaultColorScheme = () => {
  if (LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME)) return;
  LocalStorage.set(
    LOCAL_STORAGE_KEYS.COLOR_SCHEME,
    STAYDESK_DEFAULT_COLOR_SCHEME
  );
};
