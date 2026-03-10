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
    @State private var showImagePreview = false
    @State private var isDescriptionExpanded = false

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

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(displayPrice)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(Color(hex: "1D4ED8"))

                            if let savingsBadgeText {
                                Text(savingsBadgeText)
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Color(hex: "9A3412"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(hex: "FFEDD5"))
                                    .cornerRadius(999)
                            }
                        }
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

                descriptionSection

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
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color(hex: "166534"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "DCFCE7"))
                        .cornerRadius(999)
                }

                HStack(spacing: 12) {
                    Button(action: addToCart) {
                        VStack(spacing: 4) {
                            Image(systemName: "cart.badge.plus")
                            Text(languageManager.isChinese ? "加购" : "Cart")
                        }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "1D4ED8"))
                            .frame(width: 72, height: 56)
                            .background(Color.white.opacity(0.88))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            )
                            .cornerRadius(18)
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
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "4F46E5"), Color(hex: "2563EB")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .cornerRadius(20)
                            .shadow(color: Color(hex: "2563EB").opacity(0.28), radius: 14, y: 8)
                    }
                    .disabled(isPreparingPayment)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.65))
                    .frame(height: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 18, y: -4)
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            imagePreviewOverlay
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
        .hideTabBarWhenPushed()
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
                            .contentShape(RoundedRectangle(cornerRadius: 24))
                            .onTapGesture {
                                showImagePreview = true
                            }
                    }
                }
                .frame(height: 320)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .overlay(alignment: .topTrailing) {
                    Button {
                        showImagePreview = true
                    } label: {
                        Label(languageManager.isChinese ? "大图" : "Zoom", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.88))
                            .cornerRadius(999)
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 24)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(languageManager.isChinese ? "轻点查看大图" : "Tap to preview full screen")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 12)
                }

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

    private func premiumBadge(text: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(Color(hex: "334155"))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint)
        .cornerRadius(999)
    }

    private var descriptionSection: some View {
        let content = parsedDescription
        let bodyText = content.bodyParagraphs.joined(separator: "\n\n")
        let shouldCollapseBody = bodyText.count > 260 || content.bodyParagraphs.count > 1

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(hex: "1D4ED8"))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "DBEAFE"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(languageManager.isChinese ? "产品亮点" : "Product Story")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(languageManager.isChinese ? "更清晰地呈现这件商品的气质与使用体验" : "A refined overview of the product experience")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let headline = content.headline, !headline.isEmpty {
                Text(headline)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(Color(hex: "0F172A"))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "F8FAFC"), Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: "E2E8F0"), lineWidth: 1)
                    )
                    .cornerRadius(18)
            }

            if !content.highlights.isEmpty || !content.detailItems.isEmpty {
                descriptionInfoColumns(content: content)
            }

            if !bodyText.isEmpty {
                descriptionFeaturePanel(
                    title: languageManager.isChinese ? "详细介绍" : "Details",
                    subtitle: languageManager.isChinese ? "用更柔和的阅读节奏呈现使用场景与整体体验" : "A softer reading rhythm for use, feel, and daily context",
                    systemImage: "text.alignleft",
                    iconTint: Color(hex: "FEF3C7"),
                    contentBackground: Color(hex: "FFFBEB")
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(bodyText)
                            .font(.body)
                            .foregroundColor(Color(hex: "475569"))
                            .lineSpacing(8)
                            .lineLimit(shouldCollapseBody && !isDescriptionExpanded ? 6 : nil)
                            .fixedSize(horizontal: false, vertical: true)

                        if shouldCollapseBody {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDescriptionExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(isDescriptionExpanded ? (languageManager.isChinese ? "收起" : "Show less") : (languageManager.isChinese ? "展开更多" : "Read more"))
                                    Image(systemName: isDescriptionExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption.weight(.bold))
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color(hex: "1D4ED8"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.95))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 12, y: 6)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func descriptionInfoColumns(content: ParsedProductDescription) -> some View {
        if !content.highlights.isEmpty, !content.detailItems.isEmpty {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    whyLoveColumn(highlights: content.highlights)
                        .frame(maxWidth: .infinity, minHeight: 290, alignment: .topLeading)

                    materialsCareColumn(items: content.detailItems)
                        .frame(maxWidth: .infinity, minHeight: 290, alignment: .topLeading)
                }

                VStack(alignment: .leading, spacing: 14) {
                    whyLoveColumn(highlights: content.highlights)
                    materialsCareColumn(items: content.detailItems)
                }
            }
        } else if !content.highlights.isEmpty {
            whyLoveColumn(highlights: content.highlights)
        } else if !content.detailItems.isEmpty {
            materialsCareColumn(items: content.detailItems)
        }
    }

    private func whyLoveColumn(highlights: [String]) -> some View {
        descriptionFeaturePanel(
            title: languageManager.isChinese ? "精选理由" : "Why you'll love it",
            subtitle: languageManager.isChinese ? "把产品优势以更轻盈的方式呈现" : "A softer read on comfort, feel, and everyday appeal",
            systemImage: "heart.text.square.fill",
            iconTint: Color(hex: "DBEAFE"),
            contentBackground: Color(hex: "F8FAFC")
        ) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(highlights.enumerated()), id: \.offset) { index, highlight in
                    descriptionHighlightCard(text: highlight, index: index)
                }
            }
        }
    }

    private func materialsCareColumn(items: [ParsedProductDescription.DetailItem]) -> some View {
        descriptionFeaturePanel(
            title: languageManager.isChinese ? "材质与使用" : "Materials & care",
            subtitle: languageManager.isChinese ? "把材质、护理与使用场景整洁排开" : "A cleaner layout for materials, care, and usage notes",
            systemImage: "square.grid.2x2.fill",
            iconTint: Color(hex: "EDE9FE"),
            contentBackground: Color(hex: "FAF5FF")
        ) {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    descriptionDetailRow(item: item)

                    if index < items.count - 1 {
                        Divider()
                            .overlay(Color(hex: "E9D5FF"))
                    }
                }
            }
            .background(Color.white.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "E9D5FF"), lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }

    private func descriptionFeaturePanel<Content: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        iconTint: Color,
        contentBackground: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(hex: "334155"))
                    .frame(width: 34, height: 34)
                    .background(iconTint)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(hex: "0F172A"))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color(hex: "64748B"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [contentBackground, Color.white.opacity(0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.025), radius: 10, y: 4)
    }

    private func descriptionHighlightCard(text: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: descriptionHighlightSymbol(for: index))
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(hex: "1D4ED8"))
                .frame(width: 34, height: 34)
                .background(Color(hex: "DBEAFE"))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(hex: "334155"))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.white.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E2E8F0"), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private func descriptionDetailRow(item: ParsedProductDescription.DetailItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: descriptionDetailSymbol(for: item.title))
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(hex: "7C3AED"))
                .frame(width: 30, height: 30)
                .background(Color(hex: "F3E8FF"))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(hex: "64748B"))

                Text(item.value)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "334155"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func descriptionHighlightSymbol(for index: Int) -> String {
        let symbols = ["sparkles", "heart.fill", "moon.stars.fill", "leaf.fill"]
        return symbols[index % symbols.count]
    }

    private func descriptionDetailSymbol(for title: String) -> String {
        switch title.lowercased() {
        case "material":
            return "square.grid.2x2.fill"
        case "care":
            return "drop.fill"
        case "usage":
            return "house.fill"
        case "size":
            return "ruler.fill"
        case "pet":
            return "pawprint.fill"
        default:
            return "circle.hexagongrid.fill"
        }
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
        let isSelected = selectedVariantId == variant.id

        return AnyView(
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

                            if isSelected {
                                Text(languageManager.isChinese ? "已选" : "Selected")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(Color(hex: "1D4ED8"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.75))
                                    .cornerRadius(999)
                            }

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
                                            .foregroundColor(isSelected ? Color(hex: "1D4ED8") : .primary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(isSelected ? Color.white.opacity(0.82) : Color(hex: "F8FAFC"))
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

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? Color(hex: "2563EB") : .secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color(hex: "DBEAFE"), Color.white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.white
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color(hex: "2563EB") : Color(hex: "E2E8F0"), lineWidth: isSelected ? 1.5 : 1)
                )
                .cornerRadius(16)
                .shadow(color: isSelected ? Color(hex: "93C5FD").opacity(0.35) : .black.opacity(0.04), radius: isSelected ? 14 : 8, y: isSelected ? 8 : 4)
            }
            .buttonStyle(.plain)
        )
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

    private var parsedDescription: ParsedProductDescription {
        ParsedProductDescription(raw: displayDescription)
    }

    private var displayPrice: String {
        selectedVariant?.formattedPrice ?? productDetail?.formattedPriceRange ?? product.formattedPrice
    }

    private var displayCompareAtPrice: String? {
        selectedVariant?.formattedCompareAtPrice
    }

    private var savingsBadgeText: String? {
        guard let selectedVariant,
              let compareAtPrice = selectedVariant.compareAtPrice else {
            return nil
        }

        let price = NSDecimalNumber(decimal: selectedVariant.price).doubleValue
        let compare = NSDecimalNumber(decimal: compareAtPrice).doubleValue
        guard compare > price, compare > 0 else { return nil }

        let percentage = Int(round((compare - price) / compare * 100))
        guard percentage > 0 else { return nil }

        return languageManager.isChinese ? "省 \(percentage)%" : "Save \(percentage)%"
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

    private var imagePreviewOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            if galleryImages.isEmpty {
                Image(systemName: "photo")
                    .font(.system(size: 42, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
            } else {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, image in
                        Group {
                            if let imageURL = image.url {
                                AsyncImage(url: imageURL) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                    case .success(let loadedImage):
                                        loadedImage
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.7))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))

                VStack(spacing: 10) {
                    Text("\(selectedImageIndex + 1) / \(max(galleryImages.count, 1))")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, image in
                                Button {
                                    selectedImageIndex = index
                                } label: {
                                    thumbnailImage(url: image.url, isSelected: selectedImageIndex == index)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }

            Button {
                showImagePreview = false
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
    }
}

private struct ParsedProductDescription {
    struct DetailItem: Identifiable {
        let title: String
        let value: String

        var id: String { "\(title)-\(value)" }
    }

    let headline: String?
    let highlights: [String]
    let bodyParagraphs: [String]
    let detailItems: [DetailItem]

    init(raw: String) {
        let normalized = Self.normalizedDescriptionText(raw)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            self.headline = nil
            self.highlights = []
            self.bodyParagraphs = []
            self.detailItems = []
            return
        }

        if let parsed = Self.parseInlineStructuredContent(from: normalized) {
            self.headline = parsed.headline
            self.highlights = parsed.highlights
            self.bodyParagraphs = parsed.bodyParagraphs
            self.detailItems = parsed.detailItems
            return
        }

        let blocks = normalized
            .components(separatedBy: CharacterSet.newlines)
            .split(whereSeparator: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            .map { group in
                group
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }

        var extractedHeadline: String?
        var extractedHighlights: [String] = []
        var extractedParagraphs: [String] = []
        var extractedDetailItems: [DetailItem] = []

        for lines in blocks {
            guard !lines.isEmpty else { continue }

            if lines.count == 1, Self.isSectionHeading(lines[0]) {
                continue
            }

            let bullets = lines.compactMap(Self.cleanedBulletText(from:))
            if bullets.count == lines.count, !bullets.isEmpty {
                extractedHighlights.append(contentsOf: bullets)
                continue
            }

            let details = lines.compactMap(Self.detailItem(from:))
            if details.count == lines.count, !details.isEmpty {
                extractedDetailItems.append(contentsOf: details)
                continue
            }

            let paragraph = lines.joined(separator: " ")
            if extractedHeadline == nil,
               lines.count == 1,
               !Self.looksLikeMetadata(paragraph),
               paragraph.count <= 140 {
                extractedHeadline = paragraph
            } else {
                extractedParagraphs.append(paragraph)
            }
        }

        if extractedHeadline == nil,
           let firstParagraph = extractedParagraphs.first,
           firstParagraph.count <= 140 {
            extractedHeadline = firstParagraph
            extractedParagraphs.removeFirst()
        }

        if extractedHighlights.isEmpty,
           extractedParagraphs.count > 1 {
            extractedHighlights = Array(extractedParagraphs.prefix(3))
            extractedParagraphs.removeFirst(min(3, extractedParagraphs.count))
        }

        if extractedParagraphs.isEmpty, extractedHeadline == nil {
            extractedParagraphs = [normalized]
        }

        self.headline = extractedHeadline
        self.highlights = extractedHighlights
        self.bodyParagraphs = extractedParagraphs
        self.detailItems = extractedDetailItems
    }

    private nonisolated static func normalizedDescriptionText(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: NSString.CompareOptions.regularExpression)
            .replacingOccurrences(of: "</p>", with: "\n\n", options: NSString.CompareOptions.caseInsensitive)
            .replacingOccurrences(of: "</li>", with: "\n", options: NSString.CompareOptions.caseInsensitive)
            .replacingOccurrences(of: "<li>", with: "• ", options: NSString.CompareOptions.caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: NSString.CompareOptions.regularExpression)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    private nonisolated static func parseInlineStructuredContent(from text: String) -> (headline: String?, highlights: [String], bodyParagraphs: [String], detailItems: [DetailItem])? {
        let highlightsRange = text.range(
            of: #"(?i)\bKey Highlights\b|产品亮点|產品亮點|Why you'll love it|Why you’ll love it"#,
            options: .regularExpression
        )
        let aboutRange = text.range(
            of: #"(?i)\bAbout\s+(?:This|These)\b[^\n]*|Detailed Description|Details|详细介绍|詳細介紹"#,
            options: .regularExpression
        )
        let materialsRange = text.range(
            of: #"(?i)\bMaterials?\s*(?:&|and)\s*Care\b|Usage Notes|材质与护理|材質與護理|使用提示"#,
            options: .regularExpression
        )

        guard highlightsRange != nil || aboutRange != nil || materialsRange != nil else {
            return nil
        }

        let firstMarkerStart = [highlightsRange?.lowerBound, aboutRange?.lowerBound, materialsRange?.lowerBound]
            .compactMap { $0 }
            .min() ?? text.endIndex

        let headlineText = text[text.startIndex..<firstMarkerStart]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let highlightsText = sectionText(
            in: text,
            from: highlightsRange,
            until: [aboutRange?.lowerBound, materialsRange?.lowerBound]
        )
        let bodyText = sectionText(
            in: text,
            from: aboutRange,
            until: [materialsRange?.lowerBound]
        )
        let materialsText = sectionText(
            in: text,
            from: materialsRange,
            until: []
        )

        let highlights = sentenceChunks(from: highlightsText, limit: 3)
        let bodyParagraphs = paragraphChunks(from: bodyText)

        var detailItems = paragraphChunks(from: materialsText)
            .compactMap(detailItem(from:))

        if detailItems.isEmpty, !materialsText.isEmpty {
            detailItems = [
                DetailItem(title: "Materials & Care", value: materialsText)
            ]
        }

        let hasStructuredOutput = !headlineText.isEmpty || !highlights.isEmpty || !bodyParagraphs.isEmpty || !detailItems.isEmpty
        guard hasStructuredOutput else { return nil }

        return (
            headline: headlineText.isEmpty ? nil : headlineText,
            highlights: highlights,
            bodyParagraphs: bodyParagraphs,
            detailItems: detailItems
        )
    }

    private nonisolated static func sectionText(in text: String, from range: Range<String.Index>?, until boundaries: [String.Index?]) -> String {
        guard let range else { return "" }

        let endIndex = boundaries
            .compactMap { $0 }
            .filter { $0 > range.upperBound }
            .min() ?? text.endIndex

        return text[range.upperBound..<endIndex]
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private nonisolated static func sentenceChunks(from text: String, limit: Int? = nil) -> [String] {
        guard !text.isEmpty else { return [] }

        let pieces = text
            .split(whereSeparator: { $0 == "\n" })
            .flatMap { segment -> [String] in
                segment
                    .split(whereSeparator: { ".!?。！？".contains($0) })
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }

        if let limit {
            return Array(pieces.prefix(limit))
        }

        return pieces
    }

    private nonisolated static func paragraphChunks(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }

        let chunks = text
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !chunks.isEmpty {
            return chunks
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? [] : [trimmed]
    }

    private nonisolated static func cleanedBulletText(from line: String) -> String? {
        let bulletPrefixes = ["•", "-", "–", "*", "·"]
        for prefix in bulletPrefixes where line.hasPrefix(prefix) {
            let cleaned = line.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        }

        if let regex = try? NSRegularExpression(pattern: "^[0-9]+[\\.|、|\\)]\\s*", options: []) {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, options: [], range: range),
               let matchRange = Range(match.range, in: line) {
                let cleaned = line[matchRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                return cleaned.isEmpty ? nil : cleaned
            }
        }

        return nil
    }

    private nonisolated static func detailItem(from line: String) -> DetailItem? {
        let separators = [":", "："]
        for separator in separators {
            let parts = line.components(separatedBy: separator)
            guard parts.count >= 2 else { continue }

            let title = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts.dropFirst().joined(separator: separator).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !title.isEmpty, !value.isEmpty, isMetadataKey(title) else { continue }
            return DetailItem(title: normalizedMetadataTitle(title), value: value)
        }
        return nil
    }

    private nonisolated static func isSectionHeading(_ line: String) -> Bool {
        let normalized = line.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let headings = [
            "description", "product highlights", "key highlights", "details",
            "detailed description", "materials & care", "materials and care",
            "usage notes", "why you'll love it", "why you’ll love it",
            "描述", "产品亮点", "產品亮點", "详细介绍", "詳細介紹", "材质与护理", "材質與護理", "使用提示"
        ]
        return headings.contains(normalized)
    }

    private nonisolated static func looksLikeMetadata(_ line: String) -> Bool {
        cleanedBulletText(from: line) != nil || detailItem(from: line) != nil || isSectionHeading(line)
    }

    private nonisolated static func isMetadataKey(_ key: String) -> Bool {
        let normalized = key.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let knownKeys = [
            "material", "materials", "care", "care instructions", "usage", "usage scenario",
            "suitable for", "scene", "size", "size note", "fit", "pet type",
            "材质", "材質", "护理", "護理", "适用场景", "適用場景", "使用场景", "尺寸", "适用对象", "適用對象"
        ]
        return knownKeys.contains(normalized)
    }

    private nonisolated static func normalizedMetadataTitle(_ title: String) -> String {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalized.lowercased() {
        case "material", "materials": return "Material"
        case "care", "care instructions": return "Care"
        case "usage", "usage scenario", "scene", "suitable for": return "Usage"
        case "size", "size note": return "Size"
        case "pet type": return "Pet"
        default:
            switch normalized {
            case "材质", "材質": return "Material"
            case "护理", "護理": return "Care"
            case "适用场景", "適用場景", "使用场景": return "Usage"
            case "尺寸": return "Size"
            case "适用对象", "適用對象": return "Pet"
            default: return normalized
            }
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
