import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

describe('focus page architecture', () => {
  it('keeps critical pomodoro controls on the page runtime', () => {
    const pagePath = resolve(process.cwd(), 'src/pages/focus/index.vue');
    const source = readFileSync(pagePath, 'utf8');

    expect(source).not.toContain('PomodoroPanel');
    expect(source).not.toContain('FocusHistoryModal');
    expect(source).toContain('@tap.stop="pauseFocus"');
    expect(source).toContain('@tap.stop="completeFocus"');
    expect(source).toContain('@tap.stop="abandonFocus"');
    expect(source).toContain('v-if="showFocusHistory"');
    expect(source).toContain('onHide(handlePageHide)');
    expect(source.match(/data-eventsync="true"/g)?.length).toBeGreaterThanOrEqual(8);
  });
});
