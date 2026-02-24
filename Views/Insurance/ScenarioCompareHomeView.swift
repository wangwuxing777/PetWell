//
//  ScenarioCompareHomeView.swift
//  PetWell
//
//  Created by AI Assistant on 2026/2/24.
//

import SwiftUI

struct ScenarioCompareHomeView: View {
  @StateObject private var scenarioService = ScenarioService.shared

  var body: some View {
    ZStack {
      Color(hex: "F8F9FA").ignoresSafeArea()  // Light grey background

      if scenarioService.isLoading {
        ProgressView("Loading scenarios...")
      } else if let error = scenarioService.errorMessage {
        VStack {
          Text("Error loading data")
            .font(.headline)
            .foregroundColor(.red)
          Text(error)
            .font(.caption)
            .foregroundColor(.secondary)

          Button("Retry") {
            Task { await scenarioService.fetchScenarios() }
          }
          .padding(.top)
        }
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {

            Text("Compare insurance payouts for real-world veterinary scenarios.")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .padding(.horizontal)

            LazyVStack(spacing: 16) {
              ForEach(scenarioService.scenarios) { scenario in
                NavigationLink(destination: ScenarioDetailView(scenario: scenario)) {
                  ScenarioCard(scenario: scenario)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
          }
          .padding(.top, 16)
        }
      }
    }
  }
}

struct ScenarioCard: View {
  let scenario: Scenario

  // Count how many providers were recommended
  var recommendedCount: Int {
    scenario.payouts.filter { $0.isRecommended }.count
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {

      Text(scenario.title)
        .font(.headline)
        .foregroundColor(.black)
        .lineLimit(2)

      HStack {
        // Cost Tag
        HStack(spacing: 4) {
          Image(systemName: "dollarsign.circle.fill")
            .foregroundColor(.orange)
          Text("Total Cost: HK$\(scenario.totalCostHkd)")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
        }

        Spacer()

        // Recommended count tag
        if recommendedCount > 0 {
          HStack(spacing: 4) {
            Image(systemName: "star.fill")
              .foregroundColor(.yellow)
            Text("\(recommendedCount) Recommended")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(.primary)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.yellow.opacity(0.15))
          .cornerRadius(8)
        } else {
          Text("View Breakdown")
            .font(.caption)
            .foregroundColor(.blue)
        }
      }
    }
    .padding(16)
    .background(Color.white)
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
  }
}
