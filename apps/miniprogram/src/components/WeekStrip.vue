<script setup lang="ts">
import { computed } from 'vue';
import { getNextSevenDays } from '@/domain/date';
import type { ISODate, Todo } from '@/domain/types';

const props = defineProps<{
  startDate: ISODate;
  activeDate: ISODate;
  todos: Todo[];
}>();

const emit = defineEmits<{
  select: [date: ISODate];
}>();

const days = computed(() =>
  getNextSevenDays(props.startDate).map((date) => ({
    date,
    count: props.todos.filter((todo) => todo.date === date && !todo.completed).length
  }))
);
</script>

<template>
  <view class="week-strip">
    <button
      v-for="day in days"
      :key="day.date"
      :class="['day-button', { active: day.date === activeDate }]"
      @click="emit('select', day.date)"
    >
      <text class="day-label">{{ day.date === startDate ? '今天' : day.date.slice(5) }}</text>
      <text class="count">{{ day.count }}项</text>
    </button>
  </view>
</template>

<style scoped lang="scss">
.week-strip {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  gap: 3px;
}

.day-button {
  display: grid;
  min-width: 0;
  height: 44px;
  grid-template-rows: 18px 16px;
  align-content: center;
  justify-items: center;
  border: 1px solid #e2ebf2;
  border-radius: 8px;
  padding: 4px 2px;
  background: #fbfdff;
  color: #6f7b8a;
  font-size: 10px;
  line-height: 1;
}

.day-button.active {
  border-color: rgba(74, 144, 217, 0.56);
  background: #eaf4ff;
  color: #2f72b4;
  font-weight: 750;
}

.day-label,
.count {
  display: block;
  max-width: 100%;
  overflow: hidden;
  line-height: 16px;
  text-align: center;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.day-label {
  line-height: 18px;
}

@media (max-width: 360px) {
  .day-button {
    height: 40px;
    grid-template-rows: 16px 14px;
    padding: 4px 1px;
    font-size: 9px;
  }

  .day-label,
  .count {
    line-height: 14px;
  }

  .day-label {
    line-height: 16px;
  }
}
</style>
