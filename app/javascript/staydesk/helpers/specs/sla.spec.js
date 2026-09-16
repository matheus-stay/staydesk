import { formatDuration, slaState } from '../sla';

const NOW = new Date('2026-09-16T12:00:00Z').getTime();

describe('sla helpers', () => {
  it('formats durations the short way', () => {
    expect(formatDuration(45 * 60 * 1000)).toBe('45m');
    expect(formatDuration(3 * 60 * 60 * 1000)).toBe('3h');
    expect(formatDuration(-2 * 60 * 60 * 1000)).toBe('-2h');
    expect(formatDuration(973 * 24 * 60 * 60 * 1000)).toBe('973d');
  });

  it('returns null without a known status', () => {
    expect(slaState({}, NOW)).toBeNull();
    expect(slaState({ sla_status: 'weird' }, NOW)).toBeNull();
  });

  it('describes running, paused and breached SLAs', () => {
    expect(
      slaState(
        { sla_status: 'running', sla_vence_em: '2026-09-16T14:00:00Z' },
        NOW
      )
    ).toEqual({
      status: 'running',
      label: '2h',
    });
    expect(
      slaState(
        { sla_status: 'paused', sla_vence_em: '2026-09-16T14:00:00Z' },
        NOW
      )
    ).toEqual({
      status: 'paused',
      label: null,
    });
    expect(
      slaState(
        { sla_status: 'running', sla_vence_em: '2026-09-16T10:00:00Z' },
        NOW
      )
    ).toEqual({
      status: 'breached',
      label: '-2h',
    });
  });
});
