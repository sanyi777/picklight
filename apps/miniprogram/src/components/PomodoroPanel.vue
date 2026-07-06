<script setup lang="ts">
import { computed, ref } from 'vue';
import type { FocusSession } from '@/domain/types';

const props = defineProps<{
  latestSession?: FocusSession;
}>();

const emit = defineEmits<{
  create: [task: string, durationMinutes: number];
  start: [id: string];
  complete: [id: string];
  distraction: [id: string, content: string];
}>();

const task = ref('');
const durationMinutes = ref(25);
const distraction = ref('');
const sessionStatus = computed(() => {
  if (!props.latestSession) {
    return '未开始';
  }
  if (props.latestSession.completed) {
    return '已完成';
  }
  if (props.latestSession.startedAt) {
    return '进行中';
  }
  return '已创建';
});

function createSession() {
  const trimmed = task.value.trim();
  if (!trimmed) {
    return;
  }
  emit('create', trimmed, durationMinutes.value);
  task.value = '';
}

function recordDistraction() {
  if (!props.latestSession || !distraction.value.trim()) {
    return;
  }
  emit('distraction', props.latestSession.id, distraction.value);
  distraction.value = '';
}
</script>

<template>
  <view class="pomodoro">
    <view class="field">
      <text class="label">本轮小事</text>
      <input v-model="task" placeholder="这一轮只完成什么" />
    </view>
  <view class="field">
      <text class="label">分钟</text>
      <slider
        :value="durationMinutes"
        min="5"
        max="60"
        show-value
        activeColor="#25635f"
        @change="durationMinutes = Number($event.detail.value)"
      />
    </view>
    <button class="primary-button" @click="createSession">创建番茄钟</button>

    <view v-if="latestSession" class="session">
      <text class="status">{{ sessionStatus }}</text>
      <text class="task">{{ latestSession.task }} / {{ latestSession.durationMinutes }} 分钟</text>
      <view class="actions">
        <button size="mini" @click="emit('start', latestSession.id)">开始</button>
        <button size="mini" @click="emit('complete', latestSession.id)">完成</button>
      </view>
      <view class="distraction">
        <input v-model="distraction" placeholder="分心了，先记下" />
        <button size="mini" @click="recordDistraction">记录</button>
      </view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.pomodoro {
  display: grid;
  gap: 12px;
}

.field {
  display: grid;
  gap: 6px;
}

.label,
.status {
  color: #6f6b62;
  font-size: 12px;
}

input {
  height: 40px;
  border: 1px solid rgba(34, 34, 34, 0.1);
  border-radius: 8px;
  padding: 0 10px;
  background: #ffffff;
}

.primary-button {
  border-radius: 8px;
  background: #25635f;
  color: #ffffff;
  font-size: 15px;
}

.session {
  display: grid;
  gap: 8px;
  border-top: 1px solid rgba(34, 34, 34, 0.08);
  padding-top: 12px;
}

.task {
  overflow-wrap: anywhere;
}

.actions,
.distraction {
  display: flex;
  align-items: center;
  gap: 8px;
}

.distraction input {
  flex: 1;
}
</style>
