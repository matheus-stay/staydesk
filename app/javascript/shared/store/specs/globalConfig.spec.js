import { appendBrandAssetVersion } from '../globalConfig';

describe('appendBrandAssetVersion', () => {
  it('versions bundled brand assets to invalidate stale browser caches', () => {
    expect(appendBrandAssetVersion('/brand-assets/logo.svg', 'abc123')).toBe(
      '/brand-assets/logo.svg?v=abc123'
    );
  });

  it('preserves existing query parameters', () => {
    expect(
      appendBrandAssetVersion('/brand-assets/logo.svg?theme=dark', 'abc123')
    ).toBe('/brand-assets/logo.svg?theme=dark&v=abc123');
  });

  it('does not modify custom or externally hosted logos', () => {
    expect(
      appendBrandAssetVersion('https://cdn.example.com/logo.svg', 'abc123')
    ).toBe('https://cdn.example.com/logo.svg');
  });
});
