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

struct ShopProduct: ShopItem {
  let id: String
  let title: String
  let description: String
  let price: Decimal
  let currencyCode: String
  let imageUrl: URL?
  let productType: String
  let vendor: String
  let handle: String  // For deep linking or web view
  let variantId: String?

  // Helper for display
  var formattedPrice: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    return formatter.string(from: price as NSNumber) ?? "\(currencyCode) \(price)"
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

struct ShopCollection: ShopItem {
  let id: String
  let title: String
  let products: [ShopProduct]
}

struct CartItem: Identifiable {
  let product: ShopProduct
  var quantity: Int

  var id: String { product.id }

  var lineTotal: Decimal {
    NSDecimalNumber(decimal: product.price)
      .multiplying(by: NSDecimalNumber(value: quantity))
      .decimalValue
  }
}
