<script setup lang="ts">
withDefaults(
  defineProps<{
    hasTime: boolean;
    time: string;
    compact?: boolean;
  }>(),
  {
    compact: false
  }
);

const emit = defineEmits<{
  'update:hasTime': [value: boolean];
  'update:time': [value: string];
}>();
</script>

<template>
  <view :class="['todo-time-picker', { compact }]">
    <button :class="['time-toggle', { active: !hasTime }]" @tap.stop="emit('update:hasTime', false)">无截止</button>
    <button :class="['time-toggle', { active: hasTime }]" @tap.stop="emit('update:hasTime', true)">截止时间</button>
    <picker mode="time" :value="time" @change="emit('update:time', String($event.detail.value))">
      <view :class="['time-picker', { disabled: !hasTime }]">{{ hasTime ? time : '未设置' }}</view>
    </picker>
  </view>
</template>

<style scoped lang="scss">
.todo-time-picker {
  display: grid;
  grid-template-columns: 58px 58px minmax(0, 1fr);
  gap: 7px;
  align-items: center;
}

.time-toggle,
.time-picker {
  height: 30px;
  min-height: 30px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  background: #fbfdff;
  color: #6f7b8a;
  font-size: 12px;
  font-weight: 700;
  line-height: 30px;
  text-align: center;
}

.time-toggle.active,
.time-picker:not(.disabled) {
  border-color: rgba(74, 144, 217, 0.56);
  background: #eaf4ff;
  color: #2f72b4;
}

.time-picker.disabled {
  color: #9aa6b3;
}

.compact {
  grid-template-columns: 50px 50px minmax(0, 1fr);
  gap: 5px;
}

.compact .time-toggle,
.compact .time-picker {
  height: 26px;
  min-height: 26px;
  font-size: 11px;
  line-height: 26px;
}

@media (max-width: 360px) {
  .todo-time-picker {
    grid-template-columns: 52px 52px minmax(0, 1fr);
    gap: 5px;
  }
}
</style>
