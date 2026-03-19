# PetWell iOS Dark Mode 设计方案（v1）

## 目标
- 在不破坏现有信息架构和交互的前提下，给 PetWell 提供一致、可读、可维护的深色模式。
- 以“语义色 Token + 渐进改造”方式落地，避免一次性大改风险。

## 1. 设计原则
- **语义优先**：页面只使用语义颜色（如 `textPrimary`），不直接写 `Color.white`/`Color.black`。
- **对比可读**：正文对比度目标不低于 WCAG AA（普通文字至少 4.5:1）。
- **层级清晰**：背景分 3 层（Base / Elevated / Card），让卡片和浮层在暗色下仍有层次。
- **品牌一致**：保留主品牌蓝，深色下通过亮度与容器色调整保持可读性。

## 2. 颜色 Token（建议）

> 命名使用 `PW/` 前缀，放到 Asset Catalog 的 Color Set，全部支持 Any + Dark 两套值。

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `PW/bg/base` | `#F7F8FA` | `#0F1115` | 页面主背景 |
| `PW/bg/elevated` | `#FFFFFF` | `#161A22` | 导航条/分组块 |
| `PW/bg/card` | `#FFFFFF` | `#1C2230` | 卡片背景 |
| `PW/bg/input` | `#F1F3F7` | `#202838` | 输入框背景 |
| `PW/text/primary` | `#111827` | `#F3F4F6` | 主标题/正文 |
| `PW/text/secondary` | `#6B7280` | `#A3ADC2` | 次要说明文字 |
| `PW/text/inverse` | `#FFFFFF` | `#0B0D12` | 反色文字（品牌按钮） |
| `PW/border/subtle` | `#E5E7EB` | `#2B3548` | 细边框/分割线 |
| `PW/brand/primary` | `#2D6BFF` | `#4A7DFF` | 主按钮、选中态 |
| `PW/state/success` | `#10B981` | `#34D399` | 成功态 |
| `PW/state/warning` | `#F59E0B` | `#FBBF24` | 警告态 |
| `PW/state/error` | `#EF4444` | `#F87171` | 错误态 |

## 3. 组件样式规范

### 3.1 Navigation Bar / Header
- 背景：`PW/bg/elevated`
- 主标题：`PW/text/primary`
- 次级标签：`PW/text/secondary`
- 选中指示条：`PW/brand/primary`

### 3.2 Card（博客卡片/保险卡片/记录卡片）
- 卡片背景：`PW/bg/card`
- 卡片标题：`PW/text/primary`
- 描述：`PW/text/secondary`
- 边框（可选）：`PW/border/subtle`

### 3.3 Button
- Primary：背景 `PW/brand/primary` + 文字 `PW/text/inverse`
- Secondary：背景 `PW/bg/input` + 文字 `PW/text/primary`
- Destructive：背景透明 + 文字 `PW/state/error`

### 3.4 Input / Search / Chip
- 输入框：背景 `PW/bg/input`，文字 `PW/text/primary`，描边 `PW/border/subtle`
- 未选中 Chip：背景 `PW/bg/input`，文字 `PW/text/secondary`
- 选中 Chip：背景 `PW/brand/primary`（低透明度容器），文字 `PW/brand/primary`

## 4. SwiftUI 落地架构（建议）

## 4.1 Theme 访问层
创建 `AppTheme.swift`，统一出口：

```swift
import SwiftUI

enum AppTheme {
  static let bgBase = Color("PW/bg/base")
  static let bgElevated = Color("PW/bg/elevated")
  static let bgCard = Color("PW/bg/card")
  static let bgInput = Color("PW/bg/input")

  static let textPrimary = Color("PW/text/primary")
  static let textSecondary = Color("PW/text/secondary")
  static let textInverse = Color("PW/text/inverse")

  static let borderSubtle = Color("PW/border/subtle")
  static let brandPrimary = Color("PW/brand/primary")
  static let success = Color("PW/state/success")
  static let warning = Color("PW/state/warning")
  static let error = Color("PW/state/error")
}
```

### 4.2 View 层替换策略
- `.foregroundColor(.black)` -> `.foregroundColor(AppTheme.textPrimary)`
- `.foregroundColor(.gray)` -> `.foregroundColor(AppTheme.textSecondary)`
- `.background(Color.white)` -> `.background(AppTheme.bgCard)` 或 `AppTheme.bgElevated`
- 固定浅灰（如 `F8F9FA`）-> `AppTheme.bgBase`

## 5. 分批改造计划（建议 3 批）

### Batch 1（高影响页面，1-2 天）
- `apps/PetWell/PetWell/ContentView.swift`
- `apps/PetWell/Views/Insurance/InsuranceCompareView.swift`
- 目标：去掉核心硬编码白/黑，切到语义色。

### Batch 2（模块页面，2-3 天）
- `apps/PetWell/PetWell/Views/Auth/LoginView.swift`
- `apps/PetWell/PetWell/Views/Onboarding/OnboardingView.swift`
- `apps/PetWell/Views/Records/*.swift`

### Batch 3（全局收敛，1-2 天）
- 通用组件与 Modifier 收敛到统一 Theme API
- 清理遗留 hex 常量和散落颜色逻辑

## 6. 验收标准
- iOS Light/Dark 下关键页面截图回归无“黑字黑底 / 白字白底”问题。
- 主要正文、按钮、输入框文字满足可读性要求。
- 全项目中 `Color.white` / `Color.black`（非图片蒙版等特例）显著下降并可追踪。

## 7. 快速收益（先做这 5 条）
1. 全局页面底色统一替换为 `PW/bg/base`。
2. 所有标题/正文替换为 `PW/text/primary`。
3. 所有次要文字替换为 `PW/text/secondary`。
4. 卡片背景从纯白改为 `PW/bg/card`。
5. 主按钮统一 `PW/brand/primary + PW/text/inverse`。
