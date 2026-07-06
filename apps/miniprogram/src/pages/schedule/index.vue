<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import AnchorCard from '@/components/AnchorCard.vue';
import TodoItem from '@/components/TodoItem.vue';
import WeekStrip from '@/components/WeekStrip.vue';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const todoContent = ref('');
const todoTime = ref('');
const anchorTitle = ref('');
const review = ref('');

const selectedTodos = computed(() => store.todayTodos);

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
      title: error instanceof Error ? error.message : '无法添加主锚点',
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
  <view class="page">
    <view class="section">
      <text class="section-title">未来 7 天</text>
      <WeekStrip :active-date="store.activeDate" :todos="store.state.todos" @select="store.setActiveDate" />
    </view>

    <view class="section panel">
      <text class="section-title">新增待办</text>
      <input v-model="todoTime" placeholder="时间，可不填，如 09:30" />
      <input v-model="todoContent" placeholder="待办内容" />
      <button class="primary-button" @click="submitTodo">加入今天</button>
    </view>

    <view class="section">
      <text class="section-title">今日待办</text>
      <view class="panel" v-if="selectedTodos.length">
        <TodoItem v-for="todo in selectedTodos" :key="todo.id" :todo="todo" @toggle="store.setTodoCompleted" />
      </view>
      <view v-else class="panel muted">这一天还没有待办</view>
    </view>

    <view class="section panel">
      <text class="section-title">主锚点</text>
      <input v-model="anchorTitle" placeholder="今天最重要的方向" />
      <button class="primary-button" @click="submitAnchor">添加主锚点</button>
      <view class="anchor-list" v-if="store.todayAnchors.length">
        <AnchorCard
          v-for="anchor in store.todayAnchors"
          :key="anchor.id"
          :anchor="anchor"
          @current="store.makeAnchorCurrent"
          @progress="store.setAnchorProgress"
        />
      </view>
    </view>

    <view class="section panel">
      <text class="section-title">当日复盘</text>
      <textarea v-model="review" placeholder="今天发生了什么，哪里偏了，哪里做得不错" auto-height />
      <button class="primary-button" @click="submitReview">归档到复盘</button>
    </view>
  </view>
</template>

<style scoped lang="scss">
.panel {
  display: grid;
  gap: 10px;
}

input,
textarea {
  width: 100%;
  border: 1px solid rgba(34, 34, 34, 0.1);
  border-radius: 8px;
  padding: 10px;
  background: #ffffff;
  font-size: 15px;
}

input {
  height: 40px;
}

.primary-button {
  width: 100%;
  border-radius: 8px;
  background: #25635f;
  color: #ffffff;
  font-size: 15px;
}

.anchor-list {
  display: grid;
  gap: 10px;
}

.muted {
  color: #6f6b62;
  font-size: 14px;
}
</style>
