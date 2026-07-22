import { mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import FocusHistoryModal from '../FocusHistoryModal.vue';

describe('FocusHistoryModal', () => {
  it('dismisses synchronously from the close button', async () => {
    const wrapper = mount(FocusHistoryModal, { props: { sessions: [] } });
    const closeButton = wrapper.get('.close-button');

    expect(closeButton.attributes('data-eventsync')).toBe('true');

    await closeButton.trigger('tap');

    expect(wrapper.emitted('dismiss')).toEqual([[]]);
  });
});
