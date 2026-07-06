import { PICKLIGHT_STORAGE_KEY } from './keys';
import type { PicklightState } from '@/domain/types';

export interface StoragePort {
  load(): PicklightState | undefined;
  save(state: PicklightState): void;
}

export const localStore: StoragePort = {
  load() {
    try {
      const raw = uni.getStorageSync(PICKLIGHT_STORAGE_KEY);
      return raw ? (raw as PicklightState) : undefined;
    } catch {
      return undefined;
    }
  },
  save(state) {
    uni.setStorageSync(PICKLIGHT_STORAGE_KEY, state);
  }
};
