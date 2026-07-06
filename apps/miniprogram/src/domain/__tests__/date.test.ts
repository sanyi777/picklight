import { describe, expect, it } from 'vitest';
import { addDays, getNextSevenDays, todayISODate, toISODate } from '../date';

describe('date helpers', () => {
  it('formats local dates as yyyy-MM-dd', () => {
    expect(toISODate(new Date(2026, 6, 5))).toBe('2026-07-05');
  });

  it('adds days across month boundaries', () => {
    expect(addDays('2026-07-31', 1)).toBe('2026-08-01');
  });

  it('builds a seven day window from the active date', () => {
    expect(getNextSevenDays('2026-07-05')).toEqual([
      '2026-07-05',
      '2026-07-06',
      '2026-07-07',
      '2026-07-08',
      '2026-07-09',
      '2026-07-10',
      '2026-07-11'
    ]);
  });

  it('can derive today from an injected clock', () => {
    expect(todayISODate(new Date(2026, 6, 5))).toBe('2026-07-05');
  });
});
