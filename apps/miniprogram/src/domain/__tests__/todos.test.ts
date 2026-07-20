import { describe, expect, it } from 'vitest';
import { createTodo, getTodosForDate, rollUnfinishedTodos, toggleTodo } from '../todos';

describe('todos', () => {
  it('creates an incomplete todo for a date', () => {
    const todo = createTodo({
      id: 'todo-1',
      date: '2026-07-05',
      content: '  写完小程序计划  ',
      now: '2026-07-05T08:00:00.000Z'
    });

    expect(todo).toMatchObject({
      id: 'todo-1',
      date: '2026-07-05',
      time: '',
      content: '写完小程序计划',
      completed: false
    });
  });

  it('sorts timed todos before untimed todos', () => {
    const todos = [
      createTodo({ id: 'a', date: '2026-07-05', content: 'A', now: '2026-07-05T08:00:00.000Z' }),
      createTodo({ id: 'b', date: '2026-07-05', content: 'B', time: '09:00', now: '2026-07-05T08:00:00.000Z' }),
      createTodo({ id: 'c', date: '2026-07-05', content: 'C', time: '08:30', now: '2026-07-05T08:00:00.000Z' })
    ];

    expect(getTodosForDate(todos, '2026-07-05').map((todo) => todo.id)).toEqual(['c', 'b', 'a']);
  });

  it('rolls unfinished todos to the next day without duplicating them', () => {
    const todos = [
      createTodo({ id: 'a', date: '2026-07-05', content: 'A', now: '2026-07-05T08:00:00.000Z' }),
      createTodo({ id: 'b', date: '2026-07-05', content: 'B', now: '2026-07-05T08:00:00.000Z' })
    ];
    const completedTodos = toggleTodo(todos, 'b', true, '2026-07-05T09:00:00.000Z');
    const rolledTodos = rollUnfinishedTodos(completedTodos, '2026-07-05', '2026-07-06T00:00:00.000Z');

    expect(rolledTodos).toHaveLength(1);
    expect(rolledTodos.find((todo) => todo.id === 'a')).toMatchObject({
      date: '2026-07-06',
      rolledOverFrom: '2026-07-05'
    });
    expect(rolledTodos.find((todo) => todo.id === 'b')).toBeUndefined();
  });

  it('sorts incomplete deadlines, then incomplete inbox todos, then completed todos', () => {
    const todos = [
      createTodo({ id: 'inbox-old', date: '2026-07-05', content: '旧', now: '2026-07-05T08:00:00.000Z' }),
      createTodo({ id: 'deadline-late', date: '2026-07-05', content: '晚', time: '12:00', now: '2026-07-05T09:00:00.000Z' }),
      createTodo({ id: 'deadline-early', date: '2026-07-05', content: '早', time: '09:00', now: '2026-07-05T10:00:00.000Z' }),
      createTodo({ id: 'inbox-new', date: '2026-07-05', content: '新', now: '2026-07-05T11:00:00.000Z' })
    ];
    const completed = toggleTodo(todos, 'deadline-early', true, '2026-07-05T12:00:00.000Z');

    expect(getTodosForDate(completed, '2026-07-05').map((todo) => todo.id)).toEqual([
      'deadline-late',
      'inbox-new',
      'inbox-old',
      'deadline-early'
    ]);
  });

  it('clears completed todos and strips an expired deadline while rolling unfinished work', () => {
    const todos = [
      createTodo({ id: 'done', date: '2026-07-05', content: '完成', now: '2026-07-05T08:00:00.000Z' }),
      createTodo({ id: 'deadline', date: '2026-07-05', content: '截止', time: '09:00', now: '2026-07-05T08:00:00.000Z' }),
      createTodo({ id: 'inbox', date: '2026-07-05', content: '收集', now: '2026-07-05T08:00:00.000Z' })
    ];
    const rolled = rollUnfinishedTodos(toggleTodo(todos, 'done', true), '2026-07-05', '2026-07-06T00:00:00.000Z');

    expect(rolled.map((todo) => todo.id)).toEqual(['deadline', 'inbox']);
    expect(rolled.find((todo) => todo.id === 'deadline')).toMatchObject({ date: '2026-07-06', time: '' });
    expect(rolled.find((todo) => todo.id === 'inbox')).toMatchObject({ date: '2026-07-06', time: '' });
  });
});
