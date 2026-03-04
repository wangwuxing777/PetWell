//
//  InsuranceService.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/14.
//  Refactored to support new pet_insurance.db schema
//

import Combine
import Foundation

// MARK: - Legacy Models (kept for backward compatibility)

/// Provider/product from pet_insurance_comparison table (legacy)
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

/// Service subcategory reference (legacy)
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

  private let baseURL = "http://127.0.0.1:8000"

  enum NetworkError: LocalizedError {
    case nonHTTPResponse
    case httpError(statusCode: Int, body: String)

    var errorDescription: String? {
      switch self {
      case .nonHTTPResponse:
        return "Non-HTTP response"
      case .httpError(let statusCode, let body):
        return "HTTP \(statusCode): \(body)"
      }
    }
  }

  // MARK: - Legacy Published Properties (for backward compatibility)
  @Published var providers: [InsuranceProvider] = []
  @Published var serviceSubcategories: [ServiceSubcategory] = []

  // MARK: - New Published Properties (from pet_insurance.db)
  @Published var companies: [InsuranceCompany] = []
  @Published var products: [InsuranceProduct] = []
  @Published var coverageItems: [CoverageItem] = []
  @Published var coverageLimits: [CoverageLimit] = []
  @Published var subCoverageLimits: [SubCoverageLimit] = []

  // MARK: - State Properties
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

    // Fetch all data in parallel
    async let companiesTask = fetchCompanies()
    async let productsTask = fetchProducts()
    async let coverageItemsTask = fetchCoverageItems()
    async let coverageLimitsTask = fetchCoverageLimits()
    async let subCoverageLimitsTask = fetchSubCoverageLimits()

    // Also fetch legacy data for backward compatibility
    async let providersTask = fetchProviders()
    async let subcategoriesTask = fetchServiceSubcategories()

    do {
      let (companies, products, coverageItems, coverageLimits, subCoverageLimits) =
        try await (
          companiesTask, productsTask, coverageItemsTask, coverageLimitsTask, subCoverageLimitsTask
        )

      self.companies = companies
      self.products = products
      self.coverageItems = coverageItems
      self.coverageLimits = coverageLimits
      self.subCoverageLimits = subCoverageLimits

      print("✅ InsuranceService: New data loaded successfully!")
      print("   - Companies: \(companies.count)")
      print("   - Products: \(products.count)")
      print("   - Coverage Items: \(coverageItems.count)")
      print("   - Coverage Limits: \(coverageLimits.count)")
      print("   - Sub Coverage Limits: \(subCoverageLimits.count)")

      // Try to load legacy data (non-fatal if it fails)
      do {
        let (p, s) = try await (providersTask, subcategoriesTask)
        self.providers = p
        self.serviceSubcategories = s
        print("   - Legacy Providers: \(p.count)")
        print("   - Legacy Subcategories: \(s.count)")
      } catch {
        print("⚠️ Legacy data not available: \(error.localizedDescription)")
      }

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

  // MARK: - New ViewModel Methods

  /// Get company for a product
  func getCompany(forProduct product: InsuranceProduct) -> InsuranceCompany? {
    companies.first { $0.companyId == product.providerId }
  }

  /// Get company by ID
  func getCompany(byId companyId: Int) -> InsuranceCompany? {
    companies.first { $0.companyId == companyId }
  }

  /// Get all products for a company
  func getProducts(forCompanyId companyId: Int) -> [InsuranceProduct] {
    products.filter { $0.providerId == companyId }
  }

  /// Get coverage limit for a specific product and coverage combination
  /// Returns nil if no mapping found (indicates "not covered")
  func getCoverageLimit(productId: Int, coverageId: Int) -> CoverageLimit? {
    coverageLimits.first { $0.productId == productId && $0.coverageId == coverageId }
  }

  /// Get display mode for a specific product and coverage
  /// Returns .notCovered if no mapping found
  func getDisplayMode(productId: Int, coverageId: Int) -> CoverageDisplayMode {
    guard let limit = getCoverageLimit(productId: productId, coverageId: coverageId) else {
      return .notCovered
    }
    return limit.displayMode
  }

  /// Get sub-coverage limits for a specific product and parent coverage
  func getSubCoverageLimits(productId: Int, parentCoverageId: Int) -> [SubCoverageLimit] {
    subCoverageLimits.filter {
      $0.productId == productId && $0.parentCoverageId == parentCoverageId
    }
  }

  /// Get all sub-coverage limits for a product
  func getSubCoverageLimits(forProductId productId: Int) -> [SubCoverageLimit] {
    subCoverageLimits.filter { $0.productId == productId }
  }

  /// Aggregate coverage data by category for List/ForEach rendering
  /// Returns ordered coverage items (already ordered by coverageId)
  func getOrderedCoverageItems() -> [CoverageItem] {
    coverageItems.sorted { $0.coverageId < $1.coverageId }
  }

  /// Get aggregate product coverage data for comparison view
  func getProductCoverageData(productId: Int) -> ProductCoverageData? {
    guard let product = products.first(where: { $0.insuranceId == productId }) else {
      return nil
    }

    let company = getCompany(forProduct: product)
    let productLimits = coverageLimits.filter { $0.productId == productId }
    let productSubLimits = subCoverageLimits.filter { $0.productId == productId }

    return ProductCoverageData(
      product: product,
      company: company,
      coverageLimits: productLimits,
      subCoverageLimits: productSubLimits
    )
  }

  /// Build coverage sections with sub-coverages for a specific product
  func buildCoverageSections(forProductId productId: Int) -> [CoverageSection] {
    let orderedItems = getOrderedCoverageItems()
    return orderedItems.map { item in
      let subCoverages = getSubCoverageLimits(
        productId: productId, parentCoverageId: item.coverageId)
      return CoverageSection(id: item.coverageId, coverageItem: item, subCoverages: subCoverages)
    }
  }

  // MARK: - Legacy Methods (for backward compatibility)

  /// Get all unique company names (legacy)
  func getCompanyNames() -> [String] {
    let names = Set(providers.map { $0.companyName })
    return Array(names).sorted()
  }

  /// Get providers for a specific company (legacy)
  func getProviders(forCompany company: String) -> [InsuranceProvider] {
    providers.filter { $0.companyName == company }
  }

  /// Get coverage limit where level = "Category" for a provider (legacy)
  func getCategoryLimit(forProviderKey key: String) -> CoverageLimit? {
    // Try to find matching product and return its total limit
    // This is a compatibility shim
    if let product = products.first(where: { "\($0.insuranceId)" == key || $0.insuranceName == key }
    ) {
      // Return the first coverage limit (Medical Coverage is usually ID 1)
      return coverageLimits.first { $0.productId == product.insuranceId && $0.coverageId == 1 }
    }
    return nil
  }

  /// Check if a provider covers a specific service subcategory (legacy)
  func getCoverage(forProviderKey key: String, service: String) -> (covered: Bool, limit: String?) {
    guard let provider = providers.first(where: { $0.providerKey == key }) else {
      return (false, nil)
    }

    if provider.isBigBucket {
      let coveredServices = provider.subcategory.split(separator: ",").map {
        $0.trimmingCharacters(in: .whitespaces)
      }
      let isCovered = coveredServices.contains { $0.lowercased() == service.lowercased() }
      return (isCovered, isCovered ? "Full Pool" : nil)
    } else {
      // Try to match with new coverage system
      if let product = products.first(where: { "\($0.insuranceId)" == key }) {
        let subLimit = subCoverageLimits.first {
          $0.productId == product.insuranceId
            && ($0.subCoverageName?.lowercased().contains(service.lowercased()) ?? false)
        }
        if let subLimit = subLimit, let limitValue = subLimit.subLimit {
          return (true, limitValue)
        }
      }
      return (false, nil)
    }
  }

  // MARK: - Private API Methods (New Endpoints)

  private func fetchJSON<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
    guard let url = URL(string: "\(baseURL)\(path)") else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw NetworkError.nonHTTPResponse
    }

    guard (200...299).contains(http.statusCode) else {
      let body = String(data: data, encoding: .utf8) ?? "<non-utf8 \(data.count) bytes>"
      print("❌ InsuranceService HTTP error: \(path) status=\(http.statusCode) body=\(body.prefix(300))")
      throw NetworkError.httpError(statusCode: http.statusCode, body: body)
    }

    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      let body = String(data: data, encoding: .utf8) ?? "<non-utf8 \(data.count) bytes>"
      print("❌ InsuranceService decode error: \(path) bodyPrefix=\(body.prefix(300))")
      throw error
    }
  }

  private func fetchCompanies() async throws -> [InsuranceCompany] {
    try await fetchJSON("/insurance-companies", as: [InsuranceCompany].self)
  }

  private func fetchProducts() async throws -> [InsuranceProduct] {
    try await fetchJSON("/insurance-products", as: [InsuranceProduct].self)
  }

  private func fetchCoverageItems() async throws -> [CoverageItem] {
    try await fetchJSON("/coverage-list", as: [CoverageItem].self)
  }

  private func fetchCoverageLimits() async throws -> [CoverageLimit] {
    try await fetchJSON("/coverage-limits", as: [CoverageLimit].self)
  }

  private func fetchSubCoverageLimits() async throws -> [SubCoverageLimit] {
    try await fetchJSON("/sub-coverage-limits", as: [SubCoverageLimit].self)
  }

  // MARK: - Legacy API Methods

  private func fetchProviders() async throws -> [InsuranceProvider] {
    try await fetchJSON("/insurance-providers", as: [InsuranceProvider].self)
  }

  private func fetchServiceSubcategories() async throws -> [ServiceSubcategory] {
    try await fetchJSON("/service-subcategories", as: [ServiceSubcategory].self)
  }

  // MARK: - AI Insurance Recommendation

  /**
   Request AI-powered insurance recommendation

   POST /api/insurance/recommend
   Request: {
       "pet_id": "uuid",
       "pet_species": "dog | cat",
       "pet_breed": "breed (optional)",
       "pet_age": 3,
       "budget_range": { "min": 500, "max": 2000, "currency": "HKD" },
       "coverage_preferences": ["意外", "疾病", "手术"],
       "additional_requirements": "string (optional)"
   }
   Response: {
       "success": true,
       "data": {
           "recommendations": [...],
           "analysis": "..."
       }
   }
   */
  func getRecommendation(
    petId: String,
    petSpecies: String,
    petBreed: String? = nil,
    petAge: Int,
    budgetMin: Int? = nil,
    budgetMax: Int? = nil,
    coveragePreferences: [String] = [],
    additionalRequirements: String? = nil
  ) async throws -> InsuranceRecommendationResponse {
    guard let url = URL(string: "\(baseURL)/insurance/recommend") else {
        throw NetworkError.nonHTTPResponse
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    var budgetRange: [String: Any]? = nil
    if let min = budgetMin, let max = budgetMax {
        budgetRange = ["min": min, "max": max, "currency": "HKD"]
    }

    var body: [String: Any] = [
        "pet_id": petId,
        "pet_species": petSpecies,
        "pet_age": petAge
    ]

    if let breed = petBreed { body["pet_breed"] = breed }
    if let budget = budgetRange { body["budget_range"] = budget }
    if !coveragePreferences.isEmpty { body["coverage_preferences"] = coveragePreferences }
    if let requirements = additionalRequirements { body["additional_requirements"] = requirements }

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.nonHTTPResponse
    }

    guard httpResponse.statusCode == 200 else {
        let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
        throw NetworkError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
    }

    let decoder = JSONDecoder()
    return try decoder.decode(InsuranceRecommendationResponse.self, from: data)
  }

  // Demo recommendation (for testing without backend)
  func getDemoRecommendation() -> InsuranceRecommendationResponse {
    InsuranceRecommendationResponse(
        success: true,
        data: InsuranceRecommendationData(
            recommendations: [
                InsuranceRecommendation(
                    insuranceId: 1,
                    insuranceName: "寵物全方位保障計劃",
                    provider: "Blue Cross",
                    matchScore: 95,
                    coverageSummary: ["意外: HK$50,000", "疾病: HK$30,000", "手術: HK$80,000"],
                    monthlyPremium: "1,280",
                    currency: "HKD",
                    reason: "根據您選擇的保障範圍和預算，這個計劃提供最全面的保障。"
                ),
                InsuranceRecommendation(
                    insuranceId: 2,
                    insuranceName: "基本寵物保險",
                    provider: "One Degree",
                    matchScore: 82,
                    coverageSummary: ["意外: HK$30,000", "疾病: HK$20,000"],
                    monthlyPremium: "680",
                    currency: "HKD",
                    reason: "經濟實惠的選擇，適合基本保障需求。"
                )
            ],
            analysis: "根據您的寵物年齡（3歲）和選擇的保障偏好，我們建議優先考慮包含手術保障的計劃。您的預算範圍內有多個選擇，但全面保障計劃在理賠時更有優勢。"
        )
    )
  }
}

// MARK: - AI Recommendation Models

struct InsuranceRecommendationResponse: Decodable {
    let success: Bool
    let data: InsuranceRecommendationData
}

struct InsuranceRecommendationData: Decodable {
    let recommendations: [InsuranceRecommendation]
    let analysis: String
}

struct InsuranceRecommendation: Identifiable, Decodable {
    let insuranceId: Int
    let insuranceName: String
    let provider: String
    let matchScore: Int
    let coverageSummary: [String]
    let monthlyPremium: String
    let currency: String
    let reason: String

    var id: Int { insuranceId }
}
