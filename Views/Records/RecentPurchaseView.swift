//
//  RecentPurchaseView.swift
//  PetWell
//
//  Created by Frontend Engineer on 2026/03/04.
//

import SwiftUI

struct RecentPurchaseView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var orders: [ShopifyOrder] = []
    @State private var isLoading = false
    @State private var selectedFilter: OrderFilter = .all
    @State private var selectedOrder: ShopifyOrder?

    enum OrderFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case shipped = "Shipped"
        case delivered = "Delivered"
    }

    var filteredOrders: [ShopifyOrder] {
        switch selectedFilter {
        case .all:
            return orders
        case .pending:
            return orders.filter { $0.fulfillmentStatus == .pending }
        case .shipped:
            return orders.filter { $0.fulfillmentStatus == .shipped }
        case .delivered:
            return orders.filter { $0.fulfillmentStatus == .delivered }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(OrderFilter.allCases, id: \.self) { filter in
                        RecentPurchaseFilterChip(
                            title: filterTitle(filter),
                            isSelected: selectedFilter == filter,
                            onTap: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemBackground))

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredOrders.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredOrders) { order in
                            OrderCard(order: order)
                                .onTapGesture {
                                    selectedOrder = order
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(languageManager.isChinese ? "最近購買" : "Recent Purchase")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBarWhenPushed()
        .sheet(item: $selectedOrder) { order in
            OrderDetailSheet(order: order)
        }
        .onAppear {
            loadOrders()
        }
    }

    private func filterTitle(_ filter: OrderFilter) -> String {
        switch filter {
        case .all: return languageManager.isChinese ? "全部" : "All"
        case .pending: return languageManager.isChinese ? "待發貨" : "Pending"
        case .shipped: return languageManager.isChinese ? "運輸中" : "Shipped"
        case .delivered: return languageManager.isChinese ? "已送達" : "Delivered"
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(languageManager.isChinese ? "暫無訂單記錄" : "No Order History")
                .font(.headline)
            Text(languageManager.isChinese ? "購買商品後將顯示在這裡" : "Your orders will appear here after purchase")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private func loadOrders() {
        isLoading = true
        // TODO: Replace with actual API call
        // Task {
        //     orders = await OrderService.fetchOrders()
        //     isLoading = false
        // }

        // Mock data for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            orders = ShopifyOrder.mockData
            isLoading = false
        }
    }
}

// MARK: - Filter Chip
private struct RecentPurchaseFilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Order Card
private struct OrderCard: View {
    let order: ShopifyOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.orderNumber)
                        .font(.headline)
                    Text(order.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                RecentPurchaseStatusBadge(status: order.fulfillmentStatus)
            }

            Divider()

            // Items Preview
            HStack(spacing: 12) {
                // First item image
                if let firstItem = order.items.first {
                    AsyncImage(url: URL(string: firstItem.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(order.items.first?.name ?? "Product")
                        .font(.subheadline)
                        .lineLimit(2)

                    if order.items.count > 1 {
                        Text("+\(order.items.count - 1) more item(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("HKD \(order.totalAmount)")
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            // Tracking info
            if let trackingNumber = order.trackingNumber, !trackingNumber.isEmpty {
                HStack {
                    Image(systemName: "shippingbox")
                        .font(.caption)
                    Text(trackingNumber)
                        .font(.caption)
                    Spacer()
                    Text("Track")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.blue)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Status Badge
private struct RecentPurchaseStatusBadge: View {
    let status: FulfillmentStatus

    var body: some View {
        Text(statusText)
            .font(.caption.weight(.medium))
            .foregroundColor(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .cornerRadius(12)
    }

    private var statusText: String {
        switch status {
        case .pending: return "Pending"
        case .shipped: return "Shipped"
        case .delivered: return "Delivered"
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .shipped: return .blue
        case .delivered: return .green
        }
    }
}

// MARK: - Order Detail Sheet
private struct OrderDetailSheet: View {
    let order: ShopifyOrder
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Order Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.isChinese ? "訂單詳情" : "Order Details")
                            .font(.headline)

                        HStack {
                            Text(languageManager.isChinese ? "訂單號" : "Order Number")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(order.orderNumber)
                        }
                        .font(.subheadline)

                        HStack {
                            Text(languageManager.isChinese ? "購買日期" : "Purchase Date")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(order.formattedDate)
                        }
                        .font(.subheadline)

                        HStack {
                            Text(languageManager.isChinese ? "總金額" : "Total Amount")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("HKD \(order.totalAmount)")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // Items
                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageManager.isChinese ? "商品" : "Items")
                            .font(.headline)

                        ForEach(order.items) { item in
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                }
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.subheadline)
                                    Text("x\(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("HKD \(item.price)")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // Shipping Address
                    if let address = order.shippingAddress {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(languageManager.isChinese ? "送貨地址" : "Shipping Address")
                                .font(.headline)

                            Text(address.line1)
                            if let line2 = address.line2, !line2.isEmpty {
                                Text(line2)
                            }
                            Text("\(address.city), \(address.country)")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Tracking
                    if let tracking = order.trackingNumber, !tracking.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(languageManager.isChinese ? "物流資訊" : "Tracking")
                                .font(.headline)

                            HStack {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(.blue)
                                Text(tracking)
                                Spacer()
                                Button(languageManager.isChinese ? "查看" : "Track") {
                                    // Open tracking URL
                                }
                                .font(.caption.weight(.semibold))
                            }
                        }
                        .font(.subheadline)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle(order.orderNumber)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Shopify Order Model
struct ShopifyOrder: Codable, Identifiable {
    let id: String
    let orderNumber: String
    let shopifyOrderId: String?
    let items: [OrderItem]
    let totalAmount: String
    let currency: String
    let purchaseDate: Date
    let fulfillmentStatus: FulfillmentStatus
    let trackingNumber: String?
    let shippingAddress: ShippingAddress?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: purchaseDate)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number"
        case shopifyOrderId = "shopify_order_id"
        case items
        case totalAmount = "total_amount"
        case currency
        case purchaseDate = "purchase_date"
        case fulfillmentStatus = "fulfillment_status"
        case trackingNumber = "tracking_number"
        case shippingAddress = "shipping_address"
    }

    static var mockData: [ShopifyOrder] {
        [
            ShopifyOrder(
                id: UUID().uuidString,
                orderNumber: "SHP-12345",
                shopifyOrderId: "shopify_12345",
                items: [
                    OrderItem(id: "1", productId: "p1", name: "Premium Dog Food", quantity: 2, price: "299.00", currency: "HKD", imageUrl: nil),
                    OrderItem(id: "2", productId: "p2", name: "Dog Toy Set", quantity: 1, price: "129.00", currency: "HKD", imageUrl: nil)
                ],
                totalAmount: "727.00",
                currency: "HKD",
                purchaseDate: Date().addingTimeInterval(-86400 * 2),
                fulfillmentStatus: .shipped,
                trackingNumber: "TRACK123456789",
                shippingAddress: ShippingAddress(line1: "123 Pet Street", line2: "Flat A", city: "Hong Kong", country: "Hong Kong")
            ),
            ShopifyOrder(
                id: UUID().uuidString,
                orderNumber: "SHP-12344",
                shopifyOrderId: "shopify_12344",
                items: [
                    OrderItem(id: "3", productId: "p3", name: "Cat Litter Premium", quantity: 3, price: "159.00", currency: "HKD", imageUrl: nil)
                ],
                totalAmount: "477.00",
                currency: "HKD",
                purchaseDate: Date().addingTimeInterval(-86400 * 5),
                fulfillmentStatus: .delivered,
                trackingNumber: nil,
                shippingAddress: ShippingAddress(line1: "123 Pet Street", line2: "Flat A", city: "Hong Kong", country: "Hong Kong")
            ),
            ShopifyOrder(
                id: UUID().uuidString,
                orderNumber: "SHP-12343",
                shopifyOrderId: "shopify_12343",
                items: [
                    OrderItem(id: "4", productId: "p4", name: "Pet Bed Comfort", quantity: 1, price: "459.00", currency: "HKD", imageUrl: nil)
                ],
                totalAmount: "459.00",
                currency: "HKD",
                purchaseDate: Date(),
                fulfillmentStatus: .pending,
                trackingNumber: nil,
                shippingAddress: ShippingAddress(line1: "123 Pet Street", line2: nil, city: "Hong Kong", country: "Hong Kong")
            )
        ]
    }
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let productId: String
    let name: String
    let quantity: Int
    let price: String
    let currency: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case name
        case quantity
        case price
        case currency
        case imageUrl = "image_url"
    }
}

enum FulfillmentStatus: String, Codable {
    case pending
    case shipped
    case delivered
}

struct ShippingAddress: Codable {
    let line1: String
    let line2: String?
    let city: String
    let country: String

    enum CodingKeys: String, CodingKey {
        case line1
        case line2
        case city
        case country
    }
}

// MARK: - Order Service (Placeholder)
class OrderService {
    // TODO: Replace with actual API call
    // GET /api/shopify/orders?status=pending|shipped|delivered&page=1&limit=20

    static func fetchOrders(status: String? = nil, page: Int = 1, limit: Int = 20) async -> [ShopifyOrder] {
        // Placeholder - return mock data
        try? await Task.sleep(nanoseconds: 500_000_000)
        return ShopifyOrder.mockData
    }
}

#Preview {
    NavigationStack {
        RecentPurchaseView()
            .environmentObject(LanguageManager())
    }
}
