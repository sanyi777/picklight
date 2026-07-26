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

    const result = store.addScrap('待办', '整理小程序 MVP', '16:30');

    expect(result.todo).toBeDefined();
    expect(store.todayTodos).toHaveLength(1);
    expect(store.todayTodos[0]).toMatchObject({
      date: '2026-07-05',
      time: '16:30',
      content: '整理小程序 MVP',
      sourceScrapId: result.scrap.id
    });
  });

  it('turns an edited scrap into a timed todo', () => {
    const store = usePicklightStore();
    store.state.activeDate = '2026-07-05';
    const result = store.addScrap('随想', '整理小程序 MVP');

    store.updateScrap(result.scrap.id, '待办', '整理小程序 MVP', '18:45');

    expect(store.todayTodos).toHaveLength(1);
    expect(store.todayTodos[0]).toMatchObject({
      date: '2026-07-05',
      time: '18:45',
      content: '整理小程序 MVP',
      sourceScrapId: result.scrap.id
    });
    expect(store.state.scraps[0].linkedTodoId).toBe(store.todayTodos[0].id);
  });

  it('syncs todo time when editing a linked todo scrap', () => {
    const store = usePicklightStore();
    store.state.activeDate = '2026-07-05';
    const result = store.addScrap('待办', '整理小程序 MVP', '16:30');

    store.updateScrap(result.scrap.id, '待办', '整理小程序 MVP 复查', '');

    expect(store.todayTodos).toHaveLength(1);
    expect(store.todayTodos[0]).toMatchObject({
      time: '',
      content: '整理小程序 MVP 复查'
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
    expect(uni.removeStorageSync).toHaveBeenCalledWith('picklight-state-v2');
  });

  it('keeps todo and scrap records linked when completing or deleting a todo', () => {
    const store = usePicklightStore();
    const { todo } = store.addScrap('待办', '同步事项');

    store.setTodoCompleted(todo!.id, true);
    expect(store.state.scraps[0].todoCompleted).toBe(true);

    store.deleteTodo(todo!.id);
    expect(store.state.todos).toHaveLength(0);
    expect(store.state.scraps).toHaveLength(0);
  });

  it('exports and imports a full local backup', () => {
    const sourceStore = usePicklightStore();
    sourceStore.state.activeDate = '2026-07-09';
    sourceStore.addTodo('准备 v0.2 正式版');
    sourceStore.addScrap('灵感', '先保护数据');

    const rawBackup = sourceStore.exportBackupText();
    const backup = JSON.parse(rawBackup);

    expect(backup).toMatchObject({
      app: 'picklight',
      schemaVersion: 3
    });

    setActivePinia(createPinia());
    const targetStore = usePicklightStore();
    targetStore.addTodo('保留的本地数据');

    targetStore.importBackupText(rawBackup);

    expect(targetStore.state.activeDate).toBeTruthy();
    expect(targetStore.state.todos).toHaveLength(2);
    expect(targetStore.state.todos.map((todo) => todo.content)).toEqual(expect.arrayContaining(['准备 v0.2 正式版', '保留的本地数据']));
    expect(targetStore.state.scraps).toHaveLength(1);
    expect(targetStore.state.scraps[0]).toMatchObject({
      category: '灵感',
      content: '先保护数据'
    });
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

  it('creates, updates, and deletes a habit with its seven-day todos', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 6, 27, 9));
    const store = usePicklightStore();

    const habit = store.addHabit('锻炼', '19:00', [1, 3, 5]);

    expect(store.state.habits).toHaveLength(1);
    expect(store.state.todos.map((todo) => todo.date)).toEqual(['2026-07-27', '2026-07-29', '2026-07-31']);

    store.updateHabit(habit.id, '读书', '', [2, 4]);

    expect(store.state.todos.map((todo) => [todo.date, todo.content, todo.time])).toEqual([
      ['2026-07-28', '读书', ''],
      ['2026-07-30', '读书', '']
    ]);

    store.deleteHabit(habit.id);

    expect(store.state.habits).toEqual([]);
    expect(store.state.todos).toEqual([]);
  });

  it('hydrates v0.1 local state without losing data', () => {
    uni.setStorageSync('picklight-state-v2', {
      todos: [],
      scraps: [],
      anchors: [],
      focusSessions: [],
      activeDate: '2026-07-27'
    });
    const store = usePicklightStore();

    store.hydrate();

    expect(store.state.habits).toEqual([]);
    expect(store.state.activeDate).toBeTruthy();
  });

  it('drops yesterday habit todos and refills the seven-day window during hydrate', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 6, 27, 9));
    const firstStore = usePicklightStore();
    firstStore.addHabit('背单词', '', [1, 2, 3, 4, 5, 6, 7]);

    vi.setSystemTime(new Date(2026, 6, 28, 9));
    setActivePinia(createPinia());
    const nextStore = usePicklightStore();
    nextStore.hydrate();

    expect(nextStore.state.todos).toHaveLength(7);
    expect(nextStore.state.todos.map((todo) => todo.date)).toEqual([
      '2026-07-28',
      '2026-07-29',
      '2026-07-30',
      '2026-07-31',
      '2026-08-01',
      '2026-08-02',
      '2026-08-03'
    ]);
  });

  it('imports a habit backup and reconciles its seven-day todos', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 6, 27, 9));
    const sourceStore = usePicklightStore();
    sourceStore.addHabit('喝水', '', [1, 2, 3, 4, 5, 6, 7]);
    const parsedBackup = JSON.parse(sourceStore.exportBackupText());
    parsedBackup.state.todos = [];

    setActivePinia(createPinia());
    const targetStore = usePicklightStore();
    targetStore.importBackupText(JSON.stringify(parsedBackup));

    expect(targetStore.state.habits).toHaveLength(1);
    expect(targetStore.state.todos).toHaveLength(7);
    expect(new Set(targetStore.state.todos.map((todo) => todo.sourceHabitId))).toEqual(
      new Set([targetStore.state.habits[0].id])
    );
  });
});
