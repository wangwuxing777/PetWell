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

// MARK: - Remark Context
struct RemarkSheetContext: Identifiable {
  let id = UUID()
  let title: String
  let remark: String
  let productName: String
}

struct InsuranceCompareView: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var languageManager: LanguageManager
  @EnvironmentObject var guideManager: GuideManager
  @ObservedObject var insuranceService = InsuranceService.shared

  // Default selection keys (Product IDs)
  @State private var leftProductId: Int?
  @State private var rightProductId: Int?

  // Sheet control
  @State private var showSelectionSheet = false
  @State private var isSelectingLeft = true

  // Remark sheet control
  @State private var remarkContext: RemarkSheetContext?

  @State private var showRAGChat = false

  // Comparison Mode
  enum CompareMode {
    case byInsurance
    case byScenario
  }
  @State private var compareMode: CompareMode = .byInsurance

  // Scroll tracking
  @State private var scrollOffset: CGFloat = 0
  private let providerHeaderHeight: CGFloat = 280
  private let addOnCoverageIds: Set<Int> = [7, 8, 11]

  private var addOnBadgeText: String {
    languageManager.isChinese ? "額外加購" : "Extra"
  }

  private var addOnGroupTitleText: String {
    languageManager.isChinese ? "額外加購保障組" : "Paid Add-on Group"
  }

  private var addOnExplanationText: String {
    languageManager.isChinese
      ? "標記「額外加購」的保障項目需另付保費。"
      : "Items marked \"Extra\" require additional premium."
  }

  // Show mini header when provider cards are halfway scrolled off
  private var showMiniHeader: Bool {
    scrollOffset > providerHeaderHeight / 2
  }

  private var orderedCoverageItems: [CoverageItem] {
    insuranceService.getOrderedCoverageItems()
  }

  private func isAddOnCoverage(_ coverageId: Int) -> Bool {
    addOnCoverageIds.contains(coverageId)
  }

  private var groupedAddOnItems: [CoverageItem] {
    orderedCoverageItems.filter { isAddOnCoverage($0.coverageId) }
  }

  private func hasDisplayableCoverage(_ item: CoverageItem) -> Bool {
    let leftSubLimits =
      leftProductId.map {
        insuranceService.getSubCoverageLimits(productId: $0, parentCoverageId: item.coverageId)
      } ?? []
    let rightSubLimits =
      rightProductId.map {
        insuranceService.getSubCoverageLimits(productId: $0, parentCoverageId: item.coverageId)
      } ?? []

    let leftNames = Set(leftSubLimits.map { $0.subCoverageName ?? "" })
    let rightNames = Set(rightSubLimits.map { $0.subCoverageName ?? "" })
    let hasSubItems = !leftNames.union(rightNames).filter { !$0.isEmpty }.isEmpty

    let hasLeftMain = leftProductId.flatMap {
      insuranceService.getCoverageLimit(productId: $0, coverageId: item.coverageId)
    } != nil
    let hasRightMain = rightProductId.flatMap {
      insuranceService.getCoverageLimit(productId: $0, coverageId: item.coverageId)
    } != nil

    return hasLeftMain || hasRightMain || hasSubItems
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
      AppTheme.bgBase.ignoresSafeArea()  // Page background

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
        VStack(spacing: 0) {
          // Toggle Picker
          Picker("Comparison Mode", selection: $compareMode) {
            Text("By Insurance").tag(CompareMode.byInsurance)
            Text("By Scenario").tag(CompareMode.byScenario)
          }
          .pickerStyle(SegmentedPickerStyle())
          .padding(.horizontal)
          .padding(.vertical, 8)
          .background(AppTheme.bgElevated)

          if compareMode == .byInsurance {
            contentView
          } else {
            ScenarioCompareHomeView()
          }
        }
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
    .onChange(of: compareMode) { mode in
      if mode == .byScenario {
        guideManager.mark(.insuranceComparedChanged)
      }
    }
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
    .sheet(item: $remarkContext) { context in
      RemarkSheetView(
        title: context.title,
        remark: context.remark,
        productName: context.productName
      )
    }
    .fullScreenCover(isPresented: $showRAGChat) {
      RAGChatView(contextString: "General pet insurance comparison", isPresented: $showRAGChat)
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
        guideManager.mark(.insuranceComparedChanged)
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
    .background(AppTheme.bgCard)
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
      }

      // Product Tags
      productTagsView(product: product)
        .padding(.top, 2)

      Button(action: {
        isSelectingLeft = isLeft
        showSelectionSheet = true
      }) {
        Text("Change")
          .font(.caption)
          .fontWeight(.medium)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(AppTheme.bgCard)
          .foregroundColor(AppTheme.textPrimary)
          .cornerRadius(20)
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(AppTheme.borderSubtle, lineWidth: 1)
          )
          .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
      }
      .padding(.bottom, 16)  // Padding from bottom edge
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)  // Fill available space
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

  // MARK: - Product Tags Helper

  private func productTagsView(product: InsuranceProduct) -> some View {
    VStack(alignment: .center, spacing: 8) {
      if let minAge = product.minAge, let maxAge = product.maxAge {
        let ageTag = "\(minAge)-\(maxAge)"
        let tagList = (product.tag?.components(separatedBy: " ").filter { !$0.isEmpty } ?? [])

        // Combine age + tags
        let allItems = [ageTag] + tagList

        // Use VStack to ensure tags are centered
        ForEach(allItems, id: \.self) { item in
          tagView(text: item)
        }
      }
    }
  }

  private func tagView(text: String) -> some View {
    Text(text)
      .font(.system(size: 11, weight: .medium))
      .foregroundColor(Color(hex: "4A5568"))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color(hex: "EDF2F7"))
      .cornerRadius(6)
      .lineLimit(1)
      .fixedSize()
  }

  // MARK: - 2. Coverage Breakdown

  private var coverageBreakdownSection: some View {
    VStack(spacing: 24) {  // Spacing between cards
      let visibleAddOnItems = groupedAddOnItems.filter { hasDisplayableCoverage($0) }
      let firstVisibleAddOnIndex = orderedCoverageItems.firstIndex {
        isAddOnCoverage($0.coverageId) && hasDisplayableCoverage($0)
      }

      ForEach(Array(orderedCoverageItems.enumerated()), id: \.element.id) { index, item in
        if isAddOnCoverage(item.coverageId) {
          if index == firstVisibleAddOnIndex, !visibleAddOnItems.isEmpty {
            addOnCoverageGroup(items: visibleAddOnItems)
          }
        } else {
          coverageCard(item: item)
        }
      }

      // Footnote
      Text("Coverage limits and details are subject to policy terms.")
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 24)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
  }

  private func addOnCoverageGroup(items: [CoverageItem]) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 8) {
        Image(systemName: "plus.circle.fill")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(Color(hex: "B45309"))

        Text(addOnGroupTitleText)
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(Color(hex: "92400E"))
      }

      Text(addOnExplanationText)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(Color(hex: "92400E"))

      VStack(spacing: 16) {
        ForEach(items) { item in
          coverageCard(item: item, showAddOnDecorations: false, applyHorizontalPadding: false)
        }
      }
    }
    .padding(14)
    .background(Color(hex: "FFFBF5"))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color(hex: "FDBA74").opacity(0.75), lineWidth: 1.2)
    )
    .cornerRadius(16)
    .padding(.horizontal)
  }

  private func coverageCard(
    item: CoverageItem,
    showAddOnDecorations: Bool = true,
    applyHorizontalPadding: Bool = true
  ) -> some View {
    let isAddOn = isAddOnCoverage(item.coverageId)
    let shouldHighlightAddOn = isAddOn && showAddOnDecorations

    // 1. Calculate Sub-Limits for both products
    let leftSubLimits =
      leftProductId.map {
        insuranceService.getSubCoverageLimits(productId: $0, parentCoverageId: item.coverageId)
      } ?? []
    let rightSubLimits =
      rightProductId.map {
        insuranceService.getSubCoverageLimits(productId: $0, parentCoverageId: item.coverageId)
      } ?? []

    // 2. Identify relevant sub-coverage names (Union of *present* data)
    // We only want to show a sub-coverage if at least one side has a valid entry for it.
    // "Valid" means it exists and displayMode is not .notCovered (unless we want to show strict misses).
    // The requirement is: "if product 5 do not have coverage_id 6,7,8 ... those not appeared term should not appear"
    // So we filter based on whether the limit actually exists in the DB response for that product.

    let leftNames = Set(leftSubLimits.map { $0.subCoverageName ?? "" })
    let rightNames = Set(rightSubLimits.map { $0.subCoverageName ?? "" })
    let allNames = leftNames.union(rightNames)

    // Sort names for consistent order
    let sortedNames = Array(allNames).filter { !$0.isEmpty }.sorted()
    let hasSubItems = !sortedNames.isEmpty

    // 3. Check Main Limit Existence
    // Similarly for the main coverage item, checks if either side has data.
    let leftMainLimit = leftProductId.flatMap {
      insuranceService.getCoverageLimit(productId: $0, coverageId: item.coverageId)
    }
    let rightMainLimit = rightProductId.flatMap {
      insuranceService.getCoverageLimit(productId: $0, coverageId: item.coverageId)
    }

    // If neither side has main limits AND neither side has sub-limits, hide the entire card.
    let hasLeftMain = leftMainLimit != nil
    let hasRightMain = rightMainLimit != nil

    if !hasLeftMain && !hasRightMain && !hasSubItems {
      return AnyView(EmptyView())
    }

    let cardContainer = AnyView(
      VStack(spacing: 0) {

        // Main Limits
        // Only show main limits row if meaningful?
        // Usually main limits are always shown if the section exists.
        HStack(alignment: .center, spacing: 12) {
          // Left Status
          if let leftId = leftProductId {
            coverageStatusCell(
              productId: leftId, coverageId: item.coverageId, coverageType: item.coverageType,
              isLeft: true)
          }

          // Right Status
          if let rightId = rightProductId {
            coverageStatusCell(
              productId: rightId, coverageId: item.coverageId, coverageType: item.coverageType,
              isLeft: false)
          }
        }
        .padding(.top, hasSubItems ? 32 : 24)
        .padding(.bottom, hasSubItems ? 16 : 24)
        .padding(.horizontal, 16)

        // Sub-coverages Display
        if hasSubItems {
          VStack(spacing: 0) {
            ForEach(sortedNames, id: \.self) { subName in
              // Dashed Divider
              Line()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

              VStack(spacing: 8) {
                // Sub-coverage Name - CENTERED
                Text(subName)
                  .font(.system(size: 13, weight: .semibold))
                  .foregroundColor(.primary.opacity(0.8))
                  .multilineTextAlignment(.center)
                  .frame(maxWidth: .infinity, alignment: .center)  // Force Center
                  .padding(.horizontal, 16)
                  .padding(.bottom, 4)

                // Sub-coverage Values
                HStack(alignment: .center, spacing: 12) {
                  // Left Value
                  if let leftId = leftProductId {
                    subCoverageStatusCell(
                      productId: leftId,
                      subName: subName,
                      limits: leftSubLimits,
                      isLeft: true
                    )
                  }

                  // Right Value
                  if let rightId = rightProductId {
                    subCoverageStatusCell(
                      productId: rightId,
                      subName: subName,
                      limits: rightSubLimits,
                      isLeft: false
                    )
                  }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
              }
            }
          }
        }
      }
      .background(shouldHighlightAddOn ? Color(hex: "FFFBF5") : Color.white)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(
            shouldHighlightAddOn ? Color(hex: "FDBA74").opacity(0.75) : Color.clear,
            lineWidth: shouldHighlightAddOn ? 1.2 : 0
          )
      )
      .cornerRadius(16)
      .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    )

    return AnyView(
      VStack(alignment: .leading, spacing: 8) {
        // 1. Title Outside the Box
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .center, spacing: 10) {
            Text(item.coverageType)
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.primary)

            if shouldHighlightAddOn {
              HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                  .font(.system(size: 11, weight: .bold))
                Text(addOnBadgeText)
                  .font(.system(size: 11, weight: .bold))
              }
              .foregroundColor(Color(hex: "92400E"))
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color(hex: "FFEDD5"))
              .clipShape(Capsule())
            }
          }
        }
        .padding(.horizontal)

        // 2. White Box Container

        if applyHorizontalPadding {
          cardContainer.padding(.horizontal)
        } else {
          cardContainer
        }
      }
    )
  }

  // Helper for Sub-Coverage Cells
  private func subCoverageStatusCell(
    productId: Int, subName: String, limits: [SubCoverageLimit], isLeft: Bool
  ) -> some View {
    let limit = limits.first { $0.subCoverageName == subName }
    let displayMode = limit?.displayMode ?? .notCovered

    return VStack(alignment: .center, spacing: 4) {
      HStack {
        // Status Box
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(backgroundColor(for: displayMode))

          content(for: displayMode)
        }
        .frame(height: 56)  // Fixed height for consistency
      }
      .overlay(alignment: .trailing) {
        if let remark = limit?.subCoverageRemark, !remark.isEmpty {
          Button(action: {
            remarkContext = RemarkSheetContext(
              title: subName,
              remark: remark,
              productName: isLeft
                ? (leftProduct?.insuranceName ?? "") : (rightProduct?.insuranceName ?? "")
            )
          }) {
            Image(systemName: "info.circle")
              .foregroundColor(.blue)
              .font(.system(size: 12))
              .padding(8)  // Add padding to make touch target larger
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
  }

  // Dashed Line Shape
  struct Line: Shape {
    func path(in rect: CGRect) -> Path {
      var path = Path()
      path.move(to: CGPoint(x: 0, y: 0))
      path.addLine(to: CGPoint(x: rect.width, y: 0))
      return path
    }
  }

  private func coverageStatusCell(
    productId: Int, coverageId: Int, coverageType: String, isLeft: Bool
  ) -> some View {
    let displayMode = insuranceService.getDisplayMode(productId: productId, coverageId: coverageId)
    let limit = insuranceService.getCoverageLimit(productId: productId, coverageId: coverageId)

    return VStack(alignment: .center, spacing: 4) {
      HStack {
        // Status Box
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(backgroundColor(for: displayMode))

          if case .value(let amount) = displayMode {
            Text(limit?.formattedLimitValue ?? amount)
              .font(.system(size: 16, weight: .bold))  // Slightly Larger
              .foregroundColor(.blue)
          } else {
            content(for: displayMode)
          }
        }
        .frame(height: 56)  // Fixed height for main cells
      }
      .overlay(alignment: .trailing) {
        // Info Button for Remark
        if let remark = limit?.remark, !remark.isEmpty {
          Button(action: {
            remarkContext = RemarkSheetContext(
              title: coverageType,
              remark: remark,
              productName: isLeft
                ? (leftProduct?.insuranceName ?? "") : (rightProduct?.insuranceName ?? "")
            )
          }) {
            Image(systemName: "info.circle")
              .foregroundColor(.blue)
              .font(.system(size: 14))
              .padding(8)
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Box Styling Helpers

  private func backgroundColor(for mode: CoverageDisplayMode) -> Color {
    switch mode {
    case .checkmark:
      return Color(hex: "F0FFF4")  // Light Green
    case .value:
      return Color(hex: "F0F7FF")  // Light Blue
    case .notCovered:
      return Color(hex: "F8F9FA")  // Light Grey
    }
  }

  @ViewBuilder
  private func content(for mode: CoverageDisplayMode) -> some View {
    switch mode {
    case .checkmark:
      Image(systemName: "checkmark.circle")  // Simple checkmark inside circle
        .font(.system(size: 20, weight: .bold))  // Larger icon
        .foregroundColor(Color(hex: "00B050"))  // Strong Green
    case .value(let amount):
      Text(amount)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(Color(hex: "0052FF"))  // Strong Blue
    case .notCovered:
      Text("—")  // Dash
        .font(.system(size: 20, weight: .medium))
        .foregroundColor(Color.gray.opacity(0.3))
    }
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
          .foregroundColor(.primary)
      }

      Text(
        "Compare coverage limits and remarks to make the best choice for your pet."
      )
      .font(.system(size: 15))
      .foregroundColor(.secondary)
      .lineSpacing(4)

      Button(action: {
        showRAGChat = true
      }) {
        HStack {
          Image(systemName: "sparkles")  // Added Sparkle to match AI theme
          Text("Get Recommendation for My Pet")
          Image(systemName: "chevron.right")
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.blue)
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.bgCard)
        .cornerRadius(12)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(
              LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 1.5
            )
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
      }

      Text("// API integration pending")
        .font(.caption2)
        .foregroundColor(.gray)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    .padding(24)
    .background(AppTheme.bgCard)
    .cornerRadius(24)
    .padding(.horizontal)
    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
  }
}

// ProviderSelectionView moved to ProviderSelectionView.swift

// MARK: - Remark Sheet View

// MARK: - Remark Sheet View

struct RemarkSheetView: View {
  @Environment(\.dismiss) var dismiss
  let title: String
  let remark: String
  let productName: String

  @State private var showRAGChat = false

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text(title)
          .font(.headline)
        Spacer()
        Button(action: { dismiss() }) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 28))
            .foregroundColor(Color(UIColor.tertiaryLabel))
            .symbolRenderingMode(.hierarchical)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 12)

      // Remark content
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text(remark)
            .font(.body)
            .foregroundColor(Color(UIColor.label))
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineSpacing(6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 40)  // extra scroll padding
      }
      .frame(maxHeight: .infinity)

      // AI Button Area
      VStack {
        Button(action: {
          showRAGChat = true
        }) {
          HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text("Ask AI for Explanation")
          }
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            LinearGradient(
              colors: [Color(hex: "0052FF"), Color.purple.opacity(0.8)],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .cornerRadius(16)
          .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background(
        Color(UIColor.systemBackground)
          .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
      )
    }
    .background(Color(UIColor.systemBackground))
    .presentationDetents([.fraction(0.4), .large])
    .presentationDragIndicator(.visible)
    .fullScreenCover(isPresented: $showRAGChat) {
      RAGChatView(contextString: constructContextString(), isPresented: $showRAGChat)
    }
  }

  private func constructContextString() -> String {
    return """
      Context:
      - Coverage Term: \(title)
      - Policy Type: \(productName)
      """
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
