import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import {
  addDailyAnchor,
  createDailyAnchor,
  deleteAnchor as removeAnchorById,
  getAnchorsForDate,
  getCurrentAnchor,
  setCurrentAnchor,
  rollDailyAnchors,
  updateAnchorProgress,
  updateAnchorTitle
} from '@/domain/anchors';
import { mergePicklightStates, normalizeImportedState, parsePicklightBackup, serializePicklightBackup } from '@/domain/backup';
import { addDays, nowISODateTime, todayISODate } from '@/domain/date';
import {
  addDistractionToFocusSession,
  completeFocusSession,
  abandonFocusSession,
  clearFocusSessionsBeforeDate,
  createFocusSession,
  extendFocusSession,
  pauseFocusSession,
  startFocusSession,
  updateFocusSessionTask
} from '@/domain/focus';
import { createHabit as createHabitRule, syncHabitTodos } from '@/domain/habits';
import { createScrap, deleteScrap as removeScrapById, getScrapsByCategory, updateScrap as updateScrapById } from '@/domain/scraps';
import { createTodo, getTodoStats, getTodosForDate, rollUnfinishedTodos, toggleTodo } from '@/domain/todos';
import type {
  DailyAnchor,
  FocusSession,
  Habit,
  HabitWeekday,
  ID,
  ISODate,
  PicklightState,
  Scrap,
  ScrapCategory,
  Todo
} from '@/domain/types';
import { localStore } from '@/storage/localStore';

function createId(prefix: string): ID {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function createInitialState(): PicklightState {
  return {
    todos: [],
    scraps: [],
    anchors: [],
    focusSessions: [],
    habits: [],
    activeDate: todayISODate()
  };
}

function normalizeStoredState(savedState: PicklightState): PicklightState {
  return {
    ...savedState,
    habits: Array.isArray(savedState.habits) ? savedState.habits : []
  };
}

function reconcileHabitTodos(savedState: PicklightState, fromDate: ISODate): PicklightState {
  return {
    ...savedState,
    todos: syncHabitTodos({
      todos: savedState.todos,
      habits: savedState.habits,
      fromDate,
      createId: () => createId('todo')
    })
  };
}

function rollOverdueTodosToToday(savedState: PicklightState, today: ISODate): PicklightState {
  const dates = [
    savedState.activeDate,
    ...savedState.todos.map((todo) => todo.date),
    ...savedState.anchors.map((anchor) => anchor.date),
    ...savedState.focusSessions.map((session) => session.date)
  ].filter((date) => date < today).sort();

  if (!dates.length) {
    return { ...savedState, activeDate: today };
  }

  let nextState = savedState;
  let cursor = dates[0];

  while (cursor < today) {
    const completedTodoIds = new Set(
      nextState.todos.filter((todo) => todo.date === cursor && todo.completed).map((todo) => todo.id)
    );
    nextState = {
      ...nextState,
      todos: rollUnfinishedTodos(nextState.todos, cursor),
      scraps: nextState.scraps.filter((scrap) => !completedTodoIds.has(scrap.linkedTodoId ?? '')),
      anchors: rollDailyAnchors(nextState.anchors, cursor),
      focusSessions: clearFocusSessionsBeforeDate(nextState.focusSessions, addDays(cursor, 1))
    };
    cursor = addDays(cursor, 1);
  }

  return { ...nextState, activeDate: today };
}

export const usePicklightStore = defineStore('picklight', () => {
  const state = ref<PicklightState>(createInitialState());

  const activeDate = computed(() => state.value.activeDate);
  const todayTodos = computed(() => getTodosForDate(state.value.todos, state.value.activeDate));
  const todayAnchors = computed(() => getAnchorsForDate(state.value.anchors, state.value.activeDate));
  const currentAnchor = computed(() => getCurrentAnchor(state.value.anchors));
  const todoStats = computed(() => getTodoStats(state.value.todos, state.value.activeDate));
  const allScraps = computed(() => getScrapsByCategory(state.value.scraps));
  const habits = computed(() => [...state.value.habits].sort((a, b) => a.createdAt.localeCompare(b.createdAt)));

  function hydrate() {
    const savedState = localStore.load();
    if (savedState) {
      const currentToday = todayISODate();
      const normalized = normalizeStoredState(savedState);
      const nextState = reconcileHabitTodos(rollOverdueTodosToToday(normalized, currentToday), currentToday);
      state.value = nextState;
      persist();
    }
  }

  function persist() {
    localStore.save(state.value);
  }

  function resetAllData() {
    state.value = createInitialState();
    localStore.clear();
  }

  function exportBackupText(): string {
    return serializePicklightBackup(state.value);
  }

  function importBackupText(raw: string) {
    const backup = parsePicklightBackup(raw);
    const today = todayISODate();
    state.value = reconcileHabitTodos(
      rollOverdueTodosToToday(mergePicklightStates(state.value, normalizeImportedState(backup.state)), today),
      today
    );
    persist();
  }

  function setActiveDate(date: ISODate) {
    const today = todayISODate();
    if (date < today || date > addDays(today, 6)) {
      return;
    }
    state.value.activeDate = date;
    persist();
  }

  function addTodo(content: string, time = '', date = state.value.activeDate): Todo {
    const todo = createTodo({
      id: createId('todo'),
      date,
      content,
      time
    });

    state.value.todos = [...state.value.todos, todo];
    persist();

    return todo;
  }

  function setTodoCompleted(id: ID, completed: boolean) {
    state.value.todos = toggleTodo(state.value.todos, id, completed);
    state.value.scraps = state.value.scraps.map((scrap) =>
      scrap.linkedTodoId === id ? { ...scrap, todoCompleted: completed, updatedAt: nowISODateTime() } : scrap
    );
    persist();
  }

  function addHabit(content: string, time: string, weekdays: HabitWeekday[]): Habit {
    const habit = createHabitRule({
      id: createId('habit'),
      content,
      time,
      weekdays
    });
    state.value.habits = [...state.value.habits, habit];
    state.value = reconcileHabitTodos(state.value, todayISODate());
    persist();
    return habit;
  }

  function updateHabit(id: ID, content: string, time: string, weekdays: HabitWeekday[]): Habit | undefined {
    const previous = state.value.habits.find((habit) => habit.id === id);
    if (!previous) {
      return undefined;
    }
    const updated = {
      ...createHabitRule({ id, content, time, weekdays }),
      createdAt: previous.createdAt
    };
    state.value.habits = state.value.habits.map((habit) => (habit.id === id ? updated : habit));
    state.value = reconcileHabitTodos(state.value, todayISODate());
    persist();
    return updated;
  }

  function deleteHabit(id: ID) {
    state.value.habits = state.value.habits.filter((habit) => habit.id !== id);
    state.value = reconcileHabitTodos(state.value, todayISODate());
    persist();
  }

  function deleteTodo(id: ID) {
    state.value.todos = state.value.todos.filter((todo) => todo.id !== id);
    state.value.scraps = state.value.scraps.filter((scrap) => scrap.linkedTodoId !== id);
    persist();
  }

  function rollDateForward(date = state.value.activeDate) {
    const completedTodoIds = new Set(state.value.todos.filter((todo) => todo.date === date && todo.completed).map((todo) => todo.id));
    state.value.todos = rollUnfinishedTodos(state.value.todos, date);
    state.value.scraps = state.value.scraps.filter((scrap) => !completedTodoIds.has(scrap.linkedTodoId ?? ''));
    state.value.anchors = rollDailyAnchors(state.value.anchors, date);
    state.value.focusSessions = clearFocusSessionsBeforeDate(state.value.focusSessions, addDays(date, 1));
    state.value = reconcileHabitTodos(state.value, addDays(date, 1));
    persist();
  }

  function addScrap(category: ScrapCategory, content: string, time = ''): { scrap: Scrap; todo?: Todo } {
    const result = createScrap({
      id: createId('scrap'),
      todoId: category === '待办' ? createId('todo') : undefined,
      todoTime: category === '待办' ? time : '',
      today: state.value.activeDate,
      category,
      content
    });

    state.value.scraps = [...state.value.scraps, result.scrap];
    if (result.todo) {
      state.value.todos = [...state.value.todos, result.todo];
    }
    persist();

    return result;
  }

  function archiveReview(content: string): Scrap {
    return addScrap('复盘', content).scrap;
  }

  function getLinkedTodoTime(scrap: Scrap): string {
    if (!scrap.linkedTodoId) {
      return '';
    }

    return state.value.todos.find((todo) => todo.id === scrap.linkedTodoId)?.time ?? '';
  }

  function updateScrap(id: ID, category: ScrapCategory, content: string, time = ''): Scrap | undefined {
    const trimmedContent = content.trim();
    const previous = state.value.scraps.find((scrap) => scrap.id === id);
    if (!previous || !trimmedContent) {
      return undefined;
    }

    const timestamp = nowISODateTime();
    const linkedTodoId = category === '待办' ? previous.linkedTodoId ?? createId('todo') : undefined;
    state.value.scraps = updateScrapById(state.value.scraps, id, {
      category,
      content: trimmedContent,
      linkedTodoId,
      now: timestamp
    });

    if (previous.linkedTodoId && category !== '待办') {
      state.value.todos = state.value.todos.filter((todo) => todo.id !== previous.linkedTodoId);
    } else if (category === '待办' && previous.linkedTodoId) {
      state.value.todos = state.value.todos.map((todo) =>
        todo.id === previous.linkedTodoId
          ? {
              ...todo,
              content: trimmedContent,
              time,
              updatedAt: timestamp
            }
          : todo
      );
    } else if (category === '待办' && linkedTodoId) {
      state.value.todos = [
        ...state.value.todos,
        createTodo({
          id: linkedTodoId,
          date: state.value.activeDate,
          content: trimmedContent,
          time,
          sourceScrapId: id,
          now: timestamp
        })
      ];
    }

    persist();
    return state.value.scraps.find((scrap) => scrap.id === id);
  }

  function deleteScrap(id: ID) {
    const previous = state.value.scraps.find((scrap) => scrap.id === id);
    state.value.scraps = removeScrapById(state.value.scraps, id);
    if (previous?.linkedTodoId) {
      state.value.todos = state.value.todos.filter((todo) => todo.id !== previous.linkedTodoId);
    }
    persist();
  }

  function addAnchor(title: string): DailyAnchor {
    const anchor = createDailyAnchor({
      id: createId('anchor'),
      date: state.value.activeDate,
      title
    });

    state.value.anchors = addDailyAnchor(state.value.anchors, anchor);
    persist();

    return anchor;
  }

  function makeAnchorCurrent(id: ID) {
    state.value.anchors = setCurrentAnchor(state.value.anchors, id);
    persist();
  }

  function setAnchorProgress(id: ID, progress: number) {
    state.value.anchors = updateAnchorProgress(state.value.anchors, id, progress);
    persist();
  }

  function renameAnchor(id: ID, title: string) {
    state.value.anchors = updateAnchorTitle(state.value.anchors, id, title);
    persist();
  }

  function deleteAnchor(id: ID) {
    state.value.anchors = removeAnchorById(state.value.anchors, id);
    state.value.focusSessions = state.value.focusSessions.map((session) =>
      session.anchorId === id
        ? {
            ...session,
            anchorId: undefined
          }
        : session
    );
    persist();
  }

  function createFocus(task: string, durationMinutes: number, anchorId?: ID): FocusSession {
    const session = createFocusSession({
      id: createId('focus'),
      date: state.value.activeDate,
      task,
      durationMinutes,
      anchorId
    });

    state.value.focusSessions = [...state.value.focusSessions, session];
    persist();

    return session;
  }

  function startFocus(id: ID) {
    state.value.focusSessions = startFocusSession(state.value.focusSessions, id);
    persist();
  }

  function pauseFocus(id: ID) {
    state.value.focusSessions = pauseFocusSession(state.value.focusSessions, id);
    persist();
  }

  function extendFocus(id: ID, minutes: number) {
    state.value.focusSessions = extendFocusSession(state.value.focusSessions, id, minutes);
    persist();
  }

  function completeFocus(id: ID) {
    state.value.focusSessions = completeFocusSession(state.value.focusSessions, id);
    persist();
  }

  function abandonFocus(id: ID) {
    state.value.focusSessions = abandonFocusSession(state.value.focusSessions, id);
    persist();
  }

  function updateFocusTask(id: ID, task: string) {
    state.value.focusSessions = updateFocusSessionTask(state.value.focusSessions, id, task);
    persist();
  }

  function deleteFocus(id: ID) {
    state.value.focusSessions = state.value.focusSessions.filter((session) => session.id !== id);
    persist();
  }

  function addFocusDistraction(sessionId: ID, content: string) {
    state.value.focusSessions = addDistractionToFocusSession(state.value.focusSessions, sessionId, content);
    addScrap('分心', content);
    persist();
  }

  return {
    state,
    activeDate,
    todayTodos,
    todayAnchors,
    currentAnchor,
    todoStats,
    allScraps,
    habits,
    hydrate,
    persist,
    resetAllData,
    exportBackupText,
    importBackupText,
    setActiveDate,
    addHabit,
    updateHabit,
    deleteHabit,
    addTodo,
    setTodoCompleted,
    deleteTodo,
    rollDateForward,
    addScrap,
    archiveReview,
    getLinkedTodoTime,
    updateScrap,
    deleteScrap,
    addAnchor,
    makeAnchorCurrent,
    setAnchorProgress,
    renameAnchor,
    deleteAnchor,
    createFocus,
    startFocus,
    pauseFocus,
    extendFocus,
    completeFocus,
    abandonFocus,
    updateFocusTask,
    deleteFocus,
    addFocusDistraction
  };
});
