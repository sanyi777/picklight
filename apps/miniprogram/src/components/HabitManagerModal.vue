<script setup lang="ts">
import { ref } from 'vue';
import HabitForm from './HabitForm.vue';
import { formatHabitWeekdays } from './habitWeekdays';
import type { Habit, HabitWeekday } from '@/domain/types';
import { usePicklightStore } from '@/stores/usePicklightStore';

const emit = defineEmits<{
  close: [];
}>();

const store = usePicklightStore();
const createFormKey = ref(0);
const editingHabit = ref<Habit>();

function createHabit(content: string, time: string, weekdays: HabitWeekday[]) {
  try {
    store.addHabit(content, time, weekdays);
    createFormKey.value += 1;
    uni.showToast({ title: '习惯已创建', icon: 'success' });
  } catch (error) {
    uni.showToast({ title: error instanceof Error ? error.message : '无法创建习惯', icon: 'none' });
  }
}

function saveHabit(content: string, time: string, weekdays: HabitWeekday[]) {
  if (!editingHabit.value) return;

  try {
    store.updateHabit(editingHabit.value.id, content, time, weekdays);
    editingHabit.value = undefined;
    uni.showToast({ title: '习惯已更新', icon: 'success' });
  } catch (error) {
    uni.showToast({ title: error instanceof Error ? error.message : '无法更新习惯', icon: 'none' });
  }
}

function confirmDelete(habit: Habit) {
  uni.showModal({
    title: '删除习惯',
    content: `将删除“${habit.content}”以及今天起 7 天内对应的待办。`,
    confirmText: '删除',
    confirmColor: '#8a5960',
    success: (result) => {
      if (result.confirm) {
        store.deleteHabit(habit.id);
        editingHabit.value = undefined;
      }
    }
  });
}
</script>

<template>
  <view class="habit-overlay" @tap="emit('close')">
    <view class="habit-modal" @tap.stop>
      <view class="modal-head">
        <view>
          <text class="modal-title">{{ editingHabit ? '修改习惯' : '习惯待办' }}</text>
          <text class="modal-subtitle">
            {{ editingHabit ? '今天起 7 天内的待办会同步更新' : '按设定日期自动进入待办' }}
          </text>
        </view>
        <button class="close-action" @tap.stop="emit('close')">关闭</button>
      </view>

      <scroll-view scroll-y class="modal-scroll">
        <view v-if="editingHabit" class="editor-content">
          <HabitForm
            :key="editingHabit.id"
            :initial-content="editingHabit.content"
            :initial-time="editingHabit.time"
            :initial-weekdays="editingHabit.weekdays"
            submit-label="保存修改"
            @submit="saveHabit"
          />
          <view class="editor-actions">
            <button class="cancel-action" @tap.stop="editingHabit = undefined">取消修改</button>
            <button class="delete-action" @tap.stop="confirmDelete(editingHabit)">删除习惯</button>
          </view>
        </view>

        <view v-else class="manager-content">
          <section class="create-section">
            <text class="section-title">设置新习惯</text>
            <HabitForm :key="createFormKey" @submit="createHabit" />
          </section>

          <section class="list-section">
            <view class="section-head">
              <text class="section-title">已有习惯</text>
              <text class="habit-count">{{ store.habits.length }} 条</text>
            </view>

            <view v-if="store.habits.length" class="habit-list">
              <view v-for="habit in store.habits" :key="habit.id" class="habit-item">
                <view class="habit-copy">
                  <text class="habit-content">{{ habit.content }}</text>
                  <text class="habit-meta">
                    {{ formatHabitWeekdays(habit.weekdays) }}{{ habit.time ? ` · ${habit.time}` : ' · 无截止时间' }}
                  </text>
                </view>
                <button class="edit-action" @tap.stop="editingHabit = habit">修改</button>
              </view>
            </view>
            <view v-else class="empty-state">还没有习惯待办</view>
          </section>
        </view>
      </scroll-view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.habit-overlay {
  position: fixed;
  z-index: 40;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 12px;
  background: rgba(32, 39, 51, 0.38);
}

.habit-modal {
  display: grid;
  width: 100%;
  max-width: 420px;
  max-height: 86vh;
  min-height: 0;
  grid-template-rows: auto minmax(0, 1fr);
  border: 1px solid #dce4ec;
  border-radius: 8px;
  background: #ffffff;
  box-shadow: 0 18px 48px rgba(32, 39, 51, 0.2);
}

.modal-head,
.section-head,
.habit-item,
.editor-actions {
  display: flex;
  min-width: 0;
  align-items: center;
}

.modal-head {
  justify-content: space-between;
  gap: 10px;
  border-bottom: 1px solid #e5edf4;
  padding: 14px 16px;
}

.modal-title,
.modal-subtitle,
.section-title,
.habit-content,
.habit-meta {
  display: block;
}

.modal-title {
  color: #202733;
  font-size: 19px;
  font-weight: 800;
  line-height: 1.2;
}

.modal-subtitle {
  margin-top: 4px;
  color: #6f7b8a;
  font-size: 12px;
  line-height: 1.35;
}

.close-action,
.edit-action,
.cancel-action,
.delete-action {
  height: 30px;
  min-height: 30px;
  border: 0;
  border-radius: 8px;
  margin: 0;
  padding: 0 10px;
  font-size: 12px;
  font-weight: 750;
  line-height: 30px;
}

.close-action,
.edit-action {
  background: #eaf4ff;
  color: #2f72b4;
}

.modal-scroll {
  width: 100%;
  max-height: calc(86vh - 67px);
  min-height: 0;
}

.manager-content,
.editor-content {
  display: grid;
  gap: 16px;
  padding: 16px;
}

.create-section,
.list-section {
  display: grid;
  gap: 12px;
}

.list-section {
  border-top: 1px solid #e5edf4;
  padding-top: 14px;
}

.section-head {
  justify-content: space-between;
  gap: 10px;
}

.section-title {
  color: #202733;
  font-size: 15px;
  font-weight: 800;
}

.habit-count,
.habit-meta {
  color: #6f7b8a;
  font-size: 12px;
}

.habit-list {
  display: grid;
}

.habit-item {
  justify-content: space-between;
  gap: 10px;
  border-bottom: 1px solid #e5edf4;
  padding: 10px 0;
}

.habit-copy {
  display: grid;
  min-width: 0;
  gap: 4px;
}

.habit-content {
  overflow-wrap: anywhere;
  color: #202733;
  font-size: 14px;
  font-weight: 750;
}

.empty-state {
  display: grid;
  min-height: 76px;
  place-items: center;
  border: 1px dashed #ccd9e5;
  border-radius: 8px;
  color: #6f7b8a;
  font-size: 13px;
}

.editor-actions {
  gap: 8px;
}

.cancel-action,
.delete-action {
  flex: 1;
}

.cancel-action {
  border: 1px solid #dce4ec;
  background: #ffffff;
  color: #6f7b8a;
}

.delete-action {
  background: rgba(138, 89, 96, 0.1);
  color: #8a5960;
}

@media (max-width: 360px) {
  .habit-overlay {
    padding: 10px;
  }

  .modal-head,
  .manager-content,
  .editor-content {
    padding-right: 12px;
    padding-left: 12px;
  }
}
</style>
