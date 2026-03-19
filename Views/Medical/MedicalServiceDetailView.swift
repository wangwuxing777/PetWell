import Combine
import SwiftUI

// MARK: - API Model

struct MedicalServiceDetail: Codable, Identifiable {
    let id: String
    let category: String
    let name: String
    let nameZh: String
    let icon: String
    let colorHex: String
    let description: String
    let descZh: String
    let contentJSON: String   // Raw JSON string — decoded into [String: Any] at render time
    let provider: String
    let contact: String
    let isActive: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, category, name, icon, description, provider, contact
        case nameZh       = "name_zh"
        case colorHex     = "color_hex"
        case descZh       = "desc_zh"
        case contentJSON  = "content_json"
        case isActive     = "is_active"
        case sortOrder    = "sort_order"
    }
}

// MARK: - Service Store

@MainActor
class MedicalServiceStore: ObservableObject {
    static let shared = MedicalServiceStore()

    @Published var cache: [String: MedicalServiceDetail] = [:]
    @Published var loading: Set<String> = []

    private let baseURL = "http://localhost:8000"

    func fetch(category: String) async {
        guard cache[category] == nil, !loading.contains(category) else { return }
        loading.insert(category)
        defer { loading.remove(category) }

        guard let url = URL(string: "\(baseURL)/api/medical/services/\(category)") else { return }
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let detail = try? JSONDecoder().decode(MedicalServiceDetail.self, from: data) {
            cache[category] = detail
        }
    }
}

// MARK: - Main View

struct MedicalServiceDetailView: View {
    let category: String
    let fallbackTitle: String

    @StateObject private var store = MedicalServiceStore.shared

    private var detail: MedicalServiceDetail? { store.cache[category] }
    private var isLoading: Bool { store.loading.contains(category) }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 80)
                    .frame(maxWidth: .infinity)
            } else if let detail {
                LoadedView(detail: detail)
            } else {
                // Fallback if API is unreachable
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text(fallbackTitle)
                        .font(.title2.weight(.bold))
                    Text("Content will appear once the server is running.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 80)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(detail?.name ?? fallbackTitle)
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBarWhenPushed()
        .task { await store.fetch(category: category) }
    }
}

// MARK: - Loaded Content

private struct LoadedView: View {
    let detail: MedicalServiceDetail

    // Parse content_json once
    private var content: [String: Any] {
        guard let data = detail.contentJSON.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return obj
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero header
            HeroHeader(detail: detail)

            VStack(alignment: .leading, spacing: 24) {
                // Overview
                if let overview = content["overview"] as? String {
                    SectionBlock(title: "Overview", icon: "info.circle.fill", color: .blue) {
                        Text(overview)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Frequency
                if let freq = content["frequency"] as? String {
                    SectionBlock(title: "Recommended Frequency", icon: "clock.fill", color: .orange) {
                        Text(freq)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                    }
                }

                // Generic list fields: steps, home_care, pre_op_checklist, when_to_call_the_vet, when_to_test, signs_of_dental_disease, important
                let listKeys: [(key: String, title: String, icon: String, color: Color)] = [
                    ("steps",               "Steps",                  "list.number",          .blue),
                    ("home_care",           "Home Care",              "house.fill",            .green),
                    ("pre_op_checklist",    "Pre-Op Checklist",       "checklist",             .purple),
                    ("post_op_care",        "Post-Op Care",           "heart.text.square.fill",.pink),
                    ("when_to_call_the_vet","When to Call the Vet",   "phone.fill",            .red),
                    ("when_to_test",        "When to Test",           "calendar.badge.clock",  .indigo),
                    ("signs_of_dental_disease", "Signs to Watch",     "exclamationmark.triangle.fill", .orange),
                ]

                ForEach(listKeys, id: \.key) { item in
                    if let list = content[item.key] as? [String], !list.isEmpty {
                        SectionBlock(title: item.title, icon: item.icon, color: item.color) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(list, id: \.self) { step in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(item.color)
                                            .font(.system(size: 14))
                                            .padding(.top, 2)
                                        Text(step)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }

                // Products table (deworming)
                if let products = content["products"] as? [[String: Any]], !products.isEmpty {
                    SectionBlock(title: "Products & Pricing", icon: "pills.fill", color: .green) {
                        VStack(spacing: 10) {
                            ForEach(products.indices, id: \.self) { i in
                                ProductRow(item: products[i])
                            }
                        }
                    }
                }

                // Services table (dental, nutrition)
                if let services = content["services"] as? [[String: Any]], !services.isEmpty {
                    SectionBlock(title: "Services & Pricing", icon: "stethoscope", color: .orange) {
                        VStack(spacing: 10) {
                            ForEach(services.indices, id: \.self) { i in
                                ServiceRow(item: services[i])
                            }
                        }
                    }
                }

                // Panels table (lab tests)
                if let panels = content["panels"] as? [[String: Any]], !panels.isEmpty {
                    SectionBlock(title: "Test Panels", icon: "testtube.2", color: .indigo) {
                        VStack(spacing: 10) {
                            ForEach(panels.indices, id: \.self) { i in
                                PanelRow(item: panels[i])
                            }
                        }
                    }
                }

                // Surgery procedures
                if let surgeries = content["common_surgeries"] as? [[String: Any]], !surgeries.isEmpty {
                    SectionBlock(title: "Common Procedures", icon: "cross.vial.fill", color: .pink) {
                        VStack(spacing: 10) {
                            ForEach(surgeries.indices, id: \.self) { i in
                                SurgeryRow(item: surgeries[i])
                            }
                        }
                    }
                }

                // Consultation types (nutrition)
                if let consultations = content["consultation_types"] as? [[String: Any]], !consultations.isEmpty {
                    SectionBlock(title: "Consultation Options", icon: "person.fill.questionmark", color: .mint) {
                        VStack(spacing: 10) {
                            ForEach(consultations.indices, id: \.self) { i in
                                ConsultationRow(item: consultations[i])
                            }
                        }
                    }
                }

                // HK Legal (microchip)
                if let legal = content["legal_requirements_hk"] as? [String: Any] {
                    SectionBlock(title: "HK Legal Requirements", icon: "building.columns.fill", color: .teal) {
                        VStack(alignment: .leading, spacing: 8) {
                            if let dogs = legal["dogs"] as? String {
                                Label(dogs, systemImage: "pawprint.fill").font(.subheadline).foregroundColor(.secondary)
                            }
                            if let cats = legal["cats"] as? String {
                                Label(cats, systemImage: "pawprint").font(.subheadline).foregroundColor(.secondary)
                            }
                            if let penalty = legal["penalty"] as? String {
                                Label(penalty, systemImage: "exclamationmark.triangle.fill")
                                    .font(.subheadline).foregroundColor(.red)
                            }
                        }
                    }
                }

                // Important note (microchip)
                if let important = content["important"] as? String {
                    SectionBlock(title: "Important", icon: "exclamationmark.circle.fill", color: .red) {
                        Text(important)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Procedure (microchip)
                if let proc = content["procedure"] as? [String: Any] {
                    SectionBlock(title: "Procedure", icon: "syringe.fill", color: .teal) {
                        VStack(alignment: .leading, spacing: 6) {
                            if let duration = proc["duration"] as? String { KeyValueRow(k: "Duration", v: duration) }
                            if let anaesthesia = proc["anaesthesia"] as? String { KeyValueRow(k: "Anaesthesia", v: anaesthesia) }
                            if let price = proc["price_hkd"] as? String { KeyValueRow(k: "Price (HKD)", v: price) }
                            if let pain = proc["pain_level"] as? String { KeyValueRow(k: "Pain Level", v: pain) }
                        }
                    }
                }

                // Provider footer
                if !detail.provider.isEmpty {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.secondary)
                        Text("Provided by \(detail.provider)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Hero Header

private struct HeroHeader: View {
    let detail: MedicalServiceDetail

    private var accentColor: Color {
        detail.colorHex.isEmpty ? .blue : Color(hex: detail.colorHex)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(LinearGradient(
                    colors: [accentColor.opacity(0.85), accentColor.opacity(0.5)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 160)

            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: detail.icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                Text(detail.description.isEmpty ? detail.name : detail.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
    }
}

// MARK: - Section Block

private struct SectionBlock<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            .padding(.horizontal, 20)

            content
                .padding(.horizontal, 20)

            Divider()
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Row helpers

private struct ProductRow: View {
    let item: [String: Any]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item["name"] as? String ?? "")
                .font(.subheadline.weight(.semibold))
            HStack {
                if let dose = item["dose"] as? String { Text(dose).font(.caption).foregroundColor(.secondary) }
                Spacer()
                if let price = item["price_hkd"] as? Int {
                    Text("HK$\(price)").font(.caption.weight(.bold)).foregroundColor(.green)
                }
            }
            if let covers = item["covers"] as? String {
                Text(covers).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
    }
}

private struct ServiceRow: View {
    let item: [String: Any]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item["name"] as? String ?? "")
                .font(.subheadline.weight(.semibold))
            HStack {
                if let duration = item["duration"] as? String { Text(duration).font(.caption).foregroundColor(.secondary) }
                Spacer()
                if let price = item["price_hkd"] as? String {
                    Text("HK$\(price)").font(.caption.weight(.bold)).foregroundColor(.orange)
                }
            }
            if let note = item["note"] as? String {
                Text(note).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
    }
}

private struct PanelRow: View {
    let item: [String: Any]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item["name"] as? String ?? "")
                .font(.subheadline.weight(.semibold))
            if let tests = item["tests"] as? [String] {
                Text(tests.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack {
                if let turnaround = item["turnaround"] as? String {
                    Label(turnaround, systemImage: "clock").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if let price = item["price_hkd"] as? String {
                    Text("HK$\(price)").font(.caption.weight(.bold)).foregroundColor(.indigo)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
    }
}

private struct SurgeryRow: View {
    let item: [String: Any]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item["name"] as? String ?? "")
                .font(.subheadline.weight(.semibold))
            HStack {
                if let duration = item["duration"] as? String { Text(duration).font(.caption).foregroundColor(.secondary) }
                Spacer()
                if let price = item["price_hkd"] as? String {
                    Text("HK$\(price)").font(.caption.weight(.bold)).foregroundColor(.pink)
                }
            }
            if let recovery = item["recovery"] as? String {
                Label("Recovery: \(recovery)", systemImage: "heart.fill")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
    }
}

private struct ConsultationRow: View {
    let item: [String: Any]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item["name"] as? String ?? "")
                .font(.subheadline.weight(.semibold))
            if let format = item["format"] as? String { Text(format).font(.caption).foregroundColor(.secondary) }
            HStack {
                if let includes = item["includes"] as? [String] {
                    Text(includes.joined(separator: " · "))
                        .font(.caption).foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if let price = item["price_hkd"] as? Int {
                    Text("HK$\(price)").font(.caption.weight(.bold)).foregroundColor(.mint)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
    }
}

private struct KeyValueRow: View {
    let k: String
    let v: String
    var body: some View {
        HStack {
            Text(k).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(v).font(.subheadline.weight(.medium))
        }
    }
}

