//
//  PetCareTipsView.swift
//  PetWell
//
//  Created by Frontend Engineer on 2026/03/04.
//

import SwiftUI

struct PetCareTipsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var tips: [PetCareTip] = []
    @State private var selectedSpecies: String = "all"
    @State private var isLoading = false
    @State private var selectedCategory: TipCategory?

    let species = ["all", "dog", "cat", "bird", "rabbit"]

    var filteredTips: [PetCareTip] {
        if selectedSpecies == "all" {
            return tips
        }
        return tips.filter { $0.applicableSpecies.contains(selectedSpecies) || $0.applicableSpecies.contains("all") }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Species Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(species, id: \.self) { species in
                            SpeciesFilterButton(
                                title: speciesTitle(species),
                                icon: speciesIcon(species),
                                isSelected: selectedSpecies == species
                            ) {
                                selectedSpecies = species
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemBackground))

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Categories
                            if selectedCategory == nil {
                                categoryGrid
                            }

                            // Tips List
                            if let category = selectedCategory {
                                tipsForCategory(category)
                            } else {
                                ForEach(TipCategory.allCases) { category in
                                    Section {
                                        ForEach(tipsForCategory(category)) { tip in
                                            TipCard(tip: tip, isChinese: languageManager.isChinese)
                                        }
                                    } header: {
                                        CategoryHeader(
                                            category: category,
                                            isChinese: languageManager.isChinese
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(languageManager.isChinese ? "護理提示" : "Pet Care Tips")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedCategory != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            selectedCategory = nil
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
            .onAppear {
                loadTips()
            }
        }
    }

    // MARK: - Category Grid
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.isChinese ? "類別" : "Categories")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TipCategory.allCases) { category in
                    CategoryCard(
                        category: category,
                        tipCount: tips.filter { $0.category == category }.count,
                        isChinese: languageManager.isChinese
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Tips for Category
    private func tipsForCategory(_ category: TipCategory) -> [PetCareTip] {
        filteredTips.filter { $0.category == category }
    }

    // MARK: - Helper Functions
    private func speciesTitle(_ species: String) -> String {
        switch species {
        case "all": return languageManager.isChinese ? "全部" : "All"
        case "dog": return languageManager.isChinese ? "狗" : "Dog"
        case "cat": return languageManager.isChinese ? "貓" : "Cat"
        case "bird": return languageManager.isChinese ? "鳥" : "Bird"
        case "rabbit": return languageManager.isChinese ? "兔" : "Rabbit"
        default: return species
        }
    }

    private func speciesIcon(_ species: String) -> String {
        switch species {
        case "all": return "pawprint.fill"
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        case "bird": return "bird.fill"
        case "rabbit": return "hare.fill"
        default: return "pawprint.fill"
        }
    }

    private func loadTips() {
        isLoading = true
        // Mock data for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tips = PetCareTip.mockData
            isLoading = false
        }
    }
}

// MARK: - Species Filter Button
private struct SpeciesFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Category Card
private struct CategoryCard: View {
    let category: TipCategory
    let tipCount: Int
    let isChinese: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundColor(category.color)
                }

                Text(category.displayName(isChinese))
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(tipCount) tips")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Category Header
private struct CategoryHeader: View {
    let category: TipCategory
    let isChinese: Bool

    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
            Text(category.displayName(isChinese))
                .font(.headline)
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Tip Card
private struct TipCard: View {
    let tip: PetCareTip
    let isChinese: Bool

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(tip.category.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: tip.category.icon)
                            .font(.body)
                            .foregroundColor(tip.category.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        // Species Tags
                        HStack(spacing: 4) {
                            ForEach(tip.applicableSpecies, id: \.self) { species in
                                Text(speciesTag(species))
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isChinese ? "詳情" : "Details")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(tip.content)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    if let tip2 = tip.tip2, !tip2.isEmpty {
                        Text(tip2)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Importance Level
                    HStack {
                        Text(isChinese ? "重要性" : "Importance:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(1...3, id: \.self) { level in
                            Image(systemName: level <= tip.importanceLevel ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(level <= tip.importanceLevel ? .yellow : .gray)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.leading, 52)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func speciesTag(_ species: String) -> String {
        switch species {
        case "dog": return isChinese ? "狗" : "Dog"
        case "cat": return isChinese ? "貓" : "Cat"
        case "bird": return isChinese ? "鳥" : "Bird"
        case "rabbit": return isChinese ? "兔" : "Rabbit"
        default: return species
        }
    }
}

// MARK: - Models
enum TipCategory: String, CaseIterable, Identifiable {
    case nutrition
    case health
    case grooming
    case exercise
    case safety
    case training

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .nutrition: return "fork.knife"
        case .health: return "heart.text.square"
        case .grooming: return "scissors"
        case .exercise: return "figure.walk"
        case .safety: return "shield.checkered"
        case .training: return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .nutrition: return .orange
        case .health: return .red
        case .grooming: return .purple
        case .exercise: return .blue
        case .safety: return .green
        case .training: return .cyan
        }
    }

    func displayName(_ isChinese: Bool) -> String {
        switch self {
        case .nutrition: return isChinese ? "營養" : "Nutrition"
        case .health: return isChinese ? "健康" : "Health"
        case .grooming: return isChinese ? "美容" : "Grooming"
        case .exercise: return isChinese ? "運動" : "Exercise"
        case .safety: return isChinese ? "安全" : "Safety"
        case .training: return isChinese ? "訓練" : "Training"
        }
    }
}

struct PetCareTip: Identifiable {
    let id: String
    let title: String
    let content: String
    let tip2: String?
    let category: TipCategory
    let importanceLevel: Int // 1-3
    let applicableSpecies: [String]

    static var mockData: [PetCareTip] {
        [
            // Nutrition
            PetCareTip(
                id: "1",
                title: "選擇優質寵物食品",
                content: "選擇符合寵物年齡、體重和健康狀況的優質寵物食品。查看成分表，確保肉類是首要成分。",
                tip2: "避免含有過多穀物或人工添加劑的食品。",
                category: .nutrition,
                importanceLevel: 3,
                applicableSpecies: ["all"]
            ),
            PetCareTip(
                id: "2",
                title: "定時餵食",
                content: "建立固定的餵食時間表，成年狗每日餵食2次，貓咪可以自由進食或少量多餐。",
                tip2: nil,
                category: .nutrition,
                importanceLevel: 2,
                applicableSpecies: ["dog", "cat"]
            ),
            PetCareTip(
                id: "3",
                title: "新鮮水源",
                content: "始終確保寵物有乾淨的新鮮飲用水。每天更換水源並清洗水碗。",
                tip2: "貓咪可能喜歡流動水，考慮使用寵物飲水機。",
                category: .nutrition,
                importanceLevel: 3,
                applicableSpecies: ["all"]
            ),

            // Health
            PetCareTip(
                id: "4",
                title: "定期疫苗注射",
                content: "按照獸醫建議的時間表為寵物注射疫苗，預防狂犬病、犬瘟熱、貓流感等疾病。",
                tip2: nil,
                category: .health,
                importanceLevel: 3,
                applicableSpecies: ["dog", "cat"]
            ),
            PetCareTip(
                id: "5",
                title: "驅蟲預防",
                content: "定期使用驅蟲藥物，預防跳蚤、蜱蟲和腸道寄生蟲。",
                tip2: "每月一次外用驅蟲，每3個月一次口服驅蟲藥。",
                category: .health,
                importanceLevel: 3,
                applicableSpecies: ["dog", "cat"]
            ),
            PetCareTip(
                id: "6",
                title: "年度健康檢查",
                content: "每年帶寵物進行一次全面健康檢查，包括血液檢查、牙齒檢查等。",
                tip2: "老年寵物可能需要更頻繁的檢查。",
                category: .health,
                importanceLevel: 2,
                applicableSpecies: ["all"]
            ),

            // Grooming
            PetCareTip(
                id: "7",
                title: "定期梳毛",
                content: "根據寵物毛髮類型定期梳毛，長毛寵物每日一次，短毛寵物每週2-3次。",
                tip2: "梳毛可以促進血液循環並建立與寵物的情感聯繫。",
                category: .grooming,
                importanceLevel: 2,
                applicableSpecies: ["dog", "cat", "rabbit"]
            ),
            PetCareTip(
                id: "8",
                title: "牙齒護理",
                content: "每週為寵物刷牙2-3次，使用專用寵物牙刷和牙膏。",
                tip2: "牙齒問題可能導致更嚴重的健康問題，切勿忽視。",
                category: .grooming,
                importanceLevel: 3,
                applicableSpecies: ["dog", "cat"]
            ),
            PetCareTip(
                id: "9",
                title: "指甲修剪",
                content: "每2-4週為狗修剪指甲，貓咪可以使用貓抓板自助磨爪。",
                tip2: "過長的指甲可能導致疼痛和行走問題。",
                category: .grooming,
                importanceLevel: 2,
                applicableSpecies: ["dog", "cat"]
            ),

            // Exercise
            PetCareTip(
                id: "10",
                title: "每日運動",
                content: "狗需要每日至少30分鐘到2小時的運動，視品種和年齡而定。",
                tip2: "運動不足可能導致肥胖和行為問題。",
                category: .exercise,
                importanceLevel: 3,
                applicableSpecies: ["dog"]
            ),
            PetCareTip(
                id: "11",
                title: "互動遊戲",
                content: "使用玩具與貓咪互動遊戲，每日至少15-20分鐘。",
                tip2: "互動遊戲有助於消耗精力並預防肥胖。",
                category: .exercise,
                importanceLevel: 2,
                applicableSpecies: ["cat"]
            ),

            // Safety
            PetCareTip(
                id: "12",
                title: "寵物晶片",
                content: "為寵物植入晶片並登記資料，確保走失時可以順利尋回。",
                tip2: nil,
                category: .safety,
                importanceLevel: 3,
                applicableSpecies: ["all"]
            ),
            PetCareTip(
                id: "13",
                title: "安全環境",
                content: "確保家居環境安全，收好電線、清潔用品和小型物件。",
                tip2: "某些室內植物對寵物有毒，需妥善處理。",
                category: .safety,
                importanceLevel: 3,
                applicableSpecies: ["all"]
            ),
            PetCareTip(
                id: "14",
                title: "項圈和名牌",
                content: "為寵物佩戴帶有名牌或聯繫方式的項圈。",
                tip2: nil,
                category: .safety,
                importanceLevel: 2,
                applicableSpecies: ["dog", "cat"]
            ),

            // Training
            PetCareTip(
                id: "15",
                title: "基本服從訓練",
                content: "教導寵物基本指令如「坐下」、「留下」、「過來」。",
                tip2: "正向強化是最有效的訓練方法。",
                category: .training,
                importanceLevel: 2,
                applicableSpecies: ["dog"]
            ),
            PetCareTip(
                id: "16",
                title: "社交化訓練",
                content: "讓寵物從小接觸不同的人、動物和環境。",
                tip2: "良好的社交化可以預防行為問題。",
                category: .training,
                importanceLevel: 2,
                applicableSpecies: ["dog", "cat"]
            ),
            PetCareTip(
                id: "17",
                title: "正確認識錯誤",
                content: "錯誤發生時當場處罰最有效，過度處罰可能適得其反。",
                tip2: "記住，責罵無法讓寵物明白正確行為。",
                category: .training,
                importanceLevel: 1,
                applicableSpecies: ["dog", "cat"]
            )
        ]
    }
}

// MARK: - Tip Service
class TipService {
    // TODO: Connect to backend API
    // GET /api/tips?species=dog&category=nutrition

    static func fetchTips(species: String? = nil, category: String? = nil) async -> [PetCareTip] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return PetCareTip.mockData
    }
}

#Preview {
    PetCareTipsView()
        .environmentObject(LanguageManager())
}
