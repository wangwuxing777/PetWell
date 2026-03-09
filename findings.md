# Findings — For You: Multi-Agent Pipeline (Final Architecture)

---

## A. 数据层（已确认）

| 数据 | 来源 | 字段 |
|------|------|------|
| 宠物基础信息 | `PetModel` (SwiftData) | species / breed / birthYear / weightKg / isNeutered / allergies |
| 年龄计算 | `PetModel.birthYear` | `Calendar.current.component(.year, from:.now) - pet.birthYear` |
| 健康报告 | `pet.healthReports: [HealthReportModel]` | `markdownContent`（AI 提取文本） |
| 保险产品 | `InsuranceService.shared.products` | minAge/maxAge 格式 = "11 years" |

---

## B. 最终 UI 流程

```
用户点击 "For Me" (两个入口)
        ↓
ForYouProgressView（全屏，Stepper 样式）
        ↓ Pipeline 自动执行
        ↓ 完成后 fade 过渡（0.4s）
RAGChatView（推荐内容作为 AI 第一条消息）
        ↓ 用户可立即追问
```

---

## C. 5-Stage 流水线（最终版）

```
Stage 1  [本地 · 即时]   AgeFilterAgent + BreedRiskAgent + LargeDogAgent (并行)
         完成展开子卡：  "12/15 plans eligible · ⚠️ HCM risk detected"

Stage 2  [本地 · 即时]   HealthReportExtractor：读 markdownContent
         完成展开子卡：  "3 health reports loaded (latest: Jan 2026)"
                        如无报告："No health reports · Basic profile only"

Stage 3  [网络 · ~3s]    Medical RAG  — POST /api/chat {model:"medical"}
         完成展开子卡：  "Key finding: Elevated ALT · No cardiac markers"
                        (无报告时 → 跳过，子卡显示 "Skipped — no health reports")

Stage 4  [本地 · 即时]   ContextAssemblerAgent
         完成展开子卡：  "Context ready · Sending to insurance AI..."

Stage 5  [网络 · ~4s]    Insurance RAG  — POST /api/chat {model:"insurance"}
         完成 → 自动 fade 到 RAGChatView，推荐作为 AI 首条消息
```

---

## D. Stepper 进度 UI 设计

### StepItem 数据模型
```swift
struct PipelineStepItem: Identifiable {
    let id: Int
    let title: String
    let subtitle: String   // 执行中的描述
    var status: StepStatus
    var resultSummary: String?  // 完成后展开子卡的文案

    enum StepStatus {
        case pending     // ○  灰色圆圈
        case running     // ⟳  蓝色旋转动画
        case completed   // ✅  绿色 checkmark
        case skipped     // ⊘  灰色 dash（无健康报告时跳过 Stage 3）
        case failed      // ✗  红色
    }
}
```

### ForYouProgressView 视觉结构
```
ForYouProgressView
├── 顶部：PetProfileCard
│   └── 头像 + 名字 + 品种 + 年龄
│
└── StepperList
    ├── [●]─ Stage 1: "Age & Breed Check"        ← ✅ 已完成
    │   │     "Checking age eligibility..."
    │   └──── [ResultCard] "12/15 eligible · ⚠️ HCM"  ← 展开子卡
    │
    ├── [●]─ Stage 2: "Loading Health Reports"   ← ✅ 已完成
    │   │
    │   └──── [ResultCard] "3 reports found"
    │
    ├── [●]─ Stage 3: "Medical AI Analysis"      ← ⟳ 进行中
    │         "Reading your pet's health history..."
    │         （蓝色脉冲动画）
    │
    ├── [○]─ Stage 4: "Preparing Context"        ← ○ 待执行
    │
    └── [○]─ Stage 5: "Insurance Recommendation" ← ○ 待执行
              "Matching plans to your pet's profile..."
```

### SwiftUI 实现要点
```swift
struct StepperProgressView: View {
    let steps: [PipelineStepItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 16) {
                    // 左侧：竖线 + 状态圆圈
                    VStack(spacing: 0) {
                        StepStatusIcon(status: step.status)  // ✅ / ⟳ / ○ / ⊘
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(stepLineColor(for: step.status))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 28)

                    // 右侧：内容
                    VStack(alignment: .leading, spacing: 6) {
                        Text(step.title).font(.system(size: 15, weight: .semibold))
                        Text(step.subtitle).font(.system(size: 13)).foregroundColor(.secondary)

                        // 完成后展开的结果子卡
                        if step.status == .completed, let summary = step.resultSummary {
                            ResultSubCard(text: summary)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: steps.map(\.status))
    }
}
```

---

## E. RAGChatView 改造：支持预填首条 AI 消息

```swift
// 新增参数：initialAIMessage（推荐内容直接作为 AI 首条消息）
struct RAGChatView: View {
    var contextString: String?
    var initialModel: ChatModel = .insurance
    var initialAIMessage: String? = nil   // ← 新增：ForYou 推荐内容
    @Binding var isPresented: Bool

    var body: some View {
        // ...
        .onAppear {
            // 如果有预填消息，跳过 greeting，直接展示推荐
            if let prefilledMsg = initialAIMessage {
                let aiMsg = ChatMessage(content: prefilledMsg, isUser: false)
                ragService.messages = [aiMsg]
            } else {
                // 现有 greeting 逻辑
                let greeting = ChatMessage(content: "Hello, I am your insurance assistant...", isUser: false)
                ragService.messages.append(greeting)
            }
            ragService.createSession()
        }
    }
}
```

---

## F. ForYouOrchestrator（最终版）

```swift
@MainActor
final class ForYouOrchestrator: ObservableObject {
    @Published var steps: [PipelineStepItem] = PipelineStepItem.defaultSteps
    @Published var isComplete = false
    @Published var forYouResult: ForYouChatResult?

    struct ForYouChatResult {
        let initialAIMessage: String    // 直接给 RAGChatView 的首条消息
        let enrichedContext: String     // 用作后续聊天的 contextString
    }

    func run(pet: PetModel, allProducts: [InsuranceProduct]) async {
        // Stage 1
        markRunning(1)
        let petAge     = Calendar.current.component(.year, from: .now) - pet.birthYear
        let eligible   = AgeFilterAgent.filter(petAgeYears: petAge, products: allProducts)
        let risks      = BreedRiskAgent.risks(forBreed: pet.breed)
        let isLargeDog = LargeDogAgent.isLargeDog(species: pet.species, breed: pet.breed)
        markCompleted(1, summary: buildStage1Summary(eligible: eligible.count,
                                                      total: allProducts.count,
                                                      risks: risks, isLargeDog: isLargeDog))

        // Stage 2
        markRunning(2)
        let healthText = HealthReportExtractor.extract(from: pet.healthReports)
        markCompleted(2, summary: healthText != nil
            ? "\(pet.healthReports.count) report(s) loaded"
            : "No health reports found")

        // Stage 3
        var clinicalSummary: String? = nil
        if let text = healthText {
            markRunning(3)
            clinicalSummary = await callMedicalRAG(healthText: text)
            let summary = clinicalSummary.map { "Key findings: \($0.prefix(80))..." }
                       ?? "Analysis unavailable"
            markCompleted(3, summary: summary)
        } else {
            markSkipped(3, summary: "Skipped — no health reports")
        }

        // Stage 4
        markRunning(4)
        let enrichedContext = ContextAssemblerAgent.build(
            pet: pet, petAgeYears: petAge,
            eligibleCount: eligible.count, totalCount: allProducts.count,
            breedRisks: risks, isLargeDog: isLargeDog, clinicalSummary: clinicalSummary
        )
        markCompleted(4, summary: "Context ready")

        // Stage 5
        markRunning(5)
        let recommendation = await callInsuranceRAG(context: enrichedContext)
            ?? "Sorry, I couldn't generate a recommendation right now. Please try again."
        markCompleted(5, summary: "Recommendation ready")

        // Done → pass result to ForYouProgressView for transition
        await Task.sleep(nanoseconds: 400_000_000)  // brief pause before transition
        forYouResult = ForYouChatResult(
            initialAIMessage: recommendation,
            enrichedContext: enrichedContext
        )
        isComplete = true
    }

    // RAG 调用（直接 http 到 localhost:8000，复用 RAGService 的 URL）
    private func callMedicalRAG(healthText: String) async -> String? { ... }
    private func callInsuranceRAG(context: String) async -> String? { ... }
}
```

---

## G. 文件变更清单（最终）

### 新建文件（8 个）
```
Services/ForYou/
├── AgeFilterAgent.swift
├── LargeDogAgent.swift
├── BreedRiskAgent.swift           ← placeholder，Human Lead 填充数据
├── HealthReportExtractor.swift
├── ContextAssemblerAgent.swift
└── ForYouOrchestrator.swift       ← 含 ForYouPipelineStage / ForYouChatResult

Views/Insurance/
├── ForYouProgressView.swift       ← Stepper 进度 UI + 自动 fade 到 Chat
└── PetSelectorSheet.swift         ← 多宠物手动选择
```

### 修改文件（3 个）
```
Views/Insurance/RAGChatView.swift
  → 新增 initialAIMessage: String? 参数（可选，不影响现有调用）

Views/Insurance/InsuranceLandingView.swift
  → "For Me" 按钮: .fullScreenCover → ForYouProgressView

Views/Insurance/InsuranceCompareView.swift
  → "Get Recommendation for My Pet": .fullScreenCover → ForYouProgressView
```
