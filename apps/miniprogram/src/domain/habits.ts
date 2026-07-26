import { addDays, nowISODateTime, parseISODate } from './date';
import { createTodo } from './todos';
import type { Habit, HabitWeekday, ID, ISODate, ISODateTime, Todo } from './types';

export interface CreateHabitInput {
  id: ID;
  content: string;
  time?: string;
  weekdays: HabitWeekday[];
  now?: ISODateTime;
}

export interface SyncHabitTodosInput {
  todos: Todo[];
  habits: Habit[];
  fromDate: ISODate;
  createId: (habitId: ID, date: ISODate) => ID;
  now?: ISODateTime;
}

export function createHabit(input: CreateHabitInput): Habit {
  const timestamp = input.now ?? nowISODateTime();
  const content = input.content.trim();
  const weekdays = [...new Set(input.weekdays)].sort((a, b) => a - b);

  if (!content) {
    throw new Error('请填写习惯内容');
  }
  if (!weekdays.length) {
    throw new Error('请至少选择一天');
  }
  if (weekdays.some((day) => day < 1 || day > 7)) {
    throw new Error('重复日期不正确');
  }
  if (input.time && !/^([01]\d|2[0-3]):[0-5]\d$/.test(input.time)) {
    throw new Error('固定时间格式不正确');
  }

  return {
    id: input.id,
    content,
    time: input.time ?? '',
    weekdays,
    createdAt: timestamp,
    updatedAt: timestamp
  };
}

export function syncHabitTodos(input: SyncHabitTodosInput): Todo[] {
  const timestamp = input.now ?? nowISODateTime();
  const dates = Array.from({ length: 7 }, (_, index) => addDays(input.fromDate, index));
  const desired = input.habits.flatMap((habit) =>
    dates.filter((date) => habit.weekdays.includes(getWeekday(date))).map((date) => ({ habit, date }))
  );
  const desiredKeys = new Set(desired.map(({ habit, date }) => habitTodoKey(habit.id, date)));
  const existingByKey = new Map<string, Todo>();
  input.todos.forEach((todo) => {
    if (!todo.sourceHabitId) return;
    const key = habitTodoKey(todo.sourceHabitId, todo.date);
    if (!desiredKeys.has(key)) return;

    const current = existingByKey.get(key);
    if (
      !current ||
      (todo.completed && !current.completed) ||
      (todo.completed === current.completed && todo.updatedAt > current.updatedAt)
    ) {
      existingByKey.set(key, todo);
    }
  });
  const generated = desired.map(({ habit, date }) => {
    const existing = existingByKey.get(habitTodoKey(habit.id, date));
    if (existing) {
      const changed = existing.content !== habit.content || existing.time !== habit.time;
      return {
        ...existing,
        content: habit.content,
        time: habit.time,
        updatedAt: changed ? timestamp : existing.updatedAt
      };
    }

    return createTodo({
        id: input.createId(habit.id, date),
        date,
        content: habit.content,
        time: habit.time,
        now: timestamp,
        sourceHabitId: habit.id
      });
  });

  return [...input.todos.filter((todo) => !todo.sourceHabitId), ...generated];
}

function getWeekday(date: ISODate): HabitWeekday {
  const day = parseISODate(date).getDay();
  return (day === 0 ? 7 : day) as HabitWeekday;
}

function habitTodoKey(habitId: ID, date: ISODate): string {
  return `${habitId}:${date}`;
}
