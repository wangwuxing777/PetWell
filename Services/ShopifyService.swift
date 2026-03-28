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
  private let apiBaseURL = "https://pawrd-backend.zeabur.app"

  // Shopify domain for checkout permalinks (safe to keep - public info)
  private let shopDomain = "petwell-8.myshopify.com"

  @Published var products: [ShopProduct] = []
  @Published var filteredProducts: [ShopProduct] = []
  @Published var availableCategories: [String] = []
  @Published var availableBrands: [String] = []
  @Published var isLoading: Bool = false
  @Published var isLoadingCategories: Bool = false
  @Published var cartItems: [CartItem] = []
  @Published var checkoutErrorMessage: String?
  @Published private(set) var activeFilterCriteria = FilterCriteria()

  struct FilterCriteria {
    var category: String? = nil  // "All", "For my pet", or specific "Toy", etc.
    var brand: String? = nil
    var minPrice: Double? = nil
    var maxPrice: Double? = nil
    var pet: PetModel? = nil  // For "For my pet" logic
  }

  struct PaymentSheetSessionConfiguration {
    let paymentIntentClientSecret: String
    let publishableKey: String
    let merchantDisplayName: String
    let amount: Int
    let currency: String
  }

  private init() {
    // No SDK client setup needed - using backend API
  }

  private var searchResults: [ShopProduct]?

  var cartItemCount: Int {
    cartItems.reduce(0) { $0 + $1.quantity }
  }

  var cartSubtotal: Decimal {
    cartItems.reduce(Decimal.zero) { partial, item in
      partial + item.lineTotal
    }
  }

  var maxFilterPrice: Double {
    let prices = products.map { NSDecimalNumber(decimal: $0.price).doubleValue }
    return max(prices.max() ?? 0, 2000)
  }

  // MARK: - Backend API Methods

  /// Fetches products from the Go backend proxy instead of directly calling Shopify
  func fetchProducts() {
    isLoading = true

    guard let url = URL(string: "\(apiBaseURL)/api/shop/products?limit=100") else {
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
          self.extractFilterOptions()
          self.recomputeFilteredProducts()
          self.fetchCategories()
        } catch {
          print("JSON Decoding Error: \(error)")
          self.checkoutErrorMessage = "Failed to parse products"
        }
      }
    }
    task.resume()
  }

  func fetchProductDetail(handle: String, completion: @escaping (Result<ShopProductDetail, Error>) -> Void) {
    guard let encodedHandle = handle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "\(apiBaseURL)/api/shop/products/\(encodedHandle)") else {
      completion(.failure(NSError(domain: "ShopifyService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid product URL"])))
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    URLSession.shared.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(error))
          return
        }

        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
          let error = NSError(
            domain: "ShopifyService",
            code: httpResponse.statusCode,
            userInfo: [NSLocalizedDescriptionKey: "Failed to load product detail"]
          )
          completion(.failure(error))
          return
        }

        guard let data else {
          completion(.failure(NSError(domain: "ShopifyService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No product detail received"])))
          return
        }

        do {
          let detail = try JSONDecoder().decode(BackendProductDetail.self, from: data)
          completion(.success(detail.toShopProductDetail()))
        } catch {
          print("Product Detail Decoding Error: \(error)")
          completion(.failure(error))
        }
      }
    }.resume()
  }

  func createPaymentSheetSession(
    for cartItems: [CartItem],
    customer: OwnerProfile,
    completion: @escaping (Result<PaymentSheetSessionConfiguration, Error>) -> Void
  ) {
    let lineItems = cartItems.map {
      BackendCheckoutLineItem(handle: $0.product.handle, variantId: $0.product.variantId, quantity: $0.quantity)
    }

    createPaymentSheetSession(lineItems: lineItems, customer: customer, completion: completion)
  }

  func createPaymentSheetSession(
    for product: ShopProduct,
    quantity: Int,
    customer: OwnerProfile,
    completion: @escaping (Result<PaymentSheetSessionConfiguration, Error>) -> Void
  ) {
    let lineItems = [BackendCheckoutLineItem(handle: product.handle, variantId: product.variantId, quantity: quantity)]
    createPaymentSheetSession(lineItems: lineItems, customer: customer, completion: completion)
  }

  private func createPaymentSheetSession(
    lineItems: [BackendCheckoutLineItem],
    customer: OwnerProfile,
    completion: @escaping (Result<PaymentSheetSessionConfiguration, Error>) -> Void
  ) {
    checkoutErrorMessage = nil

    guard !lineItems.isEmpty else {
      let error = CheckoutRequestError(message: "Cart is empty.")
      checkoutErrorMessage = error.message
      completion(.failure(error))
      return
    }

    guard let url = URL(string: "\(apiBaseURL)/api/shop/checkout/payment-sheet") else {
      let error = CheckoutRequestError(message: "Invalid checkout API URL")
      checkoutErrorMessage = error.message
      completion(.failure(error))
      return
    }

    let payload = BackendPaymentSheetRequest(
      lineItems: lineItems,
      customer: BackendCheckoutCustomer(
        name: customer.name,
        email: customer.email,
        phone: customer.phone
      )
    )

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    do {
      request.httpBody = try JSONEncoder().encode(payload)
    } catch {
      let requestError = CheckoutRequestError(message: "Failed to encode checkout payload")
      checkoutErrorMessage = requestError.message
      completion(.failure(requestError))
      return
    }

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      DispatchQueue.main.async {
        guard let self else { return }

        if let error {
          self.checkoutErrorMessage = error.localizedDescription
          completion(.failure(error))
          return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
          let responseError = CheckoutRequestError(message: "No checkout response received")
          self.checkoutErrorMessage = responseError.message
          completion(.failure(responseError))
          return
        }

        guard let data else {
          let responseError = CheckoutRequestError(message: "No checkout response received")
          self.checkoutErrorMessage = responseError.message
          completion(.failure(responseError))
          return
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
          let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
          let backendError = CheckoutRequestError(message: message?.isEmpty == false ? message! : "Checkout is unavailable right now")
          self.checkoutErrorMessage = backendError.message
          completion(.failure(backendError))
          return
        }

        do {
          let response = try JSONDecoder().decode(BackendPaymentSheetResponse.self, from: data)
          let session = PaymentSheetSessionConfiguration(
            paymentIntentClientSecret: response.paymentIntentClientSecret,
            publishableKey: response.publishableKey,
            merchantDisplayName: response.merchantDisplayName,
            amount: response.amount,
            currency: response.currency
          )
          completion(.success(session))
        } catch {
          self.checkoutErrorMessage = "Failed to parse checkout session"
          completion(.failure(error))
        }
      }
    }.resume()
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
    let categories: [String]?
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
        categories: categories ?? (productType.isEmpty ? [] : [productType]),
        vendor: vendor,
        handle: handle,
        variantId: variantId
      )
    }
  }

  struct BackendMoney: Codable {
    let amount: String
    let currencyCode: String
  }

  struct BackendPriceRange: Codable {
    let minVariantPrice: BackendMoney
    let maxVariantPrice: BackendMoney
  }

  struct BackendProductImage: Codable {
    let id: String
    let url: String
    let altText: String?
    let width: Int?
    let height: Int?

    func toShopProductImage() -> ShopProductImage {
      let parsedURL = url.isEmpty ? nil : URL(string: url)
      return ShopProductImage(
        id: id,
        url: parsedURL,
        altText: altText,
        width: width,
        height: height
      )
    }
  }

  struct BackendProductOption: Codable {
    let id: String
    let name: String
    let values: [String]

    func toShopProductOption() -> ShopProductOption {
      ShopProductOption(id: id, name: name, values: values)
    }
  }

  struct BackendSelectedOption: Codable {
    let name: String
    let value: String

    func toShopSelectedOption() -> ShopSelectedOption {
      ShopSelectedOption(name: name, value: value)
    }
  }

  struct BackendProductVariant: Codable {
    let id: String
    let title: String
    let sku: String
    let price: BackendMoney
    let compareAtPrice: BackendMoney?
    let image: BackendProductImage?
    let selectedOptions: [BackendSelectedOption]?
    let availableForSale: Bool

    func toShopProductVariant() -> ShopProductVariant {
      ShopProductVariant(
        id: id,
        title: title,
        sku: sku,
        price: Decimal(string: price.amount) ?? .zero,
        currencyCode: price.currencyCode,
        compareAtPrice: compareAtPrice.flatMap { Decimal(string: $0.amount) },
        imageURL: image?.toShopProductImage().url,
        selectedOptions: (selectedOptions ?? []).map { $0.toShopSelectedOption() },
        availableForSale: availableForSale
      )
    }
  }

  struct BackendProductDetail: Codable {
    let id: String
    let title: String
    let description: String
    let handle: String
    let productType: String
    let vendor: String
    let tags: [String]
    let priceRange: BackendPriceRange
    let images: [BackendProductImage]
    let options: [BackendProductOption]?
    let variants: [BackendProductVariant]

    func toShopProductDetail() -> ShopProductDetail {
      ShopProductDetail(
        id: id,
        title: title,
        description: description,
        handle: handle,
        productType: productType,
        vendor: vendor,
        tags: tags,
        minPrice: Decimal(string: priceRange.minVariantPrice.amount) ?? .zero,
        maxPrice: Decimal(string: priceRange.maxVariantPrice.amount) ?? .zero,
        currencyCode: priceRange.minVariantPrice.currencyCode,
        images: images.map { $0.toShopProductImage() },
        options: (options ?? []).map { $0.toShopProductOption() },
        variants: variants.map { $0.toShopProductVariant() }
      )
    }
  }

  struct BackendCheckoutLineItem: Codable {
    let handle: String
    let variantId: String?
    let quantity: Int
  }

  struct BackendCheckoutCustomer: Codable {
    let name: String
    let email: String
    let phone: String
  }

  struct BackendPaymentSheetRequest: Codable {
    let lineItems: [BackendCheckoutLineItem]
    let customer: BackendCheckoutCustomer
  }

  struct BackendPaymentSheetResponse: Codable {
    let paymentIntentClientSecret: String
    let publishableKey: String
    let merchantDisplayName: String
    let amount: Int
    let currency: String
  }

  struct CheckoutRequestError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
  }

  func fetchCategories() {
    guard let url = URL(string: "\(apiBaseURL)/api/shop/categories") else { return }

    isLoadingCategories = true

    URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
      DispatchQueue.main.async {
        guard let self else { return }
        self.isLoadingCategories = false

        guard error == nil,
              let data,
              let categories = try? JSONDecoder().decode([String].self, from: data) else {
          return
        }

        let localCategories = Set(
          self.products.flatMap { product in
            product.categories.isEmpty ? [product.productType].filter { !$0.isEmpty } : product.categories
          }
        )
        self.availableCategories = Array(Set(categories).union(localCategories)).sorted()
      }
    }.resume()
  }


  private func extractFilterOptions() {
    let categories = Set(
      products.flatMap { product in
        product.categories.isEmpty ? [product.productType].filter { !$0.isEmpty } : product.categories
      }
    ).filter { !$0.isEmpty }
    let brands = Set(products.map { $0.vendor }).filter { !$0.isEmpty }

    self.availableCategories = Array(Set(availableCategories).union(categories)).sorted()
    self.availableBrands = Array(brands).sorted()
  }

  // MARK: - Search

  /// Searches products via the Go backend's /api/shop/search?q=... endpoint.
  /// Updates filteredProducts with results. Pass empty string to reset.
  func search(query: String) {
    let trimmed = query.trimmingCharacters(in: .whitespaces)

    if trimmed.isEmpty {
      searchResults = nil
      recomputeFilteredProducts()
      return
    }

    guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: "\(apiBaseURL)/api/shop/search?q=\(encoded)") else { return }

    isLoading = true
    URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
      DispatchQueue.main.async {
        guard let self = self else { return }
        self.isLoading = false
        guard let data = data, error == nil,
              let backendProducts = try? JSONDecoder().decode([BackendProduct].self, from: data) else { return }
        self.searchResults = backendProducts.map { $0.toShopProduct() }
        self.recomputeFilteredProducts()
      }
    }.resume()
  }

  func applyFilter(_ criteria: FilterCriteria) {
    activeFilterCriteria = criteria
    recomputeFilteredProducts()
  }

  func resetFilters() {
    activeFilterCriteria = FilterCriteria()
    recomputeFilteredProducts()
  }

  private func recomputeFilteredProducts() {
    let sourceProducts = searchResults ?? products
    filteredProducts = filterProducts(sourceProducts, using: activeFilterCriteria)
  }

  private func filterProducts(_ sourceProducts: [ShopProduct], using criteria: FilterCriteria) -> [ShopProduct] {
    var result = sourceProducts

    // 1. Category Filter
    if let category = criteria.category {
      if category == "For my pet", let pet = criteria.pet {
        // AI Logic: match species or breed in title/description/type
        let keywords = [pet.species, pet.breed].filter { !$0.isEmpty }
        result = result.filter { product in
          let categoryText = product.categories.joined(separator: " ")
          let text = "\(product.title) \(product.description) \(product.productType) \(categoryText)".lowercased()
          return keywords.contains { text.contains($0.lowercased()) }
        }
      } else if category != "All" && category != "For my pet" {
        result = result.filter { product in
          product.productType == category || product.categories.contains(category)
        }
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

    return result
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
        categories: ["Food", "Dogs"],
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
        categories: ["Toy", "Cats"],
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

    if let index = cartItems.firstIndex(where: { $0.product.cartKey == product.cartKey }) {
      cartItems[index].quantity += quantity
    } else {
      cartItems.append(CartItem(product: product, quantity: quantity))
    }
  }

  func updateCartQuantity(itemId: String, quantity: Int) {
    guard let index = cartItems.firstIndex(where: { $0.id == itemId }) else { return }

    if quantity <= 0 {
      cartItems.remove(at: index)
    } else {
      cartItems[index].quantity = quantity
    }
  }

  func removeFromCart(itemId: String) {
    cartItems.removeAll { $0.id == itemId }
  }

  func clearCart() {
    cartItems.removeAll()
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
