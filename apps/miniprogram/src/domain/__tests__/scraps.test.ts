import { describe, expect, it } from 'vitest';
import { createScrap, getScrapsByCategory } from '../scraps';

describe('scraps', () => {
  it('creates a linked today todo when category is 待办', () => {
    const result = createScrap({
      id: 'scrap-1',
      todoId: 'todo-1',
      category: '待办',
      content: '整理需求',
      today: '2026-07-05',
      now: '2026-07-05T08:00:00.000Z'
    });

    expect(result.scrap.linkedTodoId).toBe('todo-1');
    expect(result.todo).toMatchObject({
      id: 'todo-1',
      sourceScrapId: 'scrap-1',
      date: '2026-07-05',
      content: '整理需求'
    });
  });

  it('filters scraps by category with newest first', () => {
    const first = createScrap({
      id: 'first',
      category: '灵感',
      content: 'A',
      today: '2026-07-05',
      now: '2026-07-05T08:00:00.000Z'
    }).scrap;
    const second = createScrap({
      id: 'second',
      category: '灵感',
      content: 'B',
      today: '2026-07-05',
      now: '2026-07-05T09:00:00.000Z'
    }).scrap;

    expect(getScrapsByCategory([first, second], '灵感').map((scrap) => scrap.id)).toEqual(['second', 'first']);
  });
});
