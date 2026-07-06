<script setup lang="ts">
import { ref } from 'vue';
import type { ScrapCategory } from '@/domain/types';

const props = withDefaults(
  defineProps<{
    defaultCategory?: ScrapCategory;
    placeholder?: string;
    variant?: 'chips' | 'compact';
  }>(),
  {
    defaultCategory: '随想',
    placeholder: '先放下一个想法',
    variant: 'chips'
  }
);

const emit = defineEmits<{
  submit: [category: ScrapCategory, content: string];
}>();

const categories: ScrapCategory[] = ['随想', '灵感', '待办', '分心', '复盘'];
const category = ref<ScrapCategory>(props.defaultCategory);
const content = ref('');

function submit() {
  const trimmed = content.value.trim();
  if (!trimmed) {
    return;
  }

  emit('submit', category.value, trimmed);
  content.value = '';
}
</script>

<template>
  <view :class="['composer', variant]">
    <template v-if="variant === 'compact'">
      <view class="compact-actions">
        <picker :range="categories" :value="categories.indexOf(category)" @change="category = categories[Number($event.detail.value)]">
          <view class="picker-value">{{ category }}</view>
        </picker>
        <button class="save-button" @click="submit">保存</button>
      </view>
      <textarea v-model="content" :placeholder="placeholder" maxlength="500" />
    </template>

    <template v-else>
      <textarea v-model="content" :placeholder="placeholder" maxlength="500" />
      <view class="composer-actions">
        <view class="category-row">
          <button
            v-for="item in categories"
            :key="item"
            :class="['category-chip', { active: category === item }]"
            @click="category = item"
          >
            {{ item }}
          </button>
        </view>
        <button class="save-button" @click="submit">＋ 收纳</button>
      </view>
    </template>
  </view>
</template>

<style scoped lang="scss">
.composer {
  display: grid;
  gap: 10px;
}

textarea {
  width: 100%;
  height: 92px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 13px 15px;
  background: #fbfdff;
  color: #202733;
  font-size: 15px;
  line-height: 1.45;
}

.composer-actions {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 88px;
  gap: 8px;
  align-items: start;
}

.category-row {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.category-chip {
  flex: 0 0 auto;
  min-width: 44px;
  height: 32px;
  min-height: 32px;
  border: 1px solid #dce4ec;
  border-radius: 999px;
  padding: 0 10px;
  background: #fbfdff;
  color: #6f7b8a;
  font-size: 13px;
  line-height: 32px;
}

.category-chip.active {
  border-color: rgba(74, 144, 217, 0.56);
  background: #eaf4ff;
  color: #2f72b4;
  font-weight: 750;
}

.save-button {
  width: 88px;
  height: 38px;
  min-height: 38px;
  border-radius: 8px;
  background: #4a90d9;
  color: #ffffff;
  font-size: 14px;
  font-weight: 750;
  line-height: 38px;
}

.compact {
  gap: 6px;
}

.compact textarea {
  height: 42px;
  padding: 7px 8px;
  font-size: 12px;
  line-height: 1.35;
}

.compact-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.compact .save-button {
  width: 58px;
  height: 28px;
  min-height: 28px;
  margin: 0;
  padding: 0;
  font-size: 12px;
  line-height: 28px;
}

.picker-value {
  display: inline-flex;
  min-width: 58px;
  height: 28px;
  align-items: center;
  justify-content: center;
  border: 1px solid #c8d6e3;
  border-radius: 8px;
  padding: 0 8px;
  background: #eaf4ff;
  color: #2f72b4;
  font-size: 12px;
}
</style>
