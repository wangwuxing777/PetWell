//
//  InsuranceCompareView.swift
//  PetWell
//
//  Created by Yu Fang on 2026/1/12.
//

import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

struct InsuranceCompareView: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var languageManager: LanguageManager
  @ObservedObject var insuranceService = InsuranceService.shared

  // Default selection keys (Product IDs)
  @State private var leftProductId: Int?
  @State private var rightProductId: Int?

  // Sheet control
  @State private var showSelectionSheet = false
  @State private var isSelectingLeft = true

  // Remark sheet control
  @State private var showRemarkSheet = false
  @State private var selectedRemark: String = ""
  @State private var selectedRemarkData: RemarkData?
  @State private var selectedRemarkTitle: String = ""

  // Scroll tracking
  @State private var scrollOffset: CGFloat = 0
  private let providerHeaderHeight: CGFloat = 280

  // Show mini header when provider cards are halfway scrolled off
  private var showMiniHeader: Bool {
    scrollOffset > providerHeaderHeight / 2
  }

  // Helpers to get current product and company
  var leftProduct: InsuranceProduct? {
    guard let id = leftProductId else { return nil }
    return insuranceService.products.first { $0.insuranceId == id }
  }

  var leftCompany: InsuranceCompany? {
    guard let product = leftProduct else { return nil }
    return insuranceService.getCompany(forProduct: product)
  }

  var rightProduct: InsuranceProduct? {
    guard let id = rightProductId else { return nil }
    return insuranceService.products.first { $0.insuranceId == id }
  }

  var rightCompany: InsuranceCompany? {
    guard let product = rightProduct else { return nil }
    return insuranceService.getCompany(forProduct: product)
  }

  var body: some View {
    ZStack(alignment: .top) {
      Color(hex: "F8F9FA").ignoresSafeArea()  // Light grey background

      if insuranceService.isLoading {
        ProgressView("Loading policies...")
      } else if let error = insuranceService.errorMessage {
        VStack {
          Text("Error loading data")
          Text(error).font(.caption).foregroundColor(.red)
          Button("Retry") {
            Task { await insuranceService.loadAllData() }
          }
        }
      } else {
        contentView
      }

      // Mini sticky header (appears when scrolled)
      if showMiniHeader {
        miniHeader
          .transition(
            .asymmetric(
              insertion: .move(edge: .top).combined(with: .opacity),
              removal: .move(edge: .top).combined(with: .opacity)
            )
          )
          .zIndex(100)
      }
    }
    .animation(.easeInOut(duration: 0.25), value: showMiniHeader)
    .navigationTitle("Coverage Breakdown")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .onAppear {
      // Set defaults if not set
      if leftProductId == nil, let first = insuranceService.products.first {
        leftProductId = first.insuranceId
      }
      if rightProductId == nil, insuranceService.products.count > 1 {
        // Find a product from a different company if possible
        if let first = insuranceService.products.first {
          rightProductId =
            insuranceService.products.first(where: { $0.providerId != first.providerId })?
            .insuranceId
            ?? insuranceService.products[1].insuranceId
        }
      }
    }
    .sheet(isPresented: $showSelectionSheet) {
      ProviderSelectionView(isPresented: $showSelectionSheet) { selectedId in
        if isSelectingLeft {
          leftProductId = selectedId
        } else {
          rightProductId = selectedId
        }
      }
    }
    .sheet(isPresented: $showRemarkSheet) {
      RemarkSheetView(
        title: selectedRemarkTitle,
        remark: selectedRemark,
        remarkData: selectedRemarkData,
        isPresented: $showRemarkSheet
      )
    }
  }

  private var contentView: some View {
    ScrollView {
      VStack(spacing: 24) {

        // 1. Provider & Top Level Limit
        providerHeaderSection

        // 2. Coverage Breakdown
        coverageBreakdownSection

        // 3. AI Interpretation
        aiInterpretationCard

        Spacer().frame(height: 40)
      }
      .padding(.vertical)
      .overlay(alignment: .top) {
        GeometryReader { geo in
          Color.clear
            .preference(
              key: ScrollOffsetPreferenceKey.self,
              value: -geo.frame(in: .named("scroll")).origin.y
            )
        }
      }
    }
    .coordinateSpace(name: "scroll")
    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
      scrollOffset = value
    }
  }

  // MARK: - Mini Sticky Header

  private var miniHeader: some View {
    VStack(spacing: 0) {
      // Provider cards row
      HStack(spacing: 0) {
        // Left provider mini card
        if let product = leftProduct, let company = leftCompany {
          miniProviderCard(product: product, company: company, isLeft: true)
        }

        // Divider
        Divider()
          .frame(height: 50)

        // Right provider mini card
        if let product = rightProduct, let company = rightCompany {
          miniProviderCard(product: product, company: company, isLeft: false)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .frame(maxWidth: .infinity)
    .background(Color(UIColor.systemBackground))  // Same as navigation bar
  }

  private func miniProviderCard(product: InsuranceProduct, company: InsuranceCompany, isLeft: Bool)
    -> some View
  {
    VStack(spacing: 4) {
      // Company and plan name centered
      VStack(spacing: 2) {
        Text(company.companyName)
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.primary)
          .lineLimit(1)

        Text(product.insuranceName)
          .font(.system(size: 11))
          .foregroundColor(.secondary)
          .lineLimit(1)
      }
      .multilineTextAlignment(.center)

      // Change button centered below
      Button(action: {
        isSelectingLeft = isLeft
        showSelectionSheet = true
      }) {
        Text("Change")
          .font(.system(size: 12, weight: .medium))
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.1))
          .foregroundColor(.blue)
          .cornerRadius(6)
      }
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - 1. Provider Header

  private var providerHeaderSection: some View {
    HStack(spacing: 0) {
      // Left Provider
      if let product = leftProduct, let company = leftCompany {
        providerHeaderCell(product: product, company: company, isLeft: true)
      } else {
        emptyHeaderCell(isLeft: true)
      }

      Divider()

      // Right Provider
      if let product = rightProduct, let company = rightCompany {
        providerHeaderCell(product: product, company: company, isLeft: false)
      } else {
        emptyHeaderCell(isLeft: false)
      }
    }
    .background(Color.white)
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    .padding(.horizontal)
  }

  private func providerHeaderCell(
    product: InsuranceProduct, company: InsuranceCompany, isLeft: Bool
  ) -> some View {
    VStack(spacing: 12) {
      // Placeholder Image or Logo
      // Note: Ideally load from company.companyLogo URL
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.1))
        .aspectRatio(1.0, contentMode: .fit)
        .frame(width: 80)
        .overlay(
          Image(systemName: "photo")
            .foregroundColor(.gray.opacity(0.5))
        )
        .padding(.top, 16)

      // Provider Name
      VStack(spacing: 4) {
        Text("INSURANCE PROVIDER")
          .font(.system(size: 10, weight: .bold))
          .foregroundColor(.secondary)
          .tracking(0.5)

        Text(company.companyName)
          .font(.system(size: 14, weight: .semibold))
          .multilineTextAlignment(.center)
          .lineLimit(1)

        Text(product.insuranceName)
          .font(.system(size: 12))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .lineLimit(1)
          .frame(height: 20)

        Button(action: {
          isSelectingLeft = isLeft
          showSelectionSheet = true
        }) {
          Text("Change")
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
      }

      Divider()

      // Total Limit (Usually Coverage ID 1 or sum of limits - logic may vary)
      VStack(spacing: 2) {
        Text("TOTAL LIMIT")
          .font(.system(size: 10, weight: .bold))
          .foregroundColor(.secondary)

        // Assuming Coverage ID 5 is the total annual limit based on previous data inspection
        // Adjust ID based on actual data. For now iterating to find "Annual Limit" or similar
        // Or just using the first coverage limit which is usually the main one.
        // Let's use getCategoryLimit with a known ID or the first one.
        // Based on earlier sqlite dump: 1|Medical Coverage, 5|Overseas...
        // Wait, earlier dump:
        // 1|5|60000 -> Coverage ID 1 (Medical), Product 5

        if let limit = insuranceService.getCoverageLimit(
          productId: product.insuranceId, coverageId: 1)
        {  // 1 = Medical Coverage / Total?
          if let formattedValue = limit.formattedLimitValue {
            Text(formattedValue)
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.primary)
          } else {
            Text("See Details")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.primary)
          }
        } else {
          Text("-")
            .font(.system(size: 16, weight: .bold))
        }
      }
      .padding(.bottom, 16)
    }
    .frame(maxWidth: .infinity)
  }

  private func emptyHeaderCell(isLeft: Bool) -> some View {
    VStack {
      Button("Select Plan") {
        isSelectingLeft = isLeft
        showSelectionSheet = true
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
  }

  // MARK: - 2. Coverage Breakdown

  private var coverageBreakdownSection: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Coverage")
          .font(.headline)
        Spacer()
        Button("HOW IT WORKS") {
          // Action
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
      }
      .padding(.horizontal)
      .padding(.bottom, 12)

      VStack(spacing: 0) {
        // Mode Tags Row (Temporarily removed or using placeholder as logic is complex with new DB)
        //        HStack(spacing: 0) {
        //           if let _ = leftProduct {
        //             // Placeholder for Big Bucket logic if available in future
        //           }
        //        }

        // Coverage List
        LazyVStack(spacing: 0) {
          ForEach(insuranceService.getOrderedCoverageItems()) { item in
            coverageItemRow(item: item)
          }
        }
        .padding(.top, 8)
      }
      .padding(.vertical, 16)
      .background(Color.white)
      .cornerRadius(16)
      .padding(.horizontal)

      // Footnote
      Text(
        "Coverage limits and details are subject to policy terms."
      )
      .font(.caption)
      .foregroundColor(.secondary)
      .padding(.horizontal, 24)
      .padding(.top, 12)
      .multilineTextAlignment(.leading)
    }
  }

  private func coverageItemRow(item: CoverageItem) -> some View {
    VStack(spacing: 0) {
      // Coverage Title
      HStack {
        Text(item.coverageType)
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.primary)
        Spacer()
      }
      .padding(.horizontal)
      .padding(.top, 12)

      HStack(alignment: .top, spacing: 12) {
        // Left Status
        if let leftId = leftProductId {
          coverageStatusCell(productId: leftId, coverageId: item.coverageId, isLeft: true)
        }

        // Right Status
        if let rightId = rightProductId {
          coverageStatusCell(productId: rightId, coverageId: item.coverageId, isLeft: false)
        }
      }
      .padding(.vertical, 8)
      .padding(.horizontal)

      Divider().padding(.leading, 16)

      // Sub-coverages (if any)
      // Logic to fetch sub coverages for this item?
      // Since sub-coverages might differ per product, getting a union of them is complex.
      // For now, let's just show main coverage limits.
    }
  }

  private func coverageStatusCell(productId: Int, coverageId: Int, isLeft: Bool) -> some View {
    let displayMode = insuranceService.getDisplayMode(productId: productId, coverageId: coverageId)
    let limit = insuranceService.getCoverageLimit(productId: productId, coverageId: coverageId)

    // Determine color based on whether it's covered
    let isCovered = displayMode != .notCovered
    let highlightColor: Color = isCovered ? .blue : .gray

    return VStack(alignment: .center, spacing: 4) {
      HStack {
        Spacer()

        // Checkmark or Dash
        if displayMode == .checkmark {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.green)
        } else if case .value(let amount) = displayMode {
          Text(limit?.formattedLimitValue ?? amount)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.gray)
        } else {
          Text("-")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.gray.opacity(0.3))
        }

        Spacer()
      }
      .overlay(alignment: .trailing) {
        // Info Button for Remark
        if let remark = limit?.remark, !remark.isEmpty {
          Button(action: {
            selectedRemark = remark
            selectedRemarkData = limit?.parsedRemark
            selectedRemarkTitle =
              isLeft ? (leftProduct?.insuranceName ?? "") : (rightProduct?.insuranceName ?? "")
            showRemarkSheet = true
          }) {
            Image(systemName: "info.circle")
              .foregroundColor(.blue)
              .font(.system(size: 14))
          }
        }
      }

      // Progress Bar Removed as per request
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - 3. AI Interpretation

  private var aiInterpretationCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "sparkles")  // Placeholder for AI icon
          .foregroundColor(.white)
          .padding(8)
          .background(Color.blue)
          .clipShape(Circle())

        Text("Which is better?")
          .font(.headline)
          .foregroundColor(.white)
      }

      Text(
        "Compare coverage limits and remarks to make the best choice for your pet."
      )
      .font(.system(size: 15))
      .foregroundColor(.white.opacity(0.9))
      .lineSpacing(4)

      Button(action: {}) {
        HStack {
          Text("Get Recommendation for My Pet")
          Image(systemName: "chevron.right")
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(12)
      }

      Text("// API integration pending")
        .font(.caption2)
        .foregroundColor(.gray)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    .padding(24)
    .background(Color(hex: "1A1A1A"))  // Dark card
    .cornerRadius(24)
    .padding(.horizontal)
    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
  }
}

// MARK: - Selection View (Use New Models)

struct ProviderSelectionView: View {
  @Binding var isPresented: Bool
  let onSelect: (Int) -> Void
  @ObservedObject var service = InsuranceService.shared

  var body: some View {
    NavigationView {
      List(service.products) { product in
        Button(action: {
          onSelect(product.insuranceId)
          isPresented = false
        }) {
          HStack {
            VStack(alignment: .leading) {
              if let company = service.getCompany(forProduct: product) {
                Text(company.companyName)
                  .font(.headline)
              }
              Text(product.insuranceName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            Spacer()
            // Can add badges here if we have logic for them
          }
        }
      }
      .navigationTitle("Select Insurance")
      .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
    }
  }
}

// MARK: - Remark Sheet View

// MARK: - Remark Sheet View

struct RemarkSheetView: View {
  let title: String
  let remark: String
  let remarkData: RemarkData?  // Pre-parsed data passed in
  @Binding var isPresented: Bool

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        // Use title from parsed data if available and passed title is generic
        Text(resolveTitle())
          .font(.headline)
        Spacer()
        Button(action: { isPresented = false }) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 24))
            .foregroundColor(.gray.opacity(0.6))
        }
      }
      .padding()
      .background(Color(UIColor.systemBackground))

      Divider()

      // Remark content
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          if let data = remarkData {
            structuredContent(data)
          } else {
            // Fallback for plain text
            Text(remark)
              .font(.body)
              .foregroundColor(.primary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding()
      }
      .frame(maxHeight: .infinity)

      Spacer()

      // AI Button
      Button(action: {
        // TODO: Future AI API Integration
      }) {
        HStack(spacing: 8) {
          Image(systemName: "sparkles")
            .font(.system(size: 16, weight: .semibold))
          Text("Ask AI for Explanation")
            .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.blue)
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private func resolveTitle() -> String {
    if let t = remarkData?.title { return t }
    if let t = remarkData?.content?.title { return t }
    if let cat = remarkData?.category { return cat }
    return title.isEmpty ? "Remark" : title
  }

  @ViewBuilder
  private func structuredContent(_ data: RemarkData) -> some View {
    if let type = data.type {
      switch type {
      case "benefit_header":
        benefitHeaderView(data)
      case "eligibility_detail":
        eligibilityDetailView(data)
      case "special_coverage":
        specialCoverageView(data)
      default:
        genericRemarkView(data)
      }
    } else {
      genericRemarkView(data)
    }
  }

  // MARK: - Specialized Views

  @ViewBuilder
  private func benefitHeaderView(_ data: RemarkData) -> some View {
    if let content = data.content {
      VStack(spacing: 16) {
        if let icon = content.icon {
          Image(systemName: icon)
            .font(.system(size: 48))
            .foregroundColor(.blue)
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(Circle())
        }

        VStack(spacing: 4) {
          if let badge = content.badgeText {
            Text(badge)
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(.secondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.gray.opacity(0.1))
              .cornerRadius(4)
          }

          if let title = content.title {
            Text(title)
              .font(.title2)
              .fontWeight(.bold)
              .multilineTextAlignment(.center)
          }
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color(UIColor.secondarySystemBackground))
      .cornerRadius(16)
    }
  }

  @ViewBuilder
  private func eligibilityDetailView(_ data: RemarkData) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      if let category = data.category {
        Label(category, systemImage: "checklist")
          .font(.headline)
          .foregroundColor(.blue)
      }

      // Eligibility Grid
      if let eligibility = data.eligibility {
        VStack(alignment: .leading, spacing: 12) {
          Text("Eligibility Requirements")
            .font(.subheadline)
            .fontWeight(.semibold)

          if let species = eligibility.species {
            infoRow(label: "Species", value: species.joined(separator: ", "))
          }
          if let age = eligibility.ageRange {
            infoRow(label: "Age Range", value: age)
          }
          if let condition = eligibility.preExistingCondition {
            infoRow(label: "Condition", value: condition)
          }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
      }

      // Limits
      if let limits = data.limits {
        HStack {
          VStack(alignment: .leading) {
            Text("Frequency")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(limits.frequency ?? "-")
              .font(.subheadline)
              .bold()
          }
          Spacer()
          VStack(alignment: .trailing) {
            Text("Payout Type")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(limits.payoutType ?? "-")
              .font(.subheadline)
              .bold()
          }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
      }
    }
  }

  @ViewBuilder
  private func specialCoverageView(_ data: RemarkData) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      if let category = data.category {
        HStack {
          Image(systemName: "exclamationmark.shield.fill")
            .foregroundColor(.orange)
          Text(category)
            .font(.headline)
        }
      }

      if let target = data.targetSpecies {
        Text(target)
          .font(.caption)
          .fontWeight(.bold)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.gray.opacity(0.2))
          .cornerRadius(4)
      }

      // Rules List
      if let rules = data.rules {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(rules) { rule in
            HStack(alignment: .top) {
              VStack(alignment: .leading) {
                Text(rule.label)
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text(rule.value)
                  .font(.body)
                  .fontWeight(rule.highlight == true ? .bold : .regular)
                  .foregroundColor(rule.highlight == true ? .primary : .secondary)
              }
              Spacer()
              if rule.isRequirement == true {
                Image(systemName: "checkmark.circle")
                  .foregroundColor(.green)
              }
            }
            Divider()
          }
        }
      }

      if let disclaimer = data.medicalDisclaimer {
        HStack(alignment: .top) {
          Image(systemName: "info.circle")
            .foregroundColor(.gray)
          Text(disclaimer)
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding(.top, 8)
      }
    }
  }

  // Generic Fallback (Reuse previous logic)
  @ViewBuilder
  private func genericRemarkView(_ data: RemarkData) -> some View {
    // 1. Summary
    if let summary = data.summary {
      Text(summary)
        .font(.body)
        .foregroundColor(.secondary)
        .lineSpacing(4)
    }

    // 2. Highlights (Top-up etc.)
    if let highlight = data.highlights {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "star.circle.fill")
          .font(.title2)
          .foregroundColor(.orange)
          .padding(.top, 2)

        VStack(alignment: .leading, spacing: 4) {
          Text(highlight.label ?? "Highlight")
            .font(.subheadline)
            .bold()
            .foregroundColor(.orange)

          if let amount = highlight.amount, let currency = highlight.currency {
            Text("\(currency) \(amount)")
              .font(.title3)
              .bold()
              .foregroundColor(.primary)
          }

          if let condition = highlight.condition {
            Text(condition)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.orange.opacity(0.1))
      .cornerRadius(12)
    }

    // 3. Coverage Scopes
    if let scopes = data.coverageScopes {
      VStack(alignment: .leading, spacing: 12) {
        Text("Coverage Detail")
          .font(.headline)
          .padding(.top, 8)

        ForEach(scopes) { scope in
          HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
              Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 36, height: 36)
              Image(systemName: scope.icon ?? "shield.fill")
                .foregroundColor(.blue)
                .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 4) {
              Text(scope.category)
                .font(.subheadline)
                .fontWeight(.semibold)

              // Bullet points for items
              ForEach(scope.items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                  Text("•")
                    .foregroundColor(.secondary)
                  Text(item)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              }
            }
          }
          .padding(.vertical, 4)
        }
      }
    }

    // 4. Raw Text
    if let raw = data.rawText {
      Divider().padding(.vertical, 8)
      Text("Original Text:")
        .font(.caption2)
        .foregroundColor(.gray)
        .padding(.bottom, 2)
      Text(raw)
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private func infoRow(label: String, value: String) -> some View {
    HStack(alignment: .top) {
      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)
        .frame(width: 80, alignment: .leading)
      Text(value)
        .font(.caption)
        .bold()
    }
  }
}

// MARK: - Color Extension
extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
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
