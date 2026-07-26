<script setup lang="ts">
import { ref } from 'vue';
import { HABIT_WEEKDAY_OPTIONS } from './habitWeekdays';
import TodoTimePicker from './TodoTimePicker.vue';
import type { HabitWeekday } from '@/domain/types';

const props = withDefaults(
  defineProps<{
    initialContent?: string;
    initialTime?: string;
    initialWeekdays?: HabitWeekday[];
    submitLabel?: string;
    autoFocus?: boolean;
  }>(),
  {
    initialContent: '',
    initialTime: '',
    initialWeekdays: () => [1, 2, 3, 4, 5, 6, 7],
    submitLabel: '保存习惯',
    autoFocus: false
  }
);

const emit = defineEmits<{
  submit: [content: string, time: string, weekdays: HabitWeekday[]];
}>();

const allWeekdays = HABIT_WEEKDAY_OPTIONS.map((item) => item.value);
const content = ref(props.initialContent);
const hasTime = ref(Boolean(props.initialTime));
const time = ref(props.initialTime || '09:00');
const weekdays = ref<HabitWeekday[]>([...props.initialWeekdays]);
const repeatMode = ref<'daily' | 'custom'>(weekdays.value.length === 7 ? 'daily' : 'custom');

function selectDaily() {
  repeatMode.value = 'daily';
  weekdays.value = [...allWeekdays];
}

function selectCustom() {
  if (repeatMode.value === 'daily') {
    weekdays.value = [];
  }
  repeatMode.value = 'custom';
}

function toggleWeekday(value: HabitWeekday) {
  selectCustom();
  weekdays.value = weekdays.value.includes(value)
    ? weekdays.value.filter((item) => item !== value)
    : [...weekdays.value, value].sort((a, b) => a - b);
}

function submit() {
  if (!content.value.trim()) {
    uni.showToast({ title: '请填写习惯内容', icon: 'none' });
    return;
  }
  if (!weekdays.value.length) {
    uni.showToast({ title: '请至少选择一天', icon: 'none' });
    return;
  }

  emit('submit', content.value.trim(), hasTime.value ? time.value : '', [...weekdays.value]);
}
</script>

<template>
  <view class="habit-form">
    <view class="form-field">
      <text class="field-label">习惯内容</text>
      <input v-model="content" :focus="autoFocus" placeholder="例如：背单词" maxlength="100" @confirm="submit" />
    </view>

    <view class="form-field">
      <text class="field-label">固定时间</text>
      <TodoTimePicker v-model:has-time="hasTime" v-model:time="time" />
    </view>

    <view class="form-field">
      <text class="field-label">重复日期</text>
      <view class="repeat-modes">
        <button :class="{ active: repeatMode === 'daily' }" @tap.stop="selectDaily">每天</button>
        <button :class="{ active: repeatMode === 'custom' }" @tap.stop="selectCustom">自选</button>
      </view>
      <view v-if="repeatMode === 'custom'" class="weekday-row">
        <button
          v-for="item in HABIT_WEEKDAY_OPTIONS"
          :key="item.value"
          :class="{ active: weekdays.includes(item.value) }"
          @tap.stop="toggleWeekday(item.value)"
        >
          {{ item.label }}
        </button>
      </view>
    </view>

    <button class="submit-action" @tap.stop="submit">{{ submitLabel }}</button>
  </view>
</template>

<style scoped lang="scss">
.habit-form,
.form-field {
  display: grid;
}

.habit-form {
  gap: 14px;
}

.form-field {
  gap: 7px;
}

.field-label {
  color: #6f7b8a;
  font-size: 12px;
  font-weight: 700;
}

input {
  height: 38px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 0 10px;
  background: #fbfdff;
  color: #202733;
  font-size: 14px;
}

.repeat-modes {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 7px;
}

.weekday-row {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  gap: 5px;
}

.repeat-modes button,
.weekday-row button {
  height: 32px;
  min-height: 32px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  background: #fbfdff;
  color: #6f7b8a;
  font-size: 12px;
  font-weight: 700;
  line-height: 32px;
}

.repeat-modes button.active,
.weekday-row button.active {
  border-color: rgba(74, 144, 217, 0.56);
  background: #eaf4ff;
  color: #2f72b4;
}

.submit-action {
  height: 38px;
  min-height: 38px;
  border: 0;
  border-radius: 8px;
  background: #4a90d9;
  color: #ffffff;
  font-size: 14px;
  font-weight: 750;
  line-height: 38px;
}
</style>
