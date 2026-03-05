//
//  ShopifyService.swift
//  PetWell
//
//  Created for Shopify Integration.
//

import Combine
import Foundation

class ShopifyService: ObservableObject {
  static let shared = ShopifyService()

  // MARK: - Configuration
  // Backend API base URL - all Shopify requests go through our Go backend
  private let apiBaseURL = "http://localhost:8000"

  // Shopify domain for checkout permalinks (safe to keep - public info)
  private let shopDomain = "petwell-8.myshopify.com"

  @Published var products: [ShopProduct] = []
  @Published var filteredProducts: [ShopProduct] = []
  @Published var availableCategories: [String] = []
  @Published var availableBrands: [String] = []
  @Published var isLoading: Bool = false
  @Published var cartItems: [CartItem] = []
  @Published var checkoutErrorMessage: String?

  struct FilterCriteria {
    var category: String? = nil  // "All", "For my pet", or specific "Toy", etc.
    var brand: String? = nil
    var minPrice: Double? = nil
    var maxPrice: Double? = nil
    var pet: PetModel? = nil  // For "For my pet" logic
  }

  private init() {
    // No SDK client setup needed - using backend API
  }

  var cartItemCount: Int {
    cartItems.reduce(0) { $0 + $1.quantity }
  }

  var cartSubtotal: Decimal {
    cartItems.reduce(Decimal.zero) { partial, item in
      partial + item.lineTotal
    }
  }

  // MARK: - Backend API Methods

  /// Fetches products from the Go backend proxy instead of directly calling Shopify
  func fetchProducts() {
    isLoading = true

    guard let url = URL(string: "\(apiBaseURL)/api/shop/products") else {
      DispatchQueue.main.async {
        self.isLoading = false
        self.checkoutErrorMessage = "Invalid API URL"
      }
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }

      DispatchQueue.main.async {
        self.isLoading = false

        if let error = error {
          print("Backend API Error: \(error)")
          self.checkoutErrorMessage = "Failed to load products"
          return
        }

        guard let data = data else {
          self.checkoutErrorMessage = "No data received"
          return
        }

        do {
          let backendProducts = try JSONDecoder().decode([BackendProduct].self, from: data)
          let shopProducts = backendProducts.map { $0.toShopProduct() }
          self.products = shopProducts
          self.filteredProducts = shopProducts
          self.extractFilterOptions()
        } catch {
          print("JSON Decoding Error: \(error)")
          self.checkoutErrorMessage = "Failed to parse products"
        }
      }
    }
    task.resume()
  }

  // MARK: - Backend Response Models

  /// Model matching the Go backend JSON response
  struct BackendProduct: Codable {
    let id: String
    let title: String
    let description: String
    let price: String
    let currencyCode: String
    let imageUrl: String?
    let productType: String
    let vendor: String
    let handle: String
    let variantId: String?

    func toShopProduct() -> ShopProduct {
      let decimalPrice = Decimal(string: price) ?? Decimal(0)
      let url = imageUrl.flatMap { URL(string: $0) }

      return ShopProduct(
        id: id,
        title: title,
        description: description,
        price: decimalPrice,
        currencyCode: currencyCode,
        imageUrl: url,
        productType: productType,
        vendor: vendor,
        handle: handle,
        variantId: variantId
      )
    }
  }


  private func extractFilterOptions() {
    let categories = Set(products.map { $0.productType }).filter { !$0.isEmpty }
    let brands = Set(products.map { $0.vendor }).filter { !$0.isEmpty }

    self.availableCategories = Array(categories).sorted()
    self.availableBrands = Array(brands).sorted()
  }

  func applyFilter(_ criteria: FilterCriteria) {
    var result = products

    // 1. Category Filter
    if let category = criteria.category {
      if category == "For my pet", let pet = criteria.pet {
        // AI Logic: match species or breed in title/description/type
        let keywords = [pet.species, pet.breed].filter { !$0.isEmpty }
        result = result.filter { product in
          let text = "\(product.title) \(product.description) \(product.productType)".lowercased()
          return keywords.contains { text.contains($0.lowercased()) }
        }
      } else if category != "All" && category != "For my pet" {
        result = result.filter { $0.productType == category }
      }
    }

    // 2. Brand Filter
    if let brand = criteria.brand {
      result = result.filter { $0.vendor == brand }
    }

    // 3. Price Filter
    if let min = criteria.minPrice {
      result = result.filter { NSDecimalNumber(decimal: $0.price).doubleValue >= min }
    }
    if let max = criteria.maxPrice {
      result = result.filter { NSDecimalNumber(decimal: $0.price).doubleValue <= max }
    }

    self.filteredProducts = result
  }

  private func loadMockData() {
    let mockProducts = [
      ShopProduct(
        id: "1",
        title: "Premium Dog Food",
        description: "High quality nutrition for your best friend.",
        price: 450.00,
        currencyCode: "HKD",
        imageUrl: nil,
        productType: "Food",
        vendor: "Brand A",
        handle: "premium-dog-food",
        variantId: "1"
      ),
      ShopProduct(
        id: "2",
        title: "Cat Scratch Post",
        description: "Save your furniture.",
        price: 120.00,
        currencyCode: "HKD",
        imageUrl: nil,
        productType: "Toy",
        vendor: "Brand B",
        handle: "cat-scratch-post",
        variantId: "2"
      ),
    ]
    self.products = mockProducts
    self.filteredProducts = mockProducts
    self.extractFilterOptions()
  }

  // MARK: - Cart

  func addToCart(product: ShopProduct, quantity: Int = 1) {
    guard quantity > 0 else { return }

    if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
      cartItems[index].quantity += quantity
    } else {
      cartItems.append(CartItem(product: product, quantity: quantity))
    }
  }

  func updateCartQuantity(productId: String, quantity: Int) {
    guard let index = cartItems.firstIndex(where: { $0.product.id == productId }) else { return }

    if quantity <= 0 {
      cartItems.remove(at: index)
    } else {
      cartItems[index].quantity = quantity
    }
  }

  func removeFromCart(productId: String) {
    cartItems.removeAll { $0.product.id == productId }
  }

  // Use Shopify cart permalink so checkout is handled by Shopify-native flow.
  func makeCheckoutURL() -> URL? {
    checkoutErrorMessage = nil

    guard !cartItems.isEmpty else {
      checkoutErrorMessage = "Cart is empty."
      return nil
    }

    let lineItems = cartItems.compactMap { item -> String? in
      guard let variantId = item.product.checkoutVariantNumericId else { return nil }
      return "\(variantId):\(item.quantity)"
    }

    guard lineItems.count == cartItems.count else {
      checkoutErrorMessage = "Some products cannot be checked out yet (missing Shopify variant ID)."
      return nil
    }

    return makeCheckoutURL(withLineItems: lineItems)
  }

  func makeCheckoutURL(for product: ShopProduct, quantity: Int = 1) -> URL? {
    checkoutErrorMessage = nil

    guard quantity > 0 else {
      checkoutErrorMessage = "Invalid quantity."
      return nil
    }

    guard let variantId = product.checkoutVariantNumericId else {
      checkoutErrorMessage = "This product cannot be checked out yet (missing Shopify variant ID)."
      return nil
    }

    return makeCheckoutURL(withLineItems: ["\(variantId):\(quantity)"])
  }

  private func makeCheckoutURL(withLineItems lineItems: [String]) -> URL? {
    guard !lineItems.isEmpty else {
      checkoutErrorMessage = "Cart is empty."
      return nil
    }

    let permalink = "https://\(shopDomain)/cart/\(lineItems.joined(separator: ","))"
    return URL(string: permalink)
  }
}
