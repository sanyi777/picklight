<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import AnchorCard from '@/components/AnchorCard.vue';
import MiniProgramShell from '@/components/MiniProgramShell.vue';
import TodoItem from '@/components/TodoItem.vue';
import WeekStrip from '@/components/WeekStrip.vue';
import { todayISODate } from '@/domain/date';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const todoContent = ref('');
const todoTime = ref('');
const anchorTitle = ref('');
const review = ref('');
const weekStartDate = todayISODate();

const selectedTodos = computed(() => store.todayTodos);
const canAddAnchor = computed(() => store.todayAnchors.length < 2);

function submitTodo() {
  if (!todoContent.value.trim()) {
    return;
  }

  store.addTodo(todoContent.value, todoTime.value);
  todoContent.value = '';
  todoTime.value = '';
}

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

function submitReview() {
  if (!review.value.trim()) {
    return;
  }

  store.archiveReview(review.value);
  review.value = '';
}

onMounted(() => {
  store.hydrate();
});
</script>

<template>
  <MiniProgramShell active="schedule">
    <view class="schedule-view">
      <section class="card day-plan">
        <view class="section-head">
          <view>
            <text class="date">{{ store.activeDate }} · 本地存储</text>
            <text class="page-title">日程</text>
          </view>
        </view>

        <view class="anchor-zone">
          <view v-if="store.todayAnchors.length" class="anchor-list">
            <AnchorCard
              v-for="anchor in store.todayAnchors"
              :key="anchor.id"
              :anchor="anchor"
              @progress="store.setAnchorProgress"
              @rename="store.renameAnchor"
              @delete="store.deleteAnchor"
            />
          </view>
          <view v-if="canAddAnchor" class="anchor-add">
            <input v-model="anchorTitle" placeholder="新增锚点，最多 2 条" @confirm="submitAnchor" />
            <button class="secondary" @click="submitAnchor">新增</button>
          </view>
        </view>

        <scroll-view v-if="selectedTodos.length" scroll-y class="plan-list">
          <view class="plan-scroll-inner">
            <TodoItem
              v-for="todo in selectedTodos"
              :key="todo.id"
              :todo="todo"
              @toggle="store.setTodoCompleted"
            />
          </view>
        </scroll-view>
        <view v-else class="empty-plan">这一天还没有待办</view>

        <view class="add-plan">
          <input v-model="todoTime" placeholder="时间" />
          <input v-model="todoContent" placeholder="添加一条待办" @confirm="submitTodo" />
          <button class="secondary" @click="submitTodo">添加</button>
        </view>
      </section>

      <section class="card week-panel">
        <view class="section-head">
          <text class="section-title-main">未来 7 天</text>
          <text class="date">未完成会滚动</text>
        </view>
        <WeekStrip
          :start-date="weekStartDate"
          :active-date="store.activeDate"
          :todos="store.state.todos"
          @select="store.setActiveDate"
        />
      </section>

      <view class="card review-card">
        <input v-model="review" placeholder="写一条今日复盘" @confirm="submitReview" />
        <button class="secondary" @click="submitReview">归档</button>
      </view>
    </view>
  </MiniProgramShell>
</template>

<style scoped lang="scss">
.schedule-view {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: minmax(0, 1fr) 108px 62px;
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

.day-plan {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: auto auto minmax(0, 1fr) auto;
  gap: 9px;
  overflow: hidden;
  padding: 12px;
}

.section-head {
  display: flex;
  align-items: flex-start;
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

.anchor-zone {
  display: grid;
  gap: 7px;
}

.anchor-list {
  display: grid;
  gap: 7px;
}

.anchor-add,
.review-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 7px;
  align-items: center;
}

.plan-list {
  display: block;
  width: 100%;
  height: 100%;
  min-height: 0;
}

.plan-scroll-inner {
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
  color: #6f7b8a;
  font-size: 13px;
}

.add-plan {
  display: grid;
  grid-template-columns: 52px minmax(0, 1fr) auto;
  gap: 7px;
  align-items: center;
}

input {
  min-width: 0;
  height: 36px;
  min-height: 36px;
  border: 1px solid #dde7ef;
  border-radius: 8px;
  padding: 0 9px;
  background: #fbfdff;
  color: #202733;
  font-size: 13px;
}

.week-panel {
  display: grid;
  min-height: 0;
  gap: 7px;
  padding: 10px 12px;
}

.review-card {
  padding: 12px;
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
