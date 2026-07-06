<script setup lang="ts">
import type { Scrap } from '@/domain/types';

defineProps<{
  scrap: Scrap;
}>();
</script>

<template>
  <view class="scrap-item">
    <text class="category">{{ scrap.category }}</text>
    <text class="content">{{ scrap.content }}</text>
  </view>
</template>

<style scoped lang="scss">
.scrap-item {
  display: grid;
  gap: 6px;
  border-bottom: 1px solid rgba(34, 34, 34, 0.08);
  padding: 10px 0;
}

.scrap-item:last-child {
  border-bottom: 0;
}

.category {
  color: #b75c3b;
  font-size: 12px;
}

.content {
  overflow-wrap: anywhere;
  font-size: 15px;
}
</style>
