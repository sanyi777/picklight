import type { HabitWeekday } from '@/domain/types';

export const HABIT_WEEKDAY_OPTIONS: Array<{ value: HabitWeekday; label: string }> = [
  { value: 1, label: '一' },
  { value: 2, label: '二' },
  { value: 3, label: '三' },
  { value: 4, label: '四' },
  { value: 5, label: '五' },
  { value: 6, label: '六' },
  { value: 7, label: '日' }
];

export function formatHabitWeekdays(weekdays: HabitWeekday[]): string {
  if (weekdays.length === HABIT_WEEKDAY_OPTIONS.length) {
    return '每天';
  }

  const labels = new Map(HABIT_WEEKDAY_OPTIONS.map((item) => [item.value, item.label]));
  return `周${weekdays.map((day) => labels.get(day)).join('、')}`;
}
