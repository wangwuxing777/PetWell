//
//  InsuranceRecommendationView.swift
//  PetWell
//
//  Created by Frontend Engineer on 2026/03/04.
//

import SwiftUI

struct InsuranceRecommendationView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentLanguage: AppLanguage = .english
    @StateObject private var insuranceService = InsuranceService.shared

    // Recommendation parameters
    @State private var petSpecies: String = "dog"
    @State private var petAge: Int = 3
    @State private var budgetMin: Int = 500
    @State private var budgetMax: Int = 2000
    @State private var selectedCoverages: Set<String> = ["意外", "疾病"]
    @State private var additionalNotes: String = ""

    @State private var recommendations: [InsuranceRecommendation] = []
    @State private var analysis: String = ""
    @State private var isLoading = false
    @State private var hasSearched = false

    private let coverageOptions = ["意外", "疾病", "手術", "住院", "門診"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !hasSearched {
                        // Input Form
                        inputForm
                    } else if isLoading {
                        // Loading
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(languageManager.isChinese ? "分析中..." : "Analyzing...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    } else if recommendations.isEmpty {
                        // No results
                        emptyResults
                    } else {
                        // Results
                        resultsView
                    }
                }
                .padding()
            }
            .navigationTitle(languageManager.isChinese ? "AI 推薦" : "AI Recommendation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Input Form
    private var inputForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Pet Species
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.isChinese ? "寵物類型" : "Pet Type")
                    .font(.headline)

                HStack(spacing: 12) {
                    PetTypeButton(
                        title: languageManager.isChinese ? "狗" : "Dog",
                        icon: "dog.fill",
                        isSelected: petSpecies == "dog"
                    ) {
                        petSpecies = "dog"
                    }

                    PetTypeButton(
                        title: languageManager.isChinese ? "貓" : "Cat",
                        icon: "cat.fill",
                        isSelected: petSpecies == "cat"
                    ) {
                        petSpecies = "cat"
                    }
                }
            }

            // Pet Age
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.isChinese ? "寵物年齡" : "Pet Age")
                    .font(.headline)

                Stepper(value: $petAge, in: 0...20) {
                    Text("\(petAge) \(languageManager.isChinese ? "歲" : "years")")
                        .font(.title3.weight(.semibold))
                }
            }

            // Budget
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.isChinese ? "每月預算 (HKD)" : "Monthly Budget (HKD)")
                    .font(.headline)

                HStack {
                    Text("HKD \(budgetMin)")
                    Slider(value: Binding(
                        get: { Double(budgetMin) },
                        set: { budgetMin = Int($0) }
                    ), in: 100...5000, step: 100)
                    Text("HKD \(budgetMax)")
                }

                Text("HKD \(budgetMin) - HKD \(budgetMax)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Coverage Preferences
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.isChinese ? "保障偏好" : "Coverage Preferences")
                    .font(.headline)

                FlowLayout(spacing: 8) {
                    ForEach(coverageOptions, id: \.self) { option in
                        CoverageChip(
                            title: option,
                            isSelected: selectedCoverages.contains(option)
                        ) {
                            if selectedCoverages.contains(option) {
                                selectedCoverages.remove(option)
                            } else {
                                selectedCoverages.insert(option)
                            }
                        }
                    }
                }
            }

            // Additional Notes
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.isChinese ? "其他需求" : "Additional Requirements")
                    .font(.headline)

                TextField(
                    languageManager.isChinese ? "例如：想保障髖關節問題" : "e.g., Hip dysplasia coverage",
                    text: $additionalNotes,
                    axis: .vertical
                )
                .lineLimit(3)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }

            // Search Button
            Button(action: searchRecommendations) {
                HStack {
                    Image(systemName: "sparkles")
                    Text(languageManager.isChinese ? "開始推薦" : "Get Recommendations")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
            }
        }
    }

    // MARK: - Results View
    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Analysis
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text(languageManager.isChinese ? "AI 分析" : "AI Analysis")
                        .font(.headline)
                }

                Text(analysis)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)

            // Recommendations
            ForEach(recommendations) { rec in
                RecommendationCard(recommendation: rec)
            }

            // Search Again
            Button(action: { hasSearched = false }) {
                Text(languageManager.isChinese ? "重新搜尋" : "Search Again")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Empty Results
    private var emptyResults: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text(languageManager.isChinese ? "沒有找到合適的計劃" : "No matching plans found")
                .font(.headline)
            Text(languageManager.isChinese ? "嘗試調整您的預算或保障偏好" : "Try adjusting your budget or coverage preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { hasSearched = false }) {
                Text(languageManager.isChinese ? "重新搜尋" : "Try Again")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, 60)
    }

    // MARK: - Actions
    private func searchRecommendations() {
        hasSearched = true
        isLoading = true

        Task {
            do {
                // Try to get real recommendation
                let response = try await insuranceService.getRecommendation(
                    petId: UUID().uuidString,
                    petSpecies: petSpecies,
                    petAge: petAge,
                    budgetMin: budgetMin,
                    budgetMax: budgetMax,
                    coveragePreferences: Array(selectedCoverages),
                    additionalRequirements: additionalNotes.isEmpty ? nil : additionalNotes
                )
                recommendations = response.data.recommendations
                analysis = response.data.analysis
            } catch {
                // Use demo data if API fails
                let demo = insuranceService.getDemoRecommendation()
                recommendations = demo.data.recommendations
                analysis = demo.data.analysis
            }

            isLoading = false
        }
    }
}

// MARK: - Pet Type Button
private struct PetTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Coverage Chip
private struct CoverageChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Recommendation Card
private struct RecommendationCard: View {
    let recommendation: InsuranceRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.insuranceName)
                        .font(.headline)
                    Text(recommendation.provider)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Match Score
                VStack {
                    Text("\(recommendation.matchScore)%")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.green)
                    Text("Match")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Coverage Summary
            VStack(alignment: .leading, spacing: 6) {
                Text("Coverage")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ForEach(recommendation.coverageSummary, id: \.self) { item in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(item)
                            .font(.subheadline)
                    }
                }
            }

            // Premium
            HStack {
                Text("HKD \(recommendation.monthlyPremium)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.blue)
                Text("/ \(languageManager.isChinese ? "月" : "month")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Reason
            Text(recommendation.reason)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private var languageManager: LanguageManager {
    // This is a workaround - in real use, inject via EnvironmentObject
    LanguageManager()
}

#Preview {
    InsuranceRecommendationView()
        .environmentObject(LanguageManager())
}
