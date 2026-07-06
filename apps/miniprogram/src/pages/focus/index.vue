<script setup lang="ts">
import { computed, onMounted } from 'vue';
import AnchorCard from '@/components/AnchorCard.vue';
import PomodoroPanel from '@/components/PomodoroPanel.vue';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const latestSession = computed(() => store.state.focusSessions[store.state.focusSessions.length - 1]);

onMounted(() => {
  store.hydrate();
});
</script>

<template>
  <view class="page">
    <view class="section panel current">
      <text class="section-title">当前锚点</text>
      <text class="current-title">{{ store.currentAnchor?.title ?? '还没有当前锚点' }}</text>
    </view>

    <view class="section" v-if="store.todayAnchors.length">
      <text class="section-title">主锚点进度</text>
      <view class="stack">
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
      <text class="section-title">番茄钟</text>
      <PomodoroPanel
        :latest-session="latestSession"
        @create="store.createFocus"
        @start="store.startFocus"
        @complete="store.completeFocus"
        @distraction="store.addFocusDistraction"
      />
    </view>
  </view>
</template>

<style scoped lang="scss">
.current {
  background: #25635f;
  color: #ffffff;
}

.current .section-title {
  color: rgba(255, 255, 255, 0.72);
}

.current-title {
  overflow-wrap: anywhere;
  font-size: 22px;
  font-weight: 700;
}

.stack {
  display: grid;
  gap: 10px;
}
</style>
