import type { ISODate, ISODateTime } from './types';

export function toISODate(date: Date): ISODate {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

export function nowISODateTime(now = new Date()): ISODateTime {
  return now.toISOString();
}

export function todayISODate(now = new Date()): ISODate {
  return toISODate(now);
}

export function addDays(date: ISODate, days: number): ISODate {
  const parsed = parseISODate(date);
  parsed.setDate(parsed.getDate() + days);

  return toISODate(parsed);
}

export function getNextSevenDays(fromDate: ISODate): ISODate[] {
  return Array.from({ length: 7 }, (_, index) => addDays(fromDate, index));
}

export function parseISODate(date: ISODate): Date {
  const [year, month, day] = date.split('-').map(Number);
  return new Date(year, month - 1, day);
}
