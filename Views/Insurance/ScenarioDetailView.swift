//
//  ScenarioDetailView.swift
//  PetWell
//
//  Created by AI Assistant on 2026/2/24.
//

import Charts
import SwiftUI

struct ScenarioDetailView: View {
  let scenario: Scenario

  var body: some View {
    VStack(spacing: 24) {
      // Intro Text
      Text(scenario.presentation.description)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)

      // Section 1: Cost Breakdown
      costBreakdownSection

      // Section 2: Payout Comparison Chart
      chartSection

      // Section 3: Payout Cards
      payoutCardsSection

      Spacer().frame(height: 16)
    }
    .background(
      .ultraThinMaterial,
      in: RoundedRectangle(cornerRadius: 14, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
    )
    .padding(.horizontal, 10)
    .padding(.top, 10)
    .padding(.bottom, 16)
  }

  // MARK: - Section 1: Cost Breakdown
  private var costBreakdownSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Estimated Total Cost")
        .font(.headline)
        .padding(.horizontal)

      // Total Big Text
      Text("HK$\(scenario.totalCostHkd)")
        .font(.system(size: 32, weight: .bold))
        .foregroundColor(.orange)
        .padding(.horizontal)

      // Tags
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(scenario.costBreakdown) { item in
            HStack(spacing: 4) {
              Text(item.itemName)
              Text("$\(item.amountHkd)")
                .fontWeight(.semibold)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.1))
            .foregroundColor(.orange)
            .cornerRadius(8)
          }
        }
        .padding(.horizontal)
      }
    }
  }

  // MARK: - Section 2: Payout Chart
  private var chartSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Payout Comparison")
        .font(.headline)
        .padding(.horizontal)

      Chart {
        ForEach(scenario.payouts) { payout in
          BarMark(
            x: .value("Payout", payout.estimatedPayoutHkd),
            y: .value("Insurer", payout.insurerName)
          )
          .foregroundStyle(payout.isRecommended ? Color.orange : Color.blue)
          .cornerRadius(4)
        }

        // Total Cost Reference Line
        RuleMark(x: .value("Total Cost", scenario.totalCostHkd))
          .foregroundStyle(.gray.opacity(0.5))
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .annotation(position: .top, alignment: .leading) {
            Text("Total Bill")
              .font(.caption2)
              .foregroundColor(.gray)
          }
      }
      .frame(height: max(200, CGFloat(scenario.payouts.count * 40)))
      .padding()
      .background(.ultraThinMaterial)
      .cornerRadius(16)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.white.opacity(0.4), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
      .padding(.horizontal)
    }
  }

  // MARK: - Section 3: Payout Cards
  private var payoutCardsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Detailed Breakdown")
        .font(.headline)
        .padding(.horizontal)

      LazyVStack(spacing: 16) {
        ForEach(scenario.payouts.sorted(by: { $0.estimatedPayoutHkd > $1.estimatedPayoutHkd })) {
          payout in
          PayoutCard(payout: payout)
        }
      }
      .padding(.horizontal)
    }
  }
}

// MARK: - Payout Card
struct PayoutCard: View {
  let payout: Payout

  var progressColor: Color {
    let p = payout.coveragePercentage
    if p == 0 { return .red }
    if p <= 50 { return .orange }
    if p <= 80 { return .yellow }
    return .green
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header: Insurer name & plan + Special Badge
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(payout.insurerName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.primary)
          Text(payout.planName)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }

        Spacer()

        if payout.isRecommended {
          Text("Recommended")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.yellow)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
      }

      // Payout value
      HStack(alignment: .bottom) {
        Text("HK$\(payout.estimatedPayoutHkd)")
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.green)

        Text("Estimated Payout")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.bottom, 4)

        Spacer()

        // Percentage Text
        Text("\(Int(payout.coveragePercentage))%")
          .font(.caption)
          .fontWeight(.bold)
          .foregroundColor(progressColor)
      }

      // Progress Bar
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 6)

          Capsule()
            .fill(progressColor)
            .frame(
              width: geo.size.width * CGFloat(min(max(payout.coveragePercentage / 100.0, 0), 1)),
              height: 6)
        }
      }
      .frame(height: 6)

      // Description/Analysis
      Text(payout.englishSummary)
        .font(.system(size: 13))
        .foregroundColor(.gray)
        .padding(.top, 4)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(16)
    .background(.ultraThinMaterial)
  .cornerRadius(16)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(payout.isRecommended ? Color.yellow.opacity(0.7) : Color.white.opacity(0.32), lineWidth: 1.2)
    )
    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
  }
}
