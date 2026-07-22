<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import AnchorCard from '@/components/AnchorCard.vue';
import CoverScreenMode from '@/components/CoverScreenMode.vue';
import FocusHistoryModal from '@/components/FocusHistoryModal.vue';
import MiniProgramShell from '@/components/MiniProgramShell.vue';
import PomodoroPanel from '@/components/PomodoroPanel.vue';
import ScrapItem from '@/components/ScrapItem.vue';
import { useViewportProfile } from '@/composables/useViewportProfile';
import { todayISODate } from '@/domain/date';
import { getActualFocusSeconds } from '@/domain/focus';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const { isCoverScreen } = useViewportProfile();
const anchorTitle = ref('');
const distraction = ref('');
const showFocusHistory = ref(false);
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

onMounted(() => {
  store.hydrate();
  store.setActiveDate(todayISODate());
});
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
        <button class="history-open-action" data-eventsync="true" @tap.stop="showFocusHistory = true">专注历史</button>
      </section>

      <section class="card pomodoro-card">
        <PomodoroPanel
          :compact="hasTwoAnchors"
          :latest-session="latestSession"
        />
      </section>

      <FocusHistoryModal
        v-if="showFocusHistory"
        :sessions="focusHistorySessions"
        @dismiss="showFocusHistory = false"
        @update="store.updateFocusTask"
        @delete="store.deleteFocus"
      />

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

.pomodoro-card :deep(.pomodoro) {
  height: 100%;
}

.focus-history-card {
  display: flex;
  min-height: 72px;
  align-items: center;
  justify-content: space-between;
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

.two-anchors .pomodoro-card {
  padding: 8px;
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
