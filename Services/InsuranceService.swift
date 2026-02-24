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

  private func fetchCompanies() async throws -> [InsuranceCompany] {
    guard let url = URL(string: "\(baseURL)/insurance-companies") else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([InsuranceCompany].self, from: data)
  }

  private func fetchProducts() async throws -> [InsuranceProduct] {
    guard let url = URL(string: "\(baseURL)/insurance-products") else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([InsuranceProduct].self, from: data)
  }

  private func fetchCoverageItems() async throws -> [CoverageItem] {
    guard let url = URL(string: "\(baseURL)/coverage-list") else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([CoverageItem].self, from: data)
  }

  private func fetchCoverageLimits() async throws -> [CoverageLimit] {
    guard let url = URL(string: "\(baseURL)/coverage-limits") else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([CoverageLimit].self, from: data)
  }

  private func fetchSubCoverageLimits() async throws -> [SubCoverageLimit] {
    guard let url = URL(string: "\(baseURL)/sub-coverage-limits") else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([SubCoverageLimit].self, from: data)
  }

  // MARK: - Legacy API Methods

  private func fetchProviders() async throws -> [InsuranceProvider] {
    guard let url = URL(string: "\(baseURL)/insurance-providers") else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([InsuranceProvider].self, from: data)
  }

  private func fetchServiceSubcategories() async throws -> [ServiceSubcategory] {
    guard let url = URL(string: "\(baseURL)/service-subcategories") else {
      throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([ServiceSubcategory].self, from: data)
  }
}
