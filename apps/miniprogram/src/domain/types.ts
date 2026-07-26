export type ID = string;
export type ISODate = string;
export type ISODateTime = string;

export type ScrapCategory = '灵感' | '随想' | '待办' | '分心' | '复盘';
export type HabitWeekday = 1 | 2 | 3 | 4 | 5 | 6 | 7;

export interface Todo {
  id: ID;
  date: ISODate;
  time: string;
  content: string;
  completed: boolean;
  completedAt?: ISODateTime;
  rolledOverFrom?: ISODate;
  sourceScrapId?: ID;
  sourceHabitId?: ID;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export interface Habit {
  id: ID;
  content: string;
  time: string;
  weekdays: HabitWeekday[];
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export interface Scrap {
  id: ID;
  date: ISODate;
  category: ScrapCategory;
  content: string;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
  linkedTodoId?: ID;
  todoCompleted?: boolean;
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
  status?: 'idle' | 'running' | 'paused' | 'completed';
  startedAt?: ISODateTime;
  pausedAt?: ISODateTime;
  pausedTotalSeconds?: number;
  completedAt?: ISODateTime;
  actualSeconds?: number;
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
  habits: Habit[];
  activeDate: ISODate;
}

export interface PicklightBackup {
  app: 'picklight';
  schemaVersion: 3;
  exportedAt: ISODateTime;
  state: PicklightState;
}
