import { metricState, slaState, formatDuration } from '../helpers/sla';

describe('metricState', () => {
  it('calls it met only when the answer came within the target', () => {
    expect(
      metricState({ met_at: '2026-09-21T20:35:00Z', breached: false })
    ).toBe('met');
  });

  it('keeps the breach visible when the answer came late', () => {
    expect(
      metricState({ met_at: '2026-09-21T20:45:00Z', breached: true })
    ).toBe('late');
  });

  it('reports a breach that has no answer yet', () => {
    expect(
      metricState({ due_at: '2026-09-21T20:37:00Z', breached: true })
    ).toBe('breached');
  });

  it('counts down while the target is still open', () => {
    expect(
      metricState({ due_at: '2026-09-21T20:37:00Z', breached: false })
    ).toBe('due');
  });

  it('says nothing when the metric is not part of the policy', () => {
    expect(metricState({})).toBe('none');
    expect(metricState(null)).toBe('none');
  });
});

describe('slaState', () => {
  it('turns a past due date into a breach even before the server catches up', () => {
    const now = new Date('2026-09-21T21:00:00Z').getTime();
    const state = slaState(
      { sla_status: 'running', sla_vence_em: '2026-09-21T20:37:00Z' },
      now
    );

    expect(state.status).toBe('breached');
    expect(state.label).toBe(formatDuration(-23 * 60 * 1000));
  });
});
