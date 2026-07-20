import { describe, expect, it } from 'vitest';
import {
  addDistractionToFocusSession,
  completeFocusSession,
  createFocusSession,
  extendFocusSession,
  getFocusStats,
  getFocusTiming,
  pauseFocusSession,
  startFocusSession,
  abandonFocusSession,
  getActualFocusSeconds,
  clearFocusSessionsBeforeDate
} from '../focus';

describe('focus', () => {
  it('creates a focus session with manual duration and task', () => {
    const session = createFocusSession({
      id: 'focus-1',
      date: '2026-07-05',
      task: '写完领域模型',
      durationMinutes: 25,
      anchorId: 'anchor-1',
      now: '2026-07-05T08:00:00.000Z'
    });

    expect(session).toMatchObject({
      task: '写完领域模型',
      durationMinutes: 25,
      completed: false,
      anchorId: 'anchor-1'
    });
  });

  it('records lifecycle and distractions', () => {
    const session = createFocusSession({
      id: 'focus-1',
      date: '2026-07-05',
      task: 'A',
      durationMinutes: 25,
      now: '2026-07-05T08:00:00.000Z'
    });
    const started = startFocusSession([session], 'focus-1', '2026-07-05T08:01:00.000Z');
    const distracted = addDistractionToFocusSession(started, 'focus-1', ' 查消息 ', '2026-07-05T08:02:00.000Z');
    const completed = completeFocusSession(distracted, 'focus-1', '2026-07-05T08:26:00.000Z');

    expect(completed[0].distractions).toEqual(['查消息']);
    expect(completed[0].completed).toBe(true);
    expect(getFocusStats(completed, '2026-07-05')).toMatchObject({
      sessions: 1,
      completedSessions: 1,
      completedMinutes: 25
    });
  });

  it('calculates remaining time from timestamps after foreground recovery', () => {
    const session = createFocusSession({
      id: 'focus-1',
      date: '2026-07-05',
      task: 'A',
      durationMinutes: 25,
      now: '2026-07-05T08:00:00.000Z'
    });
    const [started] = startFocusSession([session], 'focus-1', '2026-07-05T08:00:00.000Z');

    expect(getFocusTiming(started, '2026-07-05T08:10:00.000Z')).toMatchObject({
      totalSeconds: 1500,
      elapsedSeconds: 600,
      remainingSeconds: 900,
      elapsed: false
    });

    expect(getFocusTiming(started, '2026-07-05T08:26:00.000Z')).toMatchObject({
      remainingSeconds: 0,
      elapsed: true
    });
  });

  it('does not count paused time when resuming a focus session', () => {
    const session = createFocusSession({
      id: 'focus-1',
      date: '2026-07-05',
      task: 'A',
      durationMinutes: 25,
      now: '2026-07-05T08:00:00.000Z'
    });
    const started = startFocusSession([session], 'focus-1', '2026-07-05T08:00:00.000Z');
    const paused = pauseFocusSession(started, 'focus-1', '2026-07-05T08:05:00.000Z');
    const resumed = startFocusSession(paused, 'focus-1', '2026-07-05T08:15:00.000Z');

    expect(resumed[0]).toMatchObject({
      status: 'running',
      pausedAt: undefined,
      pausedTotalSeconds: 600
    });
    expect(getFocusTiming(resumed[0], '2026-07-05T08:20:00.000Z')).toMatchObject({
      elapsedSeconds: 600,
      remainingSeconds: 900
    });
  });

  it('extends an elapsed focus session', () => {
    const session = createFocusSession({
      id: 'focus-1',
      date: '2026-07-05',
      task: 'A',
      durationMinutes: 25,
      now: '2026-07-05T08:00:00.000Z'
    });
    const started = startFocusSession([session], 'focus-1', '2026-07-05T08:00:00.000Z');
    const extended = extendFocusSession(started, 'focus-1', 5, '2026-07-05T08:26:00.000Z');

    expect(extended[0].durationMinutes).toBe(30);
    expect(getFocusTiming(extended[0], '2026-07-05T08:26:00.000Z')).toMatchObject({
      remainingSeconds: 240,
      elapsed: false
    });
  });

  it('records an abandoned session with its actual focused duration', () => {
    const session = createFocusSession({ id: 'focus-1', date: '2026-07-05', task: 'A', durationMinutes: 25, now: '2026-07-05T08:00:00.000Z' });
    const [started] = startFocusSession([session], 'focus-1', '2026-07-05T08:00:00.000Z');
    const [abandoned] = abandonFocusSession([started], 'focus-1', '2026-07-05T08:07:00.000Z');

    expect(abandoned).toMatchObject({ completed: true, status: 'completed', actualSeconds: 420 });
    expect(getActualFocusSeconds(abandoned)).toBe(420);
  });

  it('keeps focus history for the active day only', () => {
    const old = createFocusSession({ id: 'old', date: '2026-07-05', task: '旧', durationMinutes: 25 });
    const current = createFocusSession({ id: 'today', date: '2026-07-06', task: '今', durationMinutes: 25 });
    expect(clearFocusSessionsBeforeDate([old, current], '2026-07-06').map((session) => session.id)).toEqual(['today']);
  });
});
