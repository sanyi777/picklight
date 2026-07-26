import { addDays, nowISODateTime } from './date';
import type { ID, ISODate, ISODateTime, Todo } from './types';

export interface CreateTodoInput {
  id: ID;
  date: ISODate;
  content: string;
  time?: string;
  sourceScrapId?: ID;
  sourceHabitId?: ID;
  now?: ISODateTime;
}

export function createTodo(input: CreateTodoInput): Todo {
  const timestamp = input.now ?? nowISODateTime();

  return {
    id: input.id,
    date: input.date,
    time: input.time ?? '',
    content: input.content.trim(),
    completed: false,
    sourceScrapId: input.sourceScrapId,
    sourceHabitId: input.sourceHabitId,
    createdAt: timestamp,
    updatedAt: timestamp
  };
}

export function getTodosForDate(todos: Todo[], date: ISODate): Todo[] {
  return todos
    .filter((todo) => todo.date === date)
    .sort(compareTodos);
}

export function toggleTodo(todos: Todo[], id: ID, completed: boolean, now = nowISODateTime()): Todo[] {
  return todos.map((todo) =>
    todo.id === id
      ? {
          ...todo,
          completed,
          completedAt: completed ? now : undefined,
          updatedAt: now
        }
      : todo
  );
}

export function rollUnfinishedTodos(todos: Todo[], fromDate: ISODate, now = nowISODateTime()): Todo[] {
  const nextDate = addDays(fromDate, 1);

  return todos.flatMap((todo) => {
    if (todo.date !== fromDate) {
      return todo;
    }

    if (todo.completed) {
      return [];
    }

    if (todo.sourceHabitId) {
      return [];
    }

    return {
      ...todo,
      date: nextDate,
      time: '',
      rolledOverFrom: todo.rolledOverFrom ?? fromDate,
      updatedAt: now
    };
  });
}

export function getTodoStats(todos: Todo[], date: ISODate) {
  const dayTodos = getTodosForDate(todos, date);
  const completed = dayTodos.filter((todo) => todo.completed).length;

  return {
    total: dayTodos.length,
    completed,
    remaining: dayTodos.length - completed
  };
}

function compareTodoTime(a: string, b: string): number {
  if (!a && !b) {
    return 0;
  }

  if (!a) {
    return 1;
  }

  if (!b) {
    return -1;
  }

  return a.localeCompare(b);
}

function compareTodos(a: Todo, b: Todo): number {
  if (a.completed !== b.completed) {
    return a.completed ? 1 : -1;
  }

  if (a.completed && b.completed) {
    return (b.completedAt ?? b.updatedAt).localeCompare(a.completedAt ?? a.updatedAt);
  }

  const timeOrder = compareTodoTime(a.time, b.time);
  if (timeOrder !== 0) {
    return timeOrder;
  }

  return b.createdAt.localeCompare(a.createdAt);
}
