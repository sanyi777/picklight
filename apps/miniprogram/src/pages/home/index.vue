<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import MiniProgramShell from '@/components/MiniProgramShell.vue';
import ScrapComposer from '@/components/ScrapComposer.vue';
import TodoItem from '@/components/TodoItem.vue';
import WeekStrip from '@/components/WeekStrip.vue';
import { parseISODate, todayISODate } from '@/domain/date';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const todoContent = ref('');
const weekStartDate = todayISODate();
const currentFocusLabel = computed(() => store.currentAnchor?.title ?? '设置本轮专注事项');
const scheduleTitle = computed(() => {
  if (store.activeDate === weekStartDate) {
    return '今日日程';
  }

  const date = parseISODate(store.activeDate);
  return `${date.getMonth() + 1}月${date.getDate()}日日程`;
});

onMounted(() => {
  store.hydrate();
});

function goFocus() {
  uni.redirectTo({ url: '/pages/focus/index' });
}

function submitTodo() {
  if (!todoContent.value.trim()) {
    return;
  }

  store.addTodo(todoContent.value);
  todoContent.value = '';
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
  <MiniProgramShell active="home">
    <view class="home-view">
      <section class="card schedule-card">
        <view class="page-head">
          <view class="title-stack">
            <text class="date">{{ store.activeDate }} · 本地存储</text>
            <text class="page-title">{{ scheduleTitle }}</text>
          </view>
          <button class="reset-action" @tap.stop="confirmResetData">重置</button>
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

        <view class="home-add-plan">
          <input v-model="todoContent" placeholder="添加一条待办" @confirm="submitTodo" />
          <button class="secondary" @click="submitTodo">添加</button>
        </view>

        <WeekStrip
          :start-date="weekStartDate"
          :active-date="store.activeDate"
          :todos="store.state.todos"
          @select="store.setActiveDate"
        />
      </section>

      <section class="quick-row">
        <view class="card quick-card quick-capture-card">
          <text class="quick-title">快速捕捉</text>
          <text class="quick-copy">先把想法放下，默认进入零碎池。</text>
          <ScrapComposer
            class="quick-composer"
            variant="compact"
            placeholder="记录一个念头"
            @submit="store.addScrap"
          />
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
    </view>
  </MiniProgramShell>
</template>

<style scoped lang="scss">
.home-view {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: minmax(0, 1fr) 168px;
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
  grid-template-rows: auto minmax(0, 1fr) auto auto;
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

.reset-action {
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
  grid-template-rows: auto auto minmax(0, 1fr);
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

.quick-composer {
  min-height: 0;
}

.quick-composer :deep(.composer) {
  gap: 6px;
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
</style>
