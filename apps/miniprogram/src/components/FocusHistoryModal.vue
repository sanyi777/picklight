<script setup lang="ts">
import { computed, ref } from 'vue';
import { getActualFocusSeconds } from '@/domain/focus';
import type { FocusSession } from '@/domain/types';

const props = defineProps<{
  sessions: FocusSession[];
}>();

const emit = defineEmits<{
  dismiss: [];
  update: [id: string, task: string];
  delete: [id: string];
}>();

const editingId = ref<string>();
const taskValue = ref('');
const orderedSessions = computed(() =>
  [...props.sessions].sort((a, b) => (b.completedAt ?? b.createdAt).localeCompare(a.completedAt ?? a.createdAt))
);

function formatMinutes(session: FocusSession) {
  return `${Math.floor(getActualFocusSeconds(session) / 60)} 分钟`;
}

function startEditing(session: FocusSession) {
  editingId.value = session.id;
  taskValue.value = session.task;
}

function saveEditing() {
  if (!editingId.value || !taskValue.value.trim()) return;
  emit('update', editingId.value, taskValue.value);
  editingId.value = undefined;
}

function confirmDelete(id: string) {
  uni.showModal({
    title: '删除番茄钟',
    content: '这条历史记录会被删除。',
    confirmText: '删除',
    confirmColor: '#8a5960',
    success: (result) => {
      if (result.confirm) emit('delete', id);
    }
  });
}
</script>

<template>
  <view class="history-overlay" data-eventsync="true" @tap="emit('dismiss')">
    <view class="history-modal" @tap.stop>
      <view class="history-head">
        <view>
          <text class="history-title">专注历史</text>
          <text class="history-subtitle">只保留当天的记录</text>
        </view>
        <button class="close-button" data-eventsync="true" @tap.stop="emit('dismiss')">关闭</button>
      </view>

      <scroll-view v-if="orderedSessions.length" scroll-y class="history-list">
        <view class="history-scroll-inner">
          <view v-for="session in orderedSessions" :key="session.id" class="history-item">
            <view class="history-copy">
              <input v-if="editingId === session.id" v-model="taskValue" @confirm="saveEditing" />
              <text v-else class="history-task">{{ session.task }}</text>
              <text class="history-meta">{{ formatMinutes(session) }}</text>
            </view>
            <view class="history-actions">
              <button class="history-action" @tap.stop="editingId === session.id ? saveEditing() : startEditing(session)">
                {{ editingId === session.id ? '保存' : '修改' }}
              </button>
              <button class="history-action danger" @tap.stop="confirmDelete(session.id)">删除</button>
            </view>
          </view>
        </view>
      </scroll-view>
      <view v-else class="empty-history">今天还没有专注记录</view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.history-overlay {
  position: fixed;
  z-index: 30;
  inset: 0;
  display: grid;
  align-items: end;
  padding: 12px;
  background: rgba(32, 39, 51, 0.36);
}

.history-modal {
  display: grid;
  max-height: 70vh;
  min-height: 236px;
  grid-template-rows: auto minmax(0, 1fr);
  gap: 12px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 16px;
  background: #ffffff;
  box-shadow: 0 18px 48px rgba(32, 39, 51, 0.2);
}

.history-head,
.history-item,
.history-actions {
  display: flex;
  min-width: 0;
  align-items: center;
}

.history-head {
  justify-content: space-between;
  gap: 10px;
}

.history-title,
.history-subtitle {
  display: block;
}

.history-title {
  color: #202733;
  font-size: 19px;
  font-weight: 800;
}

.history-subtitle,
.history-meta {
  color: #6f7b8a;
  font-size: 12px;
}

.history-subtitle {
  margin-top: 4px;
}

.close-button,
.history-action {
  height: 30px;
  min-height: 30px;
  border: 0;
  border-radius: 8px;
  margin: 0;
  padding: 0 10px;
  background: #eaf4ff;
  color: #2f72b4;
  font-size: 12px;
  font-weight: 750;
  line-height: 30px;
}

.history-list {
  height: 100%;
  min-height: 0;
}

.history-scroll-inner {
  padding-right: 2px;
}

.history-item {
  justify-content: space-between;
  gap: 10px;
  border-bottom: 1px solid #e5edf4;
  padding: 9px 0;
}

.history-copy {
  display: grid;
  min-width: 0;
  gap: 3px;
}

.history-task {
  overflow: hidden;
  color: #202733;
  font-size: 14px;
  font-weight: 750;
  text-overflow: ellipsis;
  white-space: nowrap;
}

input {
  height: 30px;
  min-height: 30px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 0 8px;
  background: #fbfdff;
  color: #202733;
  font-size: 13px;
}

.history-actions {
  flex: 0 0 auto;
  gap: 5px;
}

.danger {
  background: rgba(138, 89, 96, 0.1);
  color: #8a5960;
}

.empty-history {
  display: grid;
  place-items: center;
  border: 1px dashed #ccd9e5;
  border-radius: 8px;
  color: #6f7b8a;
  font-size: 13px;
}
</style>
