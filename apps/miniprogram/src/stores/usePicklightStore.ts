import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import { addDailyAnchor, createDailyAnchor, getAnchorsForDate, getCurrentAnchor, setCurrentAnchor, updateAnchorProgress } from '@/domain/anchors';
import { todayISODate } from '@/domain/date';
import { addDistractionToFocusSession, completeFocusSession, createFocusSession, startFocusSession } from '@/domain/focus';
import { createScrap, getScrapsByCategory } from '@/domain/scraps';
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
      state.value = savedState;
    }
  }

  function persist() {
    localStore.save(state.value);
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
    setActiveDate,
    addTodo,
    setTodoCompleted,
    rollDateForward,
    addScrap,
    archiveReview,
    addAnchor,
    makeAnchorCurrent,
    setAnchorProgress,
    createFocus,
    startFocus,
    completeFocus,
    addFocusDistraction
  };
});
