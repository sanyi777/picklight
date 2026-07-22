import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import PomodoroPanel from '../PomodoroPanel.vue';
import type { FocusSession } from '@/domain/types';
import { usePicklightStore } from '@/stores/usePicklightStore';

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
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.stubGlobal('uni', {
      getStorageSync: vi.fn(),
      setStorageSync: vi.fn(),
      removeStorageSync: vi.fn()
    });
  });

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

  it('completes the visible running session in the store', async () => {
    vi.useFakeTimers();
    const store = usePicklightStore();
    store.state.focusSessions = [runningSession()];
    const wrapper = mount(PomodoroPanel, { props: { latestSession: store.state.focusSessions[0] } });

    await wrapper.get('.complete-action').trigger('tap');

    expect(store.state.focusSessions[0].completed).toBe(true);
    expect(wrapper.get('.complete-action').attributes('data-eventsync')).toBe('true');
  });

  it('pauses the visible running session in the store', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-07-22T00:05:00.000Z'));
    const store = usePicklightStore();
    store.state.focusSessions = [runningSession()];
    const wrapper = mount(PomodoroPanel, { props: { latestSession: store.state.focusSessions[0] } });

    await wrapper.get('.secondary-action').trigger('tap');

    expect(store.state.focusSessions[0]).toMatchObject({
      status: 'paused',
      pausedAt: '2026-07-22T00:05:00.000Z'
    });
  });

  it('abandons the visible running session in the store', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-07-22T00:05:00.000Z'));
    const store = usePicklightStore();
    store.state.focusSessions = [runningSession()];
    const wrapper = mount(PomodoroPanel, { props: { latestSession: store.state.focusSessions[0] } });

    await wrapper.get('.abandon-action').trigger('tap');

    expect(store.state.focusSessions[0]).toMatchObject({
      status: 'completed',
      completed: true,
      actualSeconds: 300
    });
  });
});
