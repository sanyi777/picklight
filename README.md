# 拾光 TimeGleam

当前版本：`v0.1.0` MVP demo

拾光是一个微信小程序优先、本地优先的私人注意力小助理。它的目标不是做复杂日历，而是帮助用户随时接住零碎想法、看清今天要做什么、围绕每天最多两个锚点推进事情，并用番茄钟保护一轮专注时间。

## 当前功能

- 首页
  - 查看今日/选中日期待办。
  - 固定展示从真实今天开始的一周日期栏。
  - 快速新增待办。
  - 快速捕捉零碎想法。
  - 快速进入番茄钟。
  - 右上角提供数据清空/重置入口。

- 零碎
  - 记录灵感、随想、待办、分心、复盘。
  - 新增时选择分类。
  - 支持修改内容、修改分类、删除。
  - 待办类零碎会联动生成待办。
  - 收纳箱内部滚动，避免撑高页面。

- 日程
  - 待办列表内部滚动。
  - 管理每天最多两个锚点。
  - 支持锚点新增、修改、删除、手动拖动进度。
  - 支持当日复盘归档到零碎-复盘。

- 专注
  - 展示并管理当天锚点。
  - 创建番茄钟时填写本轮小事。
  - 支持手动设置番茄钟分钟数，也支持 15/25/45 分钟快捷选择。
  - 支持开始、暂停、继续、完成。
  - 支持历史番茄钟查看和删除。
  - 支持分心捕捉。

- 待办继承
  - 应用启动/页面加载本地数据时，会检查真实系统日期。
  - 未完成待办会自动从过去日期滚动到真实今天。
  - 已完成待办不会滚动。

## 技术栈

- uni-app
- Vue 3
- TypeScript
- Pinia
- Vitest
- 微信小程序构建目标：`mp-weixin`
- 本地存储：`uni.getStorageSync` / `uni.setStorageSync` / `uni.removeStorageSync`

## 运行方式

安装依赖：

```bash
cd apps/miniprogram
npm install
```

开发构建：

```bash
npm run dev:mp-weixin
```

然后在微信开发者工具中导入：

```text
apps/miniprogram/dist/dev/mp-weixin
```

## 构建方式

生产构建：

```bash
cd apps/miniprogram
npm run build:mp-weixin
```

微信开发者工具导入构建产物：

```text
apps/miniprogram/dist/build/mp-weixin
```

## 验证命令

```bash
cd apps/miniprogram
npm run typecheck
npm run test
npm run build:mp-weixin
```

## 文档

- [产品定义](docs/phase0-product-definition.md)
- [当前项目上下文](docs/current-project-context.md)
- [v0.1 验收记录](docs/v0.1-acceptance.md)
- [小程序原型](demo-miniprogram.html)

## 当前限制

- 第一版只做本地存储，不做账号、云同步和多设备协同。
- 第一版不做系统提醒/通知。
- 第一版不做 AI 自动整理。
- 番茄钟主要保证前台体验，后台和退出后的恢复策略后续再完善。
- UI 已按 demo 方向打磨，但仍需继续做更多真机尺寸回归。
