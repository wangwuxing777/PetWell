import SwiftUI

struct ProductDetailView: View {
    let product: ShopProduct
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Product Image
                if let url = product.imageUrl {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                                .aspectRatio(1, contentMode: .fit)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.vendor)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text(product.title)
                            .font(.title2)
                            .bold()
                            .fixedSize(horizontal: false, vertical: true)

                        Text(product.formattedPrice)
                            .font(.title3)
                            .foregroundColor(.blue)
                            .bold()
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageManager.isChinese ? "描述" : "Description")
                            .font(.headline)
                        
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
                
                Spacer()
            }
        }
        .navigationTitle(languageManager.isChinese ? "商品详情" : "Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
             Button(action: {
                 // Placeholder: Add to cart action
                 print("Add to cart: \(product.title)")
             }) {
                 Text(languageManager.isChinese ? "加入购物车" : "Add to Cart")
                     .font(.headline)
                     .foregroundColor(.white)
                     .frame(maxWidth: .infinity)
                     .padding()
                     .background(Color.blue)
                     .cornerRadius(12)
             }
             .padding()
             .background(Color.white.shadow(radius: 2, y: -2))
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
            vendor: "Vendor",
            handle: "test"
        ))
        .environmentObject(LanguageManager())
    }
}
