import StripePaymentSheet
import SwiftUI

struct ProductDetailView: View {
    let product: ShopProduct
    @ObservedObject private var shopifyService = ShopifyService.shared
    @EnvironmentObject var languageManager: LanguageManager
    @State private var didAddToCart = false
    @State private var paymentSheetSession: StripeCheckoutSession?
    @State private var alertTitle: String?
    @State private var alertMessage: String?
    @State private var showOwnerProfileEditor = false
    @State private var productDetail: ShopProductDetail?
    @State private var isLoadingDetail = false
    @State private var detailLoadError: String?
    @State private var selectedVariantId: String?
    @State private var selectedImageIndex = 0
    @State private var isPreparingPayment = false
    @State private var areVariantsExpanded = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                productImageSection

                VStack(alignment: .leading, spacing: 16) {
                    Text(displayTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        chip(text: displayVendor, systemImage: "tag.fill")
                        if !displayProductType.isEmpty {
                            chip(text: displayProductType, systemImage: "square.grid.2x2.fill")
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(displayPrice)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "2563EB"))
                        if let comparePrice = displayCompareAtPrice {
                            Text(comparePrice)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .strikethrough()
                        }
                        Text(languageManager.isChinese ? "含稅價格以結帳頁為準" : "Final price shown at checkout")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if isLoadingDetail {
                        ProgressView(languageManager.isChinese ? "正在載入 Shopify 詳情..." : "Loading Shopify details...")
                            .font(.caption)
                    }

                    if let detailLoadError {
                        Label(detailLoadError, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
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
                    Text(displayDescription)
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

                if let detail = productDetail {
                    if !detail.options.isEmpty {
                        sectionCard(
                            title: languageManager.isChinese ? "商品属性" : "Product Attributes",
                            systemImage: "slider.horizontal.3"
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(detail.options) { option in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(option.name)
                                            .font(.subheadline.weight(.semibold))
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(option.values, id: \.self) { value in
                                                    chip(text: value, systemImage: "circle.hexagongrid.fill")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !detail.variants.isEmpty {
                        sectionCard(
                            title: languageManager.isChinese ? "规格 / 变体" : "Variants",
                            systemImage: "square.stack.3d.up"
                        ) {
                            VStack(spacing: 12) {
                                if let firstVariant = detail.variants.first {
                                    variantCard(firstVariant)
                                }

                                if areVariantsExpanded {
                                    ForEach(Array(detail.variants.dropFirst())) { variant in
                                        variantCard(variant)
                                    }
                                }

                                if detail.variants.count > 1 {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            areVariantsExpanded.toggle()
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(
                                                areVariantsExpanded
                                                    ? (languageManager.isChinese ? "收起其他规格" : "Collapse extra variants")
                                                    : (languageManager.isChinese ? "展开其余 \(detail.variants.count - 1) 个规格" : "Show \(detail.variants.count - 1) more variants")
                                            )
                                            .font(.subheadline.weight(.semibold))

                                            Spacer()

                                            Image(systemName: areVariantsExpanded ? "chevron.up" : "chevron.down")
                                                .font(.caption.weight(.bold))
                                        }
                                        .foregroundColor(Color(hex: "1D4ED8"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "EFF6FF"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color(hex: "BFDBFE"), lineWidth: 1)
                                        )
                                        .cornerRadius(14)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if !detail.tags.isEmpty {
                        sectionCard(
                            title: languageManager.isChinese ? "标签" : "Tags",
                            systemImage: "tag"
                        ) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                                ForEach(detail.tags, id: \.self) { tag in
                                    chip(text: tag, systemImage: "number")
                                }
                            }
                        }
                    }
                }
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
                            ZStack {
                                Image(systemName: "creditcard.fill")
                                    .opacity(isPreparingPayment ? 0 : 1)

                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .opacity(isPreparingPayment ? 1 : 0)
                            }
                            .frame(width: 18, height: 18)

                            ZStack {
                                Text(languageManager.isChinese ? "准备支付中..." : "Preparing payment...")
                                    .opacity(0)

                                Text(isPreparingPayment ? (languageManager.isChinese ? "准备支付中..." : "Preparing payment...") : (languageManager.isChinese ? "立即付款" : "Pay Now"))
                            }
                            .lineLimit(1)
                        }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 24)
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
                    .disabled(isPreparingPayment)
                }
            }
            .padding()
            .background(Color.white.shadow(color: .black.opacity(0.08), radius: 8, y: -2))
        }
        .sheet(isPresented: $showOwnerProfileEditor) {
            OwnerProfileEditorSheet(isMandatory: true) { _ in }
        }
        .alert(
            alertTitle ?? (languageManager.isChinese ? "付款提示" : "Payment"),
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
        .onAppear(perform: loadProductDetail)
    }

    private var productImageSection: some View {
        VStack(spacing: 12) {
            if galleryImages.isEmpty {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
            } else {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, image in
                        productImage(url: image.url)
                            .tag(index)
                            .padding(.horizontal)
                    }
                }
                .frame(height: 320)
                .tabViewStyle(.page(indexDisplayMode: .never))

                if galleryImages.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, image in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedImageIndex = index
                                    }
                                } label: {
                                    thumbnailImage(url: image.url, isSelected: selectedImageIndex == index)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Text("\(selectedImageIndex + 1) / \(galleryImages.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
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

    private func productImage(url: URL?) -> some View {
        Group {
            if let url {
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
    }

    private func thumbnailImage(url: URL?, isSelected: Bool) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(hex: "2563EB") : Color.white.opacity(0.9), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: isSelected ? Color(hex: "93C5FD").opacity(0.6) : .clear, radius: 6, y: 2)
    }

    private func variantCard(_ variant: ShopProductVariant) -> some View {
        Button {
            selectedVariantId = variant.id
            syncSelectedImage()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(variant.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if !variant.availableForSale {
                            Text(languageManager.isChinese ? "缺货" : "Sold out")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(999)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(variant.formattedPrice)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(Color(hex: "2563EB"))

                        if let compare = variant.formattedCompareAtPrice {
                            Text(compare)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .strikethrough()
                        }
                    }

                    if !variant.selectedOptions.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                            ForEach(variant.selectedOptions) { option in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.name)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(option.value)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color(hex: "F8FAFC"))
                                .cornerRadius(10)
                            }
                        }
                    }

                    if !variant.sku.isEmpty {
                        Text("SKU: \(variant.sku)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: selectedVariantId == variant.id ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedVariantId == variant.id ? Color(hex: "2563EB") : .secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selectedVariantId == variant.id ? Color(hex: "DBEAFE") : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedVariantId == variant.id ? Color(hex: "2563EB") : Color(hex: "E2E8F0"), lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private func sectionCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundColor(.primary)

            content()
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

    private var displayTitle: String {
        productDetail?.title ?? product.title
    }

    private var displayVendor: String {
        productDetail?.vendor ?? product.vendor
    }

    private var displayProductType: String {
        productDetail?.productType ?? product.productType
    }

    private var displayDescription: String {
        productDetail?.description ?? product.description
    }

    private var displayPrice: String {
        selectedVariant?.formattedPrice ?? productDetail?.formattedPriceRange ?? product.formattedPrice
    }

    private var displayCompareAtPrice: String? {
        selectedVariant?.formattedCompareAtPrice
    }

    private var selectedVariant: ShopProductVariant? {
        guard let selectedVariantId else { return nil }
        return productDetail?.variants.first(where: { $0.id == selectedVariantId })
    }

    private var galleryImages: [ShopProductImage] {
        if let detail = productDetail, !detail.images.isEmpty {
            return detail.images
        }

        if let imageUrl = product.imageUrl {
            return [
                ShopProductImage(
                    id: product.id,
                    url: imageUrl,
                    altText: product.title,
                    width: nil,
                    height: nil
                )
            ]
        }

        return []
    }

    private var checkoutProduct: ShopProduct {
        let selectedImageURL: URL?
        if galleryImages.indices.contains(selectedImageIndex) {
            selectedImageURL = galleryImages[selectedImageIndex].url
        } else {
            selectedImageURL = product.imageUrl
        }

        return product.updating(
            price: selectedVariant?.price,
            imageUrl: selectedVariant?.imageURL ?? selectedImageURL,
            variantId: selectedVariant?.id ?? product.variantId
        )
    }

    private func loadProductDetail() {
        guard productDetail == nil, !isLoadingDetail else { return }

        isLoadingDetail = true
        detailLoadError = nil

        shopifyService.fetchProductDetail(handle: product.handle) { result in
            isLoadingDetail = false

            switch result {
            case .success(let detail):
                productDetail = detail
                if let preferredVariant = detail.variants.first(where: { $0.availableForSale }) ?? detail.variants.first {
                    selectedVariantId = preferredVariant.id
                }
                syncSelectedImage()

            case .failure:
                detailLoadError = languageManager.isChinese
                    ? "未能从 Shopify 拉取完整商品属性"
                    : "Failed to load full Shopify product attributes"
            }
        }
    }

    private func syncSelectedImage() {
        guard let variantImageURL = selectedVariant?.imageURL,
              let matchingIndex = galleryImages.firstIndex(where: { $0.url == variantImageURL }) else {
            return
        }

        selectedImageIndex = matchingIndex
    }

    private func addToCart() {
        if let selectedVariant, !selectedVariant.availableForSale {
            alertTitle = languageManager.isChinese ? "加入失败" : "Add to Cart Failed"
            alertMessage = languageManager.isChinese ? "当前规格暂时缺货。" : "This variant is currently sold out."
            return
        }

        shopifyService.addToCart(product: checkoutProduct)
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

        if let selectedVariant, !selectedVariant.availableForSale {
            alertTitle = languageManager.isChinese ? "付款失败" : "Payment Failed"
            alertMessage = languageManager.isChinese ? "当前规格暂时缺货。" : "This variant is currently sold out."
            return
        }

        isPreparingPayment = true
        let ownerProfile = OwnerProfileStore.shared.load()

        shopifyService.createPaymentSheetSession(for: checkoutProduct, quantity: 1, customer: ownerProfile) { result in
            isPreparingPayment = false

            switch result {
            case .success(let configuration):
                paymentSheetSession = makeStripeCheckoutSession(
                    from: configuration,
                    ownerProfile: ownerProfile,
                    onCompletion: handlePaymentResult
                )

            case .failure:
                alertTitle = languageManager.isChinese ? "付款失败" : "Payment Failed"
                let fallback = languageManager.isChinese ? "目前無法建立 Stripe 付款頁。" : "Unable to prepare Stripe checkout."
                alertMessage = shopifyService.checkoutErrorMessage ?? fallback
            }
        }
    }

    private func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            alertTitle = languageManager.isChinese ? "付款成功" : "Payment Successful"
            alertMessage = languageManager.isChinese ? "已收到你的付款，訂單正在處理。" : "Your payment was received and the order is now being processed."

        case .canceled:
            break

        case .failed(let error):
            alertTitle = languageManager.isChinese ? "付款失败" : "Payment Failed"
            alertMessage = error.localizedDescription
        }
    }
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
            categories: ["Test"],
            vendor: "Vendor",
            handle: "test",
            variantId: "1"
        ))
        .environmentObject(LanguageManager())
    }
}
