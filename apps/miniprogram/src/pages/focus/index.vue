<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import AnchorCard from '@/components/AnchorCard.vue';
import MiniProgramShell from '@/components/MiniProgramShell.vue';
import PomodoroPanel from '@/components/PomodoroPanel.vue';
import ScrapItem from '@/components/ScrapItem.vue';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const anchorTitle = ref('');
const distraction = ref('');
const focusSessionsForDate = computed(() =>
  store.state.focusSessions.filter((session) => session.date === store.activeDate)
);
const latestSession = computed(() => [...focusSessionsForDate.value].reverse().find((session) => !session.completed));
const distractions = computed(() => store.allScraps.filter((scrap) => scrap.category === '分心').slice(0, 4));
const canAddAnchor = computed(() => store.todayAnchors.length < 2);
const hasTwoAnchors = computed(() => store.todayAnchors.length >= 2);

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
});
</script>

<template>
  <MiniProgramShell active="focus">
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

      <section class="card pomodoro-card">
        <PomodoroPanel
          :compact="hasTwoAnchors"
          :latest-session="latestSession"
          :sessions="focusSessionsForDate"
          @create="store.createFocus"
          @start="store.startFocus"
          @complete="store.completeFocus"
          @delete="store.deleteFocus"
        />
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
            hide-category
            @update="store.updateScrap"
            @delete="store.deleteScrap"
          />
        </scroll-view>
        <view v-else class="empty-line">暂无分心记录</view>
      </section>
    </view>
  </MiniProgramShell>
</template>

<style scoped lang="scss">
.focus-view {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: 220px auto minmax(0, 1fr);
  gap: 10px;
  overflow: hidden;
  padding: 12px;
}

.focus-view.two-anchors {
  grid-template-rows: 246px auto minmax(0, 1fr);
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
  grid-template-rows: auto minmax(0, 1fr) auto;
  gap: 5px;
  overflow: hidden;
  padding: 9px 12px;
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
  min-height: 0;
  overflow: hidden;
  padding: 12px;
}

.two-anchors .pomodoro-card {
  padding: 8px;
}

.distraction-card {
  display: grid;
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
</style>
