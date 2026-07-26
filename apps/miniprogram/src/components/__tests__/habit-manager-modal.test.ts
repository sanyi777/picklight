import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

describe('habit card architecture', () => {
  it('opens from home as a centered modal and delegates habit changes to the store', () => {
    const root = process.cwd();
    const home = readFileSync(resolve(root, 'src/pages/home/index.vue'), 'utf8');
    const modal = readFileSync(resolve(root, 'src/components/HabitManagerModal.vue'), 'utf8');
    const pages = readFileSync(resolve(root, 'src/pages.json'), 'utf8');
    const app = readFileSync(resolve(root, 'src/App.vue'), 'utf8');

    expect(home).toContain('<HabitManagerModal');
    expect(home).toContain('showHabitPanel');
    expect(home).not.toContain('/pages/habits/index');
    expect(pages).not.toContain('"pages/habits/index"');
    expect(modal).toContain('place-items: center');
    expect(modal).toContain('store.addHabit');
    expect(modal).toContain('store.updateHabit');
    expect(modal).toContain('store.deleteHabit');
    expect(app).toContain('onShow(store.hydrate)');
  });
});
