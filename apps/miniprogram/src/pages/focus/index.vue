<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue';
import { onHide, onShow } from '@dcloudio/uni-app';
import AnchorCard from '@/components/AnchorCard.vue';
import CoverScreenMode from '@/components/CoverScreenMode.vue';
import MiniProgramShell from '@/components/MiniProgramShell.vue';
import ScrapItem from '@/components/ScrapItem.vue';
import { useViewportProfile } from '@/composables/useViewportProfile';
import { todayISODate } from '@/domain/date';
import { getActualFocusSeconds, getFocusTiming } from '@/domain/focus';
import type { FocusSession } from '@/domain/types';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const { isCoverScreen } = useViewportProfile();
const anchorTitle = ref('');
const distraction = ref('');
const focusTask = ref('');
const focusDuration = ref(25);
const focusDurationInput = ref('25');
const nowTick = ref(Date.now());
const showFocusHistory = ref(false);
const editingHistoryId = ref<string>();
const historyTaskValue = ref('');
let displayTimer: ReturnType<typeof setInterval> | undefined;
const focusSessionsForDate = computed(() =>
  store.state.focusSessions.filter((session) => session.date === store.activeDate)
);
const focusHistorySessions = computed(() => focusSessionsForDate.value.filter((session) => session.completed));
const latestSession = computed(() => [...focusSessionsForDate.value].reverse().find((session) => !session.completed));
const distractions = computed(() => store.allScraps.filter((scrap) => scrap.category === '分心' && scrap.date === store.activeDate));
const canAddAnchor = computed(() => store.todayAnchors.length < 2);
const hasTwoAnchors = computed(() => store.todayAnchors.length >= 2);
const completedFocusSeconds = computed(() =>
  focusHistorySessions.value
    .reduce((total, session) => total + getActualFocusSeconds(session), 0)
);
const completedFocusLabel = computed(() => {
  const minutes = Math.floor(completedFocusSeconds.value / 60);
  const hours = Math.floor(minutes / 60);
  return hours ? `${hours} 小时 ${minutes % 60} 分钟` : `${minutes} 分钟`;
});
const focusTiming = computed(() =>
  latestSession.value ? getFocusTiming(latestSession.value, new Date(nowTick.value).toISOString()) : undefined
);
const focusRunning = computed(() => latestSession.value?.status === 'running');
const focusStarted = computed(() => Boolean(latestSession.value?.startedAt));
const focusElapsed = computed(() => Boolean(focusTiming.value?.elapsed && focusStarted.value));
const remainingSeconds = computed(() => focusTiming.value?.remainingSeconds ?? focusDuration.value * 60);
const formattedFocusTime = computed(() => {
  const minutes = Math.floor(remainingSeconds.value / 60);
  const seconds = remainingSeconds.value % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
});
const focusProgress = computed(() => {
  const totalSeconds = focusTiming.value?.totalSeconds ?? Math.max(1, focusDuration.value * 60);
  const elapsedSeconds = focusTiming.value?.elapsedSeconds ?? totalSeconds - remainingSeconds.value;
  return Math.max(0, Math.min(100, Math.round((elapsedSeconds / totalSeconds) * 100)));
});
const focusStateLabel = computed(() => {
  if (focusElapsed.value) return '已到点';
  if (focusRunning.value) return '专注中';
  if (latestSession.value?.status === 'paused') return '已暂停';
  return focusStarted.value ? '已暂停' : '待开始';
});
const focusDialStyle = computed(() => ({
  background: `conic-gradient(from -90deg, #4a90d9 0 ${focusProgress.value}%, #e5edf4 ${focusProgress.value}% 100%)`
}));

function submitAnchor() {
  if (!anchorTitle.value.trim()) {
    return;
  }

  try {
    store.addAnchor(anchorTitle.value);
    anchorTitle.value = '';
  } catch (error) {
    uni.showToast({
      title: error instanceof Error ? error.message : '无法添加锚点',
      icon: 'none'
    });
  }
}

function recordDistraction() {
  if (!distraction.value.trim()) {
    return;
  }

  store.addScrap('分心', distraction.value);
  distraction.value = '';
}

function clampFocusDuration(value: number) {
  return Math.max(1, Math.min(180, Math.round(value)));
}

function setFocusDuration(value: number) {
  focusDuration.value = clampFocusDuration(value);
  focusDurationInput.value = String(focusDuration.value);
}

function updateFocusDuration(event: Event) {
  const value =
    'detail' in event && typeof event.detail === 'object' && event.detail && 'value' in event.detail
      ? String(event.detail.value)
      : (event.target as HTMLInputElement | null)?.value ?? '';
  focusDurationInput.value = value;
  const parsed = Number(value);
  if (Number.isFinite(parsed) && parsed > 0) setFocusDuration(parsed);
}

function createFocus() {
  const trimmedTask = focusTask.value.trim();
  if (!trimmedTask) return;
  store.createFocus(trimmedTask, focusDuration.value);
  focusTask.value = '';
}

function startFocus() {
  if (!latestSession.value) return;
  store.startFocus(latestSession.value.id);
  refreshFocusClock();
}

function pauseFocus() {
  if (!latestSession.value) return;
  store.pauseFocus(latestSession.value.id);
  refreshFocusClock();
}

function completeFocus() {
  if (!latestSession.value) return;
  store.completeFocus(latestSession.value.id);
  stopDisplayTimer();
}

function abandonFocus() {
  if (!latestSession.value) return;
  store.abandonFocus(latestSession.value.id);
  stopDisplayTimer();
}

function extendFocus() {
  if (!latestSession.value) return;
  store.extendFocus(latestSession.value.id, 5);
  refreshFocusClock();
}

function refreshFocusClock() {
  nowTick.value = Date.now();
  if (latestSession.value?.status === 'running') startDisplayTimer();
}

function startDisplayTimer() {
  if (displayTimer) return;
  displayTimer = setInterval(() => {
    nowTick.value = Date.now();
  }, 1000);
}

function stopDisplayTimer() {
  if (!displayTimer) return;
  clearInterval(displayTimer);
  displayTimer = undefined;
}

function formatHistoryMinutes(session: FocusSession) {
  return `${Math.floor(getActualFocusSeconds(session) / 60)} 分钟`;
}

function startEditingHistory(session: FocusSession) {
  editingHistoryId.value = session.id;
  historyTaskValue.value = session.task;
}

function saveHistory() {
  if (!editingHistoryId.value || !historyTaskValue.value.trim()) return;
  store.updateFocusTask(editingHistoryId.value, historyTaskValue.value);
  editingHistoryId.value = undefined;
}

function openFocusHistory() {
  showFocusHistory.value = true;
}

function closeFocusHistory() {
  showFocusHistory.value = false;
  editingHistoryId.value = undefined;
  historyTaskValue.value = '';
}

function deleteHistory(id: string) {
  uni.showModal({
    title: '删除番茄钟',
    content: '这条专注记录会被删除。',
    confirmText: '删除',
    confirmColor: '#8a5960',
    success: (result) => {
      if (result.confirm) store.deleteFocus(id);
    }
  });
}

function handlePageHide() {
  stopDisplayTimer();
  closeFocusHistory();
}

watch(
  () => [latestSession.value?.id, latestSession.value?.status] as const,
  ([, status]) => {
    nowTick.value = Date.now();
    if (status === 'running') startDisplayTimer();
    else stopDisplayTimer();
  },
  { immediate: true }
);

onMounted(() => {
  store.hydrate();
  store.setActiveDate(todayISODate());
});

onShow(refreshFocusClock);
onHide(handlePageHide);
onUnmounted(handlePageHide);
</script>

<template>
  <view class="page-root">
    <CoverScreenMode v-if="isCoverScreen" />
    <MiniProgramShell v-else active="focus">
      <view :class="['focus-view', { 'two-anchors': hasTwoAnchors }]">
      <section class="card focus-anchor-card">
        <view class="section-head">
          <view>
            <text class="date">{{ store.activeDate }} · 本地存储</text>
            <text class="page-title">专注</text>
          </view>
        </view>
        <scroll-view v-if="store.todayAnchors.length" scroll-y class="focus-anchor-list">
          <view class="anchor-scroll-inner">
            <AnchorCard
              v-for="anchor in store.todayAnchors"
              :key="anchor.id"
              :anchor="anchor"
              @progress="store.setAnchorProgress"
              @rename="store.renameAnchor"
              @delete="store.deleteAnchor"
            />
          </view>
        </scroll-view>
        <view v-else class="empty-list">还没有锚点</view>
        <view v-if="canAddAnchor" class="anchor-add">
          <input v-model="anchorTitle" placeholder="新增锚点，最多 2 条" @confirm="submitAnchor" />
          <button class="secondary" @tap.stop="submitAnchor">新增</button>
        </view>
      </section>

      <section class="card focus-history-card">
        <text class="history-card-value">今日已专注 {{ completedFocusLabel }}</text>
        <button class="history-open-action" data-eventsync="true" @tap.stop="openFocusHistory">专注历史</button>
      </section>

      <section class="card pomodoro-card">
        <view v-if="!latestSession" class="focus-setup">
          <view class="focus-field">
            <text class="field-label">本轮小事</text>
            <input v-model="focusTask" placeholder="这一轮只完成什么？" @confirm="createFocus" />
          </view>
          <view class="duration-row">
            <text class="field-label">分钟</text>
            <input class="duration-input" type="number" :value="focusDurationInput" @input="updateFocusDuration" />
            <view class="duration-buttons">
              <button :class="{ active: focusDuration === 15 }" data-eventsync="true" @tap.stop="setFocusDuration(15)">15</button>
              <button :class="{ active: focusDuration === 25 }" data-eventsync="true" @tap.stop="setFocusDuration(25)">25</button>
              <button :class="{ active: focusDuration === 45 }" data-eventsync="true" @tap.stop="setFocusDuration(45)">45</button>
            </view>
          </view>
          <button class="create-focus-action" data-eventsync="true" @tap.stop="createFocus">创建番茄钟</button>
        </view>

        <view v-else class="focus-running">
          <view class="focus-dial" :style="focusDialStyle">
            <view class="focus-dial-inner">
              <text class="focus-time">{{ formattedFocusTime }}</text>
              <text class="focus-state">{{ focusStateLabel }}</text>
            </view>
          </view>
          <view class="focus-session-copy">
            <text class="focus-task">{{ latestSession.task }}</text>
            <text class="focus-minutes">{{ latestSession.durationMinutes }} 分钟</text>
          </view>
          <view class="focus-actions">
            <button v-if="focusElapsed" class="focus-primary" data-eventsync="true" @tap.stop="extendFocus">再 5 分钟</button>
            <button v-else-if="!focusRunning" class="focus-primary" data-eventsync="true" @tap.stop="startFocus">
              {{ focusStarted ? '继续' : '开始' }}
            </button>
            <button v-else class="focus-secondary" data-eventsync="true" @tap.stop="pauseFocus">暂停</button>
            <button class="focus-complete" data-eventsync="true" @tap.stop="completeFocus">完成</button>
            <button class="focus-abandon" data-eventsync="true" @tap.stop="abandonFocus">放弃</button>
          </view>
        </view>
      </section>

      <section class="card distraction-card">
        <view class="section-head">
          <text class="section-title-main">分心捕捉</text>
        </view>
        <view class="distraction-form">
          <input v-model="distraction" placeholder="先记下，不打断计时" @confirm="recordDistraction" />
          <button class="secondary" @tap.stop="recordDistraction">记录</button>
        </view>
        <scroll-view v-if="distractions.length" scroll-y class="distraction-list">
          <ScrapItem
            v-for="scrap in distractions"
            :key="scrap.id"
            :scrap="scrap"
            :todo-time="store.getLinkedTodoTime(scrap)"
            hide-category
            @update="store.updateScrap"
            @delete="store.deleteScrap"
          />
        </scroll-view>
        <view v-else class="empty-line">暂无分心记录</view>
      </section>
      </view>

      <view v-if="showFocusHistory" class="history-overlay" data-eventsync="true" @tap="closeFocusHistory">
        <view class="history-modal" @tap.stop>
          <view class="history-modal-head">
            <view>
              <text class="history-modal-title">专注历史</text>
              <text class="history-modal-subtitle">只保留当天的记录</text>
            </view>
            <button class="history-close-action" data-eventsync="true" @tap.stop="closeFocusHistory">关闭</button>
          </view>

          <scroll-view v-if="focusHistorySessions.length" scroll-y class="history-modal-list">
            <view v-for="session in focusHistorySessions" :key="session.id" class="history-item">
              <view class="history-copy">
                <input v-if="editingHistoryId === session.id" v-model="historyTaskValue" @confirm="saveHistory" />
                <text v-else class="history-task">{{ session.task }}</text>
                <text class="history-meta">{{ formatHistoryMinutes(session) }}</text>
              </view>
              <view class="history-actions">
                <button class="history-action" data-eventsync="true" @tap.stop="editingHistoryId === session.id ? saveHistory() : startEditingHistory(session)">
                  {{ editingHistoryId === session.id ? '保存' : '修改' }}
                </button>
                <button class="history-action danger" data-eventsync="true" @tap.stop="deleteHistory(session.id)">删除</button>
              </view>
            </view>
          </scroll-view>
          <view v-else class="history-empty">今天还没有专注记录</view>
        </view>
      </view>
    </MiniProgramShell>
  </view>
</template>

<style scoped lang="scss">
.page-root {
  height: 100vh;
  min-height: 100vh;
  overflow: hidden;
}

.focus-view {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: auto auto auto minmax(132px, auto);
  align-content: start;
  gap: 10px;
  overflow-y: auto;
  padding: 12px;
}

.focus-view.two-anchors {
  grid-template-rows: auto auto auto minmax(132px, auto);
}

.card {
  min-height: 0;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.93);
  box-shadow: 0 10px 28px rgba(42, 63, 88, 0.08);
}

.focus-anchor-card {
  display: grid;
  max-height: 220px;
  grid-template-rows: auto minmax(0, 1fr) auto;
  gap: 5px;
  overflow: hidden;
  padding: 9px 12px;
}

.two-anchors .focus-anchor-card {
  max-height: 236px;
}

.section-head {
  display: flex;
  justify-content: space-between;
  gap: 12px;
}

.date {
  color: #6f7b8a;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
}

.page-title {
  display: block;
  margin-top: 3px;
  color: #202733;
  font-family: Georgia, "Times New Roman", "Songti SC", serif;
  font-size: 28px;
  font-weight: 700;
  line-height: 1.1;
}

.section-title-main {
  color: #202733;
  font-size: 17px;
  font-weight: 800;
}

.focus-anchor-list,
.distraction-list {
  height: 100%;
  min-height: 0;
}

.anchor-scroll-inner {
  display: grid;
  gap: 4px;
}

.anchor-add,
.distraction-form {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 8px;
}

input {
  min-width: 0;
  height: 36px;
  min-height: 36px;
  border: 1px solid #dde7ef;
  border-radius: 8px;
  padding: 0 10px;
  background: #fbfdff;
  color: #202733;
  font-size: 13px;
}

.pomodoro-card {
  display: grid;
  width: 100%;
  min-height: 0;
  overflow: visible;
  padding: 12px;
}

.focus-setup,
.focus-running {
  display: grid;
  width: 100%;
  gap: 8px;
}

.focus-field {
  display: grid;
  gap: 5px;
}

.field-label,
.focus-state,
.focus-minutes,
.history-meta {
  color: #6f7b8a;
  font-size: 12px;
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

.duration-buttons,
.focus-actions {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.duration-buttons button,
.create-focus-action,
.focus-primary,
.focus-secondary,
.focus-complete,
.focus-abandon {
  height: 34px;
  min-height: 34px;
  border-radius: 8px;
  font-size: 13px;
  line-height: 34px;
}

.duration-buttons button,
.focus-secondary {
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

.create-focus-action,
.focus-primary {
  background: #4a90d9;
  color: #ffffff;
  font-weight: 750;
}

.focus-running {
  grid-template-rows: auto auto auto;
  justify-items: stretch;
}

.focus-dial {
  display: grid;
  width: 154px;
  height: 154px;
  place-self: center;
  place-items: center;
  border-radius: 50%;
}

.focus-dial-inner {
  display: grid;
  width: 112px;
  height: 112px;
  place-items: center;
  align-content: center;
  border-radius: 50%;
  background: #ffffff;
}

.focus-time {
  color: #202733;
  font-size: 30px;
  font-weight: 800;
  font-variant-numeric: tabular-nums;
  line-height: 1;
}

.focus-session-copy {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 10px;
}

.focus-task {
  min-width: 0;
  overflow: hidden;
  color: #202733;
  font-size: 15px;
  font-weight: 700;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.focus-complete {
  border: 1px solid rgba(25, 169, 154, 0.35);
  background: rgba(25, 169, 154, 0.09);
  color: #08796f;
  font-weight: 750;
}

.focus-abandon {
  border: 1px solid rgba(138, 89, 96, 0.24);
  background: rgba(138, 89, 96, 0.08);
  color: #8a5960;
}

.focus-history-card {
  display: grid;
  min-height: 72px;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
}

.history-card-value {
  display: block;
  color: #202733;
  font-size: 15px;
  font-weight: 750;
}

.history-open-action {
  height: 32px;
  min-height: 32px;
  flex: 0 0 auto;
  border: 0;
  border-radius: 8px;
  margin: 0;
  padding: 0 10px;
  background: #eaf4ff;
  color: #2f72b4;
  font-size: 12px;
  font-weight: 750;
  line-height: 32px;
}

.history-overlay {
  position: fixed;
  z-index: 40;
  inset: 0;
  display: grid;
  align-items: end;
  padding: 12px;
  background: rgba(32, 39, 51, 0.38);
}

.history-modal {
  display: grid;
  width: 100%;
  max-height: 68vh;
  min-height: 236px;
  grid-template-rows: auto minmax(0, 1fr);
  gap: 12px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 16px;
  background: #ffffff;
  box-shadow: 0 18px 48px rgba(32, 39, 51, 0.2);
}

.history-modal-head {
  display: flex;
  min-width: 0;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.history-modal-title,
.history-modal-subtitle {
  display: block;
}

.history-modal-title {
  color: #202733;
  font-size: 19px;
  font-weight: 800;
}

.history-modal-subtitle {
  margin-top: 4px;
  color: #6f7b8a;
  font-size: 12px;
}

.history-modal-list {
  height: 100%;
  min-height: 0;
}

.history-close-action {
  height: 32px;
  min-height: 32px;
  border: 0;
  border-radius: 8px;
  margin: 0;
  padding: 0 11px;
  background: #eaf4ff;
  color: #2f72b4;
  font-size: 12px;
  font-weight: 750;
  line-height: 32px;
}

.history-empty {
  display: grid;
  place-items: center;
  border: 1px dashed #ccd9e5;
  border-radius: 8px;
  color: #6f7b8a;
  font-size: 13px;
}

.history-item,
.history-actions {
  display: flex;
  min-width: 0;
  align-items: center;
}

.history-item {
  justify-content: space-between;
  gap: 10px;
  border-bottom: 1px solid #e5edf4;
  padding: 8px 0;
}

.history-copy {
  display: grid;
  min-width: 0;
  gap: 3px;
}

.history-task {
  overflow: hidden;
  color: #202733;
  font-size: 14px;
  font-weight: 750;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.history-actions {
  flex: 0 0 auto;
  gap: 5px;
}

.history-action {
  height: 30px;
  min-height: 30px;
  border: 0;
  border-radius: 8px;
  margin: 0;
  padding: 0 10px;
  background: #eaf4ff;
  color: #2f72b4;
  font-size: 12px;
  font-weight: 750;
  line-height: 30px;
}

.history-action.danger {
  background: rgba(138, 89, 96, 0.1);
  color: #8a5960;
}

.two-anchors .pomodoro-card {
  padding: 8px;
}

.two-anchors .focus-dial {
  width: 112px;
  height: 112px;
}

.two-anchors .focus-dial-inner {
  width: 82px;
  height: 82px;
}

.two-anchors .focus-time {
  font-size: 23px;
}

.distraction-card {
  display: grid;
  min-height: 132px;
  max-height: 210px;
  grid-template-rows: auto auto minmax(0, 1fr);
  gap: 8px;
  overflow: hidden;
  padding: 12px;
}

.two-anchors .distraction-card {
  gap: 5px;
  padding: 8px;
}

.empty-list,
.empty-line {
  display: grid;
  place-items: center;
  border: 1px dashed #ccd9e5;
  border-radius: 8px;
  color: #6f7b8a;
  font-size: 13px;
}

.empty-line {
  min-height: 28px;
}

.secondary {
  height: 36px;
  min-height: 36px;
  border: 0;
  border-radius: 8px;
  padding: 0 11px;
  background: #eaf4ff;
  color: #2f72b4;
  font-size: 13px;
  font-weight: 750;
  line-height: 36px;
}

@media (max-width: 360px) {
  .focus-view {
    grid-template-rows: auto auto auto minmax(128px, auto);
    gap: 8px;
    padding: 10px;
  }

  .focus-view.two-anchors {
    grid-template-rows: auto auto auto minmax(128px, auto);
  }

  .focus-anchor-card,
  .distraction-card {
    padding: 8px 10px;
  }

  .pomodoro-card,
  .two-anchors .pomodoro-card {
    padding: 8px;
  }

  .duration-row {
    grid-template-columns: auto 48px minmax(0, 1fr);
    gap: 6px;
  }

  .duration-buttons,
  .focus-actions {
    gap: 5px;
  }

  .focus-dial {
    width: 126px;
    height: 126px;
  }

  .focus-dial-inner {
    width: 94px;
    height: 94px;
  }

  .focus-time {
    font-size: 25px;
  }

  .page-title {
    font-size: 25px;
  }

  .section-title-main {
    font-size: 16px;
  }

  .anchor-add,
  .distraction-form {
    grid-template-columns: minmax(0, 1fr) 52px;
    gap: 6px;
  }

  .secondary {
    padding: 0 8px;
  }
}

@media (max-height: 760px) {
  .focus-view {
    height: 100%;
    grid-template-rows: auto auto auto minmax(128px, auto);
    overflow-y: auto;
  }

  .focus-view.two-anchors {
    grid-template-rows: auto auto auto minmax(128px, auto);
  }

  .focus-anchor-card {
    max-height: 176px;
  }

  .two-anchors .focus-anchor-card {
    max-height: 196px;
  }

  .distraction-card {
    min-height: 128px;
    max-height: 176px;
  }
}
</style>
