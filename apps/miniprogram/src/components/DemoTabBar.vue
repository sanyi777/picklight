<script setup lang="ts">
const props = defineProps<{
  active: 'home' | 'scraps' | 'schedule' | 'focus';
}>();

const tabs = [
  { key: 'home', label: '首页', url: '/pages/home/index', icon: 'plus' },
  { key: 'scraps', label: '零碎', url: '/pages/scraps/index', icon: 'stack' },
  { key: 'schedule', label: '日程', url: '/pages/schedule/index', icon: 'calendar' },
  { key: 'focus', label: '专注', url: '/pages/focus/index', icon: 'timer' }
] as const;

function go(url: string, key: typeof props.active) {
  if (key === props.active) {
    return;
  }

  uni.redirectTo({ url });
}
</script>

<template>
  <view class="bottom-tabs">
    <button
      v-for="tab in tabs"
      :key="tab.key"
      :class="['tab', { active: active === tab.key }]"
      @click="go(tab.url, tab.key)"
    >
      <view :class="['tab-icon', tab.icon]">
        <text />
        <text />
      </view>
      <text>{{ tab.label }}</text>
    </button>
  </view>
</template>

<style scoped lang="scss">
.bottom-tabs {
  display: grid;
  min-height: 76px;
  grid-template-columns: repeat(4, 1fr);
  border-top: 1px solid rgba(220, 228, 236, 0.94);
  padding: 7px 8px 12px;
  background: rgba(255, 255, 255, 0.9);
}

.tab {
  display: grid;
  min-width: 0;
  min-height: 54px;
  place-items: center;
  gap: 3px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: #6f7b8a;
  font-size: 11px;
  line-height: 1;
}

.tab.active {
  background: #eaf4ff;
  color: #2f72b4;
  font-weight: 700;
}

.tab-icon {
  position: relative;
  width: 22px;
  height: 22px;
  color: currentColor;
}

.tab-icon::before,
.tab-icon::after,
.tab-icon text {
  position: absolute;
  display: block;
  content: '';
  border-color: currentColor;
}

.plus::before {
  inset: 3px;
  border: 2px solid currentColor;
  border-radius: 50%;
}

.plus text:first-child {
  top: 10px;
  left: 5px;
  width: 12px;
  border-top: 2px solid currentColor;
}

.plus text:last-child {
  top: 5px;
  left: 10px;
  height: 12px;
  border-left: 2px solid currentColor;
}

.stack text:first-child,
.stack text:last-child {
  left: 4px;
  width: 14px;
  border-top: 2px solid currentColor;
}

.stack text:first-child {
  top: 7px;
}

.stack text:last-child {
  top: 15px;
}

.stack::before {
  top: 3px;
  left: 10px;
  height: 16px;
  border-left: 2px solid currentColor;
}

.calendar::before {
  inset: 4px 3px 2px;
  border: 2px solid currentColor;
  border-radius: 3px;
}

.calendar::after {
  top: 9px;
  left: 4px;
  width: 14px;
  border-top: 2px solid currentColor;
}

.timer::before {
  inset: 5px 3px 2px;
  border: 2px solid currentColor;
  border-radius: 50%;
}

.timer::after {
  top: 1px;
  left: 8px;
  width: 6px;
  border-top: 2px solid currentColor;
}

.timer text:first-child {
  top: 10px;
  left: 10px;
  height: 6px;
  transform: rotate(45deg);
  border-left: 2px solid currentColor;
}
</style>
