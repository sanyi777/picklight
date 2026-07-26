import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

describe('habit page architecture', () => {
  it('routes from home and delegates habit changes to the store', () => {
    const root = process.cwd();
    const home = readFileSync(resolve(root, 'src/pages/home/index.vue'), 'utf8');
    const page = readFileSync(resolve(root, 'src/pages/habits/index.vue'), 'utf8');
    const pages = readFileSync(resolve(root, 'src/pages.json'), 'utf8');
    const app = readFileSync(resolve(root, 'src/App.vue'), 'utf8');

    expect(home).toContain('/pages/habits/index');
    expect(pages).toContain('"pages/habits/index"');
    expect(page).toContain('store.addHabit');
    expect(page).toContain('store.updateHabit');
    expect(page).toContain('store.deleteHabit');
    expect(app).toContain('onShow(store.hydrate)');
  });
});
