# Test Plan — For You (AI Insurance Recommendation Pipeline)

**Feature:** ForYou 多 Agent 保險推薦鏈路
**Branch:** `feature/ai-dev-for-you`
**Last Updated:** 2026-03-09
**Test Author:** AI Dev Team

---

## 1. 範圍概述 (Scope)

本計劃涵蓋 For You pipeline 的全部測試層次：

| 層次 | 工具 | 測試檔案 | 覆蓋對象 |
|------|------|---------|---------|
| Unit | XCTest | `PetWellTests/ForYouAgentTests.swift` | 5 個本地 Agent |
| UI | XCUITest | `PetWellUITests/ForYouUITests.swift` | 完整用戶流程 |
| 手動 E2E | 人工 | 本文第 4 節 | RAG 後端聯調 |

---

## 2. 一次性 Xcode Setup（必須先做）

> ⚠️ 項目目前 **沒有** Unit Test 或 UI Test 的 Target。
> 需要按以下步驟在 Xcode 手動新增兩個 Target，然後拖入已生成的測試檔案。

### 2A — 新增 Unit Test Target（PetWellTests）

1. 開啟 `PetWell.xcworkspace`（或 `.xcodeproj`）
2. **File → New → Target…**
3. 選擇 **Unit Testing Bundle** → Next
4. 填寫：
   - **Product Name:** `PetWellTests`
   - **Language:** Swift
   - **Target to be Tested:** `PetWell`
   - com.wwx
5. Finish
6. Xcode 會自動生成 `PetWellTests/PetWellTests.swift` — **刪除此檔案**
7. 在 Project Navigator 中找到剛才新建的 `PetWellTests` group
8. 將 `PetWellTests/ForYouAgentTests.swift`（AI 已生成）拖入該 group
9. 在彈出視窗中勾選 **"Add to targets: PetWellTests"** ✓

### 2B — 新增 UI Test Target（PetWellUITests）

1. 重複 **File → New → Target…**
2. 選擇 **UI Testing Bundle** → Next
3. 填寫：
   - **Product Name:** `PetWellUITests`
   - **Language:** Swift
   - **Target to be Tested:** `PetWell`
4. Finish
5. 刪除 Xcode 自動生成的佔位檔案
6. 將以下兩個已生成的檔案拖入 `PetWellUITests` group：
   - `PetWellUITests/ForYouUITests.swift`
   - `PetWellUITests/BlogUITests.swift`（補充現有孤兒檔案）
7. 勾選 **"Add to targets: PetWellUITests"** ✓

---

## 3. Unit Tests — ForYou Local Agents

### 3.1 如何執行

```bash
# 終端執行（推薦，CI 友好）
cd /Users/vfzzz/Desktop/PetWell_Project/apps/PetWell
xcodebuild test \
  -workspace PetWell.xcworkspace \
  -scheme PetWellTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  | xcpretty
```

或在 Xcode 中按 ⌘U（選 PetWellTests scheme）。

---

### 3.2 AgeFilterAgent Tests（`AgeFilterAgentParseTests` + `AgeFilterAgentFilterTests`）

**目的：** 驗證年齡字串解析和保險計劃篩選邏輯。

| 測試 ID | 函數名 | 輸入 | 期望輸出 | 備註 |
|--------|--------|------|---------|------|
| UT-AGE-01 | `test_parseYears_years` | `"11 years"` | `11.0` | |
| UT-AGE-02 | `test_parseYears_months` | `"6 months"` | `0.5` | 誤差 < 1e-9 |
| UT-AGE-03 | `test_parseYears_weeks` | `"8 weeks"` | `≈0.1538` | 8/52 |
| UT-AGE-04 | `test_parseYears_noLimit_returnsNil` | `"no limit"`, `"none"` | `nil` | 三種別名 |
| UT-AGE-05 | `test_parseYears_nilInput_returnsNil` | `nil` | `nil` | |
| UT-AGE-06 | `test_parseYears_emptyString_returnsNil` | `""`, `"   "` | `nil` | |
| UT-AGE-07 | `test_parseYears_unknownUnit_returnsNil` | `"5 decades"` | `nil` | |
| UT-AGE-08 | `test_filter_petInRange_returnsProduct` | age=3, min=8wk, max=11yr | count=1 | |
| UT-AGE-09 | `test_filter_petTooYoung_excludesProduct` | age=0, min=1yr | count=0 | |
| UT-AGE-10 | `test_filter_petTooOld_excludesProduct` | age=6, max=5yr | count=0 | |
| UT-AGE-11 | `test_filter_noUpperLimit_eligibleWhenOld` | age=15, max="no limit" | count=1 | |
| UT-AGE-12 | `test_filter_returnsOnlyEligible` | age=5, 3 plans | count=1 | 只有 All Ages 符合 |
| UT-AGE-13 | `test_filter_exactBoundary_inclusive` | age=11, max=11yr | count=1 (11) / 0 (12) | 邊界值 |

---

### 3.3 LargeDogAgent Tests（`LargeDogAgentTests`）

**目的：** 驗證大型犬品種識別。

| 測試 ID | 函數名 | 輸入 | 期望輸出 |
|--------|--------|------|---------|
| UT-DOG-01 | `test_largeDog_returnsTrueForKnownLargeBreed` | (Dog, Labrador) | `true` |
| UT-DOG-02 | `test_largeDog_returnsFalseForSmallBreed` | (Dog, Chihuahua) | `false` |
| UT-DOG-03 | `test_largeDog_returnsFalseForCatSpecies` | (Cat, Maine Coon) | `false` |
| UT-DOG-04 | `test_largeDog_acceptsCanineSpecies` | (Canine, German Shepherd) | `true` |
| UT-DOG-05 | `test_largeDog_caseInsensitive` | (DOG, LABRADOR) | `true` |
| UT-DOG-06 | `test_largeDog_hyphenatedBreedNormalized` | (Dog, flat-coated retriever) | `true` |
| UT-DOG-07 | `test_largeDog_emptyBreed_returnsFalse` | (Dog, "") | `false` |

---

### 3.4 BreedRiskAgent Tests（`BreedRiskAgentTests`）

**目的：** 驗證品種遺傳病資料庫查找邏輯。

| 測試 ID | 函數名 | 輸入 | 期望輸出 |
|--------|--------|------|---------|
| UT-BRD-01 | `test_risks_knownCat_returnsCorrectConditions` | "Maine Coon" | 含 HCM + HD |
| UT-BRD-02 | `test_risks_knownDog_returnsCorrectConditions` | "French Bulldog" | 含 BOAS + IVDD |
| UT-BRD-03 | `test_risks_unknownBreed_returnsEmpty` | "Unknown Mix" | `[]` |
| UT-BRD-04 | `test_risks_caseInsensitive` | "LABRADOR" == "labrador" | 同樣結果 |
| UT-BRD-05 | `test_risks_partialMatch_golden` | "Golden Retriever Mix" | 非空 |
| UT-BRD-06 | `test_risks_allHaveNonEmptyFields` | 5 known breeds | 所有 condition/abbr 非空 |
| UT-BRD-07 | `test_riskSummary_knownBreed_returnsNonNilString` | "Maine Coon" | 非 nil |
| UT-BRD-08 | `test_riskSummary_unknownBreed_returnsNil` | "Unknown Mix" | `nil` |
| UT-BRD-09 | `test_riskSummary_containsAbbreviation` | "Pug" | 含 "BOAS" |

---

### 3.5 HealthReportExtractor Tests（`HealthReportExtractorTests`）

**目的：** 驗證從 `[HealthReportModel]` 提取最新 3 條報告的邏輯。

> 注意：`HealthReportModel` 是 SwiftData `@Model`，但可以直接 `init()` 而無需
> 插入 ModelContainer，只要不使用 `@Query` 或持久化功能即可。

| 測試 ID | 函數名 | 情境 | 期望輸出 |
|--------|--------|------|---------|
| UT-HRE-01 | `test_extract_emptyList_returnsNil` | `[]` | `nil` |
| UT-HRE-02 | `test_extract_allEmptyContent_returnsNil` | 全空白內容 | `nil` |
| UT-HRE-03 | `test_extract_singleReport_returnsFormattedString` | 1 條報告 | 含 `[Health Report 1]` 及內容 |
| UT-HRE-04 | `test_extract_sortsNewestFirst` | 舊+新兩條 | 新的排在前面 |
| UT-HRE-05 | `test_extract_limitsToThreeReports` | 5 條 | 只有 1–3，無 4、5 |
| UT-HRE-06 | `test_extract_truncatesLongContent` | 800 字元內容 | X 字元數 ≤ 400 |
| UT-HRE-07 | `test_extract_multipleReports_separatedByDivider` | 2 條 | 含 `---` 分隔符 |
| UT-HRE-08 | `test_extract_categoryIncludedInLabel` | category="Blood Test" | 含 "Blood Test" |
| UT-HRE-09 | `test_extract_skipsEmptyReports_butIncludesNonEmpty` | 1 空 + 1 非空 | 返回非空內容 |

---

### 3.6 ContextAssemblerAgent Tests（`ContextAssemblerAgentTests`）

**目的：** 驗證送給 Insurance RAG 的 enrichedContext 結構完整。

| 測試 ID | 函數名 | 驗證內容 |
|--------|--------|---------|
| UT-CTX-01 | `test_build_containsPetName` | 含寵物名稱 |
| UT-CTX-02 | `test_build_containsSpeciesAndBreed` | 含 species + breed |
| UT-CTX-03 | `test_build_containsAge` | 含年齡數字 |
| UT-CTX-04 | `test_build_containsWeight` | 含體重數字 |
| UT-CTX-05 | `test_build_neuteredFlag` | neutered=true→"Yes" / false→"No" |
| UT-CTX-06 | `test_build_containsEligibilityCount` | 含 "4 of 7" |
| UT-CTX-07 | `test_build_withBreedRisks_containsConditionAbbreviations` | 含 MVD、SM |
| UT-CTX-08 | `test_build_noBreedRisks_showsFallbackText` | 含 "No specific breed risks" |
| UT-CTX-09 | `test_build_largeDogFlag_includedWhenTrue` | 含 large breed / liability |
| UT-CTX-10 | `test_build_largeDogFlag_notIncludedWhenFalse` | 不含 "Large Breed Notice" |
| UT-CTX-11 | `test_build_clinicalSummaryIncluded` | 含 clinical summary 原文 |
| UT-CTX-12 | `test_build_noClinicalSummary_showsFallbackText` | 含 "No health reports on file" |
| UT-CTX-13 | `test_build_allergiesIncluded_whenPresent` | allergies="chicken"→含 "chicken" |
| UT-CTX-14 | `test_build_allergiesNotShown_whenEmpty` | 空 allergies→不含 "Allergies:" |
| UT-CTX-15 | `test_build_containsTaskInstruction` | 含 "Task:" + "Age eligibility" |

---

## 4. UI Tests — ForYou 用戶流程

### 4.1 如何執行

```bash
# 終端執行
cd /Users/vfzzz/Desktop/PetWell_Project/apps/PetWell
xcodebuild test \
  -workspace PetWell.xcworkspace \
  -scheme PetWellUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  | xcpretty
```

**預條件：**
- 模擬器中至少存在 **1 隻寵物**（可在 Profile Tab 手動添加，或讓測試框架 seed）
- App 需正常登入（測試流程從登入後狀態開始）

---

### 4.2 測試用例

| 測試 ID | 函數名 | 流程 | 通過條件 |
|--------|--------|------|---------|
| TC-UI-01 | `test_forYouButton_visibleAfterScroll` | Insurance Tab → 向上滾動 | `ForYouButton` 出現 |
| TC-UI-02 | `test_forYouButton_tap_launchesPipelineOrSelector` | 點擊 "For Me" | `ForYouProgressView` 或 `PetSelectorSheet` 出現 |
| TC-UI-03 | `test_petSelectorSheet_cancelDismisses` | 多寵物選擇器 → Cancel | Sheet 消失 |
| TC-UI-04 | `test_forYouProgressView_showsFivePipelineSteps` | 進入 Progress View | 5 個 `ForYouStep_1` ~ `ForYouStep_5` 存在 |
| TC-UI-05 | `test_forYouProgressView_closeDismissesView` | 點擊 X 按鈕 | `ForYouProgressView` 消失 |
| TC-UI-06 | `test_guardianFAB_showsRedDotAfterPipelineCompletes` | Pipeline 完成（需後端） | Guardian FAB 可見（含紅點） |

> TC-UI-03 在單寵物裝置上會自動 `XCTSkip`
> TC-UI-06 在沒有 RAG 後端時會自動 `XCTSkip`（timeout 60s）

---

## 5. 手動 E2E 測試清單（RAG 後端聯調）

在後端 `localhost:8000` 運行的情況下，按以下步驟手動驗證完整鏈路：

### Stage 3 — Medical RAG 驗證

| 步驟 | 操作 | 期望結果 |
|------|------|---------|
| E2E-MED-01 | 為有健康報告的寵物運行 For You | Stage 3 顯示 "running" → "completed" |
| E2E-MED-02 | Stage 3 sub-card 顯示 "Key findings: …" | 摘要前 80 字元可見 |
| E2E-MED-03 | 打開後端日誌 | 看到 POST /api/chat with model=medical |
| E2E-MED-04 | 為沒有健康報告的寵物運行 | Stage 3 顯示 "Skipped — no health reports" |

### Stage 5 — Insurance RAG 驗證

| 步驟 | 操作 | 期望結果 |
|------|------|---------|
| E2E-INS-01 | Pipeline 完成 → RAGChatView 自動彈出 | 第一條 AI 消息是保險推薦，非歡迎詞 |
| E2E-INS-02 | 推薦內容含計劃名稱 | 能識別至少 1 個保險計劃名稱 |
| E2E-INS-03 | 關閉 RAGChatView | Guardian FAB 紅點消失 |
| E2E-INS-04 | 再次點擊 Guardian FAB | 顯示 RAGChatView with Insurance model + 推薦作為首條消息 |

### Guardian FAB 紅點行為

| 步驟 | 操作 | 期望結果 |
|------|------|---------|
| E2E-FAB-01 | Pipeline 運行中 | 無紅點 |
| E2E-FAB-02 | Pipeline 完成，用戶未查看 | 紅點出現（動畫） |
| E2E-FAB-03 | 點擊 FAB → 查看 RAGChatView → 關閉 | 紅點消失 |
| E2E-FAB-04 | 再次點擊 FAB（已清除）| 開啟普通 Medical RAGChat，無推薦預填 |

### 回退測試（後端離線情況）

| 步驟 | 期望行為 |
|------|---------|
| E2E-OFF-01 | 後端離線，Stage 3 失敗 | Stage 3 顯示 "Analysis unavailable"，Pipeline 繼續到 Stage 4–5 |
| E2E-OFF-02 | Stage 5 失敗 | 顯示 "Sorry, I couldn't generate a recommendation right now." |
| E2E-OFF-03 | UI 不崩潰 | App 正常顯示 fallback 消息，`hasNewResult = true` 仍被設置 |

---

## 6. 迴歸測試清單（保護現有功能）

運行 For You 後，驗證以下已有功能沒有被破壞：

- [ ] Insurance Landing View 正常顯示（Explore Plans 按鈕正常）
- [ ] InsuranceCompareView 正常顯示（不崩潰）
- [ ] Guardian FAB 在無 For You 推薦時，點擊跳轉 Medical RAGChatView（正常流程）
- [ ] Profile Tab 寵物資料正常顯示
- [ ] HealthReportModel 仍可在 Profile 中新增和查看

---

## 7. 已知限制與待辦

| 項目 | 狀態 | 說明 |
|------|------|------|
| ForYouProgressView 英文文案 | ⚠️ | Step subtitle 僅有英文，需加繁中支援 |
| BreedRiskAgent 資料庫 | ⚠️ | 30+ 品種，Human Lead 需驗證並擴充 |
| RAG 後端未聯調 | ⚠️ | Stage 3/5 需要真實 RAG 模型驗證回應格式 |
| Unit Test Target | ❌ 未建立 | 需按第 2 節步驟手動新增 Xcode Target |
| UI Test Target | ❌ 未建立 | 需按第 2 節步驟手動新增 Xcode Target |
| GuardianFAB 無 accessibilityIdentifier | ⚠️ | TC-UI-06 用近似匹配，建議為 FAB 加 ID |

---

## 8. 目錄結構（測試相關檔案）

```
PetWell_Project/apps/PetWell/
├── PetWellTests/                    ← 新建 Unit Test Target
│   └── ForYouAgentTests.swift       ✅ AI 已生成（含 56 個測試用例）
├── PetWellUITests/
│   ├── BlogUITests.swift            （現有，已孤兒，需加入 UI Test Target）
│   └── ForYouUITests.swift          ✅ AI 已生成（6 個 UI 測試用例）
└── TEST_PLAN_FOR_YOU.md             ← 本文件
```

---

## 9. 持續整合建議

```yaml
# GitHub Actions 片段（供參考）
- name: Run Unit Tests
  run: |
    xcodebuild test \
      -workspace PetWell.xcworkspace \
      -scheme PetWellTests \
      -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      | xcpretty --report junit --output test-results/unit-tests.xml

- name: Run UI Tests
  run: |
    xcodebuild test \
      -workspace PetWell.xcworkspace \
      -scheme PetWellUITests \
      -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      | xcpretty --report junit --output test-results/ui-tests.xml
```

---

*生成時間: 2026-03-09 | Branch: feature/ai-dev-for-you*
