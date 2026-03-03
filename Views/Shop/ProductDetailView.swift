import SwiftUI

struct ProductDetailView: View {
    let product: ShopProduct
    @ObservedObject private var shopifyService = ShopifyService.shared
    @EnvironmentObject var languageManager: LanguageManager
    @State private var didAddToCart = false
    @State private var checkoutSession: DetailCheckoutSession?
    @State private var alertMessage: String?
    @State private var showOwnerProfileEditor = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                productImageSection

                VStack(alignment: .leading, spacing: 16) {
                    Text(product.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        chip(text: product.vendor, systemImage: "tag.fill")
                        if !product.productType.isEmpty {
                            chip(text: product.productType, systemImage: "square.grid.2x2.fill")
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(product.formattedPrice)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "2563EB"))
                        Text(languageManager.isChinese ? "含稅價格以結帳頁為準" : "Final price shown at checkout")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text(languageManager.isChinese ? "描述" : "Description")
                        .font(.headline)
                    Text(product.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .background(Color.white.opacity(0.95))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "E2E8F0"), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "EEF2FF"), Color(hex: "F8FAFC"), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle(languageManager.isChinese ? "商品详情" : "Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if didAddToCart {
                    Text(languageManager.isChinese ? "已加入購物車" : "Added to cart")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                HStack(spacing: 10) {
                    Button(action: addToCart) {
                        HStack(spacing: 6) {
                            Image(systemName: "cart.badge.plus")
                            Text(languageManager.isChinese ? "加入購物車" : "Add to Cart")
                        }
                            .font(.headline)
                            .foregroundColor(Color(hex: "1D4ED8"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "DBEAFE"))
                            .cornerRadius(12)
                    }

                    Button(action: buyNow) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                            Text(languageManager.isChinese ? "立即結帳" : "Buy Now")
                        }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
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
            }
            .padding()
            .background(Color.white.shadow(color: .black.opacity(0.08), radius: 8, y: -2))
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
    }

    private var productImageSection: some View {
        Group {
            if let url = product.imageUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .background(Color.white.opacity(0.85))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func chip(text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color(hex: "334155"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "F1F5F9"))
        .cornerRadius(999)
    }

    private func addToCart() {
        shopifyService.addToCart(product: product)
        didAddToCart = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            didAddToCart = false
        }
    }

    private func buyNow() {
        guard OwnerProfileStore.shared.hasRequiredContact() else {
            showOwnerProfileEditor = true
            return
        }
        guard let checkoutURL = shopifyService.makeCheckoutURL(for: product, quantity: 1) else {
            let fallback = languageManager.isChinese ? "目前無法建立結帳連結。" : "Unable to create checkout link."
            alertMessage = shopifyService.checkoutErrorMessage ?? fallback
            return
        }
        checkoutSession = DetailCheckoutSession(url: checkoutURL)
    }
}

private struct DetailCheckoutSession: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    NavigationView {
        ProductDetailView(product: ShopProduct(
            id: "1",
            title: "Sample Product",
            description: "To prevent error locally if not fetching",
            price: 99.99,
            currencyCode: "USD",
            imageUrl: nil,
            productType: "Test",
            vendor: "Vendor",
            handle: "test",
            variantId: "1"
        ))
        .environmentObject(LanguageManager())
    }
}
