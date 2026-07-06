# 拾光 TimeGleam 当前项目上下文

更新时间：2026-07-06  
当前标记：`v0.1.0` MVP demo  
当前状态：关键业务测试已通过，微信小程序构建已通过，`Documents\拾光` 预览目录构建已通过。

## 1. 产品定位

拾光是一个本地优先的私人注意力小助理。它不是传统日历，也不是单纯备忘录或番茄钟，而是帮助用户在一天里随时接住零碎想法、看清待办、回到锚点、保护专注时间。

核心目标：

- 管理一天内和一周内的待办。
- 收纳灵感、随想、待办、分心、复盘等零碎内容。
- 用每天最多两个锚点帮助用户抓住主线。
- 用番茄钟管理一轮专注中要完成的小事。
- 第一版以本地存储和手动操作为主，先跑通核心闭环。

## 2. 关键产品决策

- 当前只做微信小程序。
- 暂时放弃 Windows/PC 端、iOS 原生迁移、Flutter 旧框架和 React Web 主路线。
- 第一版不做提醒/通知、情绪感知、AI 自动整理、云同步、登录账号和多设备协同。
- “日程”和“待办”是同一概念，后续统一叫“待办”。
- 未完成待办会在应用加载时自动滚动到真实今天。
- 每天最多两个锚点。
- 锚点进度第一版只支持手动拖动。
- 不在 UI 上区分“主锚点”和“当前锚点”；“专注锚点”只作为番茄钟运行时的提醒概念。
- 零碎想法一开始就必须分类。
- 零碎分类包括：灵感、随想、待办、分心、复盘。

## 3. 信息架构

底部导航 4 个页面：

- 首页
- 零碎
- 日程
- 专注

### 首页

定位：快速看清今天和快速进入动作。

已实现：

- 当日/选中日期待办。
- 固定从真实今天开始的一周日期栏。
- 动态日程标题。
- 快速新增待办。
- 快速捕捉零碎想法。
- 快速进入番茄钟。
- 数据清空/重置入口，放在“今日日程”板块右上角。

### 零碎

定位：快速收纳和分类碎片内容。

已实现：

- 顶部输入框、分类胶囊和收纳按钮。
- 分类收纳箱。
- 单条零碎修改内容、修改分类、删除。
- 待办类零碎和待办系统联动。
- 收纳箱内部滚动，避免撑高页面。

### 日程

定位：管理待办、锚点、周视图和复盘。

已实现：

- 待办列表内部滚动。
- 最多两个锚点。
- 锚点新增、修改、删除、手动拖动进度。
- 锚点卡片为长条状，不显示“主锚点”字样。
- 当日复盘归档到零碎-复盘。

### 专注

定位：执行现场。

已实现：

- 展示并管理当天锚点。
- 两个锚点时隐藏新增入口。
- 创建番茄钟时填写本轮小事。
- 手动设置分钟数，也支持 15/25/45 分钟快捷选择。
- 开始、暂停、继续、完成。
- 完成后可创建新一轮番茄钟。
- 历史番茄钟展示、内部滚动、删除。
- 分心捕捉。
- 修复历史番茄钟下方大空白和页面抽搐问题。

## 4. 技术路线

当前采用：

- uni-app
- Vue 3
- TypeScript
- Pinia
- Vitest
- 微信小程序构建目标：`mp-weixin`
- 本地存储封装：`localStore`

开发工作树：

```text
C:\Users\86185\.codex\worktrees\2350\拾光
```

微信开发者工具实际预览项目：

```text
C:\Users\86185\Documents\拾光
```

微信开发者工具应导入：

```text
C:\Users\86185\Documents\拾光\apps\miniprogram\dist\build\mp-weixin
```

工作习惯：

- 在 worktree 修改代码。
- 验证通过后同步相关文件到 `C:\Users\86185\Documents\拾光`。
- 再在 Documents 目录执行一次 `npm run build:mp-weixin`。
- 用户通常在微信开发者工具里看 Documents 目录的构建产物。

## 5. 关键业务测试状态

当前关键业务测试已通过，覆盖重点包括：

- 日期工具。
- 待办创建、排序、完成、跨日滚动。
- 应用 hydrate 时把过期未完成待办滚动到真实今天。
- 零碎创建和分类。
- 待办类零碎联动生成待办。
- 日程复盘归档为复盘类零碎。
- 锚点最多两个限制。
- 锚点更新、删除、进度。
- 番茄钟创建、开始、完成。
- 本地状态重置并清空持久化数据。

最近一次验证结果：

```bash
npm run typecheck
npm run test
npm run build:mp-weixin
```

结果：

- `npm run typecheck` 通过。
- `npm run test` 通过，6 个测试文件，20 个测试。
- worktree `npm run build:mp-weixin` 通过。
- `C:\Users\86185\Documents\拾光\apps\miniprogram` 预览目录 `npm run build:mp-weixin` 通过。

构建时会出现 Dart Sass `legacy-js-api` deprecation warning，目前不影响运行。

## 6. 重要文件

### 页面

- `apps/miniprogram/src/pages/home/index.vue`
  - 首页整体 demo 风格。
  - 固定周栏和选中日期逻辑。
  - 动态日程标题。
  - 内部滚动待办列表。
  - 快速捕捉和快速番茄钟。
  - 数据清空/重置入口。

- `apps/miniprogram/src/pages/scraps/index.vue`
  - 零碎页收纳区、分类胶囊、收纳箱。
  - 条目编辑、删除、改分类。
  - 收纳箱内部滚动。

- `apps/miniprogram/src/pages/schedule/index.vue`
  - 待办区域内部滚动。
  - 锚点列表、新增、修改、删除、进度。
  - 复盘归档到零碎。

- `apps/miniprogram/src/pages/focus/index.vue`
  - 专注页锚点、番茄钟、分心捕捉三段布局。
  - 两个锚点时压缩布局。
  - 番茄钟区按内容自适应，避免历史下方空白。

### 组件

- `MiniProgramShell.vue`：自定义小程序外壳，处理状态栏和底部导航。
- `DemoTabBar.vue`：自定义底部导航。
- `WeekStrip.vue`：固定 7 天周栏。
- `TodoItem.vue`：待办条目。
- `ScrapComposer.vue`：零碎输入和分类。
- `ScrapItem.vue`：零碎条目编辑/删除/改分类。
- `AnchorCard.vue`：锚点长条卡片，支持进度、修改、删除。
- `PomodoroPanel.vue`：番茄钟创建态、运行态和历史记录。

### 状态和业务逻辑

- `apps/miniprogram/src/stores/usePicklightStore.ts`
  - 全局状态中心。
  - hydrate/persist。
  - 过期未完成待办滚动到真实今天。
  - 数据重置。
  - 待办、零碎、锚点、番茄钟 action。

- `apps/miniprogram/src/storage/localStore.ts`
  - 本地加载、保存、清空。

- `apps/miniprogram/src/domain/todos.ts`
  - 待办创建、完成、滚动。

- `apps/miniprogram/src/domain/scraps.ts`
  - 零碎创建、分类、更新、删除。

- `apps/miniprogram/src/domain/anchors.ts`
  - 锚点创建、数量限制、改名、删除、进度。

- `apps/miniprogram/src/domain/focus.ts`
  - 专注会话创建、开始、完成。

## 7. 架构思路

当前架构分 5 层：

- `pages`：页面结构和用户流程。
- `components`：可复用 UI 和局部交互。
- `stores`：Pinia 状态中心，负责本地数据加载、保存和业务 action。
- `domain`：纯业务逻辑，不依赖 UI 和小程序 API，可单元测试。
- `storage`：本地持久化封装。

原则：

- 本地优先。
- 第一版不接云端。
- 业务逻辑尽量放在 domain/store，页面只负责流程和展示。
- UI 继续围绕 `demo-miniprogram.html` 的方向打磨。

## 8. v0.1 已知限制

- 只做本地存储，不做账号、云同步和多设备协同。
- 不做系统提醒/通知。
- 不做 AI 自动整理。
- 番茄钟主要保证前台体验，后台和退出后的恢复策略后续再完善。
- 真机尺寸适配还需要继续回归。
- 构建有 Sass deprecation warning，暂不影响运行。

## 9. 下次新会话建议起点

可以直接说：

```text
继续开发拾光小程序。请先读取 docs/current-project-context.md 和 docs/v0.1-acceptance.md。当前 v0.1.0 MVP demo 已通过关键业务测试、typecheck、test 和 mp-weixin 构建；下一步从 v0.1 已知限制和真机回归问题继续。
```
