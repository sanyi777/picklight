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

    expect(rolledTodos).toHaveLength(2);
    expect(rolledTodos.find((todo) => todo.id === 'a')).toMatchObject({
      date: '2026-07-06',
      rolledOverFrom: '2026-07-05'
    });
    expect(rolledTodos.find((todo) => todo.id === 'b')).toMatchObject({
      date: '2026-07-05',
      completed: true
    });
  });
});
