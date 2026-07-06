import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import {
  addDailyAnchor,
  createDailyAnchor,
  deleteAnchor as removeAnchorById,
  getAnchorsForDate,
  getCurrentAnchor,
  setCurrentAnchor,
  updateAnchorProgress,
  updateAnchorTitle
} from '@/domain/anchors';
import { addDays, nowISODateTime, todayISODate } from '@/domain/date';
import { addDistractionToFocusSession, completeFocusSession, createFocusSession, startFocusSession } from '@/domain/focus';
import { createScrap, deleteScrap as removeScrapById, getScrapsByCategory, updateScrap as updateScrapById } from '@/domain/scraps';
import { createTodo, getTodoStats, getTodosForDate, rollUnfinishedTodos, toggleTodo } from '@/domain/todos';
import type { DailyAnchor, FocusSession, ID, ISODate, PicklightState, Scrap, ScrapCategory, Todo } from '@/domain/types';
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
    activeDate: todayISODate()
  };
}

function rollOverdueTodosToToday(savedState: PicklightState, today: ISODate): PicklightState {
  const overdueDates = savedState.todos
    .filter((todo) => !todo.completed && todo.date < today)
    .map((todo) => todo.date)
    .sort();

  if (!overdueDates.length && savedState.activeDate >= today) {
    return savedState;
  }

  let todos = savedState.todos;
  let cursor = overdueDates[0] ?? savedState.activeDate;

  while (cursor < today) {
    todos = rollUnfinishedTodos(todos, cursor);
    cursor = addDays(cursor, 1);
  }

  return {
    ...savedState,
    todos,
    activeDate: savedState.activeDate < today ? today : savedState.activeDate
  };
}

export const usePicklightStore = defineStore('picklight', () => {
  const state = ref<PicklightState>(createInitialState());

  const activeDate = computed(() => state.value.activeDate);
  const todayTodos = computed(() => getTodosForDate(state.value.todos, state.value.activeDate));
  const todayAnchors = computed(() => getAnchorsForDate(state.value.anchors, state.value.activeDate));
  const currentAnchor = computed(() => getCurrentAnchor(state.value.anchors));
  const todoStats = computed(() => getTodoStats(state.value.todos, state.value.activeDate));
  const allScraps = computed(() => getScrapsByCategory(state.value.scraps));

  function hydrate() {
    const savedState = localStore.load();
    if (savedState) {
      const currentToday = todayISODate();
      const nextState = rollOverdueTodosToToday(savedState, currentToday);
      state.value = nextState;
      if (nextState !== savedState) {
        persist();
      }
    }
  }

  function persist() {
    localStore.save(state.value);
  }

  function resetAllData() {
    state.value = createInitialState();
    localStore.clear();
  }

  function setActiveDate(date: ISODate) {
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
    persist();
  }

  function rollDateForward(date = state.value.activeDate) {
    state.value.todos = rollUnfinishedTodos(state.value.todos, date);
    persist();
  }

  function addScrap(category: ScrapCategory, content: string): { scrap: Scrap; todo?: Todo } {
    const result = createScrap({
      id: createId('scrap'),
      todoId: category === '待办' ? createId('todo') : undefined,
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

  function updateScrap(id: ID, category: ScrapCategory, content: string): Scrap | undefined {
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

  function createFocus(task: string, durationMinutes: number, anchorId = currentAnchor.value?.id): FocusSession {
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

  function completeFocus(id: ID) {
    state.value.focusSessions = completeFocusSession(state.value.focusSessions, id);
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
    hydrate,
    persist,
    resetAllData,
    setActiveDate,
    addTodo,
    setTodoCompleted,
    rollDateForward,
    addScrap,
    archiveReview,
    updateScrap,
    deleteScrap,
    addAnchor,
    makeAnchorCurrent,
    setAnchorProgress,
    renameAnchor,
    deleteAnchor,
    createFocus,
    startFocus,
    completeFocus,
    deleteFocus,
    addFocusDistraction
  };
});
