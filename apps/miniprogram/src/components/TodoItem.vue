<script setup lang="ts">
import type { Todo } from '@/domain/types';

defineProps<{
  todo: Todo;
}>();

const emit = defineEmits<{
  toggle: [id: string, completed: boolean];
}>();
</script>

<template>
  <view class="todo-item">
    <view :class="['todo-main', { 'no-time': !todo.time }]">
      <text v-if="todo.time" class="todo-time">{{ todo.time }}</text>
      <text :class="['todo-content', { done: todo.completed }]">{{ todo.content }}</text>
    </view>
    <view :class="['check-dot', { checked: todo.completed }]" @click="emit('toggle', todo.id, !todo.completed)">
      <text v-if="todo.completed">✓</text>
    </view>
  </view>
</template>

<style scoped lang="scss">
.todo-item {
  display: grid;
  grid-template-columns: 1fr auto;
  align-items: start;
  gap: 9px;
  min-height: 39px;
  border: 1px solid #e5edf4;
  border-radius: 8px;
  padding: 7px 9px;
  background: #fbfdff;
  overflow: hidden;
}

.todo-item:last-child {
  border-bottom: 1px solid #e5edf4;
}

.check-dot {
  display: flex;
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  border: 2px solid #c8d4df;
  border-radius: 50%;
  background: #ffffff;
  color: #ffffff;
  font-size: 12px;
  line-height: 1;
}

.check-dot.checked {
  border-color: #19a99a;
  background: #19a99a;
}

.todo-main {
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr);
  min-width: 0;
  align-items: start;
  gap: 8px;
}

.todo-main.no-time {
  grid-template-columns: minmax(0, 1fr);
}

.todo-time {
  flex: 0 0 auto;
  color: #2f72b4;
  font-size: 12px;
  font-weight: 750;
  font-variant-numeric: tabular-nums;
}

.todo-content {
  min-width: 0;
  overflow-wrap: anywhere;
  color: #202733;
  font-size: 14px;
  line-height: 1.35;
}

.todo-content.done {
  color: #9aa6b3;
  text-decoration: line-through;
}
</style>
