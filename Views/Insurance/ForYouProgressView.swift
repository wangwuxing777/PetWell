import SwiftUI
import SwiftData

// MARK: - ForYouProgressView
// Full-screen progress sheet shown while the pipeline runs.
// Transitions to RAGChatView once Stage 5 completes.

struct ForYouProgressView: View {
    let pet: PetModel

    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var orchestrator = ForYouOrchestrator.shared
    @EnvironmentObject private var insuranceService: InsuranceService

    @Binding var isPresented: Bool
    @State private var showChat = false
    @State private var animateIn = false

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

                // ── Stepper Progress List ─────────────────────
                ScrollView {
                    StepperProgressView(steps: orchestrator.steps)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                }

                Spacer(minLength: 0)

                // ── Bottom Dismiss Note ───────────────────────
                VStack(spacing: 6) {
                    Divider()
                    Text("Analysis running in background · You'll be notified when done")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { animateIn = true }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                }
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

// MARK: - StepperProgressView

struct StepperProgressView: View {
    let steps: [ForYouPipelineStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 16) {
                    // Left: vertical connector + status icon
                    VStack(spacing: 0) {
                        StepStatusIcon(status: step.status)
                            .frame(width: 28, height: 28)

                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(connectorColor(for: step.status))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 2)
                        }
                    }
                    .frame(width: 28)

                    // Right: content
                    VStack(alignment: .leading, spacing: 6) {
                        Text(step.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(step.subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        // Expandable result sub-card
                        if step.status == .completed || step.status == .skipped,
                           let summary = step.resultSummary {
                            ResultSubCard(text: summary, isSkipped: step.status == .skipped)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: steps.map { $0.status })
    }

    private func connectorColor(for status: ForYouPipelineStep.StepStatus) -> Color {
        switch status {
        case .completed: return .green.opacity(0.4)
        case .skipped:   return Color(.systemGray4)
        default:         return Color(.systemGray5)
        }
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
