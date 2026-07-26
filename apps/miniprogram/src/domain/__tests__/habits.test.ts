import { describe, expect, it } from 'vitest';
import { createHabit, syncHabitTodos } from '../habits';
import { toggleTodo } from '../todos';
import type { Habit } from '../types';

describe('habits', () => {
  it('rejects an empty habit, an empty schedule, or an invalid time', () => {
    expect(() => createHabit({ id: 'empty', content: ' ', weekdays: [1] })).toThrow('请填写习惯内容');
    expect(() => createHabit({ id: 'days', content: '阅读', weekdays: [] })).toThrow('请至少选择一天');
    expect(() => createHabit({ id: 'time', content: '阅读', time: '25:90', weekdays: [1] })).toThrow(
      '固定时间格式不正确'
    );
  });

  it('generates matching todos for the next seven days', () => {
    const habit = createHabit({
      id: 'habit-1',
      content: '锻炼',
      time: '19:00',
      weekdays: [1, 3, 5],
      now: '2026-07-27T01:00:00.000Z'
    });

    const todos = syncHabitTodos({
      todos: [],
      habits: [habit],
      fromDate: '2026-07-27',
      createId: (habitId, date) => `${habitId}-${date}`,
      now: '2026-07-27T01:00:00.000Z'
    });

    expect(todos.map((todo) => [todo.date, todo.content, todo.time, todo.sourceHabitId])).toEqual([
      ['2026-07-27', '锻炼', '19:00', 'habit-1'],
      ['2026-07-29', '锻炼', '19:00', 'habit-1'],
      ['2026-07-31', '锻炼', '19:00', 'habit-1']
    ]);
  });

  it('does not duplicate generated todos or reset their completion state', () => {
    const habit = createHabit({
      id: 'habit-1',
      content: '背单词',
      weekdays: [1, 2, 3, 4, 5, 6, 7],
      now: '2026-07-27T01:00:00.000Z'
    });
    const first = syncHabitTodos({
      todos: [],
      habits: [habit],
      fromDate: '2026-07-27',
      createId: (habitId, date) => `${habitId}-${date}`,
      now: '2026-07-27T01:00:00.000Z'
    });
    const completed = toggleTodo(first, 'habit-1-2026-07-27', true, '2026-07-27T02:00:00.000Z');

    const second = syncHabitTodos({
      todos: completed,
      habits: [habit],
      fromDate: '2026-07-27',
      createId: (habitId, date) => `${habitId}-${date}-duplicate`,
      now: '2026-07-27T03:00:00.000Z'
    });

    expect(second).toHaveLength(7);
    expect(second.find((todo) => todo.date === '2026-07-27')).toMatchObject({
      id: 'habit-1-2026-07-27',
      completed: true
    });
  });

  it('collapses duplicate generated todos and preserves a completed instance', () => {
    const habit = createHabit({
      id: 'habit-1',
      content: '背单词',
      weekdays: [1],
      now: '2026-07-27T01:00:00.000Z'
    });
    const generated = syncHabitTodos({
      todos: [],
      habits: [habit],
      fromDate: '2026-07-27',
      createId: () => 'first',
      now: '2026-07-27T01:00:00.000Z'
    });
    const duplicate = { ...generated[0], id: 'completed-copy', completed: true };

    const reconciled = syncHabitTodos({
      todos: [...generated, duplicate],
      habits: [habit],
      fromDate: '2026-07-27',
      createId: () => 'new',
      now: '2026-07-27T02:00:00.000Z'
    });

    expect(reconciled).toHaveLength(1);
    expect(reconciled[0]).toMatchObject({ id: 'completed-copy', completed: true });
  });

  it('reconciles generated todos after a habit is changed or deleted', () => {
    const original = createHabit({
      id: 'habit-1',
      content: '阅读',
      time: '20:00',
      weekdays: [1, 3, 5],
      now: '2026-07-27T01:00:00.000Z'
    });
    const initialTodos = syncHabitTodos({
      todos: [],
      habits: [original],
      fromDate: '2026-07-27',
      createId: (habitId, date) => `${habitId}-${date}`,
      now: '2026-07-27T01:00:00.000Z'
    });
    const changed = { ...original, content: '读书', time: '', weekdays: [2, 4] as Habit['weekdays'] };

    const changedTodos = syncHabitTodos({
      todos: initialTodos,
      habits: [changed],
      fromDate: '2026-07-27',
      createId: (habitId, date) => `${habitId}-${date}`,
      now: '2026-07-27T02:00:00.000Z'
    });

    expect(changedTodos.map((todo) => [todo.date, todo.content, todo.time])).toEqual([
      ['2026-07-28', '读书', ''],
      ['2026-07-30', '读书', '']
    ]);
    expect(
      syncHabitTodos({
        todos: changedTodos,
        habits: [],
        fromDate: '2026-07-27',
        createId: (habitId, date) => `${habitId}-${date}`,
        now: '2026-07-27T03:00:00.000Z'
      })
    ).toEqual([]);
  });
});
