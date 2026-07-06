import { nowISODateTime } from './date';
import type { FocusSession, ID, ISODate, ISODateTime } from './types';

export interface CreateFocusSessionInput {
  id: ID;
  date: ISODate;
  task: string;
  durationMinutes: number;
  anchorId?: ID;
  now?: ISODateTime;
}

export function createFocusSession(input: CreateFocusSessionInput): FocusSession {
  const timestamp = input.now ?? nowISODateTime();

  return {
    id: input.id,
    date: input.date,
    anchorId: input.anchorId,
    task: input.task.trim(),
    durationMinutes: Math.max(1, Math.round(input.durationMinutes)),
    completed: false,
    distractions: [],
    createdAt: timestamp,
    updatedAt: timestamp
  };
}

export function startFocusSession(sessions: FocusSession[], id: ID, now = nowISODateTime()): FocusSession[] {
  return sessions.map((session) =>
    session.id === id
      ? {
          ...session,
          startedAt: now,
          updatedAt: now
        }
      : session
  );
}

export function completeFocusSession(sessions: FocusSession[], id: ID, now = nowISODateTime()): FocusSession[] {
  return sessions.map((session) =>
    session.id === id
      ? {
          ...session,
          completed: true,
          completedAt: now,
          updatedAt: now
        }
      : session
  );
}

export function addDistractionToFocusSession(
  sessions: FocusSession[],
  id: ID,
  distraction: string,
  now = nowISODateTime()
): FocusSession[] {
  const trimmedDistraction = distraction.trim();

  if (!trimmedDistraction) {
    return sessions;
  }

  return sessions.map((session) =>
    session.id === id
      ? {
          ...session,
          distractions: [...session.distractions, trimmedDistraction],
          updatedAt: now
        }
      : session
  );
}

export function getFocusStats(sessions: FocusSession[], date: ISODate) {
  const daySessions = sessions.filter((session) => session.date === date);
  const completedSessions = daySessions.filter((session) => session.completed);

  return {
    sessions: daySessions.length,
    completedSessions: completedSessions.length,
    completedMinutes: completedSessions.reduce((total, session) => total + session.durationMinutes, 0)
  };
}
