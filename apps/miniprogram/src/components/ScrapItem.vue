<script setup lang="ts">
import { ref } from 'vue';
import TodoTimePicker from '@/components/TodoTimePicker.vue';
import type { ID, Scrap, ScrapCategory } from '@/domain/types';

const props = withDefaults(
  defineProps<{
    scrap: Scrap;
    hideCategory?: boolean;
    todoTime?: string;
  }>(),
  {
    hideCategory: false,
    todoTime: ''
  }
);

const emit = defineEmits<{
  update: [id: ID, category: ScrapCategory, content: string, time?: string];
  delete: [id: ID];
}>();

const categories: ScrapCategory[] = ['随想', '灵感', '待办', '分心', '复盘'];
const editing = ref(false);
const draftCategory = ref<ScrapCategory>(props.scrap.category);
const draftContent = ref(props.scrap.content);
const draftTodoHasTime = ref(false);
const draftTodoTime = ref('09:00');

function startEdit() {
  draftCategory.value = props.scrap.category;
  draftContent.value = props.scrap.content;
  draftTodoHasTime.value = props.scrap.category === '待办' && Boolean(props.todoTime);
  draftTodoTime.value = props.todoTime || '09:00';
  editing.value = true;
}

function cancelEdit() {
  editing.value = false;
}

function saveEdit() {
  if (!draftContent.value.trim()) {
    return;
  }

  emit(
    'update',
    props.scrap.id,
    draftCategory.value,
    draftContent.value,
    draftCategory.value === '待办' && draftTodoHasTime.value ? draftTodoTime.value : ''
  );
  editing.value = false;
}

function confirmDelete() {
  uni.showModal({
    title: '删除零碎',
    content: '这条记录会被删除。如果它关联了待办，对应待办也会一起移除。',
    confirmText: '删除',
    confirmColor: '#8a5960',
    success: (result) => {
      if (result.confirm) {
        emit('delete', props.scrap.id);
      }
    }
  });
}
</script>

<template>
  <view class="scrap-item">
    <view v-if="!editing" class="read-mode">
      <view class="item-top">
        <text v-if="!hideCategory" class="category">{{ scrap.category }}</text>
        <text v-else class="content inline-content">{{ scrap.content }}</text>
        <view class="item-actions">
          <button class="ghost-action" @tap.stop="startEdit">修改</button>
          <button class="danger-action" @tap.stop="confirmDelete">删除</button>
        </view>
      </view>
      <text v-if="!hideCategory" class="content">{{ scrap.content }}</text>
    </view>

    <view v-else class="edit-mode">
      <textarea v-model="draftContent" maxlength="500" />
      <scroll-view scroll-x enable-flex class="category-scroll">
        <view class="category-row">
          <button
            v-for="item in categories"
            :key="item"
            :class="['category-chip', { active: draftCategory === item }]"
            @tap.stop="draftCategory = item"
          >
            {{ item }}
          </button>
        </view>
      </scroll-view>
      <TodoTimePicker v-if="draftCategory === '待办'" v-model:has-time="draftTodoHasTime" v-model:time="draftTodoTime" compact />
      <view class="edit-actions">
        <button class="ghost-action" @tap.stop="cancelEdit">取消</button>
        <button class="save-action" @tap.stop="saveEdit">保存</button>
      </view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.scrap-item {
  border-bottom: 1px solid #e5edf4;
  padding: 8px 0;
}

.scrap-item:last-child {
  border-bottom: 0;
}

.read-mode,
.edit-mode {
  display: grid;
  gap: 7px;
}

.item-top {
  display: flex;
  min-width: 0;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.item-actions,
.edit-actions {
  display: flex;
  gap: 6px;
}

.category {
  flex: 0 0 auto;
  width: fit-content;
  border-radius: 999px;
  padding: 2px 8px;
  background: #eaf4ff;
  color: #2f72b4;
  font-size: 12px;
}

.content {
  overflow-wrap: anywhere;
  color: #202733;
  font-size: 14px;
  line-height: 1.45;
}

.inline-content {
  min-width: 0;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

textarea {
  width: 100%;
  height: 72px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 9px;
  background: #fbfdff;
  color: #202733;
  font-size: 14px;
  line-height: 1.45;
}

.category-scroll {
  display: block;
  width: 100%;
  min-width: 0;
  height: 30px;
  white-space: nowrap;
}

.category-row {
  display: inline-flex;
  min-width: max-content;
  gap: 6px;
}

.category-chip {
  min-width: 54px;
  height: 30px;
  min-height: 30px;
  border: 1px solid #dce4ec;
  border-radius: 999px;
  padding: 0 10px;
  background: #fbfdff;
  color: #6f7b8a;
  font-size: 12px;
  line-height: 30px;
}

.category-chip.active {
  border-color: rgba(74, 144, 217, 0.56);
  background: #eaf4ff;
  color: #2f72b4;
  font-weight: 750;
}

.ghost-action,
.danger-action,
.save-action {
  height: 26px;
  min-height: 26px;
  border-radius: 8px;
  padding: 0 8px;
  font-size: 11px;
  line-height: 26px;
}

.ghost-action {
  border: 1px solid #dce4ec;
  background: #fbfdff;
  color: #6f7b8a;
}

.danger-action {
  border: 1px solid rgba(138, 89, 96, 0.24);
  background: rgba(138, 89, 96, 0.08);
  color: #8a5960;
}

.save-action {
  background: #4a90d9;
  color: #ffffff;
}
</style>
