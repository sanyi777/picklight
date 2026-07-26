<script setup lang="ts">
import { onShow } from '@dcloudio/uni-app';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();

onShow(store.hydrate);
</script>

<template>
  <slot />
</template>

<style lang="scss">
page {
  min-height: 100%;
  background: #edf3f8;
  color: #202733;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}
</style>
