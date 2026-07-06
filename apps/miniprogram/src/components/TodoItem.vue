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
    <checkbox :checked="todo.completed" @click="emit('toggle', todo.id, !todo.completed)" />
    <view class="todo-main">
      <text class="todo-time" v-if="todo.time">{{ todo.time }}</text>
      <text :class="['todo-content', { done: todo.completed }]">{{ todo.content }}</text>
    </view>
  </view>
</template>

<style scoped lang="scss">
.todo-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 0;
  border-bottom: 1px solid rgba(34, 34, 34, 0.08);
}

.todo-item:last-child {
  border-bottom: 0;
}

.todo-main {
  display: flex;
  min-width: 0;
  flex: 1;
  align-items: baseline;
  gap: 8px;
}

.todo-time {
  flex: 0 0 auto;
  color: #25635f;
  font-size: 12px;
}

.todo-content {
  overflow-wrap: anywhere;
  font-size: 15px;
}

.todo-content.done {
  color: #8a857c;
  text-decoration: line-through;
}
</style>
