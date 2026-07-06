<script setup lang="ts">
import { ref } from 'vue';
import type { ScrapCategory } from '@/domain/types';

const props = withDefaults(
  defineProps<{
    defaultCategory?: ScrapCategory;
    placeholder?: string;
  }>(),
  {
    defaultCategory: '随想',
    placeholder: '先放下这个想法'
  }
);

const emit = defineEmits<{
  submit: [category: ScrapCategory, content: string];
}>();

const categories: ScrapCategory[] = ['灵感', '随想', '待办', '分心', '复盘'];
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
  <view class="composer">
    <picker :range="categories" :value="categories.indexOf(category)" @change="category = categories[Number($event.detail.value)]">
      <view class="picker-value">{{ category }}</view>
    </picker>
    <textarea v-model="content" :placeholder="placeholder" auto-height maxlength="500" />
    <button class="primary-button" @click="submit">保存</button>
  </view>
</template>

<style scoped lang="scss">
.composer {
  display: grid;
  gap: 10px;
}

.picker-value {
  display: inline-flex;
  min-width: 72px;
  border: 1px solid rgba(37, 99, 95, 0.25);
  border-radius: 8px;
  padding: 8px 10px;
  background: #eef7f4;
  color: #25635f;
  font-size: 14px;
}

textarea {
  width: 100%;
  min-height: 72px;
  border: 1px solid rgba(34, 34, 34, 0.1);
  border-radius: 8px;
  padding: 10px;
  background: #ffffff;
  font-size: 15px;
}

.primary-button {
  width: 100%;
  border-radius: 8px;
  background: #25635f;
  color: #ffffff;
  font-size: 15px;
}
</style>
