//
//  ScenarioModels.swift
//  PetWell
//
//  Created by AI Assistant on 2026/2/24.
//

import Foundation

struct ScenarioResponse: Codable {
  let scenarios: [Scenario]
}

struct Scenario: Codable, Identifiable {
  let id: String
  let title: String
  let description: String
  let totalCostHkd: Int
  let costBreakdown: [CostItem]
  let payouts: [Payout]

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case description
    case totalCostHkd = "total_cost_hkd"
    case costBreakdown = "cost_breakdown"
    case payouts
  }
}

struct CostItem: Codable, Identifiable {
  let id: UUID = UUID()  // Locally generated
  let itemName: String
  let amountHkd: Int

  enum CodingKeys: String, CodingKey {
    case itemName = "item_name"
    case amountHkd = "amount_hkd"
  }
}

struct Payout: Codable, Identifiable {
  let id: UUID = UUID()  // Locally generated
  let insurerId: String
  let insurerName: String
  let planName: String
  let estimatedPayoutHkd: Int
  let coveragePercentage: Double
  let analysis: String?
  let isRecommended: Bool

  enum CodingKeys: String, CodingKey {
    case insurerId = "insurer_id"
    case insurerName = "insurer_name"
    case planName = "plan_name"
    case estimatedPayoutHkd = "estimated_payout_hkd"
    case coveragePercentage = "coverage_percentage"
    case analysis
    case isRecommended = "is_recommended"
  }
}
