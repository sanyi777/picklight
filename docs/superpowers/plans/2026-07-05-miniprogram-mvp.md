# PickLight Mini Program MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first WeChat mini program MVP of 拾光, covering Home, Scraps, Schedule, Focus, local storage, and the core attention workflow defined in Phase 0.

**Architecture:** Use a uni-app + Vue 3 application with four tab pages and a small shared domain layer. Keep product rules in TypeScript utilities, keep persistence behind one storage adapter, and keep pages thin by moving reusable UI into focused components.

**Tech Stack:** uni-app, Vue 3, TypeScript, Pinia, Vitest, WeChat mini program local storage APIs through uni storage wrappers.

---

## Product Baseline

Source documents:

- `docs/phase0-product-definition.md`
- `demo-miniprogram.html`

First version scope:

- Four bottom tabs: `主页 / 零碎 / 日程 / 专注`
- Mini program only
- Local-first, no account, no cloud sync
- Max 2 daily anchors
- Anchor progress is manual
- Scraps require a category at input time
- Scrap category `待办` automatically enters today todo
- Schedule page review is archived to `零碎-复盘`
- Unfinished todos roll their original `date` forward to the next day
- Pomodoro has manual duration and a required small focus task

## File Structure

Create a new mini program app under:

```text
apps/miniprogram/
```

Recommended files:

```text
apps/miniprogram/package.json
apps/miniprogram/vite.config.ts
apps/miniprogram/tsconfig.json
apps/miniprogram/src/App.vue
apps/miniprogram/src/main.ts
apps/miniprogram/src/pages.json
apps/miniprogram/src/styles/tokens.scss
apps/miniprogram/src/styles/global.scss

apps/miniprogram/src/domain/types.ts
apps/miniprogram/src/domain/date.ts
apps/miniprogram/src/domain/todos.ts
apps/miniprogram/src/domain/scraps.ts
apps/miniprogram/src/domain/anchors.ts
apps/miniprogram/src/domain/focus.ts

apps/miniprogram/src/storage/keys.ts
apps/miniprogram/src/storage/localStore.ts
apps/miniprogram/src/stores/usePicklightStore.ts

apps/miniprogram/src/components/AppShell.vue
apps/miniprogram/src/components/TabBar.vue
apps/miniprogram/src/components/TodoItem.vue
apps/miniprogram/src/components/WeekStrip.vue
apps/miniprogram/src/components/AnchorCard.vue
apps/miniprogram/src/components/ScrapComposer.vue
apps/miniprogram/src/components/ScrapItem.vue
apps/miniprogram/src/components/PomodoroPanel.vue

apps/miniprogram/src/pages/home/index.vue
apps/miniprogram/src/pages/scraps/index.vue
apps/miniprogram/src/pages/schedule/index.vue
apps/miniprogram/src/pages/focus/index.vue

apps/miniprogram/src/domain/__tests__/todos.test.ts
apps/miniprogram/src/domain/__tests__/scraps.test.ts
apps/miniprogram/src/domain/__tests__/anchors.test.ts
apps/miniprogram/src/domain/__tests__/focus.test.ts
apps/miniprogram/src/stores/__tests__/usePicklightStore.test.ts
```

Boundaries:

- `domain/*`: pure functions, no Vue, no `uni`.
- `storage/*`: reads and writes local mini program state.
- `stores/*`: app state orchestration.
- `components/*`: reusable UI only.
- `pages/*`: page composition and navigation-level behavior.

## Data Model

Use these TypeScript types as the first version contract:

```ts
export type ID = string;
export type ISODate = string; // yyyy-MM-dd
export type ISODateTime = string;

export type ScrapCategory = '灵感' | '随想' | '待办' | '分心' | '复盘';

export interface Todo {
  id: ID;
  date: ISODate;
  time: string;
  content: string;
  completed: boolean;
  rolledOverFrom?: ISODate;
  sourceScrapId?: ID;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export interface Scrap {
  id: ID;
  category: ScrapCategory;
  content: string;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
  linkedTodoId?: ID;
}

export interface DailyAnchor {
  id: ID;
  date: ISODate;
  title: string;
  progress: number;
  isCurrent: boolean;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export interface FocusSession {
  id: ID;
  date: ISODate;
  anchorId?: ID;
  task: string;
  durationMinutes: number;
  startedAt?: ISODateTime;
  completedAt?: ISODateTime;
  completed: boolean;
  distractions: string[];
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export interface PicklightState {
  todos: Todo[];
  scraps: Scrap[];
  anchors: DailyAnchor[];
  focusSessions: FocusSession[];
  activeDate: ISODate;
}
```

## Task 1: Scaffold Mini Program App

**Files:**

- Create: `apps/miniprogram/package.json`
- Create: `apps/miniprogram/vite.config.ts`
- Create: `apps/miniprogram/tsconfig.json`
- Create: `apps/miniprogram/src/main.ts`
- Create: `apps/miniprogram/src/App.vue`
- Create: `apps/miniprogram/src/pages.json`

- [x] **Step 1: Create package manifest**

```json
{
  "name": "picklight-miniprogram",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev:mp-weixin": "uni -p mp-weixin",
    "build:mp-weixin": "uni build -p mp-weixin",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "@dcloudio/uni-app": "latest",
    "@dcloudio/uni-components": "latest",
    "@dcloudio/uni-h5": "latest",
    "@dcloudio/uni-mp-weixin": "latest",
    "pinia": "latest",
    "vue": "latest"
  },
  "devDependencies": {
    "@dcloudio/vite-plugin-uni": "latest",
    "@vue/test-utils": "latest",
    "sass": "latest",
    "typescript": "latest",
    "vite": "latest",
    "vitest": "latest",
    "vue-tsc": "latest"
  }
}
```

- [x] **Step 2: Add Vite config**

```ts
import { defineConfig } from 'vite';
import uni from '@dcloudio/vite-plugin-uni';

export default defineConfig({
  plugins: [uni()],
  test: {
    environment: 'jsdom',
    globals: true
  }
});
```

- [x] **Step 3: Add TypeScript config**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "moduleResolution": "Node",
    "strict": true,
    "jsx": "preserve",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "lib": ["ES2020", "DOM"],
    "types": ["vitest/globals"]
  },
  "include": ["src/**/*.ts", "src/**/*.vue"]
}
```

- [x] **Step 4: Add app entry**

```ts
import { createSSRApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import './styles/global.scss';

export function createApp() {
  const app = createSSRApp(App);
  app.use(createPinia());
  return { app };
}
```

- [x] **Step 5: Add root component**

```vue
<script setup lang="ts">
</script>

<template>
  <slot />
</template>
```

- [x] **Step 6: Add tab pages config**

```json
{
  "pages": [
    { "path": "pages/home/index", "style": { "navigationBarTitleText": "主页" } },
    { "path": "pages/scraps/index", "style": { "navigationBarTitleText": "零碎" } },
    { "path": "pages/schedule/index", "style": { "navigationBarTitleText": "日程" } },
    { "path": "pages/focus/index", "style": { "navigationBarTitleText": "专注" } }
  ],
  "tabBar": {
    "color": "#6f7b8a",
    "selectedColor": "#2f72b4",
    "backgroundColor": "#ffffff",
    "borderStyle": "black",
    "list": [
      { "pagePath": "pages/home/index", "text": "主页" },
      { "pagePath": "pages/scraps/index", "text": "零碎" },
      { "pagePath": "pages/schedule/index", "text": "日程" },
      { "pagePath": "pages/focus/index", "text": "专注" }
    ]
  }
}
```

- [x] **Step 7: Verify app scaffolding**

Run:

```bash
cd apps/miniprogram
npm install
npm run test
```

Expected: dependencies install; tests exit successfully once test files exist. If tests do not exist yet, Vitest may report no test files.

## Task 2: Define Domain Types and Date Helpers

**Files:**

- Create: `apps/miniprogram/src/domain/types.ts`
- Create: `apps/miniprogram/src/domain/date.ts`
- Test: `apps/miniprogram/src/domain/__tests__/todos.test.ts`

- [x] **Step 1: Add shared types**

```ts
export type ID = string;
export type ISODate = string;
export type ISODateTime = string;

export type ScrapCategory = '灵感' | '随想' | '待办' | '分心' | '复盘';

export interface Todo {
  id: ID;
  date: ISODate;
  time: string;
  content: string;
  completed: boolean;
  rolledOverFrom?: ISODate;
  sourceScrapId?: ID;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export interface Scrap {
  id: ID;
  category: ScrapCategory;
  content: string;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
  linkedTodoId?: ID;
}

export interface DailyAnchor {
  id: ID;
  date: ISODate;
  title: string;
  progress: number;
  isCurrent: boolean;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export interface FocusSession {
  id: ID;
  date: ISODate;
  anchorId?: ID;
  task: string;
  durationMinutes: number;
  startedAt?: ISODateTime;
  completedAt?: ISODateTime;
  completed: boolean;
  distractions: string[];
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export interface PicklightState {
  todos: Todo[];
  scraps: Scrap[];
  anchors: DailyAnchor[];
  focusSessions: FocusSession[];
  activeDate: ISODate;
}
```

- [x] **Step 2: Add deterministic date helpers**

```ts
import type { ISODate } from './types';

export function toISODate(date: Date): ISODate {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function addDays(date: ISODate, days: number): ISODate {
  const [year, month, day] = date.split('-').map(Number);
  const next = new Date(year, month - 1, day);
  next.setDate(next.getDate() + days);
  return toISODate(next);
}

export function nextSevenDays(date: ISODate): ISODate[] {
  return Array.from({ length: 7 }, (_, index) => addDays(date, index));
}
```

- [x] **Step 3: Write date helper tests**

```ts
import { describe, expect, it } from 'vitest';
import { addDays, nextSevenDays, toISODate } from '../date';

describe('date helpers', () => {
  it('formats local dates as yyyy-MM-dd', () => {
    expect(toISODate(new Date(2026, 6, 5))).toBe('2026-07-05');
  });

  it('adds days across month boundaries', () => {
    expect(addDays('2026-07-31', 1)).toBe('2026-08-01');
  });

  it('returns seven consecutive days', () => {
    expect(nextSevenDays('2026-07-05')).toEqual([
      '2026-07-05',
      '2026-07-06',
      '2026-07-07',
      '2026-07-08',
      '2026-07-09',
      '2026-07-10',
      '2026-07-11'
    ]);
  });
});
```

- [x] **Step 4: Run date tests**

Run:

```bash
cd apps/miniprogram
npm run test -- src/domain/__tests__/todos.test.ts
```

Expected: all date helper tests pass.

## Task 3: Implement Todo Rules

**Files:**

- Create: `apps/miniprogram/src/domain/todos.ts`
- Test: `apps/miniprogram/src/domain/__tests__/todos.test.ts`

- [x] **Step 1: Add todo tests**

```ts
import { describe, expect, it } from 'vitest';
import type { Todo } from '../types';
import { todosForDate, rollUnfinishedTodos, weekTodoCounts } from '../todos';

const baseTodo: Todo = {
  id: 'todo-1',
  date: '2026-07-05',
  time: '09:30',
  content: '写小程序 MVP 计划',
  completed: false,
  createdAt: '2026-07-05T09:00:00.000Z',
  updatedAt: '2026-07-05T09:00:00.000Z'
};

describe('todo rules', () => {
  it('filters todos by date', () => {
    expect(todosForDate([baseTodo], '2026-07-05')).toHaveLength(1);
    expect(todosForDate([baseTodo], '2026-07-06')).toHaveLength(0);
  });

  it('rolls unfinished old todos to active date without duplicating them', () => {
    const rolled = rollUnfinishedTodos([baseTodo], '2026-07-06', '2026-07-06T08:00:00.000Z');
    expect(rolled).toHaveLength(1);
    expect(rolled[0]).toMatchObject({
      id: 'todo-1',
      date: '2026-07-06',
      rolledOverFrom: '2026-07-05',
      completed: false
    });
  });

  it('does not roll completed todos', () => {
    const completed = { ...baseTodo, completed: true };
    const rolled = rollUnfinishedTodos([completed], '2026-07-06', '2026-07-06T08:00:00.000Z');
    expect(rolled[0].date).toBe('2026-07-05');
  });

  it('counts todos for a seven day strip', () => {
    expect(weekTodoCounts([baseTodo], '2026-07-05')).toEqual([
      { date: '2026-07-05', pending: 1, total: 1 },
      { date: '2026-07-06', pending: 0, total: 0 },
      { date: '2026-07-07', pending: 0, total: 0 },
      { date: '2026-07-08', pending: 0, total: 0 },
      { date: '2026-07-09', pending: 0, total: 0 },
      { date: '2026-07-10', pending: 0, total: 0 },
      { date: '2026-07-11', pending: 0, total: 0 }
    ]);
  });
});
```

- [x] **Step 2: Implement todo rules**

```ts
import { nextSevenDays } from './date';
import type { ISODate, ISODateTime, Todo } from './types';

export function todosForDate(todos: Todo[], date: ISODate): Todo[] {
  return todos
    .filter((todo) => todo.date === date)
    .sort((a, b) => a.time.localeCompare(b.time));
}

export function rollUnfinishedTodos(
  todos: Todo[],
  activeDate: ISODate,
  now: ISODateTime
): Todo[] {
  return todos.map((todo) => {
    if (todo.completed || todo.date >= activeDate) {
      return todo;
    }

    return {
      ...todo,
      date: activeDate,
      rolledOverFrom: todo.rolledOverFrom ?? todo.date,
      updatedAt: now
    };
  });
}

export function weekTodoCounts(todos: Todo[], startDate: ISODate) {
  return nextSevenDays(startDate).map((date) => {
    const dayTodos = todos.filter((todo) => todo.date === date);
    return {
      date,
      pending: dayTodos.filter((todo) => !todo.completed).length,
      total: dayTodos.length
    };
  });
}
```

- [x] **Step 3: Run todo tests**

Run:

```bash
cd apps/miniprogram
npm run test -- src/domain/__tests__/todos.test.ts
```

Expected: all todo rule tests pass.

## Task 4: Implement Scrap Rules

**Files:**

- Create: `apps/miniprogram/src/domain/scraps.ts`
- Test: `apps/miniprogram/src/domain/__tests__/scraps.test.ts`

- [x] **Step 1: Add scrap tests**

```ts
import { describe, expect, it } from 'vitest';
import { createScrap, todoFromScrap } from '../scraps';

describe('scrap rules', () => {
  it('creates a categorized scrap', () => {
    const scrap = createScrap({
      id: 'scrap-1',
      category: '灵感',
      content: '把主页做成今日状态入口',
      now: '2026-07-05T10:00:00.000Z'
    });

    expect(scrap).toMatchObject({
      id: 'scrap-1',
      category: '灵感',
      content: '把主页做成今日状态入口'
    });
  });

  it('turns 待办 scraps into today todos', () => {
    const scrap = createScrap({
      id: 'scrap-2',
      category: '待办',
      content: '整理周视图字段',
      now: '2026-07-05T10:00:00.000Z'
    });

    const todo = todoFromScrap(scrap, {
      id: 'todo-1',
      date: '2026-07-05',
      now: '2026-07-05T10:00:00.000Z'
    });

    expect(todo).toMatchObject({
      id: 'todo-1',
      date: '2026-07-05',
      time: '待定',
      content: '整理周视图字段',
      completed: false,
      sourceScrapId: 'scrap-2'
    });
  });
});
```

- [x] **Step 2: Implement scrap rules**

```ts
import type { ID, ISODate, ISODateTime, Scrap, ScrapCategory, Todo } from './types';

export function createScrap(input: {
  id: ID;
  category: ScrapCategory;
  content: string;
  now: ISODateTime;
}): Scrap {
  return {
    id: input.id,
    category: input.category,
    content: input.content.trim(),
    createdAt: input.now,
    updatedAt: input.now
  };
}

export function todoFromScrap(
  scrap: Scrap,
  input: { id: ID; date: ISODate; now: ISODateTime }
): Todo {
  return {
    id: input.id,
    date: input.date,
    time: '待定',
    content: scrap.content,
    completed: false,
    sourceScrapId: scrap.id,
    createdAt: input.now,
    updatedAt: input.now
  };
}
```

- [x] **Step 3: Run scrap tests**

Run:

```bash
cd apps/miniprogram
npm run test -- src/domain/__tests__/scraps.test.ts
```

Expected: scrap creation and 待办 conversion tests pass.

## Task 5: Implement Anchor Rules

**Files:**

- Create: `apps/miniprogram/src/domain/anchors.ts`
- Test: `apps/miniprogram/src/domain/__tests__/anchors.test.ts`

- [x] **Step 1: Add anchor tests**

```ts
import { describe, expect, it } from 'vitest';
import type { DailyAnchor } from '../types';
import { addAnchor, setAnchorProgress, setCurrentAnchor } from '../anchors';

const anchor: DailyAnchor = {
  id: 'anchor-1',
  date: '2026-07-05',
  title: '完成小程序 MVP 计划',
  progress: 20,
  isCurrent: true,
  createdAt: '2026-07-05T10:00:00.000Z',
  updatedAt: '2026-07-05T10:00:00.000Z'
};

describe('anchor rules', () => {
  it('allows at most two anchors for one day', () => {
    const anchors = [anchor, { ...anchor, id: 'anchor-2', isCurrent: false }];
    expect(() =>
      addAnchor(anchors, {
        id: 'anchor-3',
        date: '2026-07-05',
        title: '第三个锚点',
        now: '2026-07-05T10:00:00.000Z'
      })
    ).toThrow('当日主锚点最多 2 个');
  });

  it('clamps progress between 0 and 100', () => {
    const updated = setAnchorProgress([anchor], 'anchor-1', 130, '2026-07-05T11:00:00.000Z');
    expect(updated[0].progress).toBe(100);
  });

  it('sets only one current anchor', () => {
    const anchors = [anchor, { ...anchor, id: 'anchor-2', isCurrent: false }];
    const updated = setCurrentAnchor(anchors, 'anchor-2', '2026-07-05T11:00:00.000Z');
    expect(updated.find((item) => item.id === 'anchor-1')?.isCurrent).toBe(false);
    expect(updated.find((item) => item.id === 'anchor-2')?.isCurrent).toBe(true);
  });
});
```

- [x] **Step 2: Implement anchor rules**

```ts
import type { DailyAnchor, ID, ISODate, ISODateTime } from './types';

export function addAnchor(
  anchors: DailyAnchor[],
  input: { id: ID; date: ISODate; title: string; now: ISODateTime }
): DailyAnchor[] {
  const sameDayCount = anchors.filter((anchor) => anchor.date === input.date).length;
  if (sameDayCount >= 2) {
    throw new Error('当日主锚点最多 2 个');
  }

  return [
    ...anchors,
    {
      id: input.id,
      date: input.date,
      title: input.title.trim(),
      progress: 0,
      isCurrent: sameDayCount === 0,
      createdAt: input.now,
      updatedAt: input.now
    }
  ];
}

export function setAnchorProgress(
  anchors: DailyAnchor[],
  anchorId: ID,
  progress: number,
  now: ISODateTime
): DailyAnchor[] {
  const clamped = Math.max(0, Math.min(100, Math.round(progress)));
  return anchors.map((anchor) =>
    anchor.id === anchorId ? { ...anchor, progress: clamped, updatedAt: now } : anchor
  );
}

export function setCurrentAnchor(
  anchors: DailyAnchor[],
  anchorId: ID,
  now: ISODateTime
): DailyAnchor[] {
  return anchors.map((anchor) => ({
    ...anchor,
    isCurrent: anchor.id === anchorId,
    updatedAt: anchor.id === anchorId ? now : anchor.updatedAt
  }));
}
```

- [x] **Step 3: Run anchor tests**

Run:

```bash
cd apps/miniprogram
npm run test -- src/domain/__tests__/anchors.test.ts
```

Expected: anchor count, progress, and current-anchor tests pass.

## Task 6: Implement Focus Rules

**Files:**

- Create: `apps/miniprogram/src/domain/focus.ts`
- Test: `apps/miniprogram/src/domain/__tests__/focus.test.ts`

- [x] **Step 1: Add focus tests**

```ts
import { describe, expect, it } from 'vitest';
import { addDistraction, completeFocusSession, createFocusSession } from '../focus';

describe('focus rules', () => {
  it('requires a small focus task', () => {
    expect(() =>
      createFocusSession({
        id: 'focus-1',
        date: '2026-07-05',
        task: ' ',
        durationMinutes: 25,
        now: '2026-07-05T10:00:00.000Z'
      })
    ).toThrow('本轮专注需要填写一件小事');
  });

  it('creates a focus session with manual duration', () => {
    const session = createFocusSession({
      id: 'focus-1',
      date: '2026-07-05',
      task: '写数据模型',
      durationMinutes: 35,
      now: '2026-07-05T10:00:00.000Z'
    });

    expect(session.durationMinutes).toBe(35);
    expect(session.completed).toBe(false);
  });

  it('records distractions without completing the session', () => {
    const session = createFocusSession({
      id: 'focus-1',
      date: '2026-07-05',
      task: '写数据模型',
      durationMinutes: 25,
      now: '2026-07-05T10:00:00.000Z'
    });

    const updated = addDistraction(session, '想看配色', '2026-07-05T10:05:00.000Z');
    expect(updated.distractions).toEqual(['想看配色']);
    expect(updated.completed).toBe(false);
  });

  it('completes focus session', () => {
    const session = createFocusSession({
      id: 'focus-1',
      date: '2026-07-05',
      task: '写数据模型',
      durationMinutes: 25,
      now: '2026-07-05T10:00:00.000Z'
    });

    const completed = completeFocusSession(session, '2026-07-05T10:25:00.000Z');
    expect(completed.completed).toBe(true);
    expect(completed.completedAt).toBe('2026-07-05T10:25:00.000Z');
  });
});
```

- [x] **Step 2: Implement focus rules**

```ts
import type { FocusSession, ID, ISODate, ISODateTime } from './types';

export function createFocusSession(input: {
  id: ID;
  date: ISODate;
  anchorId?: ID;
  task: string;
  durationMinutes: number;
  now: ISODateTime;
}): FocusSession {
  const task = input.task.trim();
  if (!task) {
    throw new Error('本轮专注需要填写一件小事');
  }

  return {
    id: input.id,
    date: input.date,
    anchorId: input.anchorId,
    task,
    durationMinutes: Math.max(1, Math.round(input.durationMinutes)),
    startedAt: input.now,
    completed: false,
    distractions: [],
    createdAt: input.now,
    updatedAt: input.now
  };
}

export function addDistraction(
  session: FocusSession,
  text: string,
  now: ISODateTime
): FocusSession {
  const trimmed = text.trim();
  if (!trimmed) {
    return session;
  }

  return {
    ...session,
    distractions: [trimmed, ...session.distractions],
    updatedAt: now
  };
}

export function completeFocusSession(session: FocusSession, now: ISODateTime): FocusSession {
  return {
    ...session,
    completed: true,
    completedAt: now,
    updatedAt: now
  };
}
```

- [x] **Step 3: Run focus tests**

Run:

```bash
cd apps/miniprogram
npm run test -- src/domain/__tests__/focus.test.ts
```

Expected: focus tests pass.

## Task 7: Build Local Storage Adapter

**Files:**

- Create: `apps/miniprogram/src/storage/keys.ts`
- Create: `apps/miniprogram/src/storage/localStore.ts`
- Test: `apps/miniprogram/src/stores/__tests__/usePicklightStore.test.ts`

- [x] **Step 1: Add storage keys**

```ts
export const PICKLIGHT_STATE_KEY = 'picklight:miniprogram:v1';
```

- [x] **Step 2: Add storage adapter**

```ts
import type { PicklightState } from '../domain/types';
import { PICKLIGHT_STATE_KEY } from './keys';

export function loadState(fallback: PicklightState): PicklightState {
  try {
    const value = uni.getStorageSync(PICKLIGHT_STATE_KEY);
    if (!value) {
      return fallback;
    }
    return JSON.parse(value) as PicklightState;
  } catch {
    return fallback;
  }
}

export function saveState(state: PicklightState): void {
  uni.setStorageSync(PICKLIGHT_STATE_KEY, JSON.stringify(state));
}
```

- [x] **Step 3: Test strategy**

Do not unit test `uni` directly in this task. The store task will mock `loadState` and `saveState`. Manual mini program testing will verify storage works in the simulator.

## Task 8: Build Pinia Store

**Files:**

- Create: `apps/miniprogram/src/stores/usePicklightStore.ts`
- Test: `apps/miniprogram/src/stores/__tests__/usePicklightStore.test.ts`

- [x] **Step 1: Add store tests**

```ts
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { createPinia, setActivePinia } from 'pinia';
import { usePicklightStore } from '../usePicklightStore';

vi.mock('../../storage/localStore', () => ({
  loadState: vi.fn((fallback) => fallback),
  saveState: vi.fn()
}));

describe('usePicklightStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it('adds 待办 scrap and creates today todo', () => {
    const store = usePicklightStore();
    store.setActiveDate('2026-07-05');
    store.addScrap('待办', '补齐小程序数据模型');

    expect(store.scraps).toHaveLength(1);
    expect(store.todos).toHaveLength(1);
    expect(store.todos[0].content).toBe('补齐小程序数据模型');
  });

  it('archives schedule review to 复盘 scraps', () => {
    const store = usePicklightStore();
    store.addReview('今天需要把页面交互收住');

    expect(store.scraps[0]).toMatchObject({
      category: '复盘',
      content: '今天需要把页面交互收住'
    });
  });
});
```

- [x] **Step 2: Add store implementation**

```ts
import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import { toISODate } from '../domain/date';
import { addAnchor, setAnchorProgress, setCurrentAnchor } from '../domain/anchors';
import { createFocusSession, addDistraction, completeFocusSession } from '../domain/focus';
import { createScrap, todoFromScrap } from '../domain/scraps';
import { rollUnfinishedTodos, todosForDate, weekTodoCounts } from '../domain/todos';
import type { DailyAnchor, FocusSession, PicklightState, Scrap, ScrapCategory, Todo } from '../domain/types';
import { loadState, saveState } from '../storage/localStore';

function nowISO() {
  return new Date().toISOString();
}

function newId(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function emptyState(): PicklightState {
  return {
    todos: [],
    scraps: [],
    anchors: [],
    focusSessions: [],
    activeDate: toISODate(new Date())
  };
}

export const usePicklightStore = defineStore('picklight', () => {
  const initial = loadState(emptyState());
  const todos = ref<Todo[]>(initial.todos);
  const scraps = ref<Scrap[]>(initial.scraps);
  const anchors = ref<DailyAnchor[]>(initial.anchors);
  const focusSessions = ref<FocusSession[]>(initial.focusSessions);
  const activeDate = ref(initial.activeDate);

  function persist() {
    saveState({
      todos: todos.value,
      scraps: scraps.value,
      anchors: anchors.value,
      focusSessions: focusSessions.value,
      activeDate: activeDate.value
    });
  }

  function setActiveDate(date: string) {
    activeDate.value = date;
    todos.value = rollUnfinishedTodos(todos.value, date, nowISO());
    persist();
  }

  function addScrap(category: ScrapCategory, content: string) {
    const now = nowISO();
    const scrap = createScrap({ id: newId('scrap'), category, content, now });
    scraps.value = [scrap, ...scraps.value];
    if (category === '待办') {
      const todo = todoFromScrap(scrap, { id: newId('todo'), date: activeDate.value, now });
      todos.value = [todo, ...todos.value];
      scrap.linkedTodoId = todo.id;
    }
    persist();
  }

  function addReview(content: string) {
    addScrap('复盘', content);
  }

  function addTodo(content: string, time = '待定') {
    const now = nowISO();
    todos.value = [
      {
        id: newId('todo'),
        date: activeDate.value,
        time,
        content: content.trim(),
        completed: false,
        createdAt: now,
        updatedAt: now
      },
      ...todos.value
    ];
    persist();
  }

  function toggleTodo(todoId: string) {
    const now = nowISO();
    todos.value = todos.value.map((todo) =>
      todo.id === todoId ? { ...todo, completed: !todo.completed, updatedAt: now } : todo
    );
    persist();
  }

  function addDailyAnchor(title: string) {
    anchors.value = addAnchor(anchors.value, {
      id: newId('anchor'),
      date: activeDate.value,
      title,
      now: nowISO()
    });
    persist();
  }

  function updateAnchorProgress(anchorId: string, progress: number) {
    anchors.value = setAnchorProgress(anchors.value, anchorId, progress, nowISO());
    persist();
  }

  function chooseCurrentAnchor(anchorId: string) {
    anchors.value = setCurrentAnchor(anchors.value, anchorId, nowISO());
    persist();
  }

  function startFocusSession(input: { task: string; durationMinutes: number; anchorId?: string }) {
    const session = createFocusSession({
      id: newId('focus'),
      date: activeDate.value,
      anchorId: input.anchorId,
      task: input.task,
      durationMinutes: input.durationMinutes,
      now: nowISO()
    });
    focusSessions.value = [session, ...focusSessions.value];
    persist();
    return session.id;
  }

  function recordDistraction(sessionId: string, text: string) {
    focusSessions.value = focusSessions.value.map((session) =>
      session.id === sessionId ? addDistraction(session, text, nowISO()) : session
    );
    addScrap('分心', text);
    persist();
  }

  function finishFocusSession(sessionId: string) {
    focusSessions.value = focusSessions.value.map((session) =>
      session.id === sessionId ? completeFocusSession(session, nowISO()) : session
    );
    persist();
  }

  const todayTodos = computed(() => todosForDate(todos.value, activeDate.value));
  const weekCounts = computed(() => weekTodoCounts(todos.value, activeDate.value));
  const todayAnchors = computed(() => anchors.value.filter((anchor) => anchor.date === activeDate.value));
  const currentAnchor = computed(() => todayAnchors.value.find((anchor) => anchor.isCurrent));

  return {
    todos,
    scraps,
    anchors,
    focusSessions,
    activeDate,
    todayTodos,
    weekCounts,
    todayAnchors,
    currentAnchor,
    setActiveDate,
    addScrap,
    addReview,
    addTodo,
    toggleTodo,
    addDailyAnchor,
    updateAnchorProgress,
    chooseCurrentAnchor,
    startFocusSession,
    recordDistraction,
    finishFocusSession
  };
});
```

- [x] **Step 3: Run store tests**

Run:

```bash
cd apps/miniprogram
npm run test -- src/stores/__tests__/usePicklightStore.test.ts
```

Expected: store tests pass.

## Task 9: Build Shared UI Components

**Files:**

- Create: `apps/miniprogram/src/components/TodoItem.vue`
- Create: `apps/miniprogram/src/components/WeekStrip.vue`
- Create: `apps/miniprogram/src/components/AnchorCard.vue`
- Create: `apps/miniprogram/src/components/ScrapComposer.vue`
- Create: `apps/miniprogram/src/components/ScrapItem.vue`
- Create: `apps/miniprogram/src/components/PomodoroPanel.vue`
- Create: `apps/miniprogram/src/styles/tokens.scss`
- Create: `apps/miniprogram/src/styles/global.scss`

- [x] **Step 1: Add style tokens**

```scss
$ink: #202733;
$muted: #6f7b8a;
$line: #dce4ec;
$wash: #f5f8fb;
$card: #ffffff;
$blue: #4a90d9;
$blue-deep: #2f72b4;
$green: #19a99a;
$yellow: #df9c2f;
```

- [x] **Step 2: Add global styles**

```scss
@import './tokens.scss';

page {
  min-height: 100%;
  background: $wash;
  color: $ink;
  font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif;
}

.page {
  min-height: 100vh;
  padding: 24rpx;
  box-sizing: border-box;
}

.card {
  border: 1rpx solid $line;
  border-radius: 16rpx;
  background: $card;
  box-shadow: 0 12rpx 32rpx rgba(42, 63, 88, 0.08);
}

.muted {
  color: $muted;
}
```

- [x] **Step 3: Add component contracts**

Keep each component controlled by props and emits. Do not let components read or write global store directly.

Example `TodoItem.vue`:

```vue
<script setup lang="ts">
import type { Todo } from '../domain/types';

defineProps<{ todo: Todo }>();
const emit = defineEmits<{ toggle: [todoId: string] }>();
</script>

<template>
  <view class="todo-item" :class="{ done: todo.completed }">
    <text class="time">{{ todo.time }}</text>
    <text class="content">{{ todo.content }}</text>
    <button class="check" @tap="emit('toggle', todo.id)">
      {{ todo.completed ? '✓' : '' }}
    </button>
  </view>
</template>

<style scoped lang="scss">
.todo-item {
  display: grid;
  grid-template-columns: 92rpx 1fr 56rpx;
  gap: 12rpx;
  align-items: center;
  padding: 16rpx;
  border-radius: 16rpx;
  background: #fbfdff;
}
.time {
  color: #2f72b4;
  font-size: 24rpx;
  font-weight: 700;
}
.content {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 28rpx;
}
.check {
  width: 44rpx;
  height: 44rpx;
  border-radius: 50%;
  padding: 0;
  line-height: 44rpx;
}
.done .content {
  color: #6f7b8a;
  text-decoration: line-through;
}
```

- [ ] **Step 4: Manual component review**

Open each component in the mini program simulator after pages use them. Confirm text does not overflow buttons and tap targets remain usable.

## Task 10: Build Home Page

**Files:**

- Create: `apps/miniprogram/src/pages/home/index.vue`

- [x] **Step 1: Implement Home page**

```vue
<script setup lang="ts">
import { ref } from 'vue';
import TodoItem from '../../components/TodoItem.vue';
import { usePicklightStore } from '../../stores/usePicklightStore';

const store = usePicklightStore();
const quickText = ref('');
const quickCategory = ref<'灵感' | '随想' | '待办' | '分心' | '复盘'>('随想');

function submitQuickScrap() {
  const text = quickText.value.trim();
  if (!text) return;
  store.addScrap(quickCategory.value, text);
  quickText.value = '';
}

function startQuickFocus() {
  uni.switchTab({ url: '/pages/focus/index' });
}
</script>

<template>
  <view class="page home">
    <view class="card hero">
      <text class="eyebrow">当前锚点</text>
      <text class="anchor">{{ store.currentAnchor?.title || '还没有设置主锚点' }}</text>
      <button class="primary" @tap="startQuickFocus">开启番茄钟</button>
    </view>

    <view class="card section">
      <text class="title">今日待办</text>
      <TodoItem
        v-for="todo in store.todayTodos"
        :key="todo.id"
        :todo="todo"
        @toggle="store.toggleTodo"
      />
      <text v-if="store.todayTodos.length === 0" class="empty">今天还没有待办</text>
    </view>

    <view class="card section">
      <text class="title">快速捕捉</text>
      <textarea v-model="quickText" class="quick-input" placeholder="记录一个念头" />
      <picker
        :range="['灵感', '随想', '待办', '分心', '复盘']"
        @change="quickCategory = ['灵感', '随想', '待办', '分心', '复盘'][Number($event.detail.value)]"
      >
        <view class="picker">分类：{{ quickCategory }}</view>
      </picker>
      <button class="secondary" @tap="submitQuickScrap">收纳</button>
    </view>
  </view>
</template>
```

- [ ] **Step 2: Manual Home acceptance**

Checklist:

- Home shows current anchor if one exists.
- Home shows today todos.
- Quick capture category `待办` creates a today todo.
- Quick focus navigates to Focus tab.

## Task 11: Build Scraps Page

**Files:**

- Create: `apps/miniprogram/src/pages/scraps/index.vue`

- [x] **Step 1: Implement Scraps page**

Use store `scraps`, `addScrap`, and category filtering. The page must include:

- category picker
- textarea input
- filter row: 全部 / 灵感 / 随想 / 待办 / 分心 / 复盘
- list of scraps sorted by creation order from store

- [ ] **Step 2: Manual Scraps acceptance**

Checklist:

- Input requires non-empty text.
- User chooses a category before save.
- Saved scraps appear at top.
- Category filter hides unrelated scraps.
- Category `待办` creates a todo visible on Home and Schedule.

## Task 12: Build Schedule Page

**Files:**

- Create: `apps/miniprogram/src/pages/schedule/index.vue`

- [x] **Step 1: Implement Schedule page**

The page must include:

- today todo list
- add todo form with `time` and `content`
- max two daily anchors
- manual anchor progress sliders
- future 7 day strip with pending counts
- daily review input that calls `store.addReview`

- [ ] **Step 2: Manual Schedule acceptance**

Checklist:

- Add todo creates item for selected day.
- Toggle completion updates Home and Schedule.
- Add anchor stops at 2 anchors.
- Slider updates anchor progress.
- Review input creates a `复盘` scrap.

## Task 13: Build Focus Page

**Files:**

- Create: `apps/miniprogram/src/pages/focus/index.vue`

- [x] **Step 1: Implement Focus page**

The page must include:

- daily anchor list
- manual progress sliders
- add/edit/delete anchor controls
- focus setup with required small task
- manual duration input or preset buttons
- countdown while page stays in foreground
- distraction input that records a `分心` scrap

- [ ] **Step 2: Manual Focus acceptance**

Checklist:

- Cannot start without a small task.
- Can set 15 / 25 / 45 minute duration and a custom duration.
- Start, pause, reset work in foreground.
- Distraction creates a `分心` scrap.
- Completed focus session is stored.

## Task 14: Demo Parity Review

**Files:**

- Read: `demo-miniprogram.html`
- Read: `docs/phase0-product-definition.md`

- [ ] **Step 1: Compare tab coverage**

Confirm the app includes:

- 主页
- 零碎
- 日程
- 专注

- [ ] **Step 2: Compare interaction coverage**

Confirm the app implements:

- categorized scrap input
- scrap `待办` to today todo
- review to `零碎-复盘`
- max two daily anchors
- manual anchor progress
- pomodoro manual duration
- focus small task
- distraction record
- seven-day todo view

- [x] **Step 3: Run full checks**

Run:

```bash
cd apps/miniprogram
npm run test
npm run build:mp-weixin
```

Expected:

- Unit tests pass.
- WeChat mini program build completes.

## Task 15: Update Project Documentation

**Files:**

- Modify: `docs/phase0-product-definition.md`
- Create: `docs/miniprogram-mvp-acceptance.md`

- [ ] **Step 1: Add acceptance checklist document**

```md
# 拾光小程序 MVP 验收清单

## 主页

- [ ] 展示今日待办
- [ ] 展示当前主锚点
- [ ] 可快速捕捉零碎
- [ ] 可快速进入番茄钟

## 零碎

- [ ] 输入时选择分类
- [ ] 支持灵感、随想、待办、分心、复盘
- [ ] 待办自动进入今日待办
- [ ] 可按分类筛选

## 日程

- [ ] 管理今日待办
- [ ] 可查看未来 7 天
- [ ] 未完成待办滚动到下一天
- [ ] 当日复盘归档到零碎-复盘

## 专注

- [ ] 最多 2 个主锚点
- [ ] 主锚点进度手动调整
- [ ] 番茄钟可设置时间
- [ ] 每轮番茄钟必须填写小事
- [ ] 分心记录归档到零碎-分心
```

- [ ] **Step 2: Commit documentation**

```bash
git add docs/phase0-product-definition.md docs/miniprogram-mvp-acceptance.md docs/superpowers/plans/2026-07-05-miniprogram-mvp.md
git commit -m "docs: plan mini program MVP"
```

Expected: documentation commit created.

## Self-Review

Spec coverage:

- Four tabs are covered by Tasks 10 through 13.
- Core data model is covered by Tasks 2 through 8.
- Local storage is covered by Task 7.
- Demo parity is covered by Task 14.
- Documentation is covered by Task 15.

Placeholder scan:

- No `TBD`, `TODO`, or "implement later" placeholders remain.
- Tasks that require code include exact file paths and code snippets where useful.

Type consistency:

- `Todo`, `Scrap`, `DailyAnchor`, `FocusSession`, and `PicklightState` are defined once in `types.ts`.
- Domain, store, and page tasks refer to the same field names.

Known execution notes:

- The first implementation pass should keep timer behavior foreground-only.
- Mini program background timer behavior is an explicit open question in Phase 0 and should not block MVP.
- PC / Windows work is excluded from this plan.

