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

  // Helper for display
  var formattedPrice: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    return formatter.string(from: price as NSNumber) ?? "\(currencyCode) \(price)"
  }
}

struct ShopCollection: ShopItem {
  let id: String
  let title: String
  let products: [ShopProduct]
}
