import { describe, expect, it, vi } from 'vitest';
import { mergePicklightStates, parsePicklightBackup, serializePicklightBackup } from '../backup';
import type { PicklightState } from '../types';

function createState(): PicklightState {
  return {
    todos: [],
    scraps: [],
    anchors: [],
    focusSessions: [],
    habits: [],
    activeDate: '2026-07-09'
  };
}

describe('backup', () => {
  it('serializes and parses a picklight backup', () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 6, 9, 12));

    const raw = serializePicklightBackup(createState());
    const backup = parsePicklightBackup(raw);

    expect(backup).toMatchObject({
      app: 'picklight',
      schemaVersion: 3,
      exportedAt: '2026-07-09T04:00:00.000Z',
      state: {
        activeDate: '2026-07-09'
      }
    });

    vi.useRealTimers();
  });

  it('rejects invalid json', () => {
    expect(() => parsePicklightBackup('{ nope')).toThrow('备份内容不是有效的 JSON');
  });

  it('rejects backups from another app', () => {
    expect(() => parsePicklightBackup(JSON.stringify({ app: 'other' }))).toThrow('这不是拾光的数据备份');
  });

  it('rejects unsupported schema versions', () => {
    const raw = JSON.stringify({
      app: 'picklight',
      schemaVersion: 99,
      exportedAt: '2026-07-09T00:00:00.000Z',
      state: createState()
    });

    expect(() => parsePicklightBackup(raw)).toThrow('暂不支持 schemaVersion 99 的备份');
  });

  it('migrates a schema 2 backup without habits', () => {
    const legacyState = createState();
    const { habits: _habits, ...stateWithoutHabits } = legacyState;
    const raw = JSON.stringify({
      app: 'picklight',
      schemaVersion: 2,
      exportedAt: '2026-07-09T00:00:00.000Z',
      state: stateWithoutHabits
    });

    expect(parsePicklightBackup(raw)).toMatchObject({
      schemaVersion: 3,
      state: {
        habits: []
      }
    });
  });

  it('rejects a schema 3 backup that omits habits', () => {
    const state = createState();
    const { habits: _habits, ...stateWithoutHabits } = state;
    const raw = JSON.stringify({
      app: 'picklight',
      schemaVersion: 3,
      exportedAt: '2026-07-09T00:00:00.000Z',
      state: stateWithoutHabits
    });

    expect(() => parsePicklightBackup(raw)).toThrow('备份中的数据结构不完整');
  });

  it('rejects a schema 3 backup with malformed habit records', () => {
    const state = createState();
    const raw = JSON.stringify({
      app: 'picklight',
      schemaVersion: 3,
      exportedAt: '2026-07-09T00:00:00.000Z',
      state: {
        ...state,
        habits: [{}]
      }
    });

    expect(() => parsePicklightBackup(raw)).toThrow('备份中的数据结构不完整');
  });

  it('merges distinct records and keeps the local version for duplicate text', () => {
    const local = createState();
    local.scraps = [{ id: 'local', date: '2026-07-09', category: '随想', content: '重复', createdAt: '2026-07-09T00:00:00.000Z', updatedAt: '2026-07-09T00:00:00.000Z' }];
    const incoming = createState();
    incoming.scraps = [
      { id: 'remote-duplicate', date: '2026-07-09', category: '灵感', content: '重复', createdAt: '2026-07-09T01:00:00.000Z', updatedAt: '2026-07-09T01:00:00.000Z' },
      { id: 'remote-new', date: '2026-07-09', category: '灵感', content: '新增', createdAt: '2026-07-09T01:00:00.000Z', updatedAt: '2026-07-09T01:00:00.000Z' }
    ];

    expect(mergePicklightStates(local, incoming).scraps.map((scrap) => scrap.id)).toEqual(['local', 'remote-new']);
  });

  it('merges distinct habit rules and keeps equivalent local rules', () => {
    const local = createState();
    local.habits = [
      {
        id: 'local-habit',
        content: '背单词',
        time: '08:30',
        weekdays: [1, 2, 3, 4, 5],
        createdAt: '2026-07-09T00:00:00.000Z',
        updatedAt: '2026-07-09T00:00:00.000Z'
      }
    ];
    const incoming = createState();
    incoming.habits = [
      { ...local.habits[0], id: 'duplicate-habit' },
      {
        id: 'new-habit',
        content: '锻炼',
        time: '',
        weekdays: [2, 4, 6],
        createdAt: '2026-07-09T01:00:00.000Z',
        updatedAt: '2026-07-09T01:00:00.000Z'
      }
    ];

    expect(mergePicklightStates(local, incoming).habits.map((habit) => habit.id)).toEqual([
      'local-habit',
      'new-habit'
    ]);
  });
});
