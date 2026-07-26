# 拾光 TimeGleam

当前线上版本：`v0.1.0`

当前开发版本：`v0.2.0`，习惯待办已实现，待真机验收。

拾光是一个微信小程序优先、本地优先的私人注意力助理。它帮助用户快速接住零碎想法、看清今天要做什么、围绕每天最多两个锚点推进事情，并用番茄钟保护当前的一轮专注。

## 当前状态

- `v0.1.0` 已完成真机验收并发布线上版本。
- 当前只维护微信小程序，不开发 Windows、PC、Android 或 iOS 客户端。
- 数据保存在微信本地存储，可通过 JSON 备份导出和合并导入。
- 底部导航固定为首页、零碎、专注三栏。

## 核心功能

### 首页

- 查看真实今天到未来 6 天的待办。
- 创建有截止时间或无截止时间的待办。
- 管理每天最多两个锚点及其手动进度。
- 通过屏幕中央的快速捕捉卡片记录零碎内容。
- 快速进入专注页。
- 查看首次指引和管理本地数据。

### 零碎

- 记录灵感、随想、待办、分心和复盘。
- 默认混排全部内容，也可按分类筛选。
- 支持修改内容、修改分类和删除。
- 待办类零碎与首页待办双向联动。

### 专注

- 创建 15、25、45 分钟或自定义时长的番茄钟。
- 支持开始、暂停、继续、完成、放弃和延长 5 分钟。
- 使用真实时间戳恢复切页面、切后台和锁屏后的剩余时间。
- 在屏幕中央查看、修改和删除当天专注历史。
- 随时记录分心内容。

### 跨日与备份

- 未完成待办自动滚到下一天并清空旧截止时间。
- 未完成锚点携带进度滚到下一天；完成锚点次日清除。
- 已完成待办和当天专注历史按规则在次日清理。
- 线上 v0.1 备份格式为 schema 2；开发版 v0.2 升级为 schema 3，并兼容导入 schema 2。

### v0.2 习惯待办

- 首页点击“习惯”后，通过居中卡片创建和管理习惯，不跳转全屏页面。
- 设置每天或每周指定日期重复的习惯。
- 固定时间可选，生成的实例沿用普通待办排序与完成交互。
- 未完成习惯实例次日删除，不继承为普通待办。
- 修改和删除规则会同步重算今天起 7 天内的实例。
- 当前开发版验证为 10 个测试文件、53 项测试通过，类型检查和微信生产构建通过。

## 技术栈

- uni-app
- Vue 3
- TypeScript
- Pinia
- Vitest
- 微信小程序本地存储

## 项目结构

```text
apps/miniprogram/
  src/
    components/     可复用界面组件
    composables/     屏幕与视口状态
    domain/          纯业务规则和单元测试
    pages/           首页、零碎、专注页面
    storage/         本地存储适配
    stores/          Pinia 应用状态中心
    styles/          全局样式和设计 token
docs/                产品研究、PRD、验收和项目上下文
demo-miniprogram.html 早期交互原型
```

## 开发与构建

```powershell
cd apps/miniprogram
npm install
npm run dev:mp-weixin
```

微信开发者工具开发目录：

```text
apps/miniprogram/dist/dev/mp-weixin
```

生产构建：

```powershell
cd apps/miniprogram
npm run build:mp-weixin
```

生产构建目录：

```text
apps/miniprogram/dist/build/mp-weixin
```

## 验证

```powershell
cd apps/miniprogram
npm run test -- --run
npm run typecheck
npm run build:mp-weixin
```

`v0.1.0` 发布基线：

- 8 个测试文件、38 项测试通过。
- TypeScript 类型检查通过。
- 微信小程序生产构建通过。
- 最新版本已完成真机体验并发布上线。

构建时存在 Dart Sass `legacy-js-api` deprecation warning，目前不影响构建和运行。

## 文档

- [当前项目上下文](docs/current-project-context.md)
- [v0.1 PRD](docs/v0.1-prd.md)
- [Phase 0 用户研究](docs/phase0-user-research.md)
- [Phase 0 产品定义](docs/phase0-product-definition.md)
- [v0.1 验收记录](docs/v0.1-acceptance.md)
- [早期小程序原型](demo-miniprogram.html)

## 当前边界

- 不做登录、云同步和多设备协同。
- 不做系统提醒和截止时间通知。
- 不做 AI 自动整理、情绪识别、标签和复杂统计。
- 不做零碎关键词搜索。
- 后台不持续执行 JavaScript 定时器；返回小程序时根据真实时间戳恢复计时状态。
