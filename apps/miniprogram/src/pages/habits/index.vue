<script setup lang="ts">
import { onMounted, ref } from 'vue';
import HabitForm from '@/components/HabitForm.vue';
import { formatHabitWeekdays } from '@/components/habitWeekdays';
import MiniProgramShell from '@/components/MiniProgramShell.vue';
import type { Habit, HabitWeekday } from '@/domain/types';
import { usePicklightStore } from '@/stores/usePicklightStore';

const store = usePicklightStore();
const createFormKey = ref(0);
const editingHabit = ref<Habit>();

onMounted(() => {
  store.hydrate();
});

function goBack() {
  uni.navigateBack({
    delta: 1,
    fail: () => uni.redirectTo({ url: '/pages/home/index' })
  });
}

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
      }
    }
  });
}

</script>

<template>
  <view class="page-root">
    <MiniProgramShell active="home" hide-tabs>
      <view class="habit-page">
        <view class="page-head">
          <button class="back-action" aria-label="返回" @tap.stop="goBack">←</button>
          <view class="title-copy">
            <text class="page-title">习惯待办</text>
            <text class="page-subtitle">按设定日期自动进入待办</text>
          </view>
        </view>

        <section class="section create-section">
          <text class="section-title">设置新习惯</text>
          <HabitForm :key="createFormKey" auto-focus @submit="createHabit" />
        </section>

        <section class="section habit-list-section">
          <view class="section-head">
            <text class="section-title">已有习惯</text>
            <text class="habit-count">{{ store.habits.length }} 条</text>
          </view>

          <scroll-view v-if="store.habits.length" scroll-y class="habit-list">
            <view class="habit-list-inner">
              <view v-for="habit in store.habits" :key="habit.id" class="habit-item">
                <view class="habit-copy">
                  <text class="habit-content">{{ habit.content }}</text>
                  <text class="habit-meta">
                    {{ formatHabitWeekdays(habit.weekdays) }}{{ habit.time ? ` · ${habit.time}` : ' · 无截止时间' }}
                  </text>
                </view>
                <view class="habit-actions">
                  <button class="edit-action" @tap.stop="editingHabit = habit">修改</button>
                  <button class="delete-action" @tap.stop="confirmDelete(habit)">删除</button>
                </view>
              </view>
            </view>
          </scroll-view>
          <view v-else class="empty-state">还没有习惯待办</view>
        </section>
      </view>

      <view v-if="editingHabit" class="editor-overlay" @tap="editingHabit = undefined">
        <view class="editor-modal" @tap.stop>
          <view class="editor-head">
            <view>
              <text class="editor-title">修改习惯</text>
              <text class="editor-subtitle">今天起 7 天内的待办会同步更新</text>
            </view>
            <button class="close-action" @tap.stop="editingHabit = undefined">关闭</button>
          </view>
          <HabitForm
            :key="editingHabit.id"
            :initial-content="editingHabit.content"
            :initial-time="editingHabit.time"
            :initial-weekdays="editingHabit.weekdays"
            submit-label="保存修改"
            @submit="saveHabit"
          />
        </view>
      </view>
    </MiniProgramShell>
  </view>
</template>

<style scoped lang="scss">
.page-root {
  height: 100vh;
  min-height: 100vh;
  overflow: hidden;
}

.habit-page {
  display: grid;
  height: 100%;
  min-height: 0;
  grid-template-rows: auto auto minmax(0, 1fr);
  gap: 12px;
  overflow-y: auto;
  padding: 12px;
}

.page-head {
  display: flex;
  min-width: 0;
  align-items: center;
  gap: 10px;
}

.back-action {
  width: 36px;
  height: 36px;
  min-height: 36px;
  flex: 0 0 auto;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  background: #ffffff;
  color: #2f72b4;
  font-size: 20px;
  line-height: 36px;
}

.title-copy {
  min-width: 0;
}

.page-title,
.page-subtitle,
.section-title,
.habit-content,
.habit-meta,
.editor-title,
.editor-subtitle {
  display: block;
}

.page-title {
  color: #202733;
  font-family: Georgia, "Times New Roman", "Songti SC", serif;
  font-size: 25px;
  font-weight: 700;
  line-height: 1.1;
}

.page-subtitle,
.habit-meta,
.editor-subtitle,
.habit-count {
  color: #6f7b8a;
  font-size: 12px;
}

.page-subtitle,
.editor-subtitle {
  margin-top: 4px;
}

.section {
  min-height: 0;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 14px;
  background: rgba(255, 255, 255, 0.94);
  box-shadow: 0 10px 28px rgba(42, 63, 88, 0.08);
}

.create-section {
  display: grid;
  gap: 12px;
}

.habit-list-section {
  display: grid;
  grid-template-rows: auto minmax(0, 1fr);
  gap: 8px;
  overflow: hidden;
}

.section-head,
.habit-item,
.habit-actions,
.editor-head {
  display: flex;
  min-width: 0;
  align-items: center;
}

.section-head,
.editor-head {
  justify-content: space-between;
  gap: 10px;
}

.section-title {
  color: #202733;
  font-size: 16px;
  font-weight: 800;
}

.habit-list {
  height: 100%;
  min-height: 0;
}

.habit-list-inner {
  display: grid;
}

.habit-item {
  justify-content: space-between;
  gap: 10px;
  border-bottom: 1px solid #e5edf4;
  padding: 11px 0;
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

.habit-actions {
  flex: 0 0 auto;
  gap: 6px;
}

.edit-action,
.delete-action,
.close-action {
  height: 30px;
  min-height: 30px;
  border: 0;
  border-radius: 8px;
  padding: 0 10px;
  font-size: 12px;
  font-weight: 750;
  line-height: 30px;
}

.edit-action,
.close-action {
  background: #eaf4ff;
  color: #2f72b4;
}

.delete-action {
  background: rgba(138, 89, 96, 0.1);
  color: #8a5960;
}

.empty-state {
  display: grid;
  min-height: 120px;
  place-items: center;
  border: 1px dashed #ccd9e5;
  border-radius: 8px;
  color: #6f7b8a;
  font-size: 13px;
}

.editor-overlay {
  position: fixed;
  z-index: 40;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 12px;
  background: rgba(32, 39, 51, 0.38);
}

.editor-modal {
  display: grid;
  width: 100%;
  max-width: 420px;
  max-height: 82vh;
  gap: 14px;
  overflow-y: auto;
  border: 1px solid #dce4ec;
  border-radius: 8px;
  padding: 16px;
  background: #ffffff;
  box-shadow: 0 18px 48px rgba(32, 39, 51, 0.2);
}

.editor-title {
  color: #202733;
  font-size: 19px;
  font-weight: 800;
}

@media (max-width: 360px) {
  .habit-page {
    gap: 8px;
    padding: 10px;
  }

  .section {
    padding: 11px;
  }

  .page-title {
    font-size: 22px;
  }

  .habit-actions {
    gap: 4px;
  }

  .edit-action,
  .delete-action {
    padding: 0 8px;
  }
}
</style>
