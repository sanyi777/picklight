<script setup lang="ts">
import { computed } from 'vue';
import { getNextSevenDays } from '@/domain/date';
import type { ISODate, Todo } from '@/domain/types';

const props = defineProps<{
  activeDate: ISODate;
  todos: Todo[];
}>();

const emit = defineEmits<{
  select: [date: ISODate];
}>();

const days = computed(() =>
  getNextSevenDays(props.activeDate).map((date) => ({
    date,
    count: props.todos.filter((todo) => todo.date === date && !todo.completed).length
  }))
);
</script>

<template>
  <scroll-view scroll-x class="week-strip">
    <view class="day-list">
      <button v-for="day in days" :key="day.date" class="day-button" @click="emit('select', day.date)">
        <text>{{ day.date.slice(5) }}</text>
        <text class="count">{{ day.count }} 件</text>
      </button>
    </view>
  </scroll-view>
</template>

<style scoped lang="scss">
.week-strip {
  width: 100%;
}

.day-list {
  display: flex;
  gap: 8px;
}

.day-button {
  width: 76px;
  border-radius: 8px;
  background: #fffaf1;
  color: #222222;
  font-size: 13px;
}

.count {
  display: block;
  color: #6f6b62;
  font-size: 11px;
}
</style>
