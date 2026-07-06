<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import ScrapComposer from '@/components/ScrapComposer.vue';
import ScrapItem from '@/components/ScrapItem.vue';
import type { ScrapCategory } from '@/domain/types';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const categories: Array<ScrapCategory | '全部'> = ['全部', '灵感', '随想', '待办', '分心', '复盘'];
const selectedCategory = ref<ScrapCategory | '全部'>('全部');

const visibleScraps = computed(() =>
  selectedCategory.value === '全部'
    ? store.allScraps
    : store.allScraps.filter((scrap) => scrap.category === selectedCategory.value)
);

onMounted(() => {
  store.hydrate();
});
</script>

<template>
  <view class="page">
    <view class="section">
      <text class="section-title">记录想法</text>
      <view class="panel">
        <ScrapComposer @submit="store.addScrap" />
      </view>
    </view>

    <view class="section">
      <scroll-view scroll-x>
        <view class="filters">
          <button
            v-for="category in categories"
            :key="category"
            size="mini"
            :class="['filter', { active: selectedCategory === category }]"
            @click="selectedCategory = category"
          >
            {{ category }}
          </button>
        </view>
      </scroll-view>
    </view>

    <view class="section panel" v-if="visibleScraps.length">
      <ScrapItem v-for="scrap in visibleScraps" :key="scrap.id" :scrap="scrap" />
    </view>
    <view v-else class="panel muted">还没有这一类记录</view>
  </view>
</template>

<style scoped lang="scss">
.filters {
  display: flex;
  gap: 8px;
}

.filter {
  border-radius: 8px;
  background: #fffaf1;
  color: #6f6b62;
  font-size: 13px;
}

.filter.active {
  background: #25635f;
  color: #ffffff;
}

.muted {
  color: #6f6b62;
  font-size: 14px;
}
</style>
