//
//  ShopView.swift
//  PetWell
//
//  Created for Shopify Integration.
//

import SafariServices
import SwiftUI

struct ShopView: View {
  @StateObject private var shopifyService = ShopifyService.shared
  @EnvironmentObject var languageManager: LanguageManager
  @EnvironmentObject var guideManager: GuideManager
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
              guideManager.mark(.shopOpenedFilter)
            }) {
              Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title2)
                .foregroundColor(.black)
            }

            NavigationLink(destination: CartView()) {
              ZStack(alignment: .topTrailing) {
                Image(systemName: "cart")
                  .font(.title2)
                  .foregroundColor(.black)

                if shopifyService.cartItemCount > 0 {
                  Text("\(min(shopifyService.cartItemCount, 99))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
                }
              }
            }
          }
        }
        .padding(.horizontal)
        .padding(.top, 10)  // Adjustment for status bar if needed, or rely on safe area

        if guideManager.currentStep?.tab == .shop {
          HStack(spacing: 8) {
            Image(systemName: "sparkles")
              .foregroundColor(.blue)
            Text("Tip: Open Filter and select \"For my pet\" for personalized picks.")
              .font(.caption)
              .foregroundColor(.secondary)
            Spacer()
          }
          .padding(.horizontal)
          .padding(.bottom, 8)
        }

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

  // Fixed card dimensions for uniform grid
  private let cardWidth: CGFloat = 170
  private let cardHeight: CGFloat = 260
  private let imageHeight: CGFloat = 170
  private let textAreaHeight: CGFloat = 90

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Product Image - Fixed size container
      ZStack {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.1))

        if let url = product.imageUrl {
          AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
              ProgressView()
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            case .failure:
              Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            @unknown default:
              EmptyView()
            }
          }
        } else {
          Image(systemName: "photo")
            .font(.system(size: 40))
            .foregroundColor(.gray)
        }
      }
      .frame(width: cardWidth, height: imageHeight)
      .clipped()
      .cornerRadius(12)

      // Text Content - Fixed size area
      VStack(alignment: .leading, spacing: 4) {
        Text(product.title)
          .font(.system(size: 13, weight: .semibold))
          .lineLimit(2)
          .frame(height: 34, alignment: .topLeading)

        Text(product.vendor)
          .font(.caption2)
          .foregroundColor(.secondary)
          .lineLimit(1)
          .frame(height: 14, alignment: .topLeading)

        Text(product.formattedPrice)
          .font(.subheadline)
          .bold()
          .foregroundColor(Color(hex: "2563EB"))
          .frame(height: 20, alignment: .topLeading)
      }
      .frame(width: cardWidth - 16, height: textAreaHeight - 12)
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
    }
    .frame(width: cardWidth, height: cardHeight)
    .background(Color.white.opacity(0.95))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(Color(hex: "E2E8F0"), lineWidth: 1)
    )
    .cornerRadius(14)
    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
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

// MARK: - Cart View

struct CartView: View {
  @ObservedObject private var shopifyService = ShopifyService.shared
  @EnvironmentObject var languageManager: LanguageManager

  @State private var checkoutSession: CheckoutSession?
  @State private var alertMessage: String?
  @State private var showOwnerProfileEditor = false

  var body: some View {
    VStack(spacing: 0) {
      if shopifyService.cartItems.isEmpty {
        VStack(spacing: 16) {
          Image(systemName: "cart.badge.questionmark")
            .font(.system(size: 44, weight: .semibold))
            .foregroundColor(Color(hex: "4F46E5"))

          Text(languageManager.isChinese ? "你的購物車還是空的" : "Your cart is empty")
            .font(.headline)

          Text(
            languageManager.isChinese
              ? "回到商店挑選你想要的商品，隨時都可以再回來結帳。"
              : "Browse products and add what you need, then come back to checkout."
          )
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          VStack(spacing: 14) {
            ForEach(shopifyService.cartItems) { item in
              cartRow(item: item)
            }
          }
          .padding()
        }
      }
    }
    .background(
      LinearGradient(
        colors: [Color(hex: "EEF2FF"), Color(hex: "F8FAFC"), Color.white],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    )
    .navigationTitle(languageManager.isChinese ? "購物車" : "Cart")
    .navigationBarTitleDisplayMode(.inline)
    .safeAreaInset(edge: .bottom) {
      if !shopifyService.cartItems.isEmpty {
        checkoutBar
      }
    }
    .alert(
      languageManager.isChinese ? "結帳失敗" : "Checkout Failed",
      isPresented: Binding(
        get: { alertMessage != nil },
        set: { if !$0 { alertMessage = nil } }
      )
    ) {
      Button(languageManager.isChinese ? "知道了" : "OK", role: .cancel) {}
    } message: {
      Text(alertMessage ?? "")
    }
    .sheet(item: $checkoutSession) { session in
      ShopCheckoutContainer(
        url: session.url,
        title: languageManager.isChinese ? "安全結帳" : "Secure Checkout"
      )
      .ignoresSafeArea()
    }
    .sheet(isPresented: $showOwnerProfileEditor) {
      OwnerProfileEditorSheet(isMandatory: true) { _ in }
    }
  }

  private var checkoutBar: some View {
    VStack(spacing: 10) {
      HStack {
        Text(languageManager.isChinese ? "商品 \(shopifyService.cartItemCount) 件" : "\(shopifyService.cartItemCount) items")
          .font(.subheadline)
          .foregroundColor(.secondary)
        Spacer()
        Text(languageManager.isChinese ? "小計" : "Subtotal")
          .font(.subheadline)
          .foregroundColor(.secondary)
        Text(formatCurrency(shopifyService.cartSubtotal))
          .font(.headline)
      }

      Button(action: startCheckout) {
        HStack(spacing: 8) {
          Image(systemName: "lock.shield.fill")
          Text(languageManager.isChinese ? "在 App 內安全結帳" : "Checkout In App")
        }
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(
            LinearGradient(
              colors: [Color(hex: "4F46E5"), Color(hex: "2563EB")],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .cornerRadius(12)
      }
    }
    .padding()
    .background(Color.white.shadow(color: .black.opacity(0.06), radius: 8, y: -2))
  }

  private func cartRow(item: CartItem) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 12) {
        if let url = item.product.imageUrl {
          AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
              RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
                .overlay(ProgressView())
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            case .failure:
              RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
                .overlay(Image(systemName: "photo").foregroundColor(.gray))
            @unknown default:
              EmptyView()
            }
          }
          .frame(width: 72, height: 72)
          .clipped()
          .cornerRadius(10)
        } else {
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.1))
            .frame(width: 72, height: 72)
            .overlay(Image(systemName: "photo").foregroundColor(.gray))
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(item.product.title)
            .font(.system(size: 15, weight: .semibold))
            .fontWeight(.semibold)
            .lineLimit(2)

          Text(item.product.vendor)
            .font(.caption)
            .foregroundColor(.secondary)

          Text(item.product.formattedPrice)
            .font(.subheadline)
            .foregroundColor(Color(hex: "2563EB"))
        }

        Spacer()

        Button(action: { shopifyService.removeFromCart(productId: item.product.id) }) {
          Image(systemName: "trash")
            .foregroundColor(.red.opacity(0.85))
        }
      }

      HStack {
        quantityControl(item: item)

        Spacer()

        Text(formatCurrency(item.lineTotal))
          .font(.system(size: 16, weight: .bold))
          .fontWeight(.semibold)
      }
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.95))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color(hex: "E2E8F0"), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
  }

  private func quantityControl(item: CartItem) -> some View {
    HStack(spacing: 14) {
      Button(action: {
        shopifyService.updateCartQuantity(productId: item.product.id, quantity: item.quantity - 1)
      }) {
        Image(systemName: "minus")
          .font(.system(size: 12, weight: .bold))
          .frame(width: 24, height: 24)
          .background(Color.white)
          .clipShape(Circle())
      }

      Text("\(item.quantity)")
        .font(.subheadline)
        .fontWeight(.medium)
        .frame(minWidth: 20)

      Button(action: {
        shopifyService.updateCartQuantity(productId: item.product.id, quantity: item.quantity + 1)
      }) {
        Image(systemName: "plus")
          .font(.system(size: 12, weight: .bold))
          .frame(width: 24, height: 24)
          .background(Color.white)
          .clipShape(Circle())
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color(hex: "E0E7FF"))
    .foregroundColor(Color(hex: "1D4ED8"))
    .cornerRadius(999)
  }

  private func startCheckout() {
    guard OwnerProfileStore.shared.hasRequiredContact() else {
      showOwnerProfileEditor = true
      return
    }
    if let checkoutURL = shopifyService.makeCheckoutURL() {
      checkoutSession = CheckoutSession(url: checkoutURL)
    } else {
      let fallback = languageManager.isChinese ? "目前無法建立結帳連結。" : "Unable to create checkout link."
      alertMessage = shopifyService.checkoutErrorMessage ?? fallback
    }
  }

  private func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = shopifyService.cartItems.first?.product.currencyCode ?? "HKD"
    return formatter.string(from: amount as NSNumber) ?? "\(amount)"
  }
}

private struct CheckoutSession: Identifiable {
  let id = UUID()
  let url: URL
}

struct ShopCheckoutContainer: View {
  @Environment(\.dismiss) private var dismiss
  let url: URL
  let title: String

  var body: some View {
    NavigationStack {
      InAppSafariView(url: url)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
              dismiss()
            }
          }
        }
    }
  }
}

struct InAppSafariView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let vc = SFSafariViewController(url: url)
    vc.dismissButtonStyle = .close
    vc.preferredControlTintColor = UIColor(Color(hex: "2563EB"))
    return vc
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
