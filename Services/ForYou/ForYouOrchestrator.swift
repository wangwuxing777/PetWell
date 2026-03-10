import Foundation
import Combine

// MARK: - Pipeline Step Model

struct ForYouPipelineStep: Identifiable {
    let id: Int
    let title: String
    let subtitle: String        // shown while running
    var status: StepStatus
    var resultSummary: String?  // shown in expanded sub-card after completion

    enum StepStatus {
        case pending    // ○  grey circle
        case running    // ⟳  blue spin
        case completed  // ✅  green checkmark
        case skipped    // ⊘  grey dash
        case failed     // ✗  red X
    }

    static let defaultSteps: [ForYouPipelineStep] = [
        ForYouPipelineStep(id: 1, title: "Age & Breed Check",
                           subtitle: "Checking age eligibility and breed risks…",
                           status: .pending),
        ForYouPipelineStep(id: 2, title: "Loading Health Reports",
                           subtitle: "Reading your pet's health history…",
                           status: .pending),
        ForYouPipelineStep(id: 3, title: "Medical AI Analysis",
                           subtitle: "Analysing health reports with Medical AI…",
                           status: .pending),
        ForYouPipelineStep(id: 4, title: "Preparing Context",
                           subtitle: "Assembling personalised profile…",
                           status: .pending),
        ForYouPipelineStep(id: 5, title: "Insurance Recommendation",
                           subtitle: "Matching plans to your pet's profile…",
                           status: .pending),
    ]
}

// MARK: - Result

struct ForYouChatResult {
    let initialAIMessage: String   // pre-filled first message in RAGChatView
    let enrichedContext: String    // contextString for follow-up questions
}

// MARK: - ForYouOrchestrator

@MainActor
final class ForYouOrchestrator: ObservableObject {

    static let shared = ForYouOrchestrator()
    private init() {}

    // MARK: Published State
    @Published var steps: [ForYouPipelineStep] = ForYouPipelineStep.defaultSteps
    @Published var isRunning: Bool = false
    @Published var hasNewResult: Bool = false
    @Published var latestResult: ForYouChatResult?

    private var runningTask: Task<Void, Never>?

    // MARK: - Public API

    func start(pet: PetModel, allProducts: [InsuranceProduct]) {
        // Cancel any in-progress run
        runningTask?.cancel()
        steps = ForYouPipelineStep.defaultSteps
        isRunning = true
        hasNewResult = false
        latestResult = nil

        runningTask = Task {
            await run(pet: pet, allProducts: allProducts)
        }
    }

    /// Call when the user opens the result chat — clears the red dot.
    func clearResult() {
        hasNewResult = false
    }

    // MARK: - Pipeline Execution

    private func run(pet: PetModel, allProducts: [InsuranceProduct]) async {
        let petAge = Calendar.current.component(.year, from: .now) - pet.birthYear

        // ── Stage 1: Local agents ─────────────────────────────
        markRunning(1)
        let eligible   = AgeFilterAgent.filter(petAgeYears: petAge, products: allProducts)
        let risks      = BreedRiskAgent.risks(forBreed: pet.breed)
        let isLargeDog = LargeDogAgent.isLargeDog(species: pet.species, weightKg: pet.weightKg)
        markCompleted(1, summary: buildStage1Summary(
            eligible: eligible.count, total: allProducts.count,
            risks: risks, isLargeDog: isLargeDog))

        guard !Task.isCancelled else { finish(); return }
        try? await Task.sleep(nanoseconds: 500_000_000)   // card gap

        // ── Stage 2: Health report extraction ────────────────
        markRunning(2)
        let healthText = HealthReportExtractor.extract(from: pet.healthReports)
        markCompleted(2, summary: healthText != nil
            ? "\(pet.healthReports.count) report(s) loaded"
            : "No health reports found")

        guard !Task.isCancelled else { finish(); return }
        try? await Task.sleep(nanoseconds: 500_000_000)   // card gap

        // ── Stage 3: Medical RAG (network) ───────────────────
        var clinicalSummary: String?
        if let text = healthText {
            markRunning(3)
            clinicalSummary = await callMedicalRAG(healthText: text, pet: pet)
            let stage3Summary = clinicalSummary.map {
                let preview = String($0.prefix(80)).trimmingCharacters(in: .whitespacesAndNewlines)
                return "Key findings: \(preview)…"
            } ?? "Analysis unavailable"
            markCompleted(3, summary: stage3Summary)
        } else {
            markSkipped(3, summary: "Skipped — no health reports")
        }

        guard !Task.isCancelled else { finish(); return }
        try? await Task.sleep(nanoseconds: 500_000_000)   // card gap

        // ── Stage 4: Context assembly ─────────────────────────
        markRunning(4)
        let enrichedContext = ContextAssemblerAgent.build(
            pet: pet, petAgeYears: petAge,
            eligibleCount: eligible.count, totalCount: allProducts.count,
            breedRisks: risks, isLargeDog: isLargeDog, clinicalSummary: clinicalSummary)
        markCompleted(4, summary: "Context ready · Sending to Insurance AI…")

        guard !Task.isCancelled else { finish(); return }
        try? await Task.sleep(nanoseconds: 500_000_000)   // card gap

        // ── Stage 5: Insurance RAG (network) ──────────────────
        markRunning(5)
        let recommendation = await callInsuranceRAG(context: enrichedContext)
            ?? "Sorry, I couldn't generate a recommendation right now. Please try again."
        markCompleted(5, summary: "Recommendation ready ✓")

        // Final pause — ensures card 5's animation finishes before transition
        try? await Task.sleep(nanoseconds: 800_000_000)

        latestResult = ForYouChatResult(
            initialAIMessage: recommendation,
            enrichedContext: enrichedContext)
        hasNewResult = true
        finish()
    }

    // MARK: - Step State Helpers

    private func markRunning(_ id: Int) {
        updateStep(id) { $0.status = .running }
    }

    private func markCompleted(_ id: Int, summary: String) {
        updateStep(id) {
            $0.status = .completed
            $0.resultSummary = summary
        }
    }

    private func markSkipped(_ id: Int, summary: String) {
        updateStep(id) {
            $0.status = .skipped
            $0.resultSummary = summary
        }
    }

    private func finish() {
        isRunning = false
    }

    private func updateStep(_ id: Int, _ block: (inout ForYouPipelineStep) -> Void) {
        guard let idx = steps.firstIndex(where: { $0.id == id }) else { return }
        block(&steps[idx])
    }

    // MARK: - Stage 1 Summary Builder

    private func buildStage1Summary(
        eligible: Int, total: Int,
        risks: [BreedRisk], isLargeDog: Bool
    ) -> String {
        var parts: [String] = ["\(eligible)/\(total) plans eligible"]
        if !risks.isEmpty {
            let abbr = risks.map { $0.abbreviation }.joined(separator: ", ")
            parts.append("⚠️ \(abbr) risk detected")
        }
        if isLargeDog { parts.append("🐕 Large breed") }
        return parts.joined(separator: " · ")
    }

    // MARK: - RAG Network Calls

    private let baseURL = "http://localhost:8000"

    private func callMedicalRAG(healthText: String, pet: PetModel) async -> String? {
        guard let url = URL(string: "\(baseURL)/api/chat") else { return nil }
        let query = """
        Pet: \(pet.name), \(pet.species), \(pet.breed).
        Please extract and summarise the key medical findings from the following health report(s).
        Focus on: diagnoses, abnormal lab values, ongoing conditions, medications, and any conditions
        that might affect insurance coverage.

        Health Reports:
        \(healthText)
        """
        return await postRAG(url: url, query: query, model: "medical")
    }

    private func callInsuranceRAG(context: String) async -> String? {
        guard let url = URL(string: "\(baseURL)/api/chat") else { return nil }
        return await postRAG(url: url, query: context, model: "insurance")
    }

    private func postRAG(url: URL, query: String, model: String) async -> String? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = RAGRequest(query: query, session_id: nil, model: model, provider: nil)
        guard let encoded = try? JSONEncoder().encode(body) else { return nil }
        request.httpBody = encoded

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { return nil }
            let decoded = try JSONDecoder().decode(RAGResponse.self, from: data)
            return decoded.answer.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("⚠️ ForYouOrchestrator RAG error (\(model)): \(error.localizedDescription)")
            return nil
        }
    }
}
