import { nowISODateTime } from './date';
import { createTodo } from './todos';
import type { ID, ISODate, ISODateTime, Scrap, ScrapCategory, Todo } from './types';

export interface CreateScrapInput {
  id: ID;
  category: ScrapCategory;
  content: string;
  today: ISODate;
  now?: ISODateTime;
  todoId?: ID;
}

export interface CreateScrapResult {
  scrap: Scrap;
  todo?: Todo;
}

export interface UpdateScrapInput {
  category: ScrapCategory;
  content: string;
  linkedTodoId?: ID;
  now?: ISODateTime;
}

export function createScrap(input: CreateScrapInput): CreateScrapResult {
  const timestamp = input.now ?? nowISODateTime();
  const trimmedContent = input.content.trim();
  const linkedTodoId = input.category === '待办' ? input.todoId : undefined;
  const scrap: Scrap = {
    id: input.id,
    category: input.category,
    content: trimmedContent,
    linkedTodoId,
    createdAt: timestamp,
    updatedAt: timestamp
  };

  if (input.category !== '待办' || !input.todoId) {
    return { scrap };
  }

  return {
    scrap,
    todo: createTodo({
      id: input.todoId,
      date: input.today,
      content: trimmedContent,
      sourceScrapId: input.id,
      now: timestamp
    })
  };
}

export function updateScrapCategory(
  scraps: Scrap[],
  id: ID,
  category: ScrapCategory,
  now = nowISODateTime()
): Scrap[] {
  return scraps.map((scrap) =>
    scrap.id === id
      ? {
          ...scrap,
          category,
          updatedAt: now
        }
      : scrap
  );
}

export function updateScrap(scraps: Scrap[], id: ID, input: UpdateScrapInput): Scrap[] {
  const timestamp = input.now ?? nowISODateTime();

  return scraps.map((scrap) =>
    scrap.id === id
      ? {
          ...scrap,
          category: input.category,
          content: input.content.trim(),
          linkedTodoId: input.linkedTodoId,
          updatedAt: timestamp
        }
      : scrap
  );
}

export function deleteScrap(scraps: Scrap[], id: ID): Scrap[] {
  return scraps.filter((scrap) => scrap.id !== id);
}

export function getScrapsByCategory(scraps: Scrap[], category?: ScrapCategory): Scrap[] {
  const filtered = category ? scraps.filter((scrap) => scrap.category === category) : scraps;

  return [...filtered].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}
