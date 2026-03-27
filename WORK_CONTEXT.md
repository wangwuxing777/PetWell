# WORK_CONTEXT — PetWell (iOS)

**TASK_ID:** TASK-20260327-2020
**更新时间:** 2026-03-27 20:20
**完整记录:** [→ 根目录 master_progress.md](../../master_progress.md)

## 当前任务
Pull latest + code review session。PR #11 已合并入 main，当前分支已 fast-forward 同步。

## 状态速览
- ✅ 已完成：`git fetch origin` + `git merge origin/main`（fast-forward 到 7046cc3）
- ✅ 已完成：代码审查 — RecordsView.swift + TravelDocumentView.swift
- 🔄 进行中：等待用户确认修复方向或开始新任务

## 本次涉及的关键文件
- `Views/Records/RecordsView.swift` — 宠物卡片拖拽排序 + 展开/收起逻辑（未提交的本地修改）
- `Views/Records/TravelDocumentView.swift` — 旅行证件模块（已提交，含 mock data）

## 注意事项
- 构建环境问题：Xcode 26.4 / iOS 26.4 SDK，但仅安装了 iOS 26.2 Simulator Runtime → 需在 Xcode Settings > Components 下载 iOS 26.4 Runtime
- TravelDocumentView 有 3 处 hardcoded `petId: "1"`（行 709、987、1000）—— 应替换为 `pet?.petID ?? UUID().uuidString`
- TravelDocumentView 使用 `PetDocument.mockData` 而非真实持久化 —— 属于占位实现，待后端接入时替换
- RecordsView 本地修改尚未提交
