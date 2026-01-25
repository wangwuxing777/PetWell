//
//  InsuranceCompareView.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/12.
//

import SwiftUI
import Foundation
// Models are imported from Models/InsuranceModels.swift

// MARK: - Mock Data Repository (Matching SQL Data)

class InsuranceRepository {
    static let shared = InsuranceRepository()
    
    private init() {}
    
    let companies: [InsuranceCompany] = [
        InsuranceCompany(id: 1, nameEn: "OneDegree", nameZh: "一度保", brandType: "insurer", website: "https://www.onedegree.hk", contactPhone: "+852 2588 3388", logoUrl: nil, logoBase64: nil, notes: "Leading HK pet insurer"),
        InsuranceCompany(id: 2, nameEn: "MSIG", nameZh: "MSIG", brandType: "insurer", website: "https://www.msig.com.hk", contactPhone: "+852 2891 0898", logoUrl: nil, logoBase64: nil, notes: "Established Japanese-backed insurer"),
        InsuranceCompany(id: 3, nameEn: "AIA", nameZh: "AIA", brandType: "bank_partner", website: "https://www.aia.com.hk", contactPhone: "+852 2881 1000", logoUrl: nil, logoBase64: nil, notes: "Major regional insurer"),
        InsuranceCompany(id: 4, nameEn: "Zurich", nameZh: "Zurich", brandType: "insurer", website: "https://www.zurich.com.hk", contactPhone: "+852 2978 8000", logoUrl: nil, logoBase64: nil, notes: "Global insurer with HK presence")
    ]
    
    let products: [InsuranceProduct] = [
        InsuranceProduct(id: 1, companyId: 1, nameEn: "Pawfect Care", nameZh: "完美呵護", description: "Comprehensive pet insurance with no sub-limits", targetSegment: "both", isActive: 1, notes: "OneDegree flagship product"),
        InsuranceProduct(id: 2, companyId: 1, nameEn: "Pawfect Care (Entry)", nameZh: "完美呵護 (入門)", description: "Budget-friendly basic coverage", targetSegment: "both", isActive: 1, notes: "Entry-level product"),
        InsuranceProduct(id: 3, companyId: 2, nameEn: "Ulti-mate Pet Insurance (Dog)", nameZh: "毛價保 (狗)", description: "Multi-tier coverage with annual limits", targetSegment: "dog", isActive: 1, notes: "Popular MSIG dog insurance"),
        InsuranceProduct(id: 4, companyId: 2, nameEn: "Ulti-mate Pet Insurance (Cat)", nameZh: "毛價保 (貓)", description: "Specialized cat coverage", targetSegment: "cat", isActive: 1, notes: "MSIG cat-specific insurance"),
        InsuranceProduct(id: 5, companyId: 3, nameEn: "AIA Pet Insurance", nameZh: "AIA 寵物保險", description: "Bundled with health screening", targetSegment: "both", isActive: 1, notes: "AIA partnership product"),
        InsuranceProduct(id: 6, companyId: 4, nameEn: "Pamper U", nameZh: "毛孩 寵愛", description: "Comprehensive accident & illness coverage", targetSegment: "both", isActive: 1, notes: "Zurich premium offering")
    ]
    
    let profiles: [ProductCoverageProfile] = [
        // OneDegree - Pawfect Care
        ProductCoverageProfile(id: 1, productId: 1, typicalSurgeryCovered: 1, chronicIllnessSupported: 1, coverageVsCostNotes: "Covers most surgical procedures", annualLimitAmount: 100000, hasSubLimits: 0, subLimitStructure: nil, noSubLimitMarketingTag: 1, chronicMultiYearLimit: "Supports ongoing chronic claims", preexistingExcluded: 1, hereditaryDiseasePolicy: "Covered if no symptoms for 180 days", breedAgeRestrictions: "8 weeks - 10 years", waitingPeriodDescription: "Accident: Immediate; Illness: 14 days", inpatientSurgeryIncluded: 1, exclusionsNotes: "Routine care, breeding", typicalMonthlyPremium: 196, reimbursementPercent: 90, hasDeductible: 1, deductibleAmount: 3000, copayPercent: 0, priceValueNotes: "Excellent value", onlineClaimSupported: 1, claimProcessSpeedNote: "5-7 days", claimConvenienceNotes: "Mobile app with photo upload", brandReputationSummary: "High satisfaction", reviewSourceNotes: "Google Reviews 4.7/5",
            keyPros: "- No sub-limits\n- High reimbursement rate\n- Digital claims",
            keyCons: "- Deductible applies per condition"),
        
        // OneDegree - Happy Paws
        ProductCoverageProfile(id: 2, productId: 2, typicalSurgeryCovered: 1, chronicIllnessSupported: 0, coverageVsCostNotes: "Covers common surgeries", annualLimitAmount: 60000, hasSubLimits: 1, subLimitStructure: "Per-incident: $15k", noSubLimitMarketingTag: 0, chronicMultiYearLimit: "Limited", preexistingExcluded: 1, hereditaryDiseasePolicy: "Excluded", breedAgeRestrictions: "8 weeks - 8 years", waitingPeriodDescription: "Accident: 3 days; Illness: 14 days", inpatientSurgeryIncluded: 1, exclusionsNotes: "Routine care", typicalMonthlyPremium: 128, reimbursementPercent: 70, hasDeductible: 1, deductibleAmount: 2000, copayPercent: 0, priceValueNotes: "Budget option", onlineClaimSupported: 1, claimProcessSpeedNote: "7-10 days", claimConvenienceNotes: "Online app", brandReputationSummary: "Good for budget", reviewSourceNotes: "Google Reviews 4.5/5",
            keyPros: "- Low monthly premium\n- Digital claims",
            keyCons: "- Has sub-limits\n- Lower reimbursement rate"),
            
        // MSIG - Pet Care Plus
        ProductCoverageProfile(id: 3, productId: 3, typicalSurgeryCovered: 1, chronicIllnessSupported: 1, coverageVsCostNotes: "Strong surgical coverage", annualLimitAmount: 80000, hasSubLimits: 1, subLimitStructure: "Per-incident: $12k", noSubLimitMarketingTag: 0, chronicMultiYearLimit: "Supported", preexistingExcluded: 1, hereditaryDiseasePolicy: "Some covered", breedAgeRestrictions: "2 months - 9 years", waitingPeriodDescription: "Accident: 48h; Illness: 10 days", inpatientSurgeryIncluded: 1, exclusionsNotes: "Routine care", typicalMonthlyPremium: 178, reimbursementPercent: 75, hasDeductible: 1, deductibleAmount: 2500, copayPercent: 0, priceValueNotes: "Good balance", onlineClaimSupported: 0, claimProcessSpeedNote: "10-14 days", claimConvenienceNotes: "Paper claims", brandReputationSummary: "Established brand", reviewSourceNotes: "MSIG website",
            keyPros: "- Strong brand reputation\n- Good chronic support",
            keyCons: "- Paper claims process\n- Sub-limits apply"),
        
        // Zurich - PetShield
        ProductCoverageProfile(id: 6, productId: 6, typicalSurgeryCovered: 1, chronicIllnessSupported: 1, coverageVsCostNotes: "Premium coverage", annualLimitAmount: 120000, hasSubLimits: 0, subLimitStructure: nil, noSubLimitMarketingTag: 1, chronicMultiYearLimit: "Comprehensive", preexistingExcluded: 1, hereditaryDiseasePolicy: "Covered", breedAgeRestrictions: "6 weeks - 12 years", waitingPeriodDescription: "Accident: Immediate; Illness: 7 days", inpatientSurgeryIncluded: 1, exclusionsNotes: "Routine care", typicalMonthlyPremium: 270, reimbursementPercent: 90, hasDeductible: 0, deductibleAmount: 0, copayPercent: 0, priceValueNotes: "Premium tier", onlineClaimSupported: 1, claimProcessSpeedNote: "5-7 days", claimConvenienceNotes: "Email/Post", brandReputationSummary: "High satisfaction", reviewSourceNotes: "International reviews",
            keyPros: "- 90% reimbursement\n- High annual limit\n- No sub-limits",
            keyCons: "- Higher premium\n- No online claims portal")
    ]
    
    func getCompany(for productId: Int) -> InsuranceCompany? {
        guard let product = products.first(where: { $0.id == productId }) else { return nil }
        return companies.first(where: { $0.id == product.companyId })
    }
}

// MARK: - View Models

struct ComparisonItem: Identifiable {
    let id = UUID()
    let product: InsuranceProduct
    let company: InsuranceCompany
    let profile: ProductCoverageProfile
}

// MARK: - Main View

struct InsuranceCompareView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var languageManager: LanguageManager
    
    // State management for selected plans
    @State private var leftPlanId: Int = 1 // OneDegree Pawfect Care
    @State private var rightPlanId: Int = 6 // Zurich Pamper U
    
    // Selection Sheet State
    @State private var showSelectionSheet = false
    @State private var isSelectingLeft = true
    
    var leftItem: ComparisonItem? { getItem(for: leftPlanId) }
    var rightItem: ComparisonItem? { getItem(for: rightPlanId) }
    
    private func getItem(for id: Int) -> ComparisonItem? {
        guard let product = InsuranceRepository.shared.products.first(where: { $0.id == id }),
              let profile = InsuranceRepository.shared.profiles.first(where: { $0.productId == id }),
              let company = InsuranceRepository.shared.getCompany(for: id) else { return nil }
        return ComparisonItem(product: product, company: company, profile: profile)
    }

    var body: some View {
        ZStack {
            Color(hex: "F8F9FA").ignoresSafeArea() // Light grey background
            
            VStack(spacing: 0) {
                if let left = leftItem, let right = rightItem {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // 1. Selector Section
                            selectorSection(left: left, right: right)
                            
                            // 2. Quick Summary (Annual Limit & Premium)
                            summarySection(left: left, right: right)
                            
                            // 3. Key Pros & Cons
                            prosConsSection(left: left, right: right)
                            
                            // 4. Detailed Coverage
                            coverageDetailsSection(left: left, right: right)
                            
                            // 5. Claims & Service
                            claimsSection(left: left, right: right)
                            
                            Spacer().frame(height: 40)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Compare Insurance")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSelectionSheet) {
            CompanySelectionView(isPresented: $showSelectionSheet) { selectedProductId in
                if isSelectingLeft {
                    leftPlanId = selectedProductId
                } else {
                    rightPlanId = selectedProductId
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func selectorSection(left: ComparisonItem, right: ComparisonItem) -> some View {
        HStack(spacing: 0) {
            planHeader(company: left.company, product: left.product, isLeft: true)
            Divider()
            planHeader(company: right.company, product: right.product, isLeft: false)
        }
        .background(Color.white)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.1)), alignment: .bottom)
        .padding(.bottom, 8)
    }
    
    private func planHeader(company: InsuranceCompany, product: InsuranceProduct, isLeft: Bool) -> some View {
        VStack(spacing: 8) {
            Text(languageManager.isChinese ? (company.nameZh ?? company.nameEn) : company.nameEn)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(languageManager.isChinese ? (product.nameZh ?? product.nameEn) : product.nameEn)
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)

            Button(action: {
                isSelectingLeft = isLeft
                showSelectionSheet = true
            }) {
                Text(languageManager.isChinese ? "更換" : "Change")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "E9ECEF"))
                    .cornerRadius(12)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // Cycle through mock data for demo purposes
    private func cyclePlan(isLeft: Bool) {
        let allIds = InsuranceRepository.shared.profiles.map { $0.productId }
        if isLeft {
            if let index = allIds.firstIndex(of: leftPlanId) {
                leftPlanId = allIds[(index + 1) % allIds.count]
                if leftPlanId == rightPlanId { cyclePlan(isLeft: true) }
            }
        } else {
            if let index = allIds.firstIndex(of: rightPlanId) {
                rightPlanId = allIds[(index + 1) % allIds.count]
                if rightPlanId == leftPlanId { cyclePlan(isLeft: false) }
            }
        }
    }
    
    private func summarySection(left: ComparisonItem, right: ComparisonItem) -> some View {
        VStack(spacing: 0) {
            rowHeader(languageManager.isChinese ? "費用與限額" : "Costs & Limits")
            
            comparisonRow(title: languageManager.isChinese ? "年度限額" : "Annual Limit",
                          left: formatCurrency(left.profile.annualLimitAmount),
                          right: formatCurrency(right.profile.annualLimitAmount),
                          isHighlight: true)
            
            comparisonRow(title: languageManager.isChinese ? "預計月費" : "Est. Monthly Premium",
                          left: formatCurrency(left.profile.typicalMonthlyPremium),
                          right: formatCurrency(right.profile.typicalMonthlyPremium))
            
            comparisonRow(title: languageManager.isChinese ? "賠償比例" : "Reimbursement",
                          left: "\(left.profile.reimbursementPercent ?? 0)%",
                          right: "\(right.profile.reimbursementPercent ?? 0)%",
                          isHighlight: true)
            
            comparisonRow(title: languageManager.isChinese ? "自付額" : "Deductible",
                          left: formatDeductible(amount: left.profile.deductibleAmount),
                          right: formatDeductible(amount: right.profile.deductibleAmount))
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func prosConsSection(left: ComparisonItem, right: ComparisonItem) -> some View {
        VStack(spacing: 0) {
            rowHeader(languageManager.isChinese ? "優缺點比較" : "Key Pros & Cons")
            
            HStack(alignment: .top, spacing: 0) {
                prosConsCell(pros: left.profile.keyPros, cons: left.profile.keyCons)
                Divider()
                prosConsCell(pros: right.profile.keyPros, cons: right.profile.keyCons)
            }
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func prosConsCell(pros: String?, cons: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let pros = pros {
                VStack(alignment: .leading, spacing: 4) {
                    Label(languageManager.isChinese ? "優點" : "Pros", systemImage: "hand.thumbsup.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(pros)
                        .font(.system(size: 13))
                        .lineSpacing(2)
                }
            }
            
            if let cons = cons {
                VStack(alignment: .leading, spacing: 4) {
                    Label(languageManager.isChinese ? "缺點" : "Cons", systemImage: "hand.thumbsdown.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(cons)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func coverageDetailsSection(left: ComparisonItem, right: ComparisonItem) -> some View {
        VStack(spacing: 0) {
            rowHeader(languageManager.isChinese ? "保單詳情" : "Policy Details")
            
            comparisonRow(title: languageManager.isChinese ? "細項限額" : "Sub-Limits",
                          left: left.profile.hasSubLimits == 1 ? (left.profile.subLimitStructure ?? (languageManager.isChinese ? "有" : "Yes")) : (languageManager.isChinese ? "無" : "None"),
                          right: right.profile.hasSubLimits == 1 ? (right.profile.subLimitStructure ?? (languageManager.isChinese ? "有" : "Yes")) : (languageManager.isChinese ? "無" : "None"))
            
            comparisonRow(title: languageManager.isChinese ? "慢性疾病" : "Chronic Conditions",
                          left: left.profile.chronicIllnessSupported == 1 ? (languageManager.isChinese ? "承保" : "Covered") : (languageManager.isChinese ? "不承保" : "Excluded"),
                          right: right.profile.chronicIllnessSupported == 1 ? (languageManager.isChinese ? "承保" : "Covered") : (languageManager.isChinese ? "不承保" : "Excluded"))
            
            comparisonRow(title: languageManager.isChinese ? "等候期" : "Waiting Periods",
                          left: left.profile.waitingPeriodDescription ?? "-",
                          right: right.profile.waitingPeriodDescription ?? "-")
                          
            comparisonRow(title: languageManager.isChinese ? "遺傳疾病" : "Hereditary Conditions",
                          left: left.profile.hereditaryDiseasePolicy ?? "-",
                          right: right.profile.hereditaryDiseasePolicy ?? "-")
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func claimsSection(left: ComparisonItem, right: ComparisonItem) -> some View {
        VStack(spacing: 0) {
            rowHeader(languageManager.isChinese ? "理賠體驗" : "Claims Experience")
            
            comparisonRow(title: languageManager.isChinese ? "網上理賠" : "Online Claims",
                          left: left.profile.onlineClaimSupported == 1 ? (languageManager.isChinese ? "有 (App/Web)" : "Yes (App/Web)") : (languageManager.isChinese ? "無 (需填表)" : "No (Paper)"),
                          right: right.profile.onlineClaimSupported == 1 ? (languageManager.isChinese ? "有 (App/Web)" : "Yes (App/Web)") : (languageManager.isChinese ? "無 (需填表)" : "No (Paper)"))
                          
            comparisonRow(title: languageManager.isChinese ? "處理時間" : "Processing Time",
                          left: left.profile.claimProcessSpeedNote ?? "-",
                          right: right.profile.claimProcessSpeedNote ?? "-")
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Views
    
    private func rowHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(hex: "F1F3F5"))
    }
    
    private func comparisonRow(title: String, left: String, right: String, isHighlight: Bool = false) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            
            HStack(alignment: .top, spacing: 0) {
                Text(left)
                    .font(.system(size: 14, weight: isHighlight ? .bold : .regular))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                
                Divider().frame(height: 20)
                
                Text(right)
                    .font(.system(size: 14, weight: isHighlight ? .bold : .regular))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
            }
            .padding(.bottom, 8)
            
            Divider()
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatCurrency(_ amount: Int?) -> String {
        guard let amount = amount else { return "-" }
        return "HK$\(amount)"
    }
    
    private func formatDeductible(amount: Int?) -> String {
        guard let amount = amount, amount > 0 else { return "HK$0" }
        return "HK$\(amount)"
    }
}


// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Selection Views

struct CompanySelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationView {
            List(InsuranceRepository.shared.companies, id: \.id) { company in
                NavigationLink(destination: ProductSelectionView(companyId: company.id, isPresented: $isPresented, onSelect: onSelect).environmentObject(languageManager)) {
                    HStack {
                        if company.logoUrl != nil {
                             // Placeholder for AsyncImage or similar if needed, using text for now
                             Text(String(company.nameEn.prefix(1)))
                                 .frame(width: 30, height: 30)
                                 .background(Color.gray.opacity(0.3))
                                 .clipShape(Circle())
                        }
                        VStack(alignment: .leading) {
                            Text(languageManager.isChinese ? (company.nameZh ?? company.nameEn) : company.nameEn).font(.headline)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(languageManager.isChinese ? "選擇保險公司" : "Select Company")
            .navigationBarItems(trailing: Button(languageManager.isChinese ? "取消" : "Cancel") {
                isPresented = false
            })
        }
    }
}

struct ProductSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    let companyId: Int
    @Binding var isPresented: Bool
    let onSelect: (Int) -> Void
    
    var products: [InsuranceProduct] {
        InsuranceRepository.shared.products.filter { $0.companyId == companyId }
    }
    
    var body: some View {
        List(products, id: \.id) { product in
            Button(action: {
                onSelect(product.id)
                isPresented = false
            }) {
                VStack(alignment: .leading) {
                    Text(languageManager.isChinese ? (product.nameZh ?? product.nameEn) : product.nameEn).font(.headline).foregroundColor(.primary)
                    Text(product.description ?? "").font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(languageManager.isChinese ? "選擇產品" : "Select Product")
    }
}
