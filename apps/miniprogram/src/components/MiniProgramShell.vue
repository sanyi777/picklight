<script setup lang="ts">
import DemoTabBar from './DemoTabBar.vue';

defineProps<{
  active: 'home' | 'scraps' | 'schedule' | 'focus';
}>();
</script>

<template>
  <view class="shell">
    <view class="wx-bar">
      <view class="title-row">
        <text class="app-title">拾光</text>
      </view>
    </view>

    <view class="content">
      <slot />
    </view>

    <DemoTabBar :active="active" />
  </view>
</template>

<style scoped lang="scss">
.shell {
  display: grid;
  height: 100vh;
  min-height: 100vh;
  grid-template-rows: auto minmax(0, 1fr) auto;
  overflow: hidden;
  background: #f5f8fb;
  color: #202733;
}

.wx-bar {
  border-bottom: 1px solid rgba(220, 228, 236, 0.86);
  padding: var(--status-bar-height) 14px 0;
  background: rgba(255, 255, 255, 0.94);
}

.title-row {
  display: flex;
  height: 44px;
  align-items: center;
}

.app-title {
  color: #202733;
  font-size: 20px;
  font-weight: 800;
  line-height: 1;
}

.content {
  height: 100%;
  min-height: 0;
  overflow: hidden;
  background: #f5f8fb;
}
</style>
