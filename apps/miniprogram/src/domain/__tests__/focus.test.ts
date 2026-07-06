import { describe, expect, it } from 'vitest';
import { addDistractionToFocusSession, completeFocusSession, createFocusSession, getFocusStats, startFocusSession } from '../focus';

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
});
