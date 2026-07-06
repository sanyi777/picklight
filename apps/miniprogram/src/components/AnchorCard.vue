<script setup lang="ts">
import type { DailyAnchor } from '@/domain/types';

defineProps<{
  anchor: DailyAnchor;
}>();

const emit = defineEmits<{
  current: [id: string];
  progress: [id: string, value: number];
}>();
</script>

<template>
  <view class="anchor-card">
    <view class="anchor-head">
      <text class="anchor-title">{{ anchor.title }}</text>
      <button size="mini" class="ghost-button" @click="emit('current', anchor.id)">
        {{ anchor.isCurrent ? '当前' : '设为当前' }}
      </button>
    </view>
    <slider
      :value="anchor.progress"
      min="0"
      max="100"
      activeColor="#25635f"
      backgroundColor="#d9d2c5"
      @change="emit('progress', anchor.id, Number($event.detail.value))"
    />
    <text class="anchor-progress">{{ anchor.progress }}%</text>
  </view>
</template>

<style scoped lang="scss">
.anchor-card {
  border: 1px solid rgba(37, 99, 95, 0.16);
  border-radius: 8px;
  padding: 12px;
  background: #fffaf1;
}

.anchor-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.anchor-title {
  min-width: 0;
  flex: 1;
  overflow-wrap: anywhere;
  font-size: 16px;
  font-weight: 600;
}

.ghost-button {
  flex: 0 0 auto;
  border: 1px solid rgba(37, 99, 95, 0.25);
  background: #eef7f4;
  color: #25635f;
  font-size: 12px;
}

.anchor-progress {
  color: #6f6b62;
  font-size: 12px;
}
</style>
