import { describe, expect, it } from 'vitest';
import {
  addDailyAnchor,
  createDailyAnchor,
  deleteAnchor,
  setCurrentAnchor,
  updateAnchorProgress,
  updateAnchorTitle
} from '../anchors';

describe('anchors', () => {
  it('allows at most two daily anchors', () => {
    const first = createDailyAnchor({ id: 'a', date: '2026-07-05', title: 'A', now: '2026-07-05T08:00:00.000Z' });
    const second = createDailyAnchor({ id: 'b', date: '2026-07-05', title: 'B', now: '2026-07-05T08:00:00.000Z' });
    const third = createDailyAnchor({ id: 'c', date: '2026-07-05', title: 'C', now: '2026-07-05T08:00:00.000Z' });

    expect(() => addDailyAnchor(addDailyAnchor([first], second), third)).toThrow('每天最多只能有两个锚点');
  });

  it('keeps only one current anchor for compatibility', () => {
    const anchors = [
      createDailyAnchor({ id: 'a', date: '2026-07-05', title: 'A', now: '2026-07-05T08:00:00.000Z' }),
      createDailyAnchor({ id: 'b', date: '2026-07-05', title: 'B', now: '2026-07-05T08:00:00.000Z' })
    ];

    expect(setCurrentAnchor(anchors, 'b').filter((anchor) => anchor.isCurrent).map((anchor) => anchor.id)).toEqual(['b']);
  });

  it('updates an anchor title', () => {
    const anchors = [
      createDailyAnchor({ id: 'a', date: '2026-07-05', title: 'A', now: '2026-07-05T08:00:00.000Z' })
    ];

    expect(updateAnchorTitle(anchors, 'a', '完成小程序')[0].title).toBe('完成小程序');
  });

  it('deletes an anchor', () => {
    const anchors = [
      createDailyAnchor({ id: 'a', date: '2026-07-05', title: 'A', now: '2026-07-05T08:00:00.000Z' })
    ];

    expect(deleteAnchor(anchors, 'a')).toEqual([]);
  });

  it('bounds manual progress between 0 and 100', () => {
    const anchors = [
      createDailyAnchor({ id: 'a', date: '2026-07-05', title: 'A', now: '2026-07-05T08:00:00.000Z' })
    ];

    expect(updateAnchorProgress(anchors, 'a', 140)[0].progress).toBe(100);
    expect(updateAnchorProgress(anchors, 'a', -20)[0].progress).toBe(0);
  });
});
