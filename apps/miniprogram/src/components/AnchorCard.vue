<script setup lang="ts">
import { ref } from 'vue';
import type { DailyAnchor, ID } from '@/domain/types';

const props = defineProps<{
  anchor: DailyAnchor;
}>();

const emit = defineEmits<{
  progress: [id: ID, value: number];
  rename: [id: ID, title: string];
  delete: [id: ID];
}>();

const editing = ref(false);
const draftTitle = ref(props.anchor.title);

function startEdit() {
  draftTitle.value = props.anchor.title;
  editing.value = true;
}

function saveEdit() {
  const trimmed = draftTitle.value.trim();
  if (!trimmed) {
    return;
  }

  emit('rename', props.anchor.id, trimmed);
  editing.value = false;
}

function cancelEdit() {
  editing.value = false;
}

function confirmDelete() {
  uni.showModal({
    title: '删除锚点',
    content: '这个锚点会从今天移除，已记录的番茄钟不会被删除。',
    confirmText: '删除',
    confirmColor: '#8a5960',
    success: (result) => {
      if (result.confirm) {
        emit('delete', props.anchor.id);
      }
    }
  });
}
</script>

<template>
  <view class="anchor-card">
    <view class="anchor-layout">
      <view class="anchor-content">
        <view class="title-line">
          <text class="anchor-title">{{ anchor.title }}</text>
          <text class="anchor-progress">{{ anchor.progress }}%</text>
        </view>
        <slider
          :value="anchor.progress"
          min="0"
          max="100"
          activeColor="#4a90d9"
          backgroundColor="#e5edf4"
          block-size="14"
          @change="emit('progress', anchor.id, Number($event.detail.value))"
        />
      </view>
      <view class="anchor-actions">
        <button class="ghost-action" @tap.stop="startEdit">修改</button>
      </view>
    </view>

    <view v-if="editing" class="editor-overlay" @tap="cancelEdit">
      <view class="editor-panel" @tap.stop>
        <text class="editor-title">修改锚点</text>
        <textarea v-model="draftTitle" maxlength="80" auto-height placeholder="锚点名称" />
        <view class="editor-actions">
          <button class="ghost-action" @tap.stop="cancelEdit">取消</button>
          <button class="save-action" @tap.stop="saveEdit">保存</button>
        </view>
        <button class="danger-action delete-anchor" @tap.stop="confirmDelete">删除这个锚点</button>
      </view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.anchor-card {
  border: 1px solid #e1eaf2;
  border-radius: 8px;
  padding: 5px 8px;
  background: #fbfdff;
}

.anchor-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 44px;
  min-width: 0;
  gap: 7px;
  align-items: start;
}

.anchor-content {
  display: grid;
  min-width: 0;
  gap: 2px;
}

.title-line {
  display: flex;
  min-width: 0;
  align-items: flex-start;
  gap: 7px;
}

.anchor-title {
  flex: 1;
  min-width: 0;
  overflow-wrap: anywhere;
  color: #202733;
  font-size: 15px;
  font-weight: 700;
  line-height: 1.36;
}

.anchor-progress {
  flex: 0 0 auto;
  color: #2f72b4;
  font-size: 12px;
  font-weight: 750;
  font-variant-numeric: tabular-nums;
  line-height: 20px;
}

slider {
  height: 20px;
  margin: 0;
  transform: translateY(0);
}

textarea {
  width: 100%;
  min-height: 36px;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 8px;
  background: #ffffff;
  color: #202733;
  font-size: 13px;
  line-height: 1.35;
}

.editor-overlay {
  position: fixed;
  z-index: 40;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(32, 39, 51, 0.38);
}

.editor-panel {
  display: grid;
  width: 100%;
  max-width: 320px;
  gap: 12px;
  border-radius: 8px;
  padding: 16px;
  background: #ffffff;
  box-shadow: 0 18px 48px rgba(32, 39, 51, 0.2);
}

.editor-title {
  color: #202733;
  font-size: 17px;
  font-weight: 800;
}

.editor-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.anchor-actions {
  display: grid;
  width: 44px;
  gap: 4px;
}

.ghost-action,
.danger-action,
.save-action {
  width: 44px;
  height: 24px;
  min-height: 24px;
  border-radius: 8px;
  padding: 0;
  font-size: 11px;
  line-height: 24px;
}

.ghost-action {
  border: 1px solid #dce4ec;
  background: #ffffff;
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

.editor-actions .ghost-action,
.editor-actions .save-action,
.delete-anchor {
  width: 100%;
  height: 34px;
  min-height: 34px;
  font-size: 13px;
  line-height: 34px;
}

@media (max-width: 360px) {
  .anchor-card {
    padding: 5px 7px;
  }

  .anchor-layout {
    grid-template-columns: minmax(0, 1fr) 40px;
    gap: 5px;
  }

  .anchor-actions {
    width: 40px;
  }

  .ghost-action,
  .danger-action,
  .save-action {
    width: 40px;
    font-size: 10px;
  }

  .anchor-title {
    font-size: 14px;
  }
}
</style>
