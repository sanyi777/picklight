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
    status: 'idle',
    pausedTotalSeconds: 0,
    completed: false,
    distractions: [],
    createdAt: timestamp,
    updatedAt: timestamp
  };
}

function secondsBetween(start: ISODateTime, end: ISODateTime): number {
  return Math.max(0, Math.floor((new Date(end).getTime() - new Date(start).getTime()) / 1000));
}

export function startFocusSession(sessions: FocusSession[], id: ID, now = nowISODateTime()): FocusSession[] {
  return sessions.map((session) =>
    session.id === id && !session.completed
      ? (() => {
          const pausedTotalSeconds =
            session.status === 'paused' && session.pausedAt
              ? (session.pausedTotalSeconds ?? 0) + secondsBetween(session.pausedAt, now)
              : session.pausedTotalSeconds ?? 0;

          return {
            ...session,
            status: 'running' as const,
            startedAt: session.startedAt ?? now,
            pausedAt: undefined,
            pausedTotalSeconds,
            updatedAt: now
          };
        })()
      : session
  );
}

export function pauseFocusSession(sessions: FocusSession[], id: ID, now = nowISODateTime()): FocusSession[] {
  return sessions.map((session) =>
    session.id === id && !session.completed && session.status === 'running'
      ? {
          ...session,
          status: 'paused',
          pausedAt: now,
          updatedAt: now
        }
      : session
  );
}

export function extendFocusSession(sessions: FocusSession[], id: ID, minutes: number, now = nowISODateTime()): FocusSession[] {
  const extraMinutes = Math.max(1, Math.round(minutes));

  return sessions.map((session) =>
    session.id === id && !session.completed
      ? {
          ...session,
          durationMinutes: session.durationMinutes + extraMinutes,
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
          status: 'completed',
          completed: true,
          pausedAt: undefined,
          completedAt: now,
          actualSeconds: getActualFocusSeconds(session, now),
          updatedAt: now
        }
      : session
  );
}

export function abandonFocusSession(sessions: FocusSession[], id: ID, now = nowISODateTime()): FocusSession[] {
  return completeFocusSession(sessions, id, now);
}

export function getActualFocusSeconds(session: FocusSession, now = nowISODateTime()): number {
  if (typeof session.actualSeconds === 'number') {
    return session.actualSeconds;
  }

  if (!session.startedAt) {
    return 0;
  }

  const effectiveEnd = session.status === 'paused' && session.pausedAt ? session.pausedAt : session.completedAt ?? now;
  return Math.max(0, secondsBetween(session.startedAt, effectiveEnd) - (session.pausedTotalSeconds ?? 0));
}

export function clearFocusSessionsBeforeDate(sessions: FocusSession[], date: ISODate): FocusSession[] {
  return sessions.filter((session) => session.date >= date);
}

export function updateFocusSessionTask(
  sessions: FocusSession[],
  id: ID,
  task: string,
  now = nowISODateTime()
): FocusSession[] {
  const trimmedTask = task.trim();
  if (!trimmedTask) return sessions;

  return sessions.map((session) => (session.id === id ? { ...session, task: trimmedTask, updatedAt: now } : session));
}

export function getFocusTiming(session: FocusSession, now = nowISODateTime()) {
  const totalSeconds = Math.max(1, session.durationMinutes * 60);
  const pausedTotalSeconds = session.pausedTotalSeconds ?? 0;

  if (!session.startedAt) {
    return {
      totalSeconds,
      elapsedSeconds: 0,
      remainingSeconds: totalSeconds,
      elapsed: false
    };
  }

  const effectiveNow = session.status === 'paused' && session.pausedAt ? session.pausedAt : now;
  const elapsedSeconds = Math.min(totalSeconds, Math.max(0, secondsBetween(session.startedAt, effectiveNow) - pausedTotalSeconds));
  const remainingSeconds = Math.max(0, totalSeconds - elapsedSeconds);

  return {
    totalSeconds,
    elapsedSeconds,
    remainingSeconds,
    elapsed: remainingSeconds === 0
  };
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
