import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { applyDefaultColorScheme } from '../config/theme';

vi.mock('shared/helpers/localStorage', () => ({
  LocalStorage: { get: vi.fn(), set: vi.fn() },
}));

describe('applyDefaultColorScheme', () => {
  beforeEach(() => vi.clearAllMocks());

  it('stores light when the user never chose a scheme', () => {
    LocalStorage.get.mockReturnValue(null);

    applyDefaultColorScheme();

    expect(LocalStorage.set).toHaveBeenCalledWith(
      LOCAL_STORAGE_KEYS.COLOR_SCHEME,
      'light'
    );
  });

  it('keeps the scheme the user chose', () => {
    LocalStorage.get.mockReturnValue('dark');

    applyDefaultColorScheme();

    expect(LocalStorage.set).not.toHaveBeenCalled();
  });
});
