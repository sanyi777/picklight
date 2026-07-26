# 拾光 TimeGleam 当前项目上下文

更新时间：2026-07-26
仓库：`sanyi777/picklight`
本地项目：`C:\Users\86185\Documents\拾光`
当前阶段：`v0.1.0` 已完成真机验收并发布线上版本
当前平台：仅微信小程序，本地优先

本文用于让新的开发会话快速接管项目。产品研究原始结论见 `docs/phase0-user-research.md`，早期产品定义见 `docs/phase0-product-definition.md`；如文档与当前代码冲突，以本文、现有测试和代码为准。

## 1. 一句话定位

拾光是一个私人注意力助理，核心闭环是“30 秒记录、当天看见、围绕锚点推进、用番茄钟回到当前行动”。它不是复杂日历，也不是单纯备忘录或计时器。

## 2. 已锁定的关键决策

### 2.1 平台与技术路线

- 当前只开发微信小程序。
- 已放弃 Windows、PC、iOS 原生、Android 原生和旧 Flutter 框架路线。
- 技术栈：uni-app、Vue 3、TypeScript、Pinia、Vitest、微信小程序本地存储。
- 当前不做登录、云同步、多设备协作、系统提醒、AI 整理、情绪识别和复杂统计。
- 第一阶段保持本地优先；版本更新前通过 JSON 导出备份保障数据。

### 2.2 信息架构

底部导航固定为三栏：

1. 首页
2. 零碎
3. 专注

独立“日程”入口和路由已移除，待办与锚点流程由首页承接。`src/pages/schedule/index.vue` 仍残留在源码中，但不在 `pages.json` 路由里，属于可后续清理的旧页面。

### 2.3 产品规则

- “日程”和“待办”是同一个概念，统一称为“待办”。
- 首页只允许选择真实今天到未来第 6 天，共 7 天。
- 待办时间统一理解为“截止时间”，当前不触发提醒。
- 待办排序：未完成有时间按时间升序；未完成无时间按创建时间倒序；已完成按完成时间倒序。
- 未完成待办跨日后滚到下一天，并清空原截止时间。
- 已完成待办在次日结算时删除；若来自零碎，其关联零碎也一起删除。
- 待办与“零碎-待办”是一条记录的双向关联：内容、分类、完成状态和删除保持同步。
- 零碎创建时必须分类：灵感、随想、待办、分心、复盘。
- 零碎页默认显示“全部”，按创建时间倒序，条目不截断；暂不做搜索。
- 每天最多两个主锚点，进度只支持手动修改。
- 完成度达到 100% 的锚点次日清除；未完成锚点携带进度滚到下一天并占用名额。
- 番茄钟“本轮小事”独立于待办和锚点。
- 番茄钟支持 15/25/45 分钟和 1-180 分钟自定义时长。
- “放弃”与“完成”都写入普通历史，按真实专注秒数统计，不额外显示放弃标记。
- 专注历史只保留当天，按完成顺序展示，可修改事项、删除记录。
- 分心记录归入当天“零碎-分心”，可在零碎页编辑、改分类和删除。
- 首页不再提供“写一条今日复盘”板块；复盘仍可在零碎页直接记录。

## 3. 当前页面状态

### 3.1 首页

已实现：

- 七日日期轴和选中日期待办。
- 今日最多两个锚点，支持新增、弹窗修改、删除和手动进度。
- 快速新增待办，可选截止时间。
- 快速捕捉入口。
- 快速进入专注页。
- “指引”和“数据”位于同一行。
- 三步首次使用指引：快速捕捉、今日待办、专注。
- 数据管理：导出、合并导入、二次确认清空。

当前首页体验：

- 快速捕捉由首页内嵌输入改为点击后弹出卡片。
- 快速捕捉卡片已改为屏幕水平、垂直居中，最大宽度 `420px`。
- `ScrapComposer` 增加 `autoFocus`，弹窗打开后聚焦输入框。

### 3.2 零碎页

已实现：

- 新建时选择分类。
- 默认“全部”，也可按随想、灵感、待办、分心、复盘筛选。
- 全部和分类视图均按创建时间倒序。
- 支持编辑内容、修改分类、删除。
- 待办类零碎支持截止时间并与首页待办同步。
- 待办改为其他分类后退出待办列表；其他分类改为待办时创建关联待办。

### 3.3 专注页

已实现：

- 展示和管理当天锚点。
- 创建、开始、暂停、继续、完成、放弃、到点后再延长 5 分钟。
- 使用真实时间戳计算进度；切页面、切后台或锁屏期间不依赖前台定时器，返回后按时间戳恢复显示。
- 今日专注时长汇总。
- 点击“专注历史”打开屏幕中央的模态卡片。
- 历史卡片支持修改事项和删除；点击遮罩或关闭按钮退出。
- 历史弹窗使用 `v-if`/`wx:if` 条件创建，页面隐藏时强制销毁，避免透明遮罩拦截计时按钮。
- 分心捕捉和当天分心列表。

重要实现决策：番茄钟不再使用自定义 `PomodoroPanel` 组件。计时、暂停、完成和放弃按钮直接写在 `pages/focus/index.vue`，直接调用 Pinia store，减少微信小程序自定义组件事件边界导致的真机失效风险。

## 4. 数据与跨日行为

### 4.1 状态模型

`PicklightState` 包含：

- `todos`
- `scraps`
- `anchors`
- `focusSessions`
- `activeDate`

关键关联：

- `Todo.sourceScrapId` 指向来源零碎。
- `Scrap.linkedTodoId` 指向关联待办。
- `Scrap.todoCompleted` 镜像待办完成状态。
- `FocusSession` 通过 `status`、`startedAt`、`pausedAt`、`pausedTotalSeconds`、`actualSeconds` 表达计时状态。

### 4.2 启动结算

`usePicklightStore.hydrate()` 是应用启动结算入口：

- 从本地存储读取状态。
- 从最早过期日期逐天结算到真实今天。
- 滚动未完成待办和锚点。
- 删除已完成待办及其关联零碎。
- 清除今天以前的专注历史。
- 将 `activeDate` 重置到真实今天并持久化。

页面不应自行复制跨日业务规则，只负责展示和调用 store action。

### 4.3 备份

- 当前备份 `schemaVersion` 为 `2`。
- 导出为完整 JSON，包含 app 标识、schema 版本、导出时间和完整状态。
- 旧 schema 明确报不兼容，不提供迁移。
- 导入采用合并，不覆盖本地状态。
- 内容完全相同的待办或零碎视为重复，保留本地版本。
- 锚点按同日期同标题去重；专注记录按事项和创建时间去重。
- 清空数据要求二次确认。

## 5. 架构思路

```text
pages / components
        |
        v
usePicklightStore (应用编排、持久化、跨领域同步)
        |
        v
domain/* (纯业务规则、不可依赖 UI 或 uni API)
        |
        v
storage/localStore.ts (微信本地存储适配)
```

### pages

- 承担页面结构、输入状态和用户流程。
- 不复制排序、跨日、关联同步等领域规则。
- 专注页可以维护每秒刷新的展示时钟，但真实剩余时间必须由时间戳推导。

### components

- `MiniProgramShell.vue`：页面容器、安全区和底部导航。
- `DemoTabBar.vue`：三栏导航。
- `CoverScreenMode.vue`：Pura X 外屏等极小屏专用模式。
- `WeekStrip.vue`：七日日期轴。
- `TodoItem.vue`：待办展示和完成交互。
- `TodoTimePicker.vue`：有/无截止时间选择。
- `ScrapComposer.vue`、`ScrapItem.vue`：零碎创建与编辑。
- `AnchorCard.vue`：锚点展示、进度和编辑弹窗。

已删除：

- `PomodoroPanel.vue`
- `FocusHistoryModal.vue`

二者的交互目前直接在专注页实现，以规避此前真机按钮无响应和遮罩残留问题。

### store

`stores/usePicklightStore.ts` 是唯一应用状态中心，负责：

- hydrate / persist / reset。
- 跨日结算。
- 待办与零碎双向联动。
- 锚点操作。
- 番茄钟状态流转。
- schema 2 备份导出和合并导入。

### domain

- `domain/todos.ts`：创建、排序、完成和跨日。
- `domain/scraps.ts`：分类、排序和待办联动数据创建。
- `domain/anchors.ts`：每日上限、进度和继承。
- `domain/focus.ts`：状态机、时间戳计算、完成/放弃和历史清理。
- `domain/backup.ts`：schema 校验、序列化、归一化和合并。
- `domain/date.ts`：日期工具。
- `domain/types.ts`：领域类型。

## 6. 屏幕适配策略

- 常规页面通过固定网格轨道、内部滚动区和安全区适配避免内容互相挤压。
- 窄屏使用 `@media (max-width: 360px)` 收紧间距和计时器尺寸。
- 短屏允许专注页纵向滚动，避免按钮被底部导航裁切。
- Pura X 外屏不承载完整三栏应用，命中外屏轮廓时显示 `CoverScreenMode`。
- 中央模态卡片使用全屏 fixed 遮罩、`place-items: center`、`width: 100%` 和 `max-width: 420px`。

## 7. 最近完成的重要修改

| 提交 | 内容 |
| --- | --- |
| `d299db4e` | 实现正式迭代主体：三栏 IA、领域规则、schema 2、引导、专注和适配 |
| `611bc970` | 改进操作式引导并压缩锚点区域 |
| `5bfc7753` | 简化首页待办与锚点编辑，移除首页复盘板块 |
| `83f2946c` | 修复番茄钟控制区被裁切 |
| `49f7aa94` | 将专注控制改为同步事件 |
| `709aa359` | 让番茄钟按钮直接连接 store |
| `efd851c4` | 重写专注页番茄钟，删除旧组件和全屏历史组件 |
| `4ea80855` | 在专注页增加条件渲染的历史模态卡片 |
| `eb79b7e9` | 将专注历史卡片移到屏幕中央 |

`efd851c4` 还增加了 `pages/focus/__tests__/focus-page-architecture.test.ts`，防止旧番茄钟组件重新进入关键运行链路，并检查暂停、完成、放弃仍由页面直接处理。

## 8. 当前验证状态

2026-07-26 发布后验证：

```powershell
cd C:\Users\86185\Documents\拾光\apps\miniprogram
npm run test -- --run
npm run typecheck
npm run build:mp-weixin
```

结果：

- Vitest：8 个测试文件，38 项测试通过。
- TypeScript：通过。
- 微信小程序生产构建：通过。
- 构建目录：`apps/miniprogram/dist/build/mp-weixin`。
- 编译产物已确认包含原生暂停、完成、放弃按钮及直接 store 调用。
- 编译产物已确认专注历史遮罩受 `wx:if` 控制。
- 最新版本已由用户完成真机体验并发布线上。
- 构建仍有 Dart Sass `legacy-js-api` deprecation warning，不阻塞运行。

线上验收覆盖番茄钟核心操作、中央专注历史弹窗和中央快速捕捉弹窗。后续进入线上反馈观察阶段。

## 9. 当前 Git 工作区状态

最新产品代码提交：`6337748e feat: show quick capture in centered modal`。

当前存在未提交或未跟踪内容，接手时不要直接重置：

- `AGENTS.md`：临时产品访谈约束。
- `avatar-ui.html`：与当前小程序主线关系不明确，暂未处理。

不要使用 `git reset --hard` 或覆盖这些文件。处理前先确认它们是否仍有用途。

## 10. 下一步待办

### 已完成：v0.1.0 发布

- 最新生产构建已通过自动化验证。
- 番茄钟和两个中央弹窗已完成真机体验。
- 微信小程序线上版本已发布。

### P0：线上观察

- 收集真实用户在记录、待办、锚点和专注闭环中的反馈。
- 优先记录数据丢失、跨日异常、计时恢复失败和布局不可操作等阻塞问题。
- 不因零散建议立即扩大功能范围，先判断是否影响核心闭环。

### P1：仓库清理与补测

- 删除或归档未路由的 `pages/schedule/index.vue`，前提是确认无代码引用。
- 为首页快速捕捉弹窗补一个轻量架构/交互测试。
- 增加极端数据和长文本真机测试。
- 复核备份合并时待办/零碎双向关联在重复内容场景下是否始终完整。
- 处理或升级依赖以消除 Dart Sass warning，非发布阻塞项。
- 确认 `avatar-ui.html` 和临时 `AGENTS.md` 是否保留。

### v0.2：习惯待办（已实现，待真机验收）

- 首页已新增独立“习惯”入口，与“指引”“数据”并列。
- 点击“习惯”在首页中央打开管理卡片，不进入独立全屏页面。
- 可设置内容、可选固定时间、每天或每周指定日期；规则持续生效，直到主动删除。
- 匹配日期自动生成普通待办；未完成时次日删除，不滚动。
- 修改或删除习惯时，今天至未来第六天的实例会同步重算。
- 数据新增 `habits` 和 `Todo.sourceHabitId`；备份升级到 schema 3，并兼容 schema 2。
- 当前自动化验证为 10 个测试文件、53 项测试通过，类型检查和微信构建通过。
- 系统提醒继续暂不实现。完整需求与真机验收清单见 `docs/v0.2-habit-todo-prd.md`。

## 11. 明确暂不实现

- 登录和云同步。
- 系统提醒、DDL 通知。
- AI 自动整理和情绪识别。
- 标签、项目体系和复杂统计。
- 零碎关键词搜索。
- Windows、PC、Android 或 iOS 客户端。

## 12. 新会话建议读取顺序

1. `docs/current-project-context.md`
2. `docs/phase0-user-research.md`
3. `apps/miniprogram/src/pages.json`
4. `apps/miniprogram/src/stores/usePicklightStore.ts`
5. `apps/miniprogram/src/domain/types.ts`
6. `apps/miniprogram/src/domain/todos.ts`
7. `apps/miniprogram/src/domain/anchors.ts`
8. `apps/miniprogram/src/domain/focus.ts`
9. `apps/miniprogram/src/domain/backup.ts`
10. 当前要修改的页面与对应测试

建议使用的 skills：

- Bug 或真机交互异常：`diagnosing-bugs`
- 新功能按既定规则实现：`implement` 或 `tdd`
- UI/UX 调整：`frontend-design`，完成后配合 `web-design-guidelines`
- 代码审查：`code-review`

新会话可直接使用以下提示：

```text
继续开发拾光微信小程序。请先深度读取 docs/current-project-context.md，并检查 git status。当前线上版本为 v0.1.0，只做微信小程序，采用 uni-app + Vue 3 + TypeScript + Pinia，本地优先。三栏为首页、零碎、专注。番茄钟已重写到专注页并直接调用 store，最新自动化验证为 8 个测试文件、38 项测试通过，真机验收通过且已发布线上。请从线上反馈观察或文档中的 P1 清理事项继续。
```
