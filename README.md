# 拾光 TimeGleam

拾光是一个小程序优先、本地优先的私人注意力助理。第一版聚焦四件事：

- 管理今日待办和未来 7 天安排
- 记录零碎想法，并按灵感、随想、待办、分心、复盘分类
- 维护每天最多两个主锚点
- 用番茄钟保护当前专注

## 当前技术路线

第一版只做微信小程序，不再保留旧 Flutter、iOS、Android、Windows 或 PC demo 工程。

当前实现位于：

```text
apps/miniprogram
```

技术栈：

- uni-app
- Vue 3
- TypeScript
- Pinia
- Vitest
- 微信小程序本地存储

## 常用命令

```bash
cd apps/miniprogram
npm install
npm run test
npm run typecheck
npm run build:mp-weixin
```

微信开发者工具导入构建产物：

```text
apps/miniprogram/dist/build/mp-weixin
```

## 文档

- 产品定义：[docs/phase0-product-definition.md](docs/phase0-product-definition.md)
- MVP 实施计划：[docs/superpowers/plans/2026-07-05-miniprogram-mvp.md](docs/superpowers/plans/2026-07-05-miniprogram-mvp.md)
- 小程序原型：[demo-miniprogram.html](demo-miniprogram.html)
