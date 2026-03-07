//
//  AIService.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import Foundation

/// AI问诊服务（MVP版）
///
/// ⚠️重要：
/// 1) OpenAI 官方明确建议：不要把 API Key 放在客户端（App）里。
///    生产环境应走你自己的后端（proxy），由后端持有 Key 并做鉴权/限流/日志脱敏。
/// 2) 这里同时提供「直连 OpenAI（仅开发调试）」与「走后端」两种模式。
final class AIService {

// MARK: - Config

enum Endpoint {
    /// 生产推荐：你的后端，如 https://api.yourdomain.com/petwell/ai/triage
    case backend(url: URL)

    /// 仅开发调试：直连 OpenAI Responses API
    /// - Warning: 不要在上架版本使用。
    case openAI(apiKey: String)

    /// 仅开发调试：直连 DeepSeek（OpenAI 兼容的 Chat Completions）
    /// Docs: https://api-docs.deepseek.com/ (OpenAI-compatible)
    /// - Warning: 不要在上架版本使用。
    case deepSeek(apiKey: String, baseURL: URL = URL(string: "https://api.deepseek.com")!)
}

struct Config {
    var endpoint: Endpoint
    /// 模型名称会因不同 provider 而不同：
    /// - OpenAI: 例如 "gpt-4.1-mini" / "gpt-4.1"
    /// - DeepSeek: 例如 "deepseek-chat" / "deepseek-reasoner"
    var model: String = "deepseek-chat"
    /// 最大输出长度（越大越贵）
    var maxOutputTokens: Int = 600
    /// 温度（越大越发散）
    var temperature: Double = 0.2
}

private let config: Config
private let session: URLSession

init(config: Config, session: URLSession = .shared) {
    self.config = config
    self.session = session
}

// MARK: - Public API

    /// Chat message for multi-turn context (session memory).
    struct ChatMessageInput: Codable, Equatable {
        /// "user" | "assistant" | "system"
        var role: String
        var content: String
    }
    /// 根据用户填写的 records（你可以传“健康记录汇总”或结构化 JSON）生成：
    /// - 症状/问题摘要
    /// - 可能原因（非诊断）
    /// - 紧急程度分级（红/橙/黄/绿）
    /// - 下一步建议 & 需要补充的问题
    func triage(from recordSummary: String) async throws -> TriageResult {
        switch config.endpoint {
        case .backend(let url):
            return try await callBackend(url: url, recordSummary: recordSummary)
        case .openAI(let apiKey):
            return try await callOpenAI(apiKey: apiKey, recordSummary: recordSummary)
        case .deepSeek(let apiKey, let baseURL):
            return try await callDeepSeek(apiKey: apiKey, baseURL: baseURL, recordSummary: recordSummary)
        }
    }

    /// Health-domain smalltalk only (NO diagnosis, NO medication advice)
    func chat(_ text: String) async throws -> String {
        switch config.endpoint {
        case .deepSeek(let apiKey, let baseURL):
            return try await callDeepSeekChat(apiKey: apiKey, baseURL: baseURL, text: text)
        case .openAI:
            throw AIServiceError.invalidResponse
        case .backend:
            throw AIServiceError.invalidResponse
        }
    }

    /// Health-domain chat with multi-turn context (session memory).
    /// Pass recent messages (user/assistant) so the model can maintain context.
    func chat(messages: [ChatMessageInput]) async throws -> String {
        switch config.endpoint {
        case .deepSeek(let apiKey, let baseURL):
            return try await callDeepSeekChat(apiKey: apiKey, baseURL: baseURL, messages: messages)
        case .openAI:
            throw AIServiceError.invalidResponse
        case .backend:
            throw AIServiceError.invalidResponse
        }
    }

    /// Detect whether the user is describing concrete pet symptoms (YES/NO only)
    func detectSymptoms(from text: String) async throws -> SymptomDetectionResult {
        switch config.endpoint {
        case .deepSeek(let apiKey, let baseURL):
            return try await callDeepSeekDetectSymptoms(apiKey: apiKey, baseURL: baseURL, text: text)
        case .openAI:
            throw AIServiceError.invalidResponse
        case .backend:
            throw AIServiceError.invalidResponse
        }
    }

    /// Extract structured medical slots from free text (NO diagnosis, NO advice)
    func extractSlots(from text: String) async throws -> SlotExtractionResult {
        switch config.endpoint {
        case .backend:
            throw AIServiceError.invalidResponse // backend extraction not implemented yet
        case .openAI(let apiKey):
            return try await callOpenAIExtract(apiKey: apiKey, text: text)
        case .deepSeek(let apiKey, let baseURL):
            return try await callDeepSeekExtract(apiKey: apiKey, baseURL: baseURL, text: text)
        }
    }
}
// MARK: - DeepSeek direct mode (dev only)

private extension AIService {
func callDeepSeekChat(apiKey: String, baseURL: URL, text: String) async throws -> String {
    return try await callDeepSeekChat(
        apiKey: apiKey,
        baseURL: baseURL,
        messages: [
            .init(role: "user", content: text)
        ]
    )
}

func callDeepSeekChat(apiKey: String, baseURL: URL, messages: [ChatMessageInput]) async throws -> String {
    let url = baseURL.appendingPathComponent("v1/chat/completions")

    let systemInstruction = """
You are PetWell Guardian, a pet-health assistant.

Scope:
- ONLY discuss pets: healthcare/medical, prevention, vaccines, nutrition, basic behavior, products, insurance, and profile.
- If asked about unrelated topics, politely refuse and redirect back to pet topics.

Safety:
- You are not a veterinarian. Do NOT provide a diagnosis.
- Do NOT prescribe medication.
- Do NOT give step-by-step emergency treatment instructions.
- If the user describes urgent warning signs (e.g., trouble breathing, seizures, collapse, uncontrolled bleeding, cannot urinate, repeated vomiting with dehydration), advise seeking in-person veterinary care urgently.

Input format (may appear in the user's message):
- PET PROFILE CONTEXT: (background information about the pet)
- USER MESSAGE: (the user's actual question)

Rules:
- Answer based primarily on USER MESSAGE.
- Use PET PROFILE CONTEXT only as background to personalize; NEVER invent missing facts.
- If USER MESSAGE describes concrete symptoms, respond briefly and suggest the user can enter a step-by-step consultation mode.

Reply in friendly Chinese, 1–3 sentences.
"""

    // Convert to DeepSeek request messages, and ensure a system message is always first.
    var reqMessages: [DeepSeekChatRequest.Message] = [.init(role: "system", content: systemInstruction)]
    reqMessages.append(contentsOf: messages.map { .init(role: $0.role, content: $0.content) })

    let payload = DeepSeekChatRequest(
        model: config.model,
        messages: reqMessages,
        temperature: 0.7,
        max_tokens: 200,
        response_format: nil
    )

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    req.httpBody = try JSONEncoder().encode(payload)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        throw AIServiceError.invalidResponse
    }

    let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
    let content = decoded.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !content.isEmpty else { throw AIServiceError.missingText }
    return content
}

func callDeepSeekDetectSymptoms(apiKey: String, baseURL: URL, text: String) async throws -> SymptomDetectionResult {
    let url = baseURL.appendingPathComponent("v1/chat/completions")

    let systemInstruction = """
You are a classifier for a pet health assistant.

Task:
Decide whether the user's message describes concrete pet symptoms or an individual pet's condition.

Return ONLY JSON.

JSON Schema:
{
"hasSymptoms": true|false
}

Rules:
- true: mentions vomiting, diarrhea, not eating, lethargy, pain, coughing, breathing issues, urination problems, duration, severity, worsening.
- false: greetings, general knowledge, prevention, vaccines, diet advice, casual chat.
"""

    let payload = DeepSeekChatRequest(
        model: config.model,
        messages: [
            .init(role: "system", content: systemInstruction),
            .init(role: "user", content: text)
        ],
        temperature: 0,
        max_tokens: 60,
        response_format: .init(type: "json_object")
    )

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    req.httpBody = try JSONEncoder().encode(payload)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        throw AIServiceError.invalidResponse
    }

    let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
    let content = decoded.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard let jsonData = content.data(using: .utf8) else { throw AIServiceError.missingText }
    return try JSONDecoder().decode(SymptomDetectionResult.self, from: jsonData)
}

struct DeepSeekChatRequest: Codable {
    struct Message: Codable {
        var role: String
        var content: String
    }

    var model: String
    var messages: [Message]
    var temperature: Double
    var max_tokens: Int

    /// Request JSON output when supported by provider (DeepSeek supports OpenAI-compatible fields).
    /// Keep it optional for compatibility.
    var response_format: ResponseFormat?

    struct ResponseFormat: Codable {
        var type: String
    }
}

struct DeepSeekChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            var role: String?
            var content: String?
        }
        var message: Message?
    }

    var choices: [Choice]?
}

func callDeepSeek(apiKey: String, baseURL: URL, recordSummary: String) async throws -> TriageResult {
    // DeepSeek is OpenAI-compatible; endpoint:
    // POST {baseURL}/v1/chat/completions
    let url = baseURL.appendingPathComponent("v1").appendingPathComponent("chat").appendingPathComponent("completions")

    let systemInstruction = """
你是 PetWell 的宠物健康分诊助手（triage），帮助主人理解记录、判断紧急程度，并给出下一步行动建议。
必须遵守：
- 你不是兽医，不能做确诊；只能做风险分级与建议。
- 任何危急症状必须建议立刻就医。
- 输出必须严格为 JSON（不要 markdown）。

JSON Schema：
{
\"summary\": \"string\",
\"urgency\": \"red|orange|yellow|green\",
\"possibleCauses\": [\"string\"],
\"recommendedActions\": [\"string\"],
\"followUpQuestions\": [\"string\"],
\"safetyDisclaimer\": \"string\"
}
"""

    let userPrompt = """
以下是用户填写的健康记录汇总（可能包含疫苗、就诊、用药、体重、症状）：
\(recordSummary)

请基于以上信息进行分诊并输出 JSON。
"""

    let payload = DeepSeekChatRequest(
        model: config.model,
        messages: [
            .init(role: "system", content: systemInstruction),
            .init(role: "user", content: userPrompt)
        ],
        temperature: config.temperature,
        max_tokens: config.maxOutputTokens,
        response_format: .init(type: "json_object")
    )

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    req.httpBody = try JSONEncoder().encode(payload)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else {
        throw AIServiceError.serverError(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
    }

    let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
    let content = decoded.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !content.isEmpty else { throw AIServiceError.missingText }

    // Provider should return a JSON object as a string in `content`.
    guard let jsonData = content.data(using: .utf8) else { throw AIServiceError.missingText }
    return try JSONDecoder().decode(TriageResult.self, from: jsonData)
}

func callDeepSeekExtract(apiKey: String, baseURL: URL, text: String) async throws -> SlotExtractionResult {
    let url = baseURL.appendingPathComponent("v1/chat/completions")

    let systemInstruction = """
You are an information extraction engine for a pet health application.

Safety & boundaries:
- DO NOT provide diagnosis or advice.
- DO NOT ask questions.
- ONLY extract facts explicitly stated or strongly implied.
- Output ONLY valid JSON.

Input format note:
The user's input may include:
- PET PROFILE CONTEXT: (background information)
- USER MESSAGE: (the actual user message)
If this format is present, extract slots ONLY from USER MESSAGE. PET PROFILE CONTEXT can be used only to resolve ambiguity (e.g., species), but do NOT extract symptoms from it unless they are explicitly stated in USER MESSAGE.

Available slot keys:
- vomiting (bool)
- diarrhea (bool)
- durationHours (int)
- appetiteLow (bool)
- energyLow (bool)
- breathingDifficulty (bool)
- seizures (bool)
- cannotUrinate (bool)
- dietChangedRecently (bool)
- possibleToxinExposure (bool)

JSON Schema:
{
  "slots": [
    { "slotKey": "string", "value": true|false|number|string }
  ]
}
"""

    let payload = DeepSeekChatRequest(
        model: config.model,
        messages: [
            .init(role: "system", content: systemInstruction),
            .init(role: "user", content: text)
        ],
        temperature: 0,
        max_tokens: 300,
        response_format: .init(type: "json_object")
    )

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    req.httpBody = try JSONEncoder().encode(payload)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else {
        throw AIServiceError.serverError(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
    }

    let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
    let content = decoded.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard let jsonData = content.data(using: .utf8) else { throw AIServiceError.missingText }

    return try JSONDecoder().decode(SlotExtractionResult.self, from: jsonData)
}

func callOpenAIExtract(apiKey: String, text: String) async throws -> SlotExtractionResult {
    throw AIServiceError.invalidResponse
}
}

// MARK: - Multi-agent report extraction + fusion (profile pipeline)

final class HealthReportFusionService {

    struct VendorConfig {
        var vendorId: String
        var endpoint: URL?
        var apiKey: String?
        var model: String
        /// Optional per-vendor reliability weight (0~1), tuned from offline evaluation.
        var reliability: Double = 0.8
    }

    struct Config {
        var vendors: [VendorConfig]
        var timeoutSeconds: TimeInterval = 45

        /// Placeholder config for 3 vendors.
        /// Fill endpoint/apiKey later and keep integration style identical to existing assistant API calls.
        static let placeholder = Config(
            vendors: [
                .init(vendorId: "vendor_a", endpoint: nil, apiKey: nil, model: "MODEL_A", reliability: 0.80),
                .init(vendorId: "vendor_b", endpoint: nil, apiKey: nil, model: "MODEL_B", reliability: 0.85),
                .init(vendorId: "vendor_c", endpoint: nil, apiKey: nil, model: "MODEL_C", reliability: 0.90),
            ]
        )
    }

    struct ExtractionField: Codable, Equatable {
        var metricKey: String
        var valueNumber: Double?
        var valueText: String?
        var unit: String?
        var confidence: Double
        var sourcePage: Int?
        var sourceLine: String?
        var sourceBBox: [Double]?
    }

    struct VendorExtractionResult {
        var vendorId: String
        var fields: [ExtractionField]
    }

    enum ReviewStatus: String, Codable {
        case autoPass = "auto_pass"
        case pendingReview = "pending_review"
        case manualConfirmRequired = "manual_confirm_required"
    }

    struct FusedField: Codable {
        var metricKey: String
        var valueNumber: Double?
        var valueText: String?
        var unit: String?
        var fusionConfidence: Double
        var consensusScore: Double
        var status: ReviewStatus
        var contributingVendors: [String]
    }

    struct FusionResult: Codable {
        var reportId: String
        var fields: [FusedField]
        var perVendorFieldCount: [String: Int]
    }

    private let config: Config
    private let session: URLSession

    init(config: Config, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    /// Main entry: run all configured vendors and fuse by field-level voting.
    /// Rules:
    /// 1) High consistency -> auto pass
    /// 2) Conflict but close -> pending review
    /// 3) Severe conflict -> manual confirm required
    func extractAndFuse(reportId: String, imageBase64: String) async throws -> FusionResult {
        let vendorResults = try await fetchAllVendors(imageBase64: imageBase64)
        let fused = fuse(vendorResults: vendorResults)
        let counts = Dictionary(uniqueKeysWithValues: vendorResults.map { ($0.vendorId, $0.fields.count) })
        return FusionResult(reportId: reportId, fields: fused, perVendorFieldCount: counts)
    }
}

private extension HealthReportFusionService {

    struct VendorRequest: Codable {
        var model: String
        var imageBase64: String
    }

    struct VendorResponse: Codable {
        var fields: [ExtractionField]
    }

    enum FusionError: Error {
        case noConfiguredVendors
        case invalidResponse
        case serverError(status: Int, body: String)
    }

    func fetchAllVendors(imageBase64: String) async throws -> [VendorExtractionResult] {
        let active = config.vendors.filter { $0.endpoint != nil }
        guard !active.isEmpty else { throw FusionError.noConfiguredVendors }

        return try await withThrowingTaskGroup(of: VendorExtractionResult.self) { group in
            for vendor in active {
                group.addTask {
                    let fields = try await self.callVendor(vendor, imageBase64: imageBase64)
                    return VendorExtractionResult(vendorId: vendor.vendorId, fields: fields)
                }
            }

            var results: [VendorExtractionResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    func callVendor(_ vendor: VendorConfig, imageBase64: String) async throws -> [ExtractionField] {
        guard let url = vendor.endpoint else { return [] }

        var req = URLRequest(url: url, timeoutInterval: config.timeoutSeconds)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = vendor.apiKey, !key.isEmpty {
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONEncoder().encode(VendorRequest(model: vendor.model, imageBase64: imageBase64))

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw FusionError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw FusionError.serverError(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }

        return try JSONDecoder().decode(VendorResponse.self, from: data).fields
    }

    func fuse(vendorResults: [VendorExtractionResult]) -> [FusedField] {
        var bucket: [String: [(vendorId: String, field: ExtractionField, reliability: Double)]] = [:]
        let reliabilities = Dictionary(uniqueKeysWithValues: config.vendors.map { ($0.vendorId, $0.reliability) })

        for vendorResult in vendorResults {
            let rel = reliabilities[vendorResult.vendorId] ?? 0.8
            for field in vendorResult.fields {
                let key = field.metricKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                bucket[key, default: []].append((vendorResult.vendorId, field, rel))
            }
        }

        return bucket.keys.sorted().compactMap { key in
            guard let items = bucket[key], !items.isEmpty else { return nil }

            let picked = pickFusedValue(items: items)
            let consensus = consensusScore(items: items)
            let status: ReviewStatus
            if consensus >= 0.85 {
                status = .autoPass
            } else if consensus >= 0.55 {
                status = .pendingReview
            } else {
                status = .manualConfirmRequired
            }

            let weightedConfidence = weightedAverage(
                items.map { max(0, min(1, $0.field.confidence)) * max(0, min(1, $0.reliability)) }
            )

            return FusedField(
                metricKey: key,
                valueNumber: picked.valueNumber,
                valueText: picked.valueText,
                unit: picked.unit,
                fusionConfidence: weightedConfidence,
                consensusScore: consensus,
                status: status,
                contributingVendors: Array(Set(items.map { $0.vendorId })).sorted()
            )
        }
    }

    func pickFusedValue(items: [(vendorId: String, field: ExtractionField, reliability: Double)]) -> ExtractionField {
        let numericItems = items.compactMap { item -> (Double, String?, Double)? in
            guard let v = item.field.valueNumber else { return nil }
            let weight = max(0, min(1, item.field.confidence)) * max(0, min(1, item.reliability))
            return (v, item.field.unit, max(weight, 0.0001))
        }

        if !numericItems.isEmpty {
            let totalWeight = numericItems.reduce(0) { $0 + $1.2 }
            let fusedNumber = numericItems.reduce(0) { $0 + ($1.0 * $1.2) } / totalWeight
            let unit = majorityText(numericItems.compactMap { $0.1 })
            return ExtractionField(metricKey: items[0].field.metricKey, valueNumber: fusedNumber, valueText: nil, unit: unit, confidence: 1, sourcePage: nil, sourceLine: nil, sourceBBox: nil)
        }

        let textItems = items.compactMap { item -> (String, String?, Double)? in
            guard let t = item.field.valueText?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
            let weight = max(0, min(1, item.field.confidence)) * max(0, min(1, item.reliability))
            return (t.lowercased(), item.field.unit, max(weight, 0.0001))
        }

        let text = weightedMajorityText(textItems)
        let unit = majorityText(textItems.compactMap { $0.1 })
        return ExtractionField(metricKey: items[0].field.metricKey, valueNumber: nil, valueText: text, unit: unit, confidence: 1, sourcePage: nil, sourceLine: nil, sourceBBox: nil)
    }

    func consensusScore(items: [(vendorId: String, field: ExtractionField, reliability: Double)]) -> Double {
        if items.count == 1 { return 0.5 }

        var scores: [Double] = []
        for i in 0..<items.count {
            for j in (i + 1)..<items.count {
                scores.append(pairSimilarity(lhs: items[i].field, rhs: items[j].field))
            }
        }
        return weightedAverage(scores)
    }

    func pairSimilarity(lhs: ExtractionField, rhs: ExtractionField) -> Double {
        if let lv = lhs.valueNumber, let rv = rhs.valueNumber {
            let maxV = max(abs(lv), abs(rv), 0.0001)
            let relativeDiff = abs(lv - rv) / maxV
            if relativeDiff <= 0.03 { return 1.0 }      // high consistency
            if relativeDiff <= 0.10 { return 0.65 }     // conflict but close
            return 0.20                                  // severe conflict
        }

        let lt = lhs.valueText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let rt = rhs.valueText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if lt.isEmpty || rt.isEmpty { return 0.2 }
        if lt == rt { return 1.0 }
        if lt.contains(rt) || rt.contains(lt) { return 0.65 }
        return 0.2
    }

    func weightedAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    func majorityText(_ values: [String]) -> String? {
        guard !values.isEmpty else { return nil }
        var counter: [String: Int] = [:]
        for v in values where !v.isEmpty {
            counter[v, default: 0] += 1
        }
        return counter.max(by: { $0.value < $1.value })?.key
    }

    func weightedMajorityText(_ values: [(String, String?, Double)]) -> String? {
        guard !values.isEmpty else { return nil }
        var scoreMap: [String: Double] = [:]
        for (value, _, weight) in values where !value.isEmpty {
            scoreMap[value, default: 0] += weight
        }
        return scoreMap.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Models

extension AIService {
struct SymptomDetectionResult: Codable {
    let hasSymptoms: Bool
}

struct TriageResult: Codable {
    enum Urgency: String, Codable {
        case red, orange, yellow, green
    }

    /// 一句话总结
    var summary: String
    /// 风险分级：red=立刻就医，orange=尽快就医（24h内），yellow=预约就医/观察并记录，green=居家护理+观察
    var urgency: Urgency
    /// 可能原因（非确诊）
    var possibleCauses: [String]
    /// 建议行动（按优先级）
    var recommendedActions: [String]
    /// 需要追问用户的信息
    var followUpQuestions: [String]
    /// 安全声明（给 UI 展示）
    var safetyDisclaimer: String
}

// MARK: - Slot Extraction Models

struct SlotExtractionResult: Codable {
    let slots: [SlotItem]

    struct SlotItem: Codable {
        let slotKey: String
        let value: SlotValue
    }
}

enum SlotValue: Codable {
    case bool(Bool)
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            throw DecodingError.typeMismatch(
                SlotValue.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported slot value type")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let b): try container.encode(b)
        case .int(let i): try container.encode(i)
        case .string(let s): try container.encode(s)
        }
    }
}

enum AIServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(status: Int, body: String)
    case missingText

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "AIService: invalid URL"
        case .invalidResponse: return "AIService: invalid response"
        case .serverError(let status, _): return "AIService: server error (\(status))"
        case .missingText: return "AIService: missing output text"
        }
    }
}
}

// MARK: - Backend mode (recommended)

private extension AIService {

struct BackendRequest: Codable {
    var recordSummary: String
}

func callBackend(url: URL, recordSummary: String) async throws -> TriageResult {
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let payload = BackendRequest(recordSummary: recordSummary)
    req.httpBody = try JSONEncoder().encode(payload)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else {
        throw AIServiceError.serverError(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
    }

    return try JSONDecoder().decode(TriageResult.self, from: data)
}
}

// MARK: - OpenAI direct mode (dev only)

private extension AIService {

// Responses API request
struct OpenAIResponsesRequest: Codable {
    struct InputItem: Codable {
        struct Content: Codable {
            var type: String
            var text: String
        }
        var role: String
        var content: [Content]
    }

    var model: String
    var input: [InputItem]
    var max_output_tokens: Int
    var temperature: Double
}

// Minimal Responses API response parsing (extract output_text)
struct OpenAIResponsesResponse: Codable {
    struct OutputItem: Codable {
        struct Content: Codable {
            var type: String
            var text: String?
        }
        var content: [Content]?
    }
    var output: [OutputItem]?
}

func callOpenAI(apiKey: String, recordSummary: String) async throws -> TriageResult {
    guard let url = URL(string: "https://api.openai.com/v1/responses") else {
        throw AIServiceError.invalidURL
    }

    let systemInstruction = """
你是 PetWell 的宠物健康分诊助手（triage），帮助主人理解记录、判断紧急程度，并给出下一步行动建议。
必须遵守：
- 你不是兽医，不能做确诊；只能做风险分级与建议。
- 任何危急症状必须建议立刻就医。
- 输出必须严格为 JSON（不要 markdown）。

JSON Schema：
{
"summary": "string",
"urgency": "red|orange|yellow|green",
"possibleCauses": ["string"],
"recommendedActions": ["string"],
"followUpQuestions": ["string"],
"safetyDisclaimer": "string"
}
"""

    let userPrompt = """
以下是用户填写的健康记录汇总（可能包含疫苗、就诊、用药、体重、症状）：
\(recordSummary)

请基于以上信息进行分诊并输出 JSON。
"""

    let payload = OpenAIResponsesRequest(
        model: config.model,
        input: [
            .init(role: "system", content: [.init(type: "input_text", text: systemInstruction)]),
            .init(role: "user", content: [.init(type: "input_text", text: userPrompt)])
        ],
        max_output_tokens: config.maxOutputTokens,
        temperature: config.temperature
    )

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    req.httpBody = try JSONEncoder().encode(payload)

    let (data, resp) = try await session.data(for: req)
    guard let http = resp as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else {
        throw AIServiceError.serverError(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
    }

    let decoded = try JSONDecoder().decode(OpenAIResponsesResponse.self, from: data)

    // 拼出所有 output_text
    let texts = (decoded.output ?? []).flatMap { item in
        (item.content ?? []).compactMap { $0.text }
    }
    let joined = texts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !joined.isEmpty else { throw AIServiceError.missingText }

    // 模型返回的是 JSON 字符串 -> 再 decode 成 TriageResult
    guard let jsonData = joined.data(using: .utf8) else { throw AIServiceError.missingText }
    return try JSONDecoder().decode(TriageResult.self, from: jsonData)
}
}
