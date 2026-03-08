//
//  ShopModels.swift
//  PetWell
//
//  Created for Shopify Integration.
//

import Foundation

// MARK: - internal models
// These will map to the Shopify SDK objects later.

protocol ShopItem: Identifiable {
  var id: String { get }
  var title: String { get }
}

private func formatShopPrice(_ amount: Decimal, currencyCode: String) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .currency
  formatter.currencyCode = currencyCode
  return formatter.string(from: amount as NSNumber) ?? "\(currencyCode) \(amount)"
}

struct ShopProduct: ShopItem {
  let id: String
  let title: String
  let description: String
  let price: Decimal
  let currencyCode: String
  let imageUrl: URL?
  let productType: String
  let categories: [String]
  let vendor: String
  let handle: String  // For deep linking or web view
  let variantId: String?

  // Helper for display
  var formattedPrice: String {
    formatShopPrice(price, currencyCode: currencyCode)
  }

  func updating(price: Decimal? = nil, imageUrl: URL? = nil, variantId: String? = nil) -> ShopProduct {
    ShopProduct(
      id: id,
      title: title,
      description: description,
      price: price ?? self.price,
      currencyCode: currencyCode,
      imageUrl: imageUrl ?? self.imageUrl,
      productType: productType,
      categories: categories,
      vendor: vendor,
      handle: handle,
      variantId: variantId ?? self.variantId
    )
  }

  var cartKey: String {
    "\(id)::\(variantId ?? "default")"
  }

  // Shopify cart permalink needs a numeric variant ID.
  var checkoutVariantNumericId: String? {
    if let variantId, variantId.allSatisfy({ $0.isNumber }) {
      return variantId
    }

    if let variantId, let lastSegment = variantId.split(separator: "/").last {
      let candidate = String(lastSegment)
      if candidate.allSatisfy({ $0.isNumber }) {
        return candidate
      }
    }

    if
      let variantId,
      let data = Data(base64Encoded: variantId),
      let decoded = String(data: data, encoding: .utf8),
      let lastSegment = decoded.split(separator: "/").last
    {
      let candidate = String(lastSegment)
      if candidate.allSatisfy({ $0.isNumber }) {
        return candidate
      }
    }

    return nil
  }
}

struct ShopProductDetail: Identifiable {
  let id: String
  let title: String
  let description: String
  let handle: String
  let productType: String
  let vendor: String
  let tags: [String]
  let minPrice: Decimal
  let maxPrice: Decimal
  let currencyCode: String
  let images: [ShopProductImage]
  let options: [ShopProductOption]
  let variants: [ShopProductVariant]

  var formattedPriceRange: String {
    if minPrice == maxPrice {
      return formatShopPrice(minPrice, currencyCode: currencyCode)
    }

    return "\(formatShopPrice(minPrice, currencyCode: currencyCode)) - \(formatShopPrice(maxPrice, currencyCode: currencyCode))"
  }
}

struct ShopProductImage: Identifiable {
  let id: String
  let url: URL?
  let altText: String?
  let width: Int?
  let height: Int?
}

struct ShopProductOption: Identifiable {
  let id: String
  let name: String
  let values: [String]
}

struct ShopSelectedOption: Identifiable {
  let name: String
  let value: String

  var id: String { "\(name):\(value)" }
}

struct ShopProductVariant: Identifiable {
  let id: String
  let title: String
  let sku: String
  let price: Decimal
  let currencyCode: String
  let compareAtPrice: Decimal?
  let imageURL: URL?
  let selectedOptions: [ShopSelectedOption]
  let availableForSale: Bool

  var formattedPrice: String {
    formatShopPrice(price, currencyCode: currencyCode)
  }

  var formattedCompareAtPrice: String? {
    guard let compareAtPrice else { return nil }
    return formatShopPrice(compareAtPrice, currencyCode: currencyCode)
  }

  var displayName: String {
    let optionText = selectedOptions.map { $0.value }.joined(separator: " / ")
    if !optionText.isEmpty {
      return optionText
    }

    if !title.isEmpty, title != "Default Title" {
      return title
    }

    return "Default"
  }
}

struct ShopCollection: ShopItem {
  let id: String
  let title: String
  let products: [ShopProduct]
}

struct CartItem: Identifiable {
  let product: ShopProduct
  var quantity: Int

  var id: String { product.cartKey }

  var lineTotal: Decimal {
    NSDecimalNumber(decimal: product.price)
      .multiplying(by: NSDecimalNumber(value: quantity))
      .decimalValue
  }
}
