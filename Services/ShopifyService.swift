//
//  ShopifyService.swift
//  PetWell
//
//  Created for Shopify Integration.
//

// UNCOMMENT these lines after adding the 'Mobile Buy SDK' via Swift Package Manager
import Buy
import Combine
import Foundation

class ShopifyService: ObservableObject {
  static let shared = ShopifyService()

  // MARK: - Configuration
  // Replace these with your actual keys from Shopify Admin
  private let shopDomain = "petwell-8.myshopify.com"
  private let storefrontAccessToken = "6697b5a808943c68b44b058817d16326"

  private var client: Graph.Client?  // Uncomment after SDK install

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
    setupClient()
  }

  var cartItemCount: Int {
    cartItems.reduce(0) { $0 + $1.quantity }
  }

  var cartSubtotal: Decimal {
    cartItems.reduce(Decimal.zero) { partial, item in
      partial + item.lineTotal
    }
  }

  func setupClient() {
    // UNCOMMENT after SDK install
    client = Graph.Client(
      shopDomain: shopDomain,
      apiKey: storefrontAccessToken
    )

    // Mock data removed in favor of real API loading state
    // loadMockData()
  }

  func fetchProducts() {
    isLoading = true

    // defined query: request first 30 products, sorted by newest
    let query = Storefront.buildQuery {
      $0
        .products(first: 30, reverse: true, sortKey: .createdAt) {
          $0
            .edges {
              $0
                .node {
                  $0
                    .id()
                    .title()
                    .description()
                    .handle()
                    .productType()
                    .vendor()
                    .priceRange {
                      $0
                        .minVariantPrice {
                          $0
                            .amount()
                            .currencyCode()
                        }
                    }
                    .images(first: 1) {
                      $0
                        .edges {
                          $0
                            .node {
                              $0
                                .url()
                            }
                        }
                    }
                    .variants(first: 1) {
                      $0
                        .edges {
                          $0
                            .node {
                              $0
                                .id()
                            }
                        }
                    }
                }
            }
        }
    }

    let task = client?.queryGraphWith(query, cachePolicy: .networkOnly) { response, error in
      if let error = error {
        print("Shopify Fetch Error: \(error)")
        DispatchQueue.main.async {
          self.isLoading = false
        }
        return
      }

      guard let data = response else {
        DispatchQueue.main.async {
          self.isLoading = false
        }
        return
      }

      // Map Shopify models to our simplified ShopModels
      let shopProducts = data.products.edges.map { edge -> ShopProduct in
        let node = edge.node
        let price = node.priceRange.minVariantPrice.amount
        let currency = node.priceRange.minVariantPrice.currencyCode.rawValue
        let imageUrl = node.images.edges.first?.node.url

        return ShopProduct(
          id: node.id.rawValue,
          title: node.title,
          description: node.description,
          price: price,
          currencyCode: currency,
          imageUrl: imageUrl,
          productType: node.productType,
          vendor: node.vendor,
          handle: node.handle,
          variantId: node.variants.edges.first?.node.id.rawValue
        )
      }

      DispatchQueue.main.async {
        self.products = shopProducts
        self.filteredProducts = shopProducts
        self.extractFilterOptions()
        self.isLoading = false
      }
    }
    task?.resume()
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
