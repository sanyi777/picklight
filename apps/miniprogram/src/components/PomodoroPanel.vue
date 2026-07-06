<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue';
import type { FocusSession } from '@/domain/types';

const props = withDefaults(
  defineProps<{
    latestSession?: FocusSession;
    sessions?: FocusSession[];
    compact?: boolean;
  }>(),
  {
    sessions: () => [],
    compact: false
  }
);

const emit = defineEmits<{
  create: [task: string, durationMinutes: number];
  start: [id: string];
  complete: [id: string];
  delete: [id: string];
}>();

const task = ref('');
const durationMinutes = ref(25);
const durationInput = ref('25');
const remainingSeconds = ref(25 * 60);
const running = ref(false);
let timer: ReturnType<typeof setInterval> | undefined;

const hasSession = computed(() => Boolean(props.latestSession));
const started = computed(() => Boolean(props.latestSession?.startedAt));
const historySessions = computed(() => [...props.sessions].sort((a, b) => b.createdAt.localeCompare(a.createdAt)));
const formattedTime = computed(() => {
  const minutes = Math.floor(remainingSeconds.value / 60);
  const seconds = remainingSeconds.value % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
});
const progress = computed(() => {
  const totalSeconds = Math.max(1, (props.latestSession?.durationMinutes ?? durationMinutes.value) * 60);
  const elapsed = totalSeconds - remainingSeconds.value;
  return Math.max(0, Math.min(100, Math.round((elapsed / totalSeconds) * 100)));
});

watch(
  () => props.latestSession?.id,
  () => {
    stopTimer();
    remainingSeconds.value = getInitialRemainingSeconds();
  },
  { immediate: true }
);

onUnmounted(() => {
  stopTimer();
});

function clampDuration(value: number) {
  return Math.max(1, Math.min(180, Math.round(value)));
}

function setDuration(value: number) {
  durationMinutes.value = clampDuration(value);
  durationInput.value = String(durationMinutes.value);
  if (!props.latestSession) {
    remainingSeconds.value = durationMinutes.value * 60;
  }
}

function updateDurationInput(event: Event) {
  const value =
    'detail' in event && typeof event.detail === 'object' && event.detail && 'value' in event.detail
      ? String(event.detail.value)
      : (event.target as HTMLInputElement | null)?.value ?? '';

  durationInput.value = value;
  const parsed = Number(value);
  if (Number.isFinite(parsed) && parsed > 0) {
    setDuration(parsed);
  }
}

function getInitialRemainingSeconds() {
  if (!props.latestSession) {
    return durationMinutes.value * 60;
  }

  const totalSeconds = props.latestSession.durationMinutes * 60;
  if (!props.latestSession.startedAt) {
    return totalSeconds;
  }

  const elapsedSeconds = Math.floor((Date.now() - new Date(props.latestSession.startedAt).getTime()) / 1000);
  return Math.max(0, totalSeconds - elapsedSeconds);
}

function createSession() {
  const trimmed = task.value.trim();
  if (!trimmed) {
    return;
  }

  emit('create', trimmed, durationMinutes.value);
  task.value = '';
}

function startOrResume() {
  if (!props.latestSession) {
    return;
  }

  if (!props.latestSession.startedAt) {
    emit('start', props.latestSession.id);
  }

  startTimer();
}

function startTimer() {
  if (running.value) {
    return;
  }

  running.value = true;
  timer = setInterval(() => {
    remainingSeconds.value = Math.max(0, remainingSeconds.value - 1);
    if (remainingSeconds.value === 0 && props.latestSession) {
      completeSession();
    }
  }, 1000);
}

function pauseTimer() {
  stopTimer();
}

function stopTimer() {
  running.value = false;
  if (timer) {
    clearInterval(timer);
    timer = undefined;
  }
}

function completeSession() {
  const sessionId = props.latestSession?.id;
  if (!sessionId) {
    return;
  }

  stopTimer();
  emit('complete', sessionId);
}

function deleteSession(id: string) {
  uni.showModal({
    title: '删除番茄钟',
    content: '这条历史记录会被删除。',
    confirmText: '删除',
    confirmColor: '#8a5960',
    success: (result) => {
      if (result.confirm) {
        emit('delete', id);
      }
    }
  });
}
</script>

<template>
  <view :class="['pomodoro', { compact }]">
    <view v-if="!hasSession" class="idle-panel">
      <view class="create-panel">
        <view class="field">
          <text class="label">本轮小事</text>
          <input v-model="task" placeholder="这一轮只完成什么？" @confirm="createSession" />
        </view>
        <view class="duration-row">
          <text class="label">分钟</text>
          <input class="duration-input" type="number" :value="durationInput" @input="updateDurationInput" />
          <view class="duration-buttons">
            <button :class="{ active: durationMinutes === 15 }" @tap.stop="setDuration(15)">15</button>
            <button :class="{ active: durationMinutes === 25 }" @tap.stop="setDuration(25)">25</button>
            <button :class="{ active: durationMinutes === 45 }" @tap.stop="setDuration(45)">45</button>
          </view>
        </view>
        <button class="primary-button" @tap.stop="createSession">创建番茄钟</button>
      </view>

      <view class="history-panel">
        <view class="history-head">
          <text class="history-title">历史番茄钟</text>
          <text class="history-count">{{ sessions.length }} 轮</text>
        </view>
        <scroll-view
          v-if="historySessions.length"
          scroll-y
          class="history-list"
          :style="compact ? 'height: 64px; max-height: 64px;' : 'height: 84px; max-height: 84px;'"
        >
          <view class="history-scroll-inner">
            <view
              v-for="session in historySessions"
              :key="session.id"
              :class="['history-item', { completed: session.completed }]"
            >
              <view class="history-copy">
                <text class="history-task">{{ session.task }}</text>
                <text class="history-meta">{{ session.durationMinutes }} 分钟 · {{ session.completed ? '已完成' : '未完成' }}</text>
              </view>
              <button class="history-delete" @tap.stop="deleteSession(session.id)">删除</button>
            </view>
          </view>
        </scroll-view>
        <view v-else class="empty-history">还没有番茄钟记录</view>
      </view>
    </view>

    <view v-else class="run-panel">
      <view class="dial-shell">
        <view
          class="dial"
          :style="{ background: `conic-gradient(from -90deg, #4a90d9 0 ${progress}%, #e5edf4 ${progress}% 100%)` }"
        >
          <view class="dial-inner">
            <text class="dial-time">{{ formattedTime }}</text>
            <text class="dial-state">{{ running ? '专注中' : started ? '已暂停' : '待开始' }}</text>
          </view>
        </view>
      </view>

      <view class="session-copy">
        <text class="task">{{ latestSession?.task }}</text>
        <text class="minutes">{{ latestSession?.durationMinutes }} 分钟</text>
      </view>

      <view class="actions">
        <button v-if="!running" class="primary-action" @tap.stop="startOrResume">{{ started ? '继续' : '开始' }}</button>
        <button v-else class="secondary-action" @tap.stop="pauseTimer">暂停</button>
        <button class="complete-action" @tap.stop="completeSession">完成</button>
      </view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.pomodoro {
  display: grid;
  min-height: 0;
}

.idle-panel {
  display: grid;
  min-height: 0;
  grid-template-rows: auto auto;
  align-content: start;
  gap: 10px;
}

.create-panel {
  display: grid;
  gap: 8px;
}

.field {
  display: grid;
  gap: 5px;
}

.label {
  color: #6f7b8a;
  font-size: 12px;
}

input {
  height: 36px;
  min-height: 36px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 0 10px;
  background: #fbfdff;
  color: #202733;
  font-size: 13px;
}

.duration-row {
  display: grid;
  grid-template-columns: auto 58px minmax(0, 1fr);
  align-items: center;
  gap: 8px;
}

.duration-input {
  padding: 0 8px;
  text-align: center;
}

.duration-buttons {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 6px;
}

.duration-buttons button,
.primary-button,
.primary-action,
.secondary-action,
.complete-action {
  height: 34px;
  min-height: 34px;
  border-radius: 8px;
  font-size: 13px;
  line-height: 34px;
}

.duration-buttons button,
.secondary-action,
.complete-action {
  border: 1px solid #dce4ec;
  background: #fbfdff;
  color: #6f7b8a;
}

.duration-buttons button.active {
  border-color: rgba(74, 144, 217, 0.56);
  background: #eaf4ff;
  color: #2f72b4;
  font-weight: 750;
}

.primary-button,
.primary-action {
  background: #4a90d9;
  color: #ffffff;
  font-weight: 750;
}

.complete-action {
  border-color: rgba(25, 169, 154, 0.35);
  background: rgba(25, 169, 154, 0.09);
  color: #08796f;
  font-weight: 750;
}

.history-panel {
  display: grid;
  min-height: 0;
  grid-template-rows: auto auto;
  gap: 6px;
  border-top: 1px solid #e5edf4;
  padding-top: 8px;
  overflow: hidden;
}

.history-head {
  display: flex;
  justify-content: space-between;
  gap: 10px;
}

.history-title {
  color: #202733;
  font-size: 14px;
  font-weight: 800;
}

.history-count,
.history-meta {
  color: #6f7b8a;
  font-size: 12px;
}

.history-list {
  display: block;
  width: 100%;
  height: 84px;
  min-height: 0;
}

.history-scroll-inner {
  padding-right: 2px;
}

.history-item {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 44px;
  align-items: center;
  gap: 8px;
  border-bottom: 1px solid #e5edf4;
  padding: 6px 0;
}

.history-item.completed .history-task {
  color: #08796f;
}

.history-copy {
  display: grid;
  min-width: 0;
  gap: 2px;
}

.history-task {
  overflow: hidden;
  color: #202733;
  font-size: 13px;
  font-weight: 700;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.history-delete {
  width: 44px;
  height: 26px;
  min-height: 26px;
  border: 1px solid rgba(138, 89, 96, 0.24);
  border-radius: 8px;
  padding: 0;
  background: rgba(138, 89, 96, 0.08);
  color: #8a5960;
  font-size: 11px;
  line-height: 26px;
}

.empty-history {
  display: grid;
  place-items: center;
  border: 1px dashed #ccd9e5;
  border-radius: 8px;
  color: #6f7b8a;
  font-size: 12px;
}

.run-panel {
  display: grid;
  min-height: 228px;
  grid-template-rows: minmax(0, 1fr) auto auto;
  gap: 9px;
}

.dial-shell {
  display: grid;
  min-height: 0;
  place-items: center;
}

.dial {
  display: grid;
  width: 154px;
  height: 154px;
  place-items: center;
  border-radius: 50%;
}

.dial-inner {
  display: grid;
  width: 112px;
  height: 112px;
  place-items: center;
  align-content: center;
  border-radius: 50%;
  background: #ffffff;
}

.dial-time {
  color: #202733;
  font-size: 30px;
  font-weight: 800;
  font-variant-numeric: tabular-nums;
  line-height: 1;
}

.dial-state,
.minutes {
  color: #6f7b8a;
  font-size: 12px;
}

.session-copy {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 10px;
}

.task {
  min-width: 0;
  overflow: hidden;
  color: #202733;
  font-size: 15px;
  font-weight: 700;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.compact .idle-panel,
.compact .run-panel {
  gap: 6px;
}

.compact .history-list {
  height: 64px;
}

.compact .dial {
  width: 118px;
  height: 118px;
}

.compact .dial-inner {
  width: 88px;
  height: 88px;
}

.compact .dial-time {
  font-size: 24px;
}

.compact input,
.compact .duration-buttons button,
.compact .primary-button,
.compact .primary-action,
.compact .secondary-action,
.compact .complete-action {
  height: 32px;
  min-height: 32px;
  line-height: 32px;
}
</style>
