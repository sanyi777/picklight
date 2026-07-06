<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import MiniProgramShell from '@/components/MiniProgramShell.vue';
import ScrapComposer from '@/components/ScrapComposer.vue';
import ScrapItem from '@/components/ScrapItem.vue';
import type { ScrapCategory } from '@/domain/types';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const categories: Array<ScrapCategory | '全部'> = ['全部', '随想', '灵感', '待办', '分心', '复盘'];
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
  <MiniProgramShell active="scraps">
    <view class="scraps-view">
      <section class="card scrap-compose">
        <view class="section-head">
          <view>
            <text class="date">{{ store.activeDate }} · 本地存储</text>
            <text class="page-title">零碎</text>
          </view>
        </view>
        <ScrapComposer placeholder="先放下一个想法、待办或分心" @submit="store.addScrap" />
      </section>

      <section class="card scrap-list-card">
        <view class="section-head">
          <text class="section-title-main">收纳箱</text>
          <text class="date">按最近创建排序</text>
        </view>
        <view class="filter-row">
          <button
            v-for="category in categories"
            :key="category"
            :class="['filter', { active: selectedCategory === category }]"
            @click="selectedCategory = category"
          >
            {{ category }}
          </button>
        </view>
        <scroll-view v-if="visibleScraps.length" scroll-y class="scrap-list">
          <view class="scrap-scroll-inner">
            <ScrapItem
              v-for="scrap in visibleScraps"
              :key="scrap.id"
              :scrap="scrap"
              @update="store.updateScrap"
              @delete="store.deleteScrap"
            />
          </view>
        </scroll-view>
        <view v-else class="empty-list">还没有这一类记录</view>
      </section>
    </view>
  </MiniProgramShell>
</template>

<style scoped lang="scss">
.scraps-view {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: 222px minmax(0, 1fr);
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

.scrap-compose {
  display: grid;
  min-height: 0;
  gap: 10px;
  overflow: hidden;
  padding: 12px 14px;
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
  font-size: 30px;
  font-weight: 700;
  line-height: 1.05;
}

.section-title-main {
  color: #202733;
  font-size: 17px;
  font-weight: 800;
}

.scrap-list-card {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: auto auto minmax(0, 1fr);
  gap: 9px;
  overflow: hidden;
  padding: 12px;
}

.filter-row {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
}

.filter {
  min-width: 42px;
  height: 28px;
  min-height: 28px;
  border: 1px solid #dce4ec;
  border-radius: 999px;
  padding: 0 8px;
  background: #fbfdff;
  color: #6f7b8a;
  font-size: 11px;
  line-height: 28px;
}

.filter.active {
  border-color: rgba(74, 144, 217, 0.56);
  background: #eaf4ff;
  color: #2f72b4;
  font-weight: 750;
}

.scrap-list {
  display: block;
  width: 100%;
  height: 100%;
  min-height: 0;
}

.scrap-scroll-inner {
  padding-right: 2px;
}

.empty-list {
  display: grid;
  min-height: 0;
  place-items: center;
  border: 1px dashed #ccd9e5;
  border-radius: 8px;
  color: #6f7b8a;
  font-size: 13px;
}

.scrap-compose :deep(.composer) {
  gap: 8px;
}

.scrap-compose :deep(textarea) {
  height: 84px;
  padding: 11px 13px;
  font-size: 14px;
}

.scrap-compose :deep(.composer-actions) {
  grid-template-columns: minmax(0, 1fr) 82px;
  gap: 7px;
}

.scrap-compose :deep(.category-row) {
  gap: 5px;
}

.scrap-compose :deep(.category-chip) {
  min-width: 40px;
  height: 28px;
  min-height: 28px;
  padding: 0 8px;
  font-size: 12px;
  line-height: 28px;
}

.scrap-compose :deep(.save-button) {
  width: 82px;
  height: 36px;
  min-height: 36px;
  font-size: 13px;
  line-height: 36px;
}
</style>
