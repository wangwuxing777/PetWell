//
//  InsuranceService.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/14.
//

import Combine
import Foundation

// MARK: - API Models (matching backend)

/// Provider/product from pet_insurance_comparison table
struct InsuranceProvider: Codable, Identifiable {
  let providerKey: String
  let insuranceProvider: String
  let companyName: String
  let planName: String
  let category: String
  let subcategory: String
  let coveragePercentage: String
  let cancerCashHkd: Double?
  let cancerCashNotes: String?
  let additionalCriticalCashBenefit: Double?
  let coverageMode: String

  var id: String { providerKey }

  enum CodingKeys: String, CodingKey {
    case providerKey = "provider_key"
    case insuranceProvider = "insurance_provider"
    case companyName = "company_name"
    case planName = "plan_name"
    case category
    case subcategory
    case coveragePercentage = "coverage_percentage"
    case cancerCashHkd = "cancer_cash_hkd"
    case cancerCashNotes = "cancer_cash_notes"
    case additionalCriticalCashBenefit = "additional_critical_cash_benefit"
    case coverageMode = "coverage_mode"
  }

  /// True if this is a "big bucket" (no sub-limits, shared pool) style product
  var isBigBucket: Bool { coverageMode == "big_bucket" }

  /// True if this is a "bento box" (sub-limits per service) style product
  var isBentoBox: Bool { coverageMode == "bento_box" }
}

/// Coverage limit from coverage_limits table
struct CoverageLimit: Codable, Identifiable {
  let id: Int
  let limitItem: String
  let providerKey: String
  let level: String
  let category: String
  let subcategory: String
  let coverageAmountHkd: String
  let notes: String?

  enum CodingKeys: String, CodingKey {
    case id
    case limitItem = "limit_item"
    case providerKey = "provider_key"
    case level
    case category
    case subcategory
    case coverageAmountHkd = "coverage_amount_hkd"
    case notes
  }

  /// Parse coverage amount as integer (for display)
  var coverageAmountInt: Int? {
    Int(coverageAmountHkd.replacingOccurrences(of: ",", with: ""))
  }
}

/// Service subcategory reference
struct ServiceSubcategory: Codable, Identifiable {
  let id: Int
  let name: String
  let displayOrder: Int

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case displayOrder = "display_order"
  }
}

// MARK: - Service

/// Service to load and query insurance data from backend API
final class InsuranceService: ObservableObject {
  static let shared = InsuranceService()

  private let baseURL = "http://localhost:8000"

  @Published var providers: [InsuranceProvider] = []
  @Published var coverageLimits: [CoverageLimit] = []
  @Published var serviceSubcategories: [ServiceSubcategory] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  init() {
    // Load data on init
    Task {
      await loadAllData()
    }
  }

  // MARK: - Public Methods

  /// Load all insurance data from backend
  @MainActor
  func loadAllData() async {
    print("🔄 InsuranceService: Starting to load data...")
    isLoading = true
    errorMessage = nil

    async let providersTask = fetchProviders()
    async let limitsTask = fetchCoverageLimits()
    async let subcategoriesTask = fetchServiceSubcategories()

    do {
      let (p, l, s) = try await (providersTask, limitsTask, subcategoriesTask)
      self.providers = p
      self.coverageLimits = l
      self.serviceSubcategories = s
      print("✅ InsuranceService: Data loaded successfully!")
      print("   - Providers: \(p.count)")
      print("   - Coverage Limits: \(l.count)")
      print("   - Service Subcategories: \(s.count)")
    } catch {
      errorMessage = "Failed to load insurance data: \(error.localizedDescription)"
      print("❌ InsuranceService error: \(error)")
      print("   Error type: \(type(of: error))")
      if let urlError = error as? URLError {
        print("   URL Error code: \(urlError.code.rawValue)")
        print("   URL Error description: \(urlError.localizedDescription)")
      }
    }

    isLoading = false
    print("🏁 InsuranceService: Loading complete. IsLoading=\(isLoading)")
  }

  /// Get all unique company names
  func getCompanyNames() -> [String] {
    let names = Set(providers.map { $0.companyName })
    return Array(names).sorted()
  }

  /// Get providers for a specific company
  func getProviders(forCompany company: String) -> [InsuranceProvider] {
    providers.filter { $0.companyName == company }
  }

  /// Get coverage limit where level = "Category" for a provider
  func getCategoryLimit(forProviderKey key: String) -> CoverageLimit? {
    coverageLimits.first { $0.providerKey == key && $0.level == "Category" }
  }

  /// Get all subcategory limits for a provider
  func getSubcategoryLimits(forProviderKey key: String) -> [CoverageLimit] {
    coverageLimits.filter { $0.providerKey == key && $0.level == "Subcategory" }
  }

  /// Check if a provider covers a specific service subcategory
  /// For bento box products, returns the limit if covered
  /// For big bucket products, returns true (all services covered from pool)
  func getCoverage(forProviderKey key: String, service: String) -> (covered: Bool, limit: String?) {
    guard let provider = providers.first(where: { $0.providerKey == key }) else {
      return (false, nil)
    }

    if provider.isBigBucket {
      // Big bucket: check if service is in the provider's subcategory list
      let coveredServices = provider.subcategory.split(separator: ",").map {
        $0.trimmingCharacters(in: .whitespaces)
      }
      let isCovered = coveredServices.contains { $0.lowercased() == service.lowercased() }
      return (isCovered, isCovered ? "Full Pool" : nil)
    } else {
      // Bento box: check specific subcategory limits
      let limit = coverageLimits.first {
        $0.providerKey == key && $0.level == "Subcategory"
          && $0.subcategory.lowercased().contains(service.lowercased())
      }
      if let limit = limit {
        let amount = limit.coverageAmountHkd
        return (amount != "-" && !amount.isEmpty, amount == "-" ? nil : "HK$\(amount)")
      }
      return (false, nil)
    }
  }

  // MARK: - Private API Methods

  private func fetchProviders() async throws -> [InsuranceProvider] {
    guard let url = URL(string: "\(baseURL)/insurance-providers") else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([InsuranceProvider].self, from: data)
  }

  private func fetchCoverageLimits(providerKey: String? = nil, level: String? = nil) async throws
    -> [CoverageLimit]
  {
    var urlComponents = URLComponents(string: "\(baseURL)/coverage-limits")!
    var queryItems: [URLQueryItem] = []
    if let key = providerKey {
      queryItems.append(URLQueryItem(name: "provider_key", value: key))
    }
    if let lvl = level {
      queryItems.append(URLQueryItem(name: "level", value: lvl))
    }
    if !queryItems.isEmpty {
      urlComponents.queryItems = queryItems
    }

    guard let url = urlComponents.url else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([CoverageLimit].self, from: data)
  }

  private func fetchServiceSubcategories() async throws -> [ServiceSubcategory] {
    guard let url = URL(string: "\(baseURL)/service-subcategories") else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([ServiceSubcategory].self, from: data)
  }
}
