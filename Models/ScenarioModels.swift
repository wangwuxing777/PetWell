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

struct ScenarioPresentation {
  let title: String
  let description: String
  let imageName: String
}

extension Scenario {
  var presentation: ScenarioPresentation {
    switch totalCostHkd {
    case ..<2000:
      return ScenarioPresentation(
        title: "Common Illness (e.g., Ear Infection)",
        description: "A vet consultation, ear examination, and medication treatment.",
        imageName: "EarInfection"
      )
    case 18000...22000:
      return ScenarioPresentation(
        title: "Hereditary Condition Surgery (e.g., Patellar Luxation)",
        description: "Surgery for a common hereditary condition in pedigree pets.",
        imageName: "PatellarLuxation"
      )
    case 28000...33000:
      return ScenarioPresentation(
        title: "Chronic Illness Treatment (e.g., Cancer Chemotherapy)",
        description: "Ongoing chemotherapy treatment after a confirmed cancer diagnosis.",
        imageName: "CancerChemotherapy"
      )
    case 43000...47000:
      return ScenarioPresentation(
        title: "Major Accident Surgery (e.g., Fracture / Ligament Tear)",
        description: "X-ray, anesthesia, surgery, and multi-day hospitalization.",
        imageName: "Fracture"
      )
    case 48000...:
      return ScenarioPresentation(
        title: "Third-Party Liability (e.g., Dog Bite Incident)",
        description: "A third-party claim involving medical expenses and legal compensation.",
        imageName: "DogBite"
      )
    default:
      return ScenarioPresentation(
        title: "Insurance Payout Scenario",
        description: "A real-world veterinary case used for insurance payout comparison.",
        imageName: "CancerChemotherapy"
      )
    }
  }
}

extension Payout {
  var englishSummary: String {
    let percentage = Int(coveragePercentage.rounded())
    let base = "Estimated payout: HK$\(estimatedPayoutHkd) (\(percentage)% coverage)."
    if isRecommended {
      return "\(base) Marked as a recommended option for this scenario."
    }
    return base
  }
}
