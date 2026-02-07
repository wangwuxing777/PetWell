//
//  InsuranceModels.swift
//  PetWell
//
//  Created by AI Assistant on 2026/2/4.
//

import Foundation

// MARK: - Coverage Display Mode

/// Determines how to display coverage in UI cells
enum CoverageDisplayMode: Equatable {
  case checkmark  // limitValue is nil or "yes"
  case value(String)  // limitValue is a numeric string
  case notCovered  // No mapping found for productID-coverageID
}

// MARK: - Insurance Provider

/// Insurance company from insurance_provider table
struct InsuranceCompany: Codable, Identifiable {
  let companyId: Int
  let companyName: String
  let companyNameZh: String?
  let companyLogo: String?

  var id: Int { companyId }

  enum CodingKeys: String, CodingKey {
    case companyId = "company_id"
    case companyName = "company_name"
    case companyNameZh = "company_name_zh"
    case companyLogo = "company_logo"
  }
}

// MARK: - Product (Insurance Plan)

/// Insurance product/plan from product table
struct InsuranceProduct: Codable, Identifiable {
  let insuranceId: Int
  let providerId: Int
  let insuranceName: String
  let insuranceNameZh: String?
  let remark: String?
  let remarkZh: String?
  let minAge: String?
  let minAgeZh: String?
  let maxAge: String?
  let maxAgeZh: String?
  let coinsurance: String?
  let coinsuranceZh: String?
  let suitablePetType: String?
  let suitablePetTypeZh: String?
  let catBreedType: String?
  let catBreedTypeZh: String?
  let dogBreedType: String?
  let dogBreedTypeZh: String?
  let breedTypeRemark: String?
  let breedTypeRemarkZh: String?
  let paymentMode: String?
  let paymentModeZh: String?
  let waitingPeriod: String?
  let waitingPeriodZh: String?
  let informationLink: String?
  let informationLinkZh: String?
  let updateTime: String?
  let tag: String?
  let tagZh: String?

  var id: Int { insuranceId }

  enum CodingKeys: String, CodingKey {
    case insuranceId = "insurance_id"
    case providerId = "provider_id"
    case insuranceName = "insurance_name"
    case insuranceNameZh = "insurance_name_zh"
    case remark
    case remarkZh = "remark_zh"
    case minAge = "min_age"
    case minAgeZh = "min_age_zh"
    case maxAge = "max_age"
    case maxAgeZh = "max_age_zh"
    case coinsurance
    case coinsuranceZh = "coinsurance_zh"
    case suitablePetType = "suitable_pet_type"
    case suitablePetTypeZh = "suitable_pet_type_zh"
    case catBreedType = "cat_breed_type"
    case catBreedTypeZh = "cat_breed_type_zh"
    case dogBreedType = "dog_breed_type"
    case dogBreedTypeZh = "dog_breed_type_zh"
    case breedTypeRemark = "breed_type_remark"
    case breedTypeRemarkZh = "breed_type_remark_zh"
    case paymentMode = "payment_mode"
    case paymentModeZh = "payment_mode_zh"
    case waitingPeriod = "waiting_period"
    case waitingPeriodZh = "waiting_period_zh"
    case informationLink = "information_link"
    case informationLinkZh = "information_link_zh"
    case updateTime = "update_time"
    case tag
    case tagZh = "tag_zh"
  }
}

// MARK: - Coverage List

/// Coverage type from coverage_list table
struct CoverageItem: Codable, Identifiable {
  let coverageId: Int
  let coverageType: String
  let coverageTypeZh: String?

  var id: Int { coverageId }

  enum CodingKeys: String, CodingKey {
    case coverageId = "coverage_id"
    case coverageType = "coverage_type"
    case coverageTypeZh = "coverage_type_zh"
  }
}

// MARK: - Coverage Limit

/// Coverage limit linking productID with coverageID from coverage_limit table
struct CoverageLimit: Codable, Identifiable {
  let coverageId: Int
  let productId: Int
  let coverageLimit: String?  // Can be nil, numeric string, or "yes"
  let remark: String?
  let remarkZh: String?

  // Pre-parsed JSON data (decoded during init)
  let parsedRemark: RemarkData?

  var id: String { "\(coverageId)-\(productId)" }

  enum CodingKeys: String, CodingKey {
    case coverageId = "coverage_id"
    case productId = "product_id"
    case coverageLimit = "coverage_limit"
    case remark
    case remarkZh = "remark_zh"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    coverageId = try container.decode(Int.self, forKey: .coverageId)
    productId = try container.decode(Int.self, forKey: .productId)
    coverageLimit = try container.decodeIfPresent(String.self, forKey: .coverageLimit)
    remark = try container.decodeIfPresent(String.self, forKey: .remark)
    remarkZh = try container.decodeIfPresent(String.self, forKey: .remarkZh)

    // Attempt to parse JSON string
    if let r = remark, let data = r.data(using: .utf8) {
      // Decode directly into RemarkData
      self.parsedRemark = try? JSONDecoder().decode(RemarkData.self, from: data)
    } else {
      self.parsedRemark = nil
    }
  }

  /// Determines display mode for the cell
  /// - nil or "yes" → checkmark
  /// - numeric string → display value
  var displayMode: CoverageDisplayMode {
    guard let value = coverageLimit, !value.isEmpty else {
      return .checkmark
    }

    let lowercased = value.lowercased()
    if lowercased == "yes" {
      return .checkmark
    }

    return .value(value)
  }

  /// Returns true if this coverage should display a checkmark
  var isCheckmarkDisplay: Bool {
    if case .checkmark = displayMode {
      return true
    }
    return false
  }

  /// Returns the formatted limit value for display, or nil if checkmark should be shown
  var formattedLimitValue: String? {
    if case .value(let amount) = displayMode {
      // Try to format as currency if it's a number
      if let numericValue = Int(amount.replacingOccurrences(of: ",", with: "")) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "HK$\(formatter.string(from: NSNumber(value: numericValue)) ?? amount)"
      }
      return amount
    }
    return nil
  }
}

// MARK: - Sub Coverage Limit

/// Sub-coverage limit (child of CoverageItem) from sub_coverage_limit table
struct SubCoverageLimit: Codable, Identifiable {
  let subCoverageId: Int
  let parentCoverageId: Int
  let productId: Int
  let subCoverageName: String?
  let subCoverageNameZh: String?
  let subLimit: String?
  let subCoverageRemark: String?
  let subCoverageRemarkZh: String?

  var id: Int { subCoverageId }

  enum CodingKeys: String, CodingKey {
    case subCoverageId = "sub_coverage_id"
    case parentCoverageId = "parent_coverage_id"
    case productId = "product_id"
    case subCoverageName = "sub_coverage_name"
    case subCoverageNameZh = "sub_coverage_name_zh"
    case subLimit = "sub_limit"
    case subCoverageRemark = "sub_coverage_remark"
    case subCoverageRemarkZh = "sub_coverage_remark_zh"
  }

  /// Display mode for sub-coverage limit
  var displayMode: CoverageDisplayMode {
    guard let value = subLimit, !value.isEmpty else {
      return .checkmark
    }

    let lowercased = value.lowercased()
    if lowercased == "yes" {
      return .checkmark
    }

    return .value(value)
  }

  /// Returns true if this sub-coverage should display a checkmark
  var isCheckmarkDisplay: Bool {
    if case .checkmark = displayMode {
      return true
    }
    return false
  }
}

// MARK: - JSON Remark Models

/// Polymorphic structure for parsing various remark JSON formats
struct RemarkData: Codable {
  // Common / Generic Fields
  let remarkId: String?
  let title: String?
  let summary: String?
  let coverageScopes: [RemarkScope]?
  let highlights: RemarkHighlight?
  let rawText: String?

  // New Polymorphic Fields
  let type: String?  // "benefit_header", "eligibility_detail", "special_coverage"
  let category: String?  // For eligibility/special coverage

  // "benefit_header" fields
  let content: RemarkContent?

  // "eligibility_detail" fields
  let eligibility: RemarkEligibility?
  let limits: RemarkLimits?
  let uiHints: RemarkUIHints?

  // "special_coverage" fields
  let targetSpecies: String?
  let rules: [RemarkRule]?
  let medicalDisclaimer: String?

  enum CodingKeys: String, CodingKey {
    case remarkId = "remark_id"
    case title, summary, highlights
    case coverageScopes = "coverage_scopes"
    case rawText = "raw_text"
    case type, category, content, eligibility, limits
    case uiHints = "ui_hints"
    case targetSpecies = "target_species"
    case rules
    case medicalDisclaimer = "medical_disclaimer"
  }
}

// -- Generic Scope --
struct RemarkScope: Codable, Identifiable {
  var id: String { category }
  let category: String
  let items: [String]
  let icon: String?
}

struct RemarkHighlight: Codable {
  let type: String?
  let label: String?
  let amount: String?
  let currency: String?
  let condition: String?
}

// -- Benefit Header --
struct RemarkContent: Codable {
  let title: String?
  let badgeText: String?
  let icon: String?

  enum CodingKeys: String, CodingKey {
    case title, icon
    case badgeText = "badge_text"
  }
}

// -- Eligibility Detail --
struct RemarkEligibility: Codable {
  let species: [String]?
  let ageRange: String?
  let preExistingCondition: String?

  enum CodingKeys: String, CodingKey {
    case species
    case ageRange = "age_range"
    case preExistingCondition = "pre_existing_condition"
  }
}

struct RemarkLimits: Codable {
  let frequency: String?
  let payoutType: String?

  enum CodingKeys: String, CodingKey {
    case frequency
    case payoutType = "payout_type"
  }
}

struct RemarkUIHints: Codable {
  let tags: [String]?
  let themeColor: String?

  enum CodingKeys: String, CodingKey {
    case tags
    case themeColor = "theme_color"
  }
}

// -- Special Coverage --
struct RemarkRule: Codable, Identifiable {
  var id: String { label }
  let label: String
  let value: String
  let isRequirement: Bool?
  let highlight: Bool?

  enum CodingKeys: String, CodingKey {
    case label, value, highlight
    case isRequirement = "is_requirement"
  }
}

// MARK: - Aggregated Models for UI

/// Aggregated coverage data for a specific product with all its limits and sub-limits
struct ProductCoverageData {
  let product: InsuranceProduct
  let company: InsuranceCompany?
  let coverageLimits: [CoverageLimit]
  let subCoverageLimits: [SubCoverageLimit]

  /// Get coverage limit for a specific coverage ID
  func getCoverageLimit(forCoverageId coverageId: Int) -> CoverageLimit? {
    coverageLimits.first { $0.coverageId == coverageId }
  }

  /// Get sub-coverage limits for a specific parent coverage ID
  func getSubCoverageLimits(forParentCoverageId parentId: Int) -> [SubCoverageLimit] {
    subCoverageLimits.filter { $0.parentCoverageId == parentId }
  }

  /// Get display mode for a coverage, returns .notCovered if not found
  func getDisplayMode(forCoverageId coverageId: Int) -> CoverageDisplayMode {
    guard let limit = getCoverageLimit(forCoverageId: coverageId) else {
      return .notCovered
    }
    return limit.displayMode
  }
}

/// Section model for grouped coverage display
struct CoverageSection: Identifiable {
  let id: Int
  let coverageItem: CoverageItem
  let subCoverages: [SubCoverageLimit]

  var title: String {
    coverageItem.coverageType
  }

  var titleZh: String? {
    coverageItem.coverageTypeZh
  }
}
