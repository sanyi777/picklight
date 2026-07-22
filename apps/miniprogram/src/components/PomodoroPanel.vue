<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue';
import { getFocusTiming } from '@/domain/focus';
import type { FocusSession } from '@/domain/types';
import { usePicklightStore } from '@/stores/usePicklightStore';

const props = withDefaults(
  defineProps<{
    latestSession?: FocusSession;
    compact?: boolean;
  }>(),
  {
    compact: false
  }
);

const store = usePicklightStore();
const task = ref('');
const durationMinutes = ref(25);
const durationInput = ref('25');
const nowTick = ref(Date.now());
let timer: ReturnType<typeof setInterval> | undefined;

const hasSession = computed(() => Boolean(props.latestSession));
const started = computed(() => Boolean(props.latestSession?.startedAt));
const running = computed(() => props.latestSession?.status === 'running');
const timing = computed(() =>
  props.latestSession ? getFocusTiming(props.latestSession, new Date(nowTick.value).toISOString()) : undefined
);
const remainingSeconds = computed(() => timing.value?.remainingSeconds ?? durationMinutes.value * 60);
const elapsed = computed(() => Boolean(timing.value?.elapsed && props.latestSession?.startedAt && !props.latestSession.completed));
const formattedTime = computed(() => {
  const minutes = Math.floor(remainingSeconds.value / 60);
  const seconds = remainingSeconds.value % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
});
const progress = computed(() => {
  const totalSeconds = timing.value?.totalSeconds ?? Math.max(1, durationMinutes.value * 60);
  const elapsedSeconds = timing.value?.elapsedSeconds ?? totalSeconds - remainingSeconds.value;
  return Math.max(0, Math.min(100, Math.round((elapsedSeconds / totalSeconds) * 100)));
});
const stateLabel = computed(() => {
  if (elapsed.value) {
    return '已到点';
  }

  if (running.value) {
    return '专注中';
  }

  if (props.latestSession?.status === 'paused') {
    return '已暂停';
  }

  return started.value ? '已暂停' : '待开始';
});

watch(
  () => [props.latestSession?.id, props.latestSession?.status] as const,
  ([, status]) => {
    nowTick.value = Date.now();
    if (status === 'running') {
      startDisplayTicker();
    } else {
      stopTimer();
    }
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
    nowTick.value = Date.now();
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

function createSession() {
  const trimmed = task.value.trim();
  if (!trimmed) {
    return;
  }

  store.createFocus(trimmed, durationMinutes.value);
  task.value = '';
}

function startOrResume() {
  if (!props.latestSession) {
    return;
  }

  store.startFocus(props.latestSession.id);
  startDisplayTicker();
}

function startDisplayTicker() {
  if (timer) {
    return;
  }

  timer = setInterval(() => {
    nowTick.value = Date.now();
  }, 1000);
}

function pauseTimer() {
  const sessionId = props.latestSession?.id;
  if (!sessionId) {
    return;
  }

  stopTimer();
  nowTick.value = Date.now();
  store.pauseFocus(sessionId);
}

function stopTimer() {
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
  store.completeFocus(sessionId);
}

function abandonSession() {
  const sessionId = props.latestSession?.id;
  if (!sessionId) return;
  stopTimer();
  store.abandonFocus(sessionId);
}

function extendSession() {
  const sessionId = props.latestSession?.id;
  if (!sessionId) {
    return;
  }

  store.extendFocus(sessionId, 5);
  nowTick.value = Date.now();
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
        <button class="primary-button" data-eventsync="true" @tap.stop="createSession">创建番茄钟</button>
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
            <text class="dial-state">{{ stateLabel }}</text>
          </view>
        </view>
      </view>

      <view class="session-copy">
        <text class="task">{{ latestSession?.task }}</text>
        <text class="minutes">{{ latestSession?.durationMinutes }} 分钟</text>
      </view>

      <view class="actions">
        <button v-if="elapsed" class="primary-action" data-eventsync="true" @tap.stop="extendSession">再 5 分钟</button>
        <button v-else-if="!running" class="primary-action" data-eventsync="true" @tap.stop="startOrResume">{{ started ? '继续' : '开始' }}</button>
        <button v-else class="secondary-action" data-eventsync="true" @tap.stop="pauseTimer">暂停</button>
        <button class="complete-action" data-eventsync="true" @tap.stop="completeSession">完成</button>
        <button class="abandon-action" data-eventsync="true" @tap.stop="abandonSession">放弃</button>
      </view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.pomodoro {
  display: grid;
  width: 100%;
  height: 100%;
  min-height: 0;
}

.idle-panel {
  display: grid;
  width: 100%;
  height: 100%;
  min-height: 0;
  grid-template-rows: auto auto;
  align-content: start;
  gap: 10px;
}

.create-panel {
  display: grid;
  width: 100%;
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

.run-panel {
  display: grid;
  min-height: 206px;
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
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.abandon-action {
  height: 34px;
  min-height: 34px;
  border: 1px solid rgba(138, 89, 96, 0.24);
  border-radius: 8px;
  background: rgba(138, 89, 96, 0.08);
  color: #8a5960;
  font-size: 13px;
  line-height: 34px;
}

@media (max-width: 360px) {
  .idle-panel {
    gap: 8px;
  }

  .duration-row {
    grid-template-columns: auto 48px minmax(0, 1fr);
    gap: 6px;
  }

  .duration-buttons {
    gap: 4px;
  }

  .run-panel {
    min-height: 198px;
    gap: 7px;
  }

  .dial {
    width: 126px;
    height: 126px;
  }

  .dial-inner {
    width: 94px;
    height: 94px;
  }

  .dial-time {
    font-size: 25px;
  }

  .task {
    font-size: 14px;
  }

  .duration-buttons button,
  .primary-button,
  .primary-action,
  .secondary-action,
  .complete-action {
    font-size: 12px;
  }
}

.compact .idle-panel,
.compact .run-panel {
  gap: 6px;
}

.compact .run-panel {
  min-height: 178px;
}

.compact .dial {
  width: 108px;
  height: 108px;
}

.compact .dial-inner {
  width: 80px;
  height: 80px;
}

.compact .dial-time {
  font-size: 22px;
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
