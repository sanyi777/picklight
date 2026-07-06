import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { createPinia, setActivePinia } from 'pinia';
import { usePicklightStore } from '../usePicklightStore';

describe('usePicklightStore', () => {
  beforeEach(() => {
    const storage = new Map<string, unknown>();

    setActivePinia(createPinia());
    vi.stubGlobal('uni', {
      getStorageSync: vi.fn((key: string) => storage.get(key)),
      setStorageSync: vi.fn((key: string, value: unknown) => storage.set(key, value)),
      removeStorageSync: vi.fn((key: string) => storage.delete(key)),
      showToast: vi.fn(),
      switchTab: vi.fn()
    });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('turns a 待办 scrap into a today todo', () => {
    const store = usePicklightStore();
    store.state.activeDate = '2026-07-05';

    const result = store.addScrap('待办', '整理小程序 MVP');

    expect(result.todo).toBeDefined();
    expect(store.todayTodos).toHaveLength(1);
    expect(store.todayTodos[0]).toMatchObject({
      date: '2026-07-05',
      content: '整理小程序 MVP',
      sourceScrapId: result.scrap.id
    });
  });

  it('archives schedule review as a 复盘 scrap', () => {
    const store = usePicklightStore();

    store.archiveReview('今天先把本地闭环跑通');

    expect(store.allScraps).toHaveLength(1);
    expect(store.allScraps[0]).toMatchObject({
      category: '复盘',
      content: '今天先把本地闭环跑通'
    });
  });
  it('resets local state and clears persisted data', () => {
    const store = usePicklightStore();

    store.addTodo('整理首页');
    store.addScrap('随想', '先做本地版本');

    expect(store.state.todos).toHaveLength(1);
    expect(store.state.scraps).toHaveLength(1);

    store.resetAllData();

    expect(store.state.todos).toHaveLength(0);
    expect(store.state.scraps).toHaveLength(0);
    expect(uni.removeStorageSync).toHaveBeenCalledWith('picklight-state-v1');
  });

  it('rolls unfinished todos to real today during hydrate', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 6, 6, 10));

    const firstStore = usePicklightStore();
    firstStore.state.activeDate = '2026-07-06';
    firstStore.addTodo('完成小程序调试');

    vi.setSystemTime(new Date(2026, 6, 7, 8));
    setActivePinia(createPinia());

    const nextStore = usePicklightStore();
    nextStore.hydrate();

    expect(nextStore.state.activeDate).toBe('2026-07-07');
    expect(nextStore.state.todos).toHaveLength(1);
    expect(nextStore.state.todos[0]).toMatchObject({
      date: '2026-07-07',
      rolledOverFrom: '2026-07-06',
      completed: false
    });
  });
});
