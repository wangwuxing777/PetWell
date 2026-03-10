import SwiftUI

// MARK: - ForYouProgressView
// Full-screen progress sheet shown while the pipeline runs.
// Transitions to RAGChatView once Stage 5 completes.

struct ForYouProgressView: View {
    let pet: PetModel

    @ObservedObject private var orchestrator = ForYouOrchestrator.shared
    @ObservedObject private var insuranceService = InsuranceService.shared

    @Binding var isPresented: Bool
    @State private var showChat = false

    var body: some View {
        ZStack {
            AppTheme.bgBase.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ────────────────────────────────────
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                Divider()

                // ── Step Cards ───────────────────────────────
                ScrollViewReader { proxy in
                    ScrollView {
                        StepCardListView(steps: orchestrator.steps)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                    }
                    .onChange(of: orchestrator.steps.map { $0.status }) { _, _ in
                        guard let last = orchestrator.steps.last(where: { $0.status != .pending })
                        else { return }
                        // Small delay lets the insertion spring animation begin first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .accessibilityIdentifier("ForYouStepperScrollView")
            }
        }
        .task {
            // Wait for InsuranceService to finish loading (max 3s)
            if insuranceService.products.isEmpty {
                for _ in 0..<30 {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    if !insuranceService.products.isEmpty { break }
                }
            }
            orchestrator.start(pet: pet, allProducts: insuranceService.products)
        }
        .onChange(of: orchestrator.hasNewResult) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showChat = true
                }
            }
        }
        .fullScreenCover(isPresented: $showChat) {
            if let result = orchestrator.latestResult {
                RAGChatView(
                    contextString: result.enrichedContext,
                    initialModel: .insurance,
                    initialAIMessage: result.initialAIMessage,
                    isPresented: $showChat
                )
                .onDisappear {
                    orchestrator.clearResult()
                    isPresented = false
                }
            }
        }
        .accessibilityIdentifier("ForYouProgressView")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .accessibilityIdentifier("ForYouCloseButton")
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 14) {
            // Pet avatar
            Group {
                if let data = pet.avatarImageData, let uiImg = UIImage(data: data) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: pet.species.lowercased().contains("cat") ? "cat.fill" : "dog.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(LinearGradient(
                            colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text("Analysing \(pet.name)'s Profile")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("\(pet.breed) · \(Calendar.current.component(.year, from: .now) - pet.birthYear) yr(s) old")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Spinner or done badge
            if orchestrator.isRunning {
                ProgressView()
                    .scaleEffect(0.85)
            } else if orchestrator.hasNewResult {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 22))
            }
        }
    }
}

// MARK: - StepCardListView

struct StepCardListView: View {
    let steps: [ForYouPipelineStep]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(steps) { step in
                if step.status == .completed || step.status == .skipped || step.status == .failed {
                    StepCard(step: step)
                        .id(step.id)
                        .transition(.asymmetric(
                            insertion: .offset(y: 28).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .accessibilityIdentifier("ForYouStep_\(step.id)")
                }
            }
        }
        .animation(
            .spring(response: 0.48, dampingFraction: 0.78),
            value: steps.map { $0.status }
        )
        .accessibilityIdentifier("ForYouStepperList")
    }
}

// MARK: - StepCard

struct StepCard: View {
    let step: ForYouPipelineStep

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(spacing: 12) {
                StepStatusIcon(status: step.status)
                    .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 3) {
                    Text(step.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(step.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)
            }

            // Result sub-card — revealed after completion/skip
            if step.status == .completed || step.status == .skipped,
               let summary = step.resultSummary {
                ResultSubCard(text: summary, isSkipped: step.status == .skipped)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.82),
            value: step.status
        )
    }
}

// MARK: - StepStatusIcon

struct StepStatusIcon: View {
    let status: ForYouPipelineStep.StepStatus

    var body: some View {
        Group {
            switch status {
            case .pending:
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 2)
                    .frame(width: 22, height: 22)

            case .running:
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.25), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    ProgressView()
                        .scaleEffect(0.65)
                        .tint(.blue)
                }

            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 22))

            case .skipped:
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(Color(.systemGray3))
                    .font(.system(size: 22))

            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 22))
            }
        }
    }
}

// MARK: - ResultSubCard

struct ResultSubCard: View {
    let text: String
    let isSkipped: Bool

    init(text: String, isSkipped: Bool = false) {
        self.text = text
        self.isSkipped = isSkipped
    }

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isSkipped ? Color(.systemGray4) : Color.green.opacity(0.7))
                .frame(width: 3)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSkipped ? .secondary : AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(10)
        .background(isSkipped
            ? Color(.systemGray6)
            : Color.green.opacity(0.06))
        .cornerRadius(8)
    }
}
