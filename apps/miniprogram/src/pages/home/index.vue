<script setup lang="ts">
import { computed, onMounted } from 'vue';
import AnchorCard from '@/components/AnchorCard.vue';
import ScrapComposer from '@/components/ScrapComposer.vue';
import TodoItem from '@/components/TodoItem.vue';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();

const currentAnchorTitle = computed(() => store.currentAnchor?.title ?? '还没有当前锚点');

onMounted(() => {
  store.hydrate();
});

function goFocus() {
  uni.switchTab({ url: '/pages/focus/index' });
}
</script>

<template>
  <view class="page">
    <view class="section hero">
      <text class="date">{{ store.activeDate }}</text>
      <text class="current">{{ currentAnchorTitle }}</text>
      <button class="primary-button" @click="goFocus">开始专注</button>
    </view>

    <view class="section">
      <text class="section-title">今日主锚点</text>
      <view class="stack" v-if="store.todayAnchors.length">
        <AnchorCard
          v-for="anchor in store.todayAnchors"
          :key="anchor.id"
          :anchor="anchor"
          @current="store.makeAnchorCurrent"
          @progress="store.setAnchorProgress"
        />
      </view>
      <view v-else class="panel muted">今天还没有主锚点</view>
    </view>

    <view class="section">
      <text class="section-title">今日待办</text>
      <view class="panel" v-if="store.todayTodos.length">
        <TodoItem
          v-for="todo in store.todayTodos"
          :key="todo.id"
          :todo="todo"
          @toggle="store.setTodoCompleted"
        />
      </view>
      <view v-else class="panel muted">今天暂时没有待办</view>
    </view>

    <view class="section">
      <text class="section-title">快速捕捉</text>
      <view class="panel">
        <ScrapComposer placeholder="先记下来，不打断自己" @submit="store.addScrap" />
      </view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.hero {
  display: grid;
  gap: 10px;
  border-radius: 8px;
  padding: 16px;
  background: #25635f;
  color: #ffffff;
}

.date {
  opacity: 0.78;
  font-size: 13px;
}

.current {
  overflow-wrap: anywhere;
  font-size: 22px;
  font-weight: 700;
}

.primary-button {
  width: 100%;
  border-radius: 8px;
  background: #ffffff;
  color: #25635f;
  font-size: 15px;
}

.stack {
  display: grid;
  gap: 10px;
}

.muted {
  color: #6f6b62;
  font-size: 14px;
}
</style>
