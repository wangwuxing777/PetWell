//
//  ShopView.swift
//  PetWell
//
//  Created for Shopify Integration.
//

import SwiftUI

struct ShopView: View {
  @StateObject private var shopifyService = ShopifyService.shared
  @EnvironmentObject var languageManager: LanguageManager
  @State private var showFilter = false

  let columns = [
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16),
  ]

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Custom Header
        HStack {
          Text(languageManager.isChinese ? "商店" : "Shop")
            .font(.largeTitle)
            .bold()

          Spacer()

          HStack(spacing: 20) {
            Button(action: {
              showFilter = true
            }) {
              Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title2)
                .foregroundColor(.black)
            }

            Button(action: {
              // Cart action
            }) {
              Image(systemName: "cart")
                .font(.title2)
                .foregroundColor(.black)
            }
          }
        }
        .padding(.horizontal)
        .padding(.top, 10)  // Adjustment for status bar if needed, or rely on safe area

        if shopifyService.isLoading {
          VStack {
            Spacer()
            ProgressView("Loading products...")
              .controlSize(.large)
            Spacer()
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            if shopifyService.filteredProducts.isEmpty {
              VStack(spacing: 20) {
                Image(systemName: "magnifyingglass")
                  .font(.system(size: 50))
                  .foregroundColor(.gray)
                Text("No products found")
                  .font(.headline)
                  .foregroundColor(.gray)
              }
              .padding(.top, 50)
              .frame(maxWidth: .infinity)
            } else {
              LazyVGrid(columns: columns, spacing: 16) {
                ForEach(shopifyService.filteredProducts) { product in
                  NavigationLink(destination: ProductDetailView(product: product)) {
                    ProductCard(product: product)
                  }
                  .buttonStyle(PlainButtonStyle())
                }
              }
              .padding()
            }
          }
        }
      }
      .navigationBarHidden(true)
      .sheet(isPresented: $showFilter) {
        ShopFilterView()
      }
    }
    .onAppear {
      shopifyService.fetchProducts()
    }
  }
}

struct ProductCard: View {
  let product: ShopProduct

  var body: some View {
    VStack(alignment: .leading) {
      // Product Image
      if let url = product.imageUrl {
        AsyncImage(url: url) { phase in
          switch phase {
          case .empty:
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.gray.opacity(0.1))
              .aspectRatio(1, contentMode: .fit)
              .overlay(ProgressView())
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              .cornerRadius(12)
          case .failure:
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.gray.opacity(0.1))
              .aspectRatio(1, contentMode: .fit)
              .overlay(
                 Image(systemName: "photo")
                   .font(.largeTitle)
                   .foregroundColor(.gray)
              )
          @unknown default:
            EmptyView()
          }
        }
      } else {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.1))
          .aspectRatio(1, contentMode: .fit)
          .overlay(
            Image(systemName: "photo")
              .font(.largeTitle)
              .foregroundColor(.gray)
          )
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(product.title)
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(2)

        Text(product.formattedPrice)
          .font(.caption)
          .bold()
          .foregroundColor(.blue)
      }
      .padding(.horizontal, 4)
      .padding(.bottom, 8)
    }
    .background(Color.white)
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}

#Preview {
  ShopView()
    .environmentObject(LanguageManager())
}

// MARK: - ShopFilterView

struct ShopFilterView: View {
  @Environment(\.dismiss) var dismiss
  @ObservedObject var shopifyService = ShopifyService.shared

  // Local state to hold selections before applying
  @State private var selectedCategory: String?
  @State private var selectedBrand: String?
  @State private var priceRange: ClosedRange<Double> = 0...2000

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Filter")
          .font(.title2)
          .bold()

        Spacer()

        Button(action: resetFilters) {
          HStack(spacing: 4) {
            Image(systemName: "goforward")
            Text("Reset")
          }
          .font(.subheadline)
          .foregroundColor(.gray)
        }

        Button(action: { dismiss() }) {
          Image(systemName: "xmark")
            .font(.title3)
            .foregroundColor(.black)
            .padding(.leading, 16)
        }
      }
      .padding()

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {

          // Category Section
          VStack(alignment: .leading, spacing: 12) {
            Text("Category")
              .font(.headline)

            ShopFilterChipLayout {
              // "All" Chip
              ShopFilterChip(
                title: "All",
                isSelected: selectedCategory == "" || selectedCategory == "All"
                  || selectedCategory == nil,
                action: { selectedCategory = "All" }
              )

              // "For my pet" Chip (AI Style)
              Button(action: { selectedCategory = "For my pet" }) {
                HStack(spacing: 4) {
                  Image(systemName: "sparkles")  // AI hint
                  Text("For my pet")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                  selectedCategory == "For my pet"
                    ? Color.blue.opacity(0.1)
                    : Color.white
                )
                .foregroundColor(selectedCategory == "For my pet" ? .blue : .black)
                .overlay(
                  RoundedRectangle(cornerRadius: 20)
                    .stroke(
                      LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                      lineWidth: selectedCategory == "For my pet" ? 2 : 1
                    )
                )
                .cornerRadius(20)
              }

              // Dynamic Categories
              ForEach(shopifyService.availableCategories, id: \.self) { category in
                ShopFilterChip(
                  title: category,
                  isSelected: selectedCategory == category,
                  action: { selectedCategory = category }
                )
              }
            }
          }

          // Brand Section
          VStack(alignment: .leading, spacing: 12) {
            Text("Brand")
              .font(.headline)

            ShopFilterChipLayout {
              ForEach(shopifyService.availableBrands, id: \.self) { brand in
                ShopFilterChip(
                  title: brand,
                  isSelected: selectedBrand == brand,
                  action: { selectedBrand = brand }
                )
              }
            }
          }

          // Price Range Section
          VStack(alignment: .leading, spacing: 12) {
            Text("Price Range")
              .font(.headline)

            // Validating range for Slider
            Slider(
              value: Binding(
                get: { priceRange.lowerBound },
                set: { newValue in
                  let newMin = min(newValue, priceRange.upperBound)
                  priceRange = newMin...priceRange.upperBound
                }
              ), in: 0...2000)

            HStack {
              Text("HK$ \(Int(priceRange.lowerBound))")
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

              Spacer()
              Text("-")
              Spacer()

              Text("HK$ \(Int(priceRange.upperBound))")
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .font(.subheadline)
          }
        }
        .padding()
      }

      // Bottom Button
      VStack {
        Button(action: applyFilters) {
          Text("Show Results")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
      }
      .padding()
      .background(Color.white.shadow(radius: 2))
    }
    .onAppear {
      // Load current filter state if needed
    }
  }

  private func resetFilters() {
    selectedCategory = "All"
    selectedBrand = nil
    priceRange = 0...2000
    // Trigger update
  }

  private func applyFilters() {
    // Construct criteria
    // For demo "For my pet", we need a fake pet
    let demoPet = PetModel(
      name: "Buddy",
      species: "Dog",
      breed: "Golden Retriever",
      sex: "Male",
      birthYear: 2020,
      weightKg: 30,
      isNeutered: true,
      microchipId: "123",
      allergies: "",
      notes: ""
    )

    let criteria = ShopifyService.FilterCriteria(
      category: selectedCategory == "All" ? nil : selectedCategory,
      brand: selectedBrand,
      minPrice: priceRange.lowerBound,
      maxPrice: priceRange.upperBound,
      pet: selectedCategory == "For my pet" ? demoPet : nil
    )

    shopifyService.applyFilter(criteria)
    dismiss()
  }
}

// MARK: - Helper Views

struct ShopFilterChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline)
        .fontWeight(.medium)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
        .foregroundColor(isSelected ? .white : .black)
        .cornerRadius(20)
    }
  }
}

// Simple Flow Layout for Chips
struct ShopFilterChipLayout: Layout {
  var spacing: CGFloat = 10

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = flowLayout(proposal: proposal, subviews: subviews)
    return result.size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let result = flowLayout(proposal: proposal, subviews: subviews)
    for (index, subview) in subviews.enumerated() {
      let point = result.points[index]
      subview.place(
        at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
    }
  }

  struct LayoutResult {
    var size: CGSize
    var points: [CGPoint]
  }

  func flowLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
    let maxWidth = proposal.width ?? .infinity
    var x: CGFloat = 0
    var y: CGFloat = 0
    var maxHeightInRow: CGFloat = 0
    var points: [CGPoint] = []

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)

      if x + size.width > maxWidth && x > 0 {
        // New row
        x = 0
        y += maxHeightInRow + spacing
        maxHeightInRow = 0
      }

      points.append(CGPoint(x: x, y: y))

      x += size.width + spacing
      maxHeightInRow = max(maxHeightInRow, size.height)
    }

    return LayoutResult(size: CGSize(width: maxWidth, height: y + maxHeightInRow), points: points)
  }
}
