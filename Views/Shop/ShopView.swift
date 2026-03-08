//
//  ShopView.swift
//  PetWell
//
//  Created for Shopify Integration.
//

import StripePaymentSheet
import SwiftUI

struct ShopView: View {
  @StateObject private var shopifyService = ShopifyService.shared
  @EnvironmentObject var languageManager: LanguageManager
  @EnvironmentObject var guideManager: GuideManager
  @State private var showFilter = false
  @State private var searchText = ""

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
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
                .foregroundColor(AppTheme.textPrimary)
            }

            NavigationLink(destination: CartView()) {
              ZStack(alignment: .topTrailing) {
                Image(systemName: "cart")
                  .font(.title2)
                  .foregroundColor(AppTheme.textPrimary)

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
        .padding(.top, 10)

        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.gray)
          TextField(languageManager.isChinese ? "搜尋商品..." : "Search products...", text: $searchText)
            .autocorrectionDisabled()
            .onChange(of: searchText) { _, newValue in
              shopifyService.search(query: newValue)
            }
          if !searchText.isEmpty {
            Button { searchText = "" } label: {
              Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
            }
          }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom, 8)

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
              let productColumns = waterfallColumns(for: shopifyService.filteredProducts)

              HStack(alignment: .top, spacing: 12) {
                ForEach(Array(productColumns.enumerated()), id: \.offset) { _, columnProducts in
                  LazyVStack(spacing: 12) {
                    ForEach(columnProducts) { product in
                      NavigationLink(destination: ProductDetailView(product: product)) {
                        ProductCard(product: product)
                      }
                      .buttonStyle(PlainButtonStyle())
                    }
                  }
                  .frame(maxWidth: .infinity, alignment: .top)
                }
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 12)
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

  private func waterfallColumns(for products: [ShopProduct], count: Int = 2) -> [[ShopProduct]] {
    guard count > 1 else { return [products] }

    var columns = Array(repeating: [ShopProduct](), count: count)
    var heights = Array(repeating: CGFloat.zero, count: count)

    for product in products {
      let targetColumn = heights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
      columns[targetColumn].append(product)
      heights[targetColumn] += estimatedCardHeight(for: product)
    }

    return columns
  }

  private func estimatedCardHeight(for product: ShopProduct) -> CGFloat {
    let imageHeight = ProductCard.estimatedImageHeight(for: product)
    let titleLineEstimate = max(2, min(2, Int(ceil(Double(product.title.count) / 15.0))))

    return imageHeight + 92 + CGFloat(titleLineEstimate * 18)
  }
}

struct ProductCard: View {
  let product: ShopProduct

  static func estimatedImageHeight(for product: ShopProduct) -> CGFloat {
    let seed = product.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    let heights: [CGFloat] = [172, 198, 224, 186]
    return heights[seed % heights.count]
  }

  private var imageHeight: CGFloat {
    Self.estimatedImageHeight(for: product)
  }

  private let cardWidth: CGFloat = 170
  private let cardHeight: CGFloat = 260

  private var categoryLabel: String {
    product.categories.first ?? product.productType
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 18)
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

        if !categoryLabel.isEmpty {
          Text(categoryLabel)
            .font(.caption2.weight(.semibold))
            .foregroundColor(Color(hex: "1E293B"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.9))
            .clipShape(Capsule())
            .padding(12)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: imageHeight)
      .clipped()
      .cornerRadius(18)

      VStack(alignment: .leading, spacing: 8) {
        Text(product.title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(Color(hex: "0F172A"))
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)

        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(product.formattedPrice)
            .font(.subheadline.weight(.bold))
            .foregroundColor(Color(hex: "2563EB"))

          Spacer(minLength: 0)

          Text(product.vendor)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }
      .padding(12)
    }
    .frame(width: cardWidth, height: cardHeight)
    .background(AppTheme.bgCard)
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(AppTheme.borderSubtle, lineWidth: 1)
    )
    .cornerRadius(18)
    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
  }
}

#Preview {
  ShopView()
    .environmentObject(LanguageManager())
}

// MARK: - ShopFilterView

struct ShopFilterView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var languageManager: LanguageManager
  @ObservedObject var shopifyService = ShopifyService.shared

  @State private var selectedCategory: String?
  @State private var selectedBrand: String?
  @State private var priceRange: ClosedRange<Double> = 0...2000

  private var maxPriceLimit: Double {
    max(shopifyService.maxFilterPrice, 2000)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text(languageManager.isChinese ? "筛选" : "Filter")
          .font(.title2)
          .bold()

        Spacer()

        Button(action: resetFilters) {
          HStack(spacing: 4) {
            Image(systemName: "goforward")
            Text(languageManager.isChinese ? "重置" : "Reset")
          }
          .font(.subheadline)
          .foregroundColor(.gray)
        }

        Button(action: { dismiss() }) {
          Image(systemName: "xmark")
            .font(.title3)
            .foregroundColor(AppTheme.textPrimary)
            .padding(.leading, 16)
        }
      }
      .padding()

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {

          // Category Section
          VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.isChinese ? "商品类别" : "Category")
              .font(.headline)

            ShopFilterChipLayout {
              // "All" Chip
              ShopFilterChip(
                title: languageManager.isChinese ? "全部" : "All",
                isSelected: selectedCategory == "" || selectedCategory == "All"
                  || selectedCategory == nil,
                action: { selectedCategory = "All" }
              )

              // "For my pet" Chip (AI Style)
              Button(action: { selectedCategory = "For my pet" }) {
                HStack(spacing: 4) {
                  Image(systemName: "sparkles")  // AI hint
                  Text(languageManager.isChinese ? "适合我的宠物" : "For my pet")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                  selectedCategory == "For my pet"
                    ? Color.blue.opacity(0.1)
                    : AppTheme.bgCard
                )
                .foregroundColor(selectedCategory == "For my pet" ? .blue : AppTheme.textPrimary)
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

            if shopifyService.isLoadingCategories && shopifyService.availableCategories.isEmpty {
              ProgressView(languageManager.isChinese ? "正在同步 Shopify 类别..." : "Loading Shopify categories...")
                .font(.caption)
            } else if shopifyService.availableCategories.isEmpty {
              Text(languageManager.isChinese ? "暂时没有可用类别" : "No categories available yet")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          // Brand Section
          VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.isChinese ? "品牌" : "Brand")
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
            Text(languageManager.isChinese ? "价格区间" : "Price Range")
              .font(.headline)

            // Validating range for Slider
            Slider(
              value: Binding(
                get: { priceRange.lowerBound },
                set: { newValue in
                  let newMin = min(newValue, priceRange.upperBound)
                  priceRange = newMin...priceRange.upperBound
                }
              ), in: 0...maxPriceLimit)

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
          Text(languageManager.isChinese ? "查看结果" : "Show Results")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
      }
      .padding()
      .background(AppTheme.bgElevated.shadow(radius: 2))
    }
    .onAppear {
      syncFilterState()

      if shopifyService.availableCategories.isEmpty, !shopifyService.isLoadingCategories {
        shopifyService.fetchCategories()
      }
    }
  }

  private func resetFilters() {
    selectedCategory = "All"
    selectedBrand = nil
    priceRange = 0...maxPriceLimit
    shopifyService.resetFilters()
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

  private func syncFilterState() {
    let activeCriteria = shopifyService.activeFilterCriteria
    selectedCategory = activeCriteria.category ?? "All"
    selectedBrand = activeCriteria.brand

    let lowerBound = activeCriteria.minPrice ?? 0
    let upperBound = activeCriteria.maxPrice ?? maxPriceLimit
    let clampedLower = min(lowerBound, maxPriceLimit)
    let clampedUpper = max(clampedLower, min(upperBound, maxPriceLimit))
    priceRange = clampedLower...clampedUpper
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

  @State private var paymentSheetSession: StripeCheckoutSession?
  @State private var alertTitle: String?
  @State private var alertMessage: String?
  @State private var showOwnerProfileEditor = false
  @State private var isPreparingCheckout = false

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
    .background(AppTheme.bgBase.ignoresSafeArea())
    .navigationTitle(languageManager.isChinese ? "購物車" : "Cart")
    .navigationBarTitleDisplayMode(.inline)
    .safeAreaInset(edge: .bottom) {
      if !shopifyService.cartItems.isEmpty {
        checkoutBar
      }
    }
    .alert(
      alertTitle ?? (languageManager.isChinese ? "結帳提示" : "Checkout"),
      isPresented: Binding(
        get: { alertMessage != nil },
        set: { if !$0 { alertMessage = nil } }
      )
    ) {
      Button(languageManager.isChinese ? "知道了" : "OK", role: .cancel) {}
    } message: {
      Text(alertMessage ?? "")
    }
    .fullScreenCover(
      isPresented: Binding(
        get: { paymentSheetSession != nil },
        set: { if !$0 { paymentSheetSession = nil } }
      )
    ) {
      StripePaymentSheetFullScreenHost(session: $paymentSheetSession)
        .presentationBackground(.clear)
        .background(Color.clear)
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
          if isPreparingCheckout {
            ProgressView()
              .progressViewStyle(.circular)
              .tint(.white)
          } else {
            Image(systemName: "creditcard.fill")
          }
          Text(
            isPreparingCheckout
              ? (languageManager.isChinese ? "正在准备支付..." : "Preparing payment...")
              : (languageManager.isChinese ? "使用 Stripe 安全付款" : "Pay Securely with Stripe")
          )
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
      .disabled(isPreparingCheckout)
    }
    .padding()
    .background(AppTheme.bgElevated.shadow(color: .black.opacity(0.06), radius: 8, y: -2))
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

        Button(action: { shopifyService.removeFromCart(itemId: item.id) }) {
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
        .fill(AppTheme.bgCard)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(AppTheme.borderSubtle, lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
  }

  private func quantityControl(item: CartItem) -> some View {
    HStack(spacing: 14) {
      Button(action: {
        shopifyService.updateCartQuantity(itemId: item.id, quantity: item.quantity - 1)
      }) {
        Image(systemName: "minus")
          .font(.system(size: 12, weight: .bold))
          .frame(width: 24, height: 24)
          .background(AppTheme.bgCard)
          .clipShape(Circle())
      }

      Text("\(item.quantity)")
        .font(.subheadline)
        .fontWeight(.medium)
        .frame(minWidth: 20)

      Button(action: {
        shopifyService.updateCartQuantity(itemId: item.id, quantity: item.quantity + 1)
      }) {
        Image(systemName: "plus")
          .font(.system(size: 12, weight: .bold))
          .frame(width: 24, height: 24)
          .background(AppTheme.bgCard)
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

    isPreparingCheckout = true
    let ownerProfile = OwnerProfileStore.shared.load()

    shopifyService.createPaymentSheetSession(for: shopifyService.cartItems, customer: ownerProfile) { result in
      isPreparingCheckout = false

      switch result {
      case .success(let configuration):
        paymentSheetSession = makeStripeCheckoutSession(
          from: configuration,
          ownerProfile: ownerProfile,
          onCompletion: handlePaymentResult
        )

      case .failure:
        alertTitle = languageManager.isChinese ? "結帳失敗" : "Checkout Failed"
        let fallback = languageManager.isChinese ? "目前無法建立 Stripe 付款頁。" : "Unable to prepare Stripe checkout."
        alertMessage = shopifyService.checkoutErrorMessage ?? fallback
      }
    }
  }

  private func handlePaymentResult(_ result: PaymentSheetResult) {
    switch result {
    case .completed:
      shopifyService.clearCart()
      alertTitle = languageManager.isChinese ? "付款成功" : "Payment Successful"
      alertMessage = languageManager.isChinese ? "已收到你的付款，訂單正在處理。" : "Your payment was received and the order is now being processed."

    case .canceled:
      break

    case .failed(let error):
      alertTitle = languageManager.isChinese ? "付款失敗" : "Payment Failed"
      alertMessage = error.localizedDescription
    }
  }

  private func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = shopifyService.cartItems.first?.product.currencyCode ?? "HKD"
    return formatter.string(from: amount as NSNumber) ?? "\(amount)"
  }
}

func makeStripeCheckoutSession(
  from configuration: ShopifyService.PaymentSheetSessionConfiguration,
  ownerProfile: OwnerProfile,
  onCompletion: @escaping (PaymentSheetResult) -> Void
) -> StripeCheckoutSession {
  STPAPIClient.shared.publishableKey = configuration.publishableKey

  var paymentConfiguration = PaymentSheet.Configuration()
  paymentConfiguration.merchantDisplayName = configuration.merchantDisplayName
  paymentConfiguration.allowsDelayedPaymentMethods = true
  paymentConfiguration.returnURL = AppStripeConfiguration.returnURL

  if let applePayMerchantID = AppStripeConfiguration.applePayMerchantID {
    paymentConfiguration.applePay = .init(
      merchantId: applePayMerchantID,
      merchantCountryCode: "HK"
    )
  }

  var billingDetails = PaymentSheet.BillingDetails()
  billingDetails.name = ownerProfile.name
  billingDetails.email = ownerProfile.email
  billingDetails.phone = ownerProfile.phone
  paymentConfiguration.defaultBillingDetails = billingDetails

  let paymentSheet = PaymentSheet(
    paymentIntentClientSecret: configuration.paymentIntentClientSecret,
    configuration: paymentConfiguration
  )

  return StripeCheckoutSession(paymentSheet: paymentSheet, onCompletion: onCompletion)
}

struct StripeCheckoutSession: Identifiable {
  let id = UUID()
  let paymentSheet: PaymentSheet
  let onCompletion: (PaymentSheetResult) -> Void
}

enum AppStripeConfiguration {
  static let returnURL = "petwell://stripe-redirect"

  static var applePayMerchantID: String? {
    guard let value = Bundle.main.object(forInfoDictionaryKey: "ApplePayMerchantID") as? String,
          !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return nil
    }

    return value
  }
}

struct StripePaymentSheetFullScreenHost: View {
  @Binding var session: StripeCheckoutSession?

  var body: some View {
    ZStack {
      Color.clear
        .ignoresSafeArea()

      StripePaymentSheetPresenter(session: $session)
        .frame(width: 0, height: 0)
    }
    .background(Color.clear)
  }
}

struct StripePaymentSheetPresenter: UIViewControllerRepresentable {
  @Binding var session: StripeCheckoutSession?

  func makeCoordinator() -> Coordinator {
    Coordinator(session: $session)
  }

  func makeUIViewController(context: Context) -> UIViewController {
    let controller = UIViewController()
    controller.view.backgroundColor = .clear
    return controller
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    context.coordinator.hostViewController = uiViewController
    context.coordinator.presentIfNeeded()
  }

  final class Coordinator {
    @Binding private var session: StripeCheckoutSession?
    weak var hostViewController: UIViewController?
    var isPresenting = false

    init(session: Binding<StripeCheckoutSession?>) {
      _session = session
    }

    func presentIfNeeded() {
      guard !isPresenting,
            let session,
            let hostViewController else { return }

      isPresenting = true

      DispatchQueue.main.async {
        session.paymentSheet.present(from: hostViewController) { result in
          session.onCompletion(result)
          self.session = nil
          self.isPresenting = false
        }
      }
    }
  }
}
