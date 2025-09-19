import { isFaceLabelled } from '../src/lib/faces';

describe('isFaceLabelled', () => {
  it('returns false for empty record', () => {
    expect(isFaceLabelled({})).toBe(false);
  });

  it('detects explicit label', () => {
    expect(isFaceLabelled({ label: 'Analyst' })).toBe(true);
  });

  it('detects whitelisted metadata', () => {
    expect(isFaceLabelled({ metadata: { whitelisted: true } })).toBe(true);
  });

  it('detects annotations containing @labelled', () => {
    expect(isFaceLabelled({ annotations: ['foo', '@labelled'] })).toBe(true);
  });
});
