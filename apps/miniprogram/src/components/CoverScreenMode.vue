<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import MiniProgramShell from './MiniProgramShell.vue';
import TodoItem from './TodoItem.vue';
import { todayISODate } from '@/domain/date';
import { getTodosForDate } from '@/domain/todos';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const thought = ref('');
const today = todayISODate();
const todayTodos = computed(() => getTodosForDate(store.state.todos, today));

onMounted(() => {
  store.hydrate();
});

function submitThought() {
  const trimmed = thought.value.trim();
  if (!trimmed) {
    return;
  }

  store.addScrap('随想', trimmed);
  thought.value = '';
  uni.showToast({
    title: '已记录',
    icon: 'success'
  });
}
</script>

<template>
  <MiniProgramShell active="home" hide-tabs>
    <view class="cover-view">
      <section class="cover-card todo-card">
        <view class="cover-head">
          <view>
            <text class="cover-date">{{ today }}</text>
            <text class="cover-title">今日日程</text>
          </view>
          <text class="cover-count">{{ todayTodos.length }} 项</text>
        </view>
        <scroll-view v-if="todayTodos.length" scroll-y class="todo-list">
          <view class="todo-inner">
            <TodoItem
              v-for="todo in todayTodos"
              :key="todo.id"
              :todo="todo"
              @toggle="store.setTodoCompleted"
            />
          </view>
        </scroll-view>
        <view v-else class="empty">今天还没有待办</view>
      </section>

      <section class="cover-card thought-card">
        <view class="cover-head">
          <text class="cover-title small">记录随想</text>
        </view>
        <textarea v-model="thought" maxlength="500" placeholder="先记下来" />
        <button class="save-action" @tap.stop="submitThought">收纳</button>
      </section>
    </view>
  </MiniProgramShell>
</template>

<style scoped lang="scss">
.cover-view {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: minmax(0, 1fr) 128px;
  gap: 8px;
  overflow: hidden;
  padding: 9px;
}

.cover-card {
  display: grid;
  min-height: 0;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.94);
  box-shadow: 0 8px 22px rgba(42, 63, 88, 0.08);
}

.todo-card {
  grid-template-rows: auto minmax(0, 1fr);
  gap: 7px;
  padding: 10px;
}

.thought-card {
  grid-template-rows: auto minmax(0, 1fr) 30px;
  gap: 6px;
  padding: 9px 10px;
}

.cover-head {
  display: flex;
  min-width: 0;
  align-items: flex-start;
  justify-content: space-between;
  gap: 8px;
}

.cover-date,
.cover-count {
  display: block;
  color: #6f7b8a;
  font-size: 11px;
  line-height: 1.2;
}

.cover-title {
  display: block;
  margin-top: 2px;
  color: #202733;
  font-family: Georgia, "Times New Roman", "Songti SC", serif;
  font-size: 22px;
  font-weight: 700;
  line-height: 1.08;
}

.cover-title.small {
  margin-top: 0;
  font-size: 17px;
  font-family: inherit;
  font-weight: 800;
}

.todo-list {
  width: 100%;
  height: 100%;
  min-height: 0;
}

.todo-inner {
  display: grid;
  gap: 6px;
}

.empty {
  display: grid;
  place-items: center;
  border: 1px dashed #ccd9e5;
  border-radius: 8px;
  color: #6f7b8a;
  font-size: 12px;
}

textarea {
  width: 100%;
  height: 100%;
  border: 1px solid #dde7ef;
  border-radius: 8px;
  padding: 8px;
  background: #fbfdff;
  color: #202733;
  font-size: 13px;
  line-height: 1.35;
}

.save-action {
  height: 30px;
  min-height: 30px;
  border-radius: 8px;
  background: #4a90d9;
  color: #ffffff;
  font-size: 13px;
  font-weight: 750;
  line-height: 30px;
}
</style>
