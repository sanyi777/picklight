<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import AnchorCard from '@/components/AnchorCard.vue';
import CoverScreenMode from '@/components/CoverScreenMode.vue';
import MiniProgramShell from '@/components/MiniProgramShell.vue';
import ScrapComposer from '@/components/ScrapComposer.vue';
import TodoTimePicker from '@/components/TodoTimePicker.vue';
import TodoItem from '@/components/TodoItem.vue';
import WeekStrip from '@/components/WeekStrip.vue';
import { parseISODate, todayISODate } from '@/domain/date';
import { useViewportProfile } from '@/composables/useViewportProfile';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const { isCoverScreen } = useViewportProfile();
const todoContent = ref('');
const todoHasTime = ref(false);
const todoTime = ref('09:00');
const anchorTitle = ref('');
const showGuide = ref(false);
const showQuickCapture = ref(false);
const guideStep = ref(0);
const guideHighlight = ref<'capture' | 'todo' | null>(null);
const showDataPanel = ref(false);
const backupText = ref('');
const importText = ref('');
const weekStartDate = todayISODate();
const currentFocusLabel = computed(() => store.currentAnchor?.title ?? '设置本轮专注事项');
const scheduleTitle = computed(() => {
  if (store.activeDate === weekStartDate) {
    return '今日待办';
  }

  const date = parseISODate(store.activeDate);
  return `${date.getMonth() + 1}月${date.getDate()}日待办`;
});
const canAddAnchor = computed(() => store.todayAnchors.length < 2);
const guideCopy = computed(() => [
  { title: '先记录一件零碎', description: '点击下方“快速捕捉”，随便记下一条现在占着你脑子的事。', action: '去记录' },
  { title: '再放进今天的待办', description: '在今日待办下新增一项，让它留在你接下来会看见的位置。', action: '去添加' },
  { title: '开始一轮专注', description: '去专注页写下这轮要做的小事；分心时也可以随手记下。', action: '去专注' }
][guideStep.value]);

onMounted(() => {
  store.hydrate();
  showGuide.value = !uni.getStorageSync('picklight-onboarding-v2');
});

function openGuide() {
  guideStep.value = 0;
  guideHighlight.value = null;
  showGuide.value = true;
}

function closeGuide() {
  showGuide.value = false;
  guideHighlight.value = null;
  uni.setStorageSync('picklight-onboarding-v2', 'seen');
}

function continueGuide() {
  showGuide.value = false;
  if (guideStep.value === 0) {
    guideHighlight.value = 'capture';
    return;
  }
  if (guideStep.value === 1) {
    guideHighlight.value = 'todo';
    return;
  }
  closeGuide();
  goFocus();
}

function submitQuickScrap(category: Parameters<typeof store.addScrap>[0], content: string, time = '') {
  store.addScrap(category, content, time);
  showQuickCapture.value = false;
  if (guideHighlight.value === 'capture') {
    guideHighlight.value = null;
    guideStep.value = 1;
    showGuide.value = true;
  }
}

function openQuickCapture() {
  showQuickCapture.value = true;
}

function closeQuickCapture() {
  showQuickCapture.value = false;
}

function submitAnchor() {
  if (!anchorTitle.value.trim()) return;
  try {
    store.addAnchor(anchorTitle.value);
    anchorTitle.value = '';
  } catch (error) {
    uni.showToast({ title: error instanceof Error ? error.message : '无法添加锚点', icon: 'none' });
  }
}

function goFocus() {
  uni.redirectTo({ url: '/pages/focus/index' });
}

function submitTodo() {
  if (!todoContent.value.trim()) {
    return;
  }

  store.addTodo(todoContent.value, todoHasTime.value ? todoTime.value : '');
  todoContent.value = '';
  todoHasTime.value = false;
  todoTime.value = '09:00';
  if (guideHighlight.value === 'todo') {
    guideHighlight.value = null;
    guideStep.value = 2;
    showGuide.value = true;
  }
}

function openDataPanel() {
  backupText.value = store.exportBackupText();
  importText.value = '';
  showDataPanel.value = true;
}

function closeDataPanel() {
  showDataPanel.value = false;
}

function refreshBackupText() {
  backupText.value = store.exportBackupText();
  uni.showToast({
    title: '已刷新',
    icon: 'success'
  });
}

function copyBackupText() {
  backupText.value = store.exportBackupText();
  uni.setClipboardData({
    data: backupText.value,
    success: () => {
      uni.showToast({
        title: '已复制备份',
        icon: 'success'
      });
    }
  });
}

function pasteImportText() {
  uni.getClipboardData({
    success: (result) => {
      importText.value = result.data;
      uni.showToast({
        title: '已粘贴',
        icon: 'success'
      });
    }
  });
}

function confirmImportData() {
  const raw = importText.value.trim();
  if (!raw) {
    uni.showToast({
      title: '请先粘贴备份',
      icon: 'none'
    });
    return;
  }

  uni.showModal({
    title: '导入数据',
    content: '导入会合并到当前本地数据；内容完全相同的记录会保留本地版本。确认继续吗？',
    confirmText: '导入',
    confirmColor: '#2f72b4',
    success: (result) => {
      if (!result.confirm) {
        return;
      }

      try {
        store.importBackupText(raw);
        backupText.value = store.exportBackupText();
        importText.value = '';
        showDataPanel.value = false;
        uni.showToast({
          title: '导入成功',
          icon: 'success'
        });
      } catch (error) {
        uni.showModal({
          title: '导入失败',
          content: error instanceof Error ? error.message : '备份内容无法识别',
          showCancel: false,
          confirmText: '知道了'
        });
      }
    }
  });
}

function confirmResetData() {
  uni.showModal({
    title: '清空数据',
    content: '会清空待办、零碎、锚点和番茄钟历史，确认继续吗？',
    confirmText: '清空',
    confirmColor: '#8a5960',
    success: (result) => {
      if (result.confirm) {
        store.resetAllData();
        todoContent.value = '';
        backupText.value = store.exportBackupText();
        uni.showToast({
          title: '已清空',
          icon: 'success'
        });
      }
    }
  });
}
</script>

<template>
  <view class="page-root">
    <CoverScreenMode v-if="isCoverScreen" />
    <MiniProgramShell v-else active="home">
      <view class="home-view">
      <section class="card schedule-card">
        <view class="page-head">
          <view class="title-stack">
            <text class="date">{{ store.activeDate }} · 本地存储</text>
            <text class="page-title">{{ scheduleTitle }}</text>
          </view>
          <view class="head-actions">
            <button class="guide-action" @tap.stop="openGuide">指引</button>
            <button class="data-action" @tap.stop="openDataPanel">数据</button>
          </view>
        </view>

        <view v-if="store.activeDate === weekStartDate" class="anchor-zone">
          <AnchorCard
            v-for="anchor in store.todayAnchors"
            :key="anchor.id"
            :anchor="anchor"
            @progress="store.setAnchorProgress"
            @rename="store.renameAnchor"
            @delete="store.deleteAnchor"
          />
          <view v-if="canAddAnchor" class="anchor-add">
            <input v-model="anchorTitle" placeholder="新增今日锚点，最多 2 条" @confirm="submitAnchor" />
            <button class="secondary" @tap.stop="submitAnchor">新增</button>
          </view>
        </view>

        <scroll-view v-if="store.todayTodos.length" scroll-y class="schedule-pages">
          <view class="todo-scroll-inner">
            <TodoItem
              v-for="todo in store.todayTodos"
              :key="todo.id"
              :todo="todo"
              @toggle="store.setTodoCompleted"
            />
          </view>
        </scroll-view>
        <view v-else class="empty-plan">这一天暂时没有待办</view>

        <view :class="['home-todo-create', { 'guide-target': guideHighlight === 'todo' }]">
          <view class="home-add-plan">
            <input v-model="todoContent" placeholder="添加一条待办" @confirm="submitTodo" />
            <button class="secondary" @click="submitTodo">添加</button>
          </view>
          <TodoTimePicker v-model:has-time="todoHasTime" v-model:time="todoTime" />
        </view>

        <WeekStrip
          :start-date="weekStartDate"
          :active-date="store.activeDate"
          :todos="store.state.todos"
          @select="store.setActiveDate"
        />
      </section>

      <section class="quick-row">
        <view :class="['card', 'quick-card', 'quick-capture-card', { 'guide-target': guideHighlight === 'capture' }]">
          <text class="quick-title">快速捕捉</text>
          <text class="quick-copy">先把想法放下，不必立刻整理。</text>
          <button class="quick-capture-action" @tap.stop="openQuickCapture">记录现在的想法</button>
        </view>

        <view class="card quick-card quick-focus-card">
          <text class="quick-title">快速番茄钟</text>
          <view class="timer-mini">
            <view class="ring" />
            <view class="timer-copy">
              <text class="timer">25:00</text>
              <text class="focus-label">{{ currentFocusLabel }}</text>
            </view>
          </view>
          <button class="primary tomato-action" @click="goFocus">设置</button>
        </view>
      </section>

      <view v-if="showGuide" class="guide-overlay">
        <view class="guide-panel">
          <text class="guide-step">第 {{ guideStep + 1 }} / 3 步</text>
          <text class="guide-title">{{ guideCopy.title }}</text>
          <text>{{ guideCopy.description }}</text>
          <view class="guide-actions">
            <button class="guide-skip" @tap.stop="closeGuide">暂时跳过</button>
            <button class="primary guide-close" @tap.stop="continueGuide">{{ guideCopy.action }}</button>
          </view>
        </view>
      </view>

      <view v-if="showQuickCapture" class="quick-capture-overlay" @tap="closeQuickCapture">
        <view class="quick-capture-panel" @tap.stop>
          <view class="quick-capture-head">
            <view>
              <text class="quick-capture-title">快速捕捉</text>
              <text class="quick-capture-subtitle">先记下，之后再决定怎么用。</text>
            </view>
            <button class="close-action" @tap.stop="closeQuickCapture">关闭</button>
          </view>
          <ScrapComposer
            auto-focus
            placeholder="此刻想到什么？"
            @submit="submitQuickScrap"
          />
        </view>
      </view>

      <view v-if="showDataPanel" class="data-overlay" @tap="closeDataPanel">
        <view class="data-panel" @tap.stop>
          <view class="data-panel-head">
            <view>
              <text class="data-title">数据管理</text>
              <text class="data-subtitle">导出备份后可在正式版中导入恢复。</text>
            </view>
            <button class="close-action" @tap="closeDataPanel">关闭</button>
          </view>

          <view class="data-block">
            <view class="data-row-head">
              <text class="data-label">当前备份</text>
              <view class="data-actions">
                <button class="mini-action" @tap="refreshBackupText">刷新</button>
                <button class="mini-action primary-mini" @tap="copyBackupText">复制</button>
              </view>
            </view>
            <textarea
              class="backup-box"
              :value="backupText"
              disabled
              maxlength="-1"
              placeholder="备份内容会显示在这里"
            />
          </view>

          <view class="data-block">
            <view class="data-row-head">
              <text class="data-label">导入备份</text>
              <button class="mini-action" @tap="pasteImportText">从剪贴板粘贴</button>
            </view>
            <textarea
              v-model="importText"
              class="import-box"
              maxlength="-1"
              placeholder="把拾光 JSON 备份粘贴到这里"
            />
          </view>

          <view class="data-panel-actions">
            <button class="danger-action" @tap="confirmResetData">清空数据</button>
            <button class="import-action" @tap="confirmImportData">合并导入</button>
          </view>
        </view>
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

.home-view {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: minmax(0, 1fr) 150px;
  gap: 10px;
  overflow: hidden;
  padding: 12px;
}

.card {
  min-height: 0;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.93);
  box-shadow: 0 10px 28px rgba(42, 63, 88, 0.08);
}

.schedule-card {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: auto auto minmax(0, 1fr) auto auto;
  gap: 8px;
  overflow: hidden;
  padding: 12px;
}

.page-head {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: start;
  gap: 10px;
}

.title-stack {
  min-width: 0;
}

.date {
  display: block;
  color: #6f7b8a;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
  line-height: 1.2;
}

.page-title {
  display: block;
  margin-top: 3px;
  color: #202733;
  font-family: Georgia, "Times New Roman", "Songti SC", serif;
  font-size: 26px;
  font-weight: 700;
  line-height: 1.1;
}

.data-action {
  width: 48px;
  height: 28px;
  min-height: 28px;
  border: 1px solid rgba(138, 89, 96, 0.24);
  border-radius: 8px;
  margin: 0;
  padding: 0;
  background: rgba(138, 89, 96, 0.08);
  color: #8a5960;
  font-size: 11px;
  font-weight: 750;
  line-height: 28px;
}

.guide-action {
  width: 48px;
  height: 28px;
  min-height: 28px;
  border: 1px solid rgba(74, 144, 217, 0.3);
  border-radius: 8px;
  margin: 0;
  padding: 0;
  background: #eaf4ff;
  color: #2f72b4;
  font-size: 11px;
  font-weight: 750;
  line-height: 28px;
}

.data-overlay {
  position: fixed;
  z-index: 20;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  display: grid;
  align-items: end;
  padding: 12px;
  background: rgba(32, 39, 51, 0.36);
}

.data-panel {
  display: grid;
  max-height: 84vh;
  min-height: 0;
  grid-template-rows: auto minmax(0, 1fr) minmax(0, 1fr) auto;
  gap: 12px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 14px;
  background: #ffffff;
  box-shadow: 0 18px 48px rgba(32, 39, 51, 0.2);
}

.data-panel-head,
.data-row-head,
.data-panel-actions {
  display: flex;
  min-width: 0;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.head-actions {
  display: flex;
  align-items: center;
  gap: 6px;
}

.data-title {
  display: block;
  color: #202733;
  font-size: 18px;
  font-weight: 800;
  line-height: 1.2;
}

.data-subtitle {
  display: block;
  margin-top: 4px;
  color: #6f7b8a;
  font-size: 12px;
  line-height: 1.35;
}

.data-block {
  display: grid;
  min-height: 0;
  grid-template-rows: auto minmax(0, 1fr);
  gap: 7px;
}

.data-label {
  color: #202733;
  font-size: 13px;
  font-weight: 800;
}

.data-actions {
  display: flex;
  gap: 6px;
}

.backup-box,
.import-box {
  box-sizing: border-box;
  width: 100%;
  height: 100%;
  min-height: 112px;
  border: 1px solid #dde7ef;
  border-radius: 8px;
  padding: 9px;
  background: #f8fbfe;
  color: #202733;
  font-size: 11px;
  line-height: 1.45;
}

.import-box {
  background: #ffffff;
}

.close-action,
.mini-action,
.danger-action,
.import-action {
  min-height: 30px;
  border: 0;
  border-radius: 8px;
  margin: 0;
  padding: 0 10px;
  font-size: 12px;
  font-weight: 750;
  line-height: 30px;
}

.close-action,
.mini-action {
  background: #eaf4ff;
  color: #2f72b4;
}

.primary-mini,
.import-action {
  background: #4a90d9;
  color: #ffffff;
}

.danger-action {
  background: rgba(138, 89, 96, 0.1);
  color: #8a5960;
}

.import-action,
.danger-action {
  flex: 1;
}

.schedule-pages {
  display: block;
  width: 100%;
  height: 100%;
  min-height: 0;
}

.todo-scroll-inner {
  display: grid;
  gap: 7px;
  padding-right: 2px;
}

.empty-plan {
  display: grid;
  min-height: 0;
  place-items: center;
  border: 1px dashed #ccd9e5;
  border-radius: 8px;
  padding: 10px;
  color: #6f7b8a;
  font-size: 13px;
  text-align: center;
}

.home-todo-create {
  display: grid;
  gap: 7px;
}

.anchor-zone {
  display: grid;
  gap: 7px;
}

.anchor-add {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 7px;
}

.anchor-add input {
  min-width: 0;
  height: 34px;
  border: 1px solid #dde7ef;
  border-radius: 8px;
  padding: 0 10px;
  background: #fbfdff;
  color: #202733;
  font-size: 13px;
}

.guide-overlay {
  position: fixed;
  z-index: 30;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(32, 39, 51, 0.38);
}

.guide-panel {
  display: grid;
  gap: 12px;
  border-radius: 8px;
  padding: 20px;
  background: #ffffff;
  color: #6f7b8a;
  font-size: 14px;
  line-height: 1.5;
}

.guide-step {
  color: #2f72b4;
  font-size: 12px;
  font-weight: 750;
}

.guide-title {
  color: #202733;
  font-size: 20px;
  font-weight: 800;
}

.guide-close {
  flex: 1;
  height: 38px;
  min-height: 38px;
  line-height: 38px;
}

.guide-actions {
  display: flex;
  gap: 8px;
}

.guide-skip {
  height: 38px;
  min-height: 38px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  background: #ffffff;
  color: #6f7b8a;
  font-size: 13px;
  line-height: 38px;
}

.guide-target {
  position: relative;
  z-index: 2;
  outline: 2px solid #4a90d9;
  outline-offset: 2px;
}

.home-add-plan {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 58px;
  gap: 7px;
}

.home-add-plan input {
  min-width: 0;
  height: 34px;
  border: 1px solid #dde7ef;
  border-radius: 8px;
  padding: 0 10px;
  background: #fbfdff;
  color: #202733;
  font-size: 13px;
}

.quick-row {
  display: grid;
  min-height: 0;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 10px;
}

.quick-card {
  display: grid;
  min-width: 0;
  gap: 6px;
  overflow: hidden;
  padding: 12px 10px;
}

.quick-capture-card {
  grid-template-rows: auto minmax(0, 1fr) 34px;
}

.quick-focus-card {
  grid-template-rows: auto minmax(0, 1fr) 34px;
}

.quick-title {
  color: #202733;
  font-size: 16px;
  font-weight: 800;
  line-height: 1.2;
}

.quick-copy,
.focus-label {
  color: #6f7b8a;
  font-size: 12px;
  line-height: 1.3;
}

.quick-capture-action {
  height: 34px;
  min-height: 34px;
  border: 0;
  border-radius: 8px;
  margin: 0;
  padding: 0 8px;
  background: #eaf4ff;
  color: #2f72b4;
  font-size: 12px;
  font-weight: 750;
  line-height: 34px;
}

.quick-capture-overlay {
  position: fixed;
  z-index: 26;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 12px;
  background: rgba(32, 39, 51, 0.36);
}

.quick-capture-panel {
  display: grid;
  width: 100%;
  max-width: 420px;
  gap: 14px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 16px;
  background: #ffffff;
  box-shadow: 0 18px 48px rgba(32, 39, 51, 0.2);
}

.quick-capture-head {
  display: flex;
  min-width: 0;
  align-items: start;
  justify-content: space-between;
  gap: 10px;
}

.quick-capture-title,
.quick-capture-subtitle {
  display: block;
}

.quick-capture-title {
  color: #202733;
  font-size: 19px;
  font-weight: 800;
  line-height: 1.2;
}

.quick-capture-subtitle {
  margin-top: 4px;
  color: #6f7b8a;
  font-size: 12px;
  line-height: 1.35;
}

.timer-mini {
  display: flex;
  min-width: 0;
  align-items: center;
  gap: 8px;
}

.ring {
  display: grid;
  width: 50px;
  height: 50px;
  flex: 0 0 auto;
  place-items: center;
  border-radius: 50%;
  background: conic-gradient(from -90deg, #4a90d9 0 72%, #e5edf4 72% 100%);
}

.ring::after {
  display: block;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: #ffffff;
  content: '';
}

.timer-copy {
  min-width: 0;
}

.timer {
  display: block;
  color: #202733;
  font-size: 24px;
  font-weight: 400;
  font-variant-numeric: tabular-nums;
  line-height: 1;
}

.focus-label {
  display: block;
  max-height: 32px;
  overflow: hidden;
  margin-top: 4px;
}

.primary,
.secondary {
  border: 0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 750;
}

.primary {
  background: #4a90d9;
  color: #ffffff;
}

.secondary {
  height: 34px;
  min-height: 34px;
  margin: 0;
  padding: 0;
  background: #eaf4ff;
  color: #2f72b4;
  line-height: 34px;
}

.tomato-action {
  width: 64px;
  height: 34px;
  min-height: 34px;
  justify-self: start;
  margin: 0;
  padding: 0;
  line-height: 34px;
}

@media (max-width: 360px) {
  .home-view {
    grid-template-rows: minmax(0, 1fr) 140px;
    gap: 8px;
    padding: 10px;
  }

  .schedule-card,
  .quick-card {
    padding: 10px;
  }

  .page-title {
    font-size: 24px;
  }

  .quick-row {
    gap: 8px;
  }

  .quick-title {
    font-size: 14px;
  }

  .quick-copy {
    display: none;
  }

  .ring {
    width: 42px;
    height: 42px;
  }

  .ring::after {
    width: 28px;
    height: 28px;
  }

  .timer {
    font-size: 21px;
  }
}
</style>
