# Task Plan: PetWell iOS 未完善頁面開發計劃

## Goal
為 PetWell iOS 應用中所有未完善的頁面制定詳細的開發計劃，包括 Profile 頁面 6 個待開發模塊、Social Search、Share Pet Profile、Blog Post 功能、Insurance AI 推薦以及登錄功能佔位。

## Current Phase
Phase 3

## Phases

### Phase 1: 現狀分析與頁面盤點 ✅
- [x] 分析 iOS 項目結構（Swift + SwiftUI + SwiftData）
- [x] 識別所有未完善的頁面和功能
- [x] 評估每個功能的開發複雜度
- [x] 輸出發現記錄到 findings.md
- **Status:** complete

### Phase 2: 為每個未完善頁面制定開發計劃
- [x] Profile 頁面 6 個待開發模塊詳細計劃
- [x] Social Search 功能詳細計劃
- [x] Share Pet Profile 詳細計劃
- [x] Blog Post 功能詳細計劃
- [x] Insurance AI 推薦詳細計劃
- [x] 登錄功能詳細計劃
- [x] 文檔記錄到 findings.md
- **Status:** complete

### Phase 3: 技術架構設計
- [ ] 設計共享組件和服務層
- [ ] 規劃數據模型
- [ ] 定義 API 接口需求
- **Status:** in_progress

### Phase 4: 優先級排序與實施規劃
- [ ] 確定開發順序
- [ ] 估算工作量
- [ ] 制定里程碑
- **Status:** pending

### Phase 5: 總結與交付
- [ ] 整合所有計劃
- [ ] 生成最終報告
- **Status:** pending

---

## 已識別的未完善頁面清單

### 1. Profile 頁面 - 待開發模塊 (6個)
| 模塊 | 文件位置 | 當前狀態 |
|------|----------|----------|
| Booking Record | RecordsView.swift:125-127 | PlaceholderView |
| Recent Purchase | RecordsView.swift:129-131 | PlaceholderView |
| Insurance | RecordsView.swift:133-135 | PlaceholderView |
| Activity Tracking | RecordsView.swift:137-139 | PlaceholderView |
| Travel Document | RecordsView.swift:141-143 | PlaceholderView |
| Pet Care Tips | RecordsView.swift:145-147 | PlaceholderView |

### 2. Social Search - 功能未完成
| 功能 | 文件位置 | 當前狀態 |
|------|----------|----------|
| 添加好友 | SocialSearchView.swift:247-252 | TODO - 無動作 |
| 商店/診所詳情 | SocialSearchView.swift:254-259 | TODO - 無動作 |
| 搜尋結果數據 | SocialSearchView.swift:33-50 | Mock Data |

### 3. Share Pet Profile - 未完成
| 功能 | 文件位置 | 當前狀態 |
|------|----------|----------|
| 分享邏輯 | SharePetProfileView.swift:160 | TODO - 未實現 |

### 4. Blog Post - 部分待開發
| 功能 | 文件位置 | 當前狀態 |
|------|----------|----------|
| 圖片選擇器 | ContentView.swift:577-598 | 佔位區域 |
| Tags 功能 | ContentView.swift:622-627 | 點擊無響應 |

### 5. Insurance - 部分待完成
| 功能 | 文件位置 | 當前狀態 |
|------|----------|----------|
| AI 推薦卡 | InsuranceCompareView.swift:811 | 需連接 API |
| Provider Logos | InsuranceCompareView.swift:349 | 靜態佔位圖 |

### 6. 登錄 - 功能佔位
| 功能 | 文件位置 | 當前狀態 |
|------|----------|----------|
| Google SSO | AuthViewModel.swift:88 | 佔位 - 需 GoogleSignIn SDK |
| Email OTP | AuthViewModel.swift:121 | 佔位 - 需 API |

---

## Key Questions
1. 哪些功能應該優先開發？（用戶價值 vs 技術依賴）
2. 哪些組件可以在多個模塊間共享？
3. 是否需要後端 API 支持？優先順序如何？

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Profile 頁面的 6 個模塊作為第一優先級 | 直接影響用戶體驗的核心功能 |
| Social Search 作為第二優先級 | 社交功能是產品差異化關鍵 |
| Login 佔位最後處理 | 需要第三方 SDK 集成，較複雜 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| 無 | - | 首次規劃，暫無錯誤 |

## Notes
- 使用 SwiftUI + SwiftData 作為前端框架
- 需要與後端團隊協調 API 接口定義
- 部分功能可能需要第三方 SDK（Google Sign-In）
