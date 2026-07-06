import { nowISODateTime } from './date';
import type { DailyAnchor, ID, ISODate, ISODateTime } from './types';

export const MAX_DAILY_ANCHORS = 2;

export interface CreateDailyAnchorInput {
  id: ID;
  date: ISODate;
  title: string;
  now?: ISODateTime;
}

export function createDailyAnchor(input: CreateDailyAnchorInput): DailyAnchor {
  const timestamp = input.now ?? nowISODateTime();

  return {
    id: input.id,
    date: input.date,
    title: input.title.trim(),
    progress: 0,
    isCurrent: false,
    createdAt: timestamp,
    updatedAt: timestamp
  };
}

export function addDailyAnchor(anchors: DailyAnchor[], anchor: DailyAnchor): DailyAnchor[] {
  const sameDayAnchors = anchors.filter((item) => item.date === anchor.date);

  if (sameDayAnchors.length >= MAX_DAILY_ANCHORS) {
    throw new Error('每天最多只能有两个主锚点');
  }

  return [...anchors, anchor];
}

export function setCurrentAnchor(anchors: DailyAnchor[], id: ID, now = nowISODateTime()): DailyAnchor[] {
  return anchors.map((anchor) => ({
    ...anchor,
    isCurrent: anchor.id === id,
    updatedAt: anchor.id === id || anchor.isCurrent ? now : anchor.updatedAt
  }));
}

export function updateAnchorProgress(
  anchors: DailyAnchor[],
  id: ID,
  progress: number,
  now = nowISODateTime()
): DailyAnchor[] {
  const boundedProgress = Math.max(0, Math.min(100, Math.round(progress)));

  return anchors.map((anchor) =>
    anchor.id === id
      ? {
          ...anchor,
          progress: boundedProgress,
          updatedAt: now
        }
      : anchor
  );
}

export function getAnchorsForDate(anchors: DailyAnchor[], date: ISODate): DailyAnchor[] {
  return anchors.filter((anchor) => anchor.date === date).sort((a, b) => a.createdAt.localeCompare(b.createdAt));
}

export function getCurrentAnchor(anchors: DailyAnchor[]): DailyAnchor | undefined {
  return anchors.find((anchor) => anchor.isCurrent);
}
