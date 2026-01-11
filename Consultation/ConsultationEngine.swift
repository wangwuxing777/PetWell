//
//  ConsultationEngine.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/26.
//

import Foundation
import SwiftUI
import Combine

/// Config-driven, one-question-at-a-time consultation flow ("阿福式配置引擎")
@MainActor
final class ConsultationEngine: ObservableObject {

    // MARK: - Types

    enum Stage {
        case intake
        case triage
        case symptomDetail
        case context
        case wrapUp
    }

    struct Session {
        // Prefilled from Record
        var petName: String?
        var species: String?
        var ageMonths: Int?
        var weightKg: Double?

        // Intake
        var chiefComplaint: String?

        // Triage
        var breathingDifficulty: Bool?
        var seizures: Bool?
        var cannotUrinate: Bool?

        // Symptom detail
        var durationHours: Int?
        var appetiteLow: Bool?
        var energyLow: Bool?
        var vomiting: Bool?
        var diarrhea: Bool?

        // Context
        var dietChangedRecently: Bool?
        var possibleToxinExposure: Bool?
        var recentMedsOrVaccines: Bool?
    }

    enum RiskLevel {
        case low
        case medium
        case high
    }

    struct EngineOutput {
        let assistantText: String
        let stage: Stage
        let risk: RiskLevel
        let shouldStopAsking: Bool
    }

    struct QuestionConfig {
        let id: String
        let stage: Stage
        let priority: Int
        let slotKey: String
        let prompt: String
        let condition: (Session) -> Bool
    }

    struct StageConfig {
        let stage: Stage
        let questions: [QuestionConfig]
    }

    struct NextQuestionDecision {
        let question: String?
        let nextStage: Stage
    }

    // MARK: - Published state

    @Published private(set) var session = Session()
    @Published private(set) var stage: Stage = .intake

    // Tracks which slot the engine most recently asked the user to answer (so we can parse free-text answers)
    private var lastAskedSlotKey: String?

    // MARK: - Config table (doctor-maintained)

    private static let stageConfigs: [StageConfig] = [
        StageConfig(stage: .intake, questions: [
            QuestionConfig(
                id: "chief_complaint",
                stage: .intake,
                priority: 1,
                slotKey: "chiefComplaint",
                prompt: "你现在最担心的主要问题是什么？",
                condition: { $0.chiefComplaint == nil }
            )
        ]),

        StageConfig(stage: .triage, questions: [
            QuestionConfig(
                id: "breathing",
                stage: .triage,
                priority: 1,
                slotKey: "breathingDifficulty",
                prompt: "现在呼吸有没有明显费力或张口喘？",
                condition: { $0.breathingDifficulty == nil }
            ),
            QuestionConfig(
                id: "seizure",
                stage: .triage,
                priority: 2,
                slotKey: "seizures",
                prompt: "最近有没有抽搐、站不稳或突然倒地？",
                condition: { $0.seizures == nil }
            ),
            QuestionConfig(
                id: "urination_block",
                stage: .triage,
                priority: 3,
                slotKey: "cannotUrinate",
                prompt: "最近排尿是否正常？有没有尿不出来？",
                condition: { $0.cannotUrinate == nil }
            )
        ]),

        StageConfig(stage: .symptomDetail, questions: [
            QuestionConfig(
                id: "duration",
                stage: .symptomDetail,
                priority: 1,
                slotKey: "durationHours",
                prompt: "这种情况大概持续多久了？（小时/天）",
                condition: { $0.durationHours == nil }
            ),
            QuestionConfig(
                id: "appetite",
                stage: .symptomDetail,
                priority: 2,
                slotKey: "appetiteLow",
                prompt: "最近食欲怎么样？（完全不吃/吃得少/正常）",
                condition: { $0.appetiteLow == nil }
            ),
            QuestionConfig(
                id: "energy",
                stage: .symptomDetail,
                priority: 3,
                slotKey: "energyLow",
                prompt: "精神状态怎么样？（活跃/一般/明显没精神）",
                condition: { $0.energyLow == nil }
            ),
            QuestionConfig(
                id: "vomiting",
                stage: .symptomDetail,
                priority: 4,
                slotKey: "vomiting",
                prompt: "这段时间有呕吐吗？",
                condition: { $0.vomiting == nil }
            ),
            QuestionConfig(
                id: "diarrhea",
                stage: .symptomDetail,
                priority: 5,
                slotKey: "diarrhea",
                prompt: "排便是否正常？有没有腹泻/拉稀？",
                condition: { $0.diarrhea == nil }
            )
        ]),

        StageConfig(stage: .context, questions: [
            QuestionConfig(
                id: "diet_change",
                stage: .context,
                priority: 1,
                slotKey: "dietChangedRecently",
                prompt: "最近有没有换粮/换零食或吃了不常见的食物？",
                condition: { $0.dietChangedRecently == nil }
            ),
            QuestionConfig(
                id: "toxin",
                stage: .context,
                priority: 2,
                slotKey: "possibleToxinExposure",
                prompt: "有没有可能接触到巧克力、葡萄、药物或清洁剂？",
                condition: { $0.possibleToxinExposure == nil }
            ),
            QuestionConfig(
                id: "meds",
                stage: .context,
                priority: 3,
                slotKey: "recentMedsOrVaccines",
                prompt: "最近是否用过药、驱虫或打过疫苗？",
                condition: { $0.recentMedsOrVaccines == nil }
            )
        ])
    ]

    // MARK: - Public API

    func reset() {
        session = Session()
        stage = .intake
        lastAskedSlotKey = nil
    }

    /// Prefill basic pet info from Record. Call this once when entering the consultation.
    func prefillFromRecord(petName: String?, species: String?, ageMonths: Int?, weightKg: Double?) {
        if let petName { session.petName = petName }
        if let species { session.species = species }
        if let ageMonths { session.ageMonths = ageMonths }
        if let weightKg { session.weightKg = weightKg }

        // We do NOT skip intake entirely because we still need chief complaint.
        // Intake now only contains chief complaint, so no extra work needed.

        // Keep lastAskedSlotKey unchanged; prefill should not affect question parsing.
    }

    /// Set a slot value (fed by DeepSeek extraction)
    func handleUserInput(slotKey: String, value: Any) {
        switch slotKey {
        case "petName": session.petName = value as? String
        case "species": session.species = value as? String
        case "ageMonths": session.ageMonths = value as? Int
        case "weightKg": session.weightKg = value as? Double

        case "chiefComplaint": session.chiefComplaint = value as? String

        case "breathingDifficulty": session.breathingDifficulty = value as? Bool
        case "seizures": session.seizures = value as? Bool
        case "cannotUrinate": session.cannotUrinate = value as? Bool

        case "durationHours": session.durationHours = value as? Int
        case "appetiteLow": session.appetiteLow = value as? Bool
        case "energyLow": session.energyLow = value as? Bool
        case "vomiting": session.vomiting = value as? Bool
        case "diarrhea": session.diarrhea = value as? Bool

        case "dietChangedRecently": session.dietChangedRecently = value as? Bool
        case "possibleToxinExposure": session.possibleToxinExposure = value as? Bool
        case "recentMedsOrVaccines": session.recentMedsOrVaccines = value as? Bool

        default:
            break
        }
    }

    /// Main driver: always returns ONE next question (doctor-style) or escalation.
    func handleUserInput(_ userText: String) -> EngineOutput {
        // Heuristic fallback: if DeepSeek extraction didn't fill the last asked slot,
        // try to parse the user's answer based on the last question we asked.
        if let slotKey = lastAskedSlotKey {
            applyHeuristicAnswerIfNeeded(slotKey: slotKey, userText: userText)
        }

        // If chief complaint already captured, progress into triage.
        if stage == .intake, session.chiefComplaint != nil {
            stage = .triage
        }

        let risk = evaluateRisk()
        if risk == .high {
            stage = .wrapUp
            return EngineOutput(assistantText: escalationText(), stage: stage, risk: risk, shouldStopAsking: true)
        }

        let decision = decideNextQuestion(risk: risk)

        if decision.question == nil {
            if let ns = nextStage(after: stage) {
                stage = ns
                let retry = decideNextQuestion(risk: risk)
                if let q = retry.question {
                    return EngineOutput(assistantText: q, stage: stage, risk: risk, shouldStopAsking: false)
                }
            }
            stage = .wrapUp
            return EngineOutput(assistantText: wrapUpText(for: risk), stage: stage, risk: risk, shouldStopAsking: true)
        }

        return EngineOutput(assistantText: decision.question!, stage: stage, risk: risk, shouldStopAsking: false)
    }

    // MARK: - Decision

    private func decideNextQuestion(risk: RiskLevel) -> NextQuestionDecision {
        if let stageConfig = Self.stageConfigs.first(where: { $0.stage == stage }) {
            let candidates = stageConfig.questions
                .filter { $0.condition(session) }
                .sorted { $0.priority < $1.priority }

            if let next = candidates.first {
                lastAskedSlotKey = next.slotKey
                return NextQuestionDecision(question: next.prompt, nextStage: stage)
            }
        }

        if let nextStage = nextStage(after: stage) {
            return NextQuestionDecision(question: nil, nextStage: nextStage)
        }
        return NextQuestionDecision(question: nil, nextStage: .wrapUp)
    }

    private func nextStage(after stage: Stage) -> Stage? {
        switch stage {
        case .intake: return .triage
        case .triage: return .symptomDetail
        case .symptomDetail: return .context
        case .context: return .wrapUp
        case .wrapUp: return nil
        }
    }

    // MARK: - Safety

    private func evaluateRisk() -> RiskLevel {
        if session.breathingDifficulty == true { return .high }
        if session.seizures == true { return .high }
        if session.cannotUrinate == true { return .high }

        if session.vomiting == true || session.diarrhea == true || session.appetiteLow == true || session.energyLow == true {
            return .medium
        }
        return .low
    }

    private func escalationText() -> String {
        return "我注意到可能存在较危险信号（例如呼吸困难/抽搐/尿不出来）。为了安全，建议尽快带去线下宠物医院或急诊评估。"
    }

    private func wrapUpText(for risk: RiskLevel) -> String {
        let summary = sessionSummary()

        switch risk {
        case .low:
            return """
            我已基本了解情况，先给你一个小结：
            \(summary)

            建议：
            - 先观察 12–24 小时：精神/食欲/排便排尿/是否再呕吐或腹泻
            - 保持清淡饮食与充足饮水（如果能正常喝水、没有频繁呕吐）

            何时需要就医：
            - 症状持续不缓解或明显加重
            - 出现反复呕吐/腹泻导致疑似脱水、精神明显变差、拒食超过 24 小时
            """
        case .medium:
            return """
            我已基本了解情况，先给你一个小结：
            \(summary)

            建议：
            - 密切观察今天的变化：精神、进食、喝水、呕吐/腹泻次数、是否能正常排尿
            - 若你怀疑吃了不该吃的东西或近期换粮导致不适，尽量避免继续喂同类可疑食物

            何时需要就医（建议尽快）：
            - 持续频繁呕吐/腹泻、精神持续下降、明显腹痛或无法进食饮水
            - 任何你觉得“明显不对劲”的快速恶化
            """
        case .high:
            return escalationText()
        }
    }

    private func sessionSummary() -> String {
        var lines: [String] = []
        if let name = session.petName { lines.append("• 宠物：\(name)") }
        if let species = session.species { lines.append("• 物种：\(species)") }
        if let age = session.ageMonths { lines.append("• 年龄：约 \(max(1, age / 12)) 岁") }
        if let w = session.weightKg { lines.append(String(format: "• 体重：%.1f kg", w)) }

        if let cc = session.chiefComplaint, !cc.isEmpty { lines.append("• 主诉：\(cc)") }

        func yn(_ v: Bool?) -> String? {
            guard let v else { return nil }
            return v ? "是" : "否"
        }
        if let v = yn(session.vomiting) { lines.append("• 呕吐：\(v)") }
        if let v = yn(session.diarrhea) { lines.append("• 腹泻：\(v)") }
        if let v = yn(session.appetiteLow) { lines.append("• 食欲下降：\(v)") }
        if let v = yn(session.energyLow) { lines.append("• 精神差：\(v)") }
        if let d = session.durationHours { lines.append("• 持续时间：约 \(d) 小时") }

        if lines.isEmpty { return "•（信息较少，你也可以补充：持续多久、呕吐/腹泻次数、精神食欲、排便排尿）" }
        return lines.joined(separator: "\n")
    }

    // MARK: - Heuristic parsing (fallback when extraction misses)

    private func applyHeuristicAnswerIfNeeded(slotKey: String, userText: String) {
        let t = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        // Only apply if the slot is still nil
        switch slotKey {
        case "breathingDifficulty":
            if session.breathingDifficulty == nil, let b = parseYesNo(t) { session.breathingDifficulty = b }
        case "seizures":
            if session.seizures == nil, let b = parseYesNo(t) { session.seizures = b }
        case "cannotUrinate":
            if session.cannotUrinate == nil, let b = parseYesNo(t) { session.cannotUrinate = b }
        case "vomiting":
            if session.vomiting == nil, let b = parseYesNo(t) { session.vomiting = b }
        case "diarrhea":
            if session.diarrhea == nil, let b = parseYesNo(t) { session.diarrhea = b }
        case "dietChangedRecently":
            if session.dietChangedRecently == nil, let b = parseYesNo(t) { session.dietChangedRecently = b }
        case "possibleToxinExposure":
            if session.possibleToxinExposure == nil, let b = parseYesNo(t) { session.possibleToxinExposure = b }
        case "recentMedsOrVaccines":
            if session.recentMedsOrVaccines == nil, let b = parseYesNo(t) { session.recentMedsOrVaccines = b }

        case "durationHours":
            if session.durationHours == nil, let h = parseDurationHours(t) { session.durationHours = h }
        case "appetiteLow":
            if session.appetiteLow == nil, let b = parseAppetiteLow(t) { session.appetiteLow = b }
        case "energyLow":
            if session.energyLow == nil, let b = parseEnergyLow(t) { session.energyLow = b }
        default:
            break
        }
    }

    private func parseYesNo(_ text: String) -> Bool? {
        let t = text.lowercased()
        if t.contains("没有") || t.contains("不") || t.contains("否") || t.contains("正常") || t.contains("没") {
            // Avoid misclassifying phrases like "不太" / "不是很" which still indicates "no/low"
            return false
        }
        if t.contains("有") || t.contains("是") || t.contains("会") || t.contains("在") {
            return true
        }
        return nil
    }

    private func parseDurationHours(_ text: String) -> Int? {
        // Supports formats like: "3小时", "2天", "大概一天半", "6 h"
        let t = text.replacingOccurrences(of: " ", with: "")
        // Try to find digits
        let digits = t.compactMap { $0.isNumber ? String($0) : nil }.joined()
        guard let n = Int(digits), n > 0 else { return nil }

        if t.contains("天") {
            return n * 24
        }
        if t.contains("小时") || t.contains("h") || t.contains("hr") {
            return n
        }
        // If no unit, assume hours
        return n
    }

    private func parseAppetiteLow(_ text: String) -> Bool? {
        let t = text
        if t.contains("正常") || t.contains("还行") || t.contains("还好") {
            return false
        }
        if t.contains("不吃") || t.contains("拒食") || t.contains("吃得少") || t.contains("食欲差") || t.contains("没胃口") {
            return true
        }
        return parseYesNo(t)
    }

    private func parseEnergyLow(_ text: String) -> Bool? {
        let t = text
        if t.contains("活跃") || t.contains("正常") || t.contains("精神好") {
            return false
        }
        if t.contains("没精神") || t.contains("精神差") || t.contains("嗜睡") || t.contains("不爱动") || t.contains("萎靡") {
            return true
        }
        return parseYesNo(t)
    }
}
