import { addDays, nowISODateTime } from './date';
import type { ID, ISODate, ISODateTime, Todo } from './types';

export interface CreateTodoInput {
  id: ID;
  date: ISODate;
  content: string;
  time?: string;
  sourceScrapId?: ID;
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
    createdAt: timestamp,
    updatedAt: timestamp
  };
}

export function getTodosForDate(todos: Todo[], date: ISODate): Todo[] {
  return todos
    .filter((todo) => todo.date === date)
    .sort((a, b) => compareTodoTime(a.time, b.time));
}

export function toggleTodo(todos: Todo[], id: ID, completed: boolean, now = nowISODateTime()): Todo[] {
  return todos.map((todo) =>
    todo.id === id
      ? {
          ...todo,
          completed,
          updatedAt: now
        }
      : todo
  );
}

export function rollUnfinishedTodos(todos: Todo[], fromDate: ISODate, now = nowISODateTime()): Todo[] {
  const nextDate = addDays(fromDate, 1);

  return todos.map((todo) => {
    if (todo.date !== fromDate || todo.completed) {
      return todo;
    }

    return {
      ...todo,
      date: nextDate,
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
