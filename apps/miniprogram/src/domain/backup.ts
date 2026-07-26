import { nowISODateTime, todayISODate } from './date';
import type { PicklightBackup, PicklightState } from './types';

export const PICKLIGHT_BACKUP_SCHEMA_VERSION = 3;

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

function isHabit(value: unknown): value is PicklightState['habits'][number] {
  if (!isRecord(value)) {
    return false;
  }

  return (
    typeof value.id === 'string' &&
    typeof value.content === 'string' &&
    typeof value.time === 'string' &&
    Array.isArray(value.weekdays) &&
    value.weekdays.length > 0 &&
    value.weekdays.every(
      (day) => typeof day === 'number' && Number.isInteger(day) && day >= 1 && day <= 7
    ) &&
    typeof value.createdAt === 'string' &&
    typeof value.updatedAt === 'string'
  );
}

function parsePicklightState(value: unknown, requireHabits: boolean): PicklightState | undefined {
  if (!isRecord(value)) {
    return undefined;
  }

  const habits = value.habits;
  if (
    !Array.isArray(value.todos) ||
    !Array.isArray(value.scraps) ||
    !Array.isArray(value.anchors) ||
    !Array.isArray(value.focusSessions) ||
    (requireHabits && !Array.isArray(value.habits)) ||
    typeof value.activeDate !== 'string'
  ) {
    return undefined;
  }
  if (habits !== undefined && (!Array.isArray(habits) || !habits.every(isHabit))) {
    return undefined;
  }

  return {
    todos: value.todos as PicklightState['todos'],
    scraps: value.scraps as PicklightState['scraps'],
    anchors: value.anchors as PicklightState['anchors'],
    focusSessions: value.focusSessions as PicklightState['focusSessions'],
    habits: Array.isArray(habits) ? habits : [],
    activeDate: value.activeDate
  };
}

export function createPicklightBackup(state: PicklightState): PicklightBackup {
  return {
    app: 'picklight',
    schemaVersion: PICKLIGHT_BACKUP_SCHEMA_VERSION,
    exportedAt: nowISODateTime(),
    state
  };
}

export function serializePicklightBackup(state: PicklightState): string {
  return JSON.stringify(createPicklightBackup(state), null, 2);
}

export function parsePicklightBackup(raw: string): PicklightBackup {
  let parsed: unknown;

  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error('备份内容不是有效的 JSON');
  }

  if (!isRecord(parsed) || parsed.app !== 'picklight') {
    throw new Error('这不是拾光的数据备份');
  }

  if (parsed.schemaVersion !== 2 && parsed.schemaVersion !== PICKLIGHT_BACKUP_SCHEMA_VERSION) {
    throw new Error(`暂不支持 schemaVersion ${String(parsed.schemaVersion)} 的备份`);
  }

  if (typeof parsed.exportedAt !== 'string') {
    throw new Error('备份缺少导出时间');
  }

  const state = parsePicklightState(parsed.state, parsed.schemaVersion === PICKLIGHT_BACKUP_SCHEMA_VERSION);
  if (!state) {
    throw new Error('备份中的数据结构不完整');
  }

  return {
    app: 'picklight',
    schemaVersion: PICKLIGHT_BACKUP_SCHEMA_VERSION,
    exportedAt: parsed.exportedAt,
    state
  };
}

export function normalizeImportedState(state: PicklightState): PicklightState {
  return {
    todos: state.todos,
    scraps: state.scraps,
    anchors: state.anchors,
    focusSessions: state.focusSessions,
    habits: Array.isArray(state.habits) ? state.habits : [],
    activeDate: state.activeDate || todayISODate()
  };
}

export function mergePicklightStates(local: PicklightState, incoming: PicklightState): PicklightState {
  const localContents = new Set([...local.scraps.map((scrap) => scrap.content), ...local.todos.map((todo) => todo.content)]);
  const incomingScraps = incoming.scraps.filter((scrap) => !localContents.has(scrap.content));
  return {
    ...local,
    scraps: [...local.scraps, ...incomingScraps],
    todos: [
      ...local.todos,
      ...incoming.todos.filter((todo) => !localContents.has(todo.content))
    ],
    anchors: [...local.anchors, ...incoming.anchors.filter((anchor) => !local.anchors.some((item) => item.title === anchor.title && item.date === anchor.date))],
    focusSessions: [
      ...local.focusSessions,
      ...incoming.focusSessions.filter(
        (session) => !local.focusSessions.some((item) => item.task === session.task && item.createdAt === session.createdAt)
      )
    ],
    habits: [
      ...local.habits,
      ...incoming.habits.filter(
        (habit) =>
          !local.habits.some(
            (item) =>
              item.content === habit.content &&
              item.time === habit.time &&
              item.weekdays.join(',') === habit.weekdays.join(',')
          )
      )
    ],
    activeDate: local.activeDate
  };
}
