import { mount } from '@vue/test-utils';
import { afterEach, describe, expect, it, vi } from 'vitest';
import PomodoroPanel from '../PomodoroPanel.vue';
import type { FocusSession } from '@/domain/types';

function runningSession(): FocusSession {
  return {
    id: 'focus-1',
    date: '2026-07-22',
    task: '完成测试',
    durationMinutes: 25,
    status: 'running',
    startedAt: '2026-07-22T00:00:00.000Z',
    pausedTotalSeconds: 0,
    completed: false,
    distractions: [],
    createdAt: '2026-07-22T00:00:00.000Z',
    updatedAt: '2026-07-22T00:00:00.000Z'
  };
}

describe('PomodoroPanel', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('stops the display ticker after the session becomes paused', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-07-22T00:05:00.000Z'));
    const session = runningSession();
    const wrapper = mount(PomodoroPanel, { props: { latestSession: session } });

    expect(vi.getTimerCount()).toBe(1);

    await wrapper.setProps({
      latestSession: {
        ...session,
        status: 'paused',
        pausedAt: '2026-07-22T00:05:00.000Z'
      }
    });

    expect(vi.getTimerCount()).toBe(0);
  });

  it('settles the visible running session with the selected outcome', async () => {
    vi.useFakeTimers();
    const wrapper = mount(PomodoroPanel, { props: { latestSession: runningSession() } });

    await wrapper.get('.complete-action').trigger('tap');
    await wrapper.get('.abandon-action').trigger('tap');

    expect(wrapper.emitted('settle')).toEqual([
      ['focus-1', 'completed'],
      ['focus-1', 'abandoned']
    ]);
    expect(wrapper.get('.complete-action').attributes('data-eventsync')).toBe('true');
    expect(wrapper.get('.abandon-action').attributes('data-eventsync')).toBe('true');
  });
});
