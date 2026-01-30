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

  // Default selection keys (will update when data loads)
  @State private var leftProviderKey: String?
  @State private var rightProviderKey: String?

  // Sheet control
  @State private var showSelectionSheet = false
  @State private var isSelectingLeft = true

  // Scroll tracking
  @State private var scrollOffset: CGFloat = 0
  private let providerHeaderHeight: CGFloat = 280

  // Show mini header when provider cards are halfway scrolled off
  private var showMiniHeader: Bool {
    scrollOffset > providerHeaderHeight / 2
  }

  var leftProvider: InsuranceProvider? {
    guard let key = leftProviderKey else { return nil }
    return insuranceService.providers.first { $0.providerKey == key }
  }

  var rightProvider: InsuranceProvider? {
    guard let key = rightProviderKey else { return nil }
    return insuranceService.providers.first { $0.providerKey == key }
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
      print("📱 InsuranceCompareView appeared")
      print("   - Total providers available: \(insuranceService.providers.count)")
      print("   - Is loading: \(insuranceService.isLoading)")
      print("   - Error message: \(insuranceService.errorMessage ?? "none")")

      // Set defaults if not set
      if leftProviderKey == nil, let first = insuranceService.providers.first {
        leftProviderKey = first.providerKey
        print("   - Set left provider to: \(first.companyName)")
      }
      if rightProviderKey == nil, insuranceService.providers.count > 1 {
        // Try to find a different one for comparison
        rightProviderKey =
          insuranceService.providers.first(where: { $0.providerKey != leftProviderKey })?
          .providerKey
        if let rightKey = rightProviderKey {
          let rightProviderName =
            insuranceService.providers.first(where: { $0.providerKey == rightKey })?.companyName
            ?? "unknown"
          print("   - Set right provider to: \(rightProviderName)")
        }
      }
    }
    .sheet(isPresented: $showSelectionSheet) {
      ProviderSelectionView(isPresented: $showSelectionSheet) { selectedKey in
        if isSelectingLeft {
          leftProviderKey = selectedKey
        } else {
          rightProviderKey = selectedKey
        }
      }
    }
  }

  private var contentView: some View {
    ScrollView {
      VStack(spacing: 24) {

        // 1. Provider & Top Level Limit
        providerHeaderSection

        // 2. Coverage Mode & Services
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
        if let left = leftProvider {
          miniProviderCard(provider: left, isLeft: true)
        }

        // Divider
        Divider()
          .frame(height: 50)

        // Right provider mini card
        if let right = rightProvider {
          miniProviderCard(provider: right, isLeft: false)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .frame(maxWidth: .infinity)
    .background(Color(UIColor.systemBackground))  // Same as navigation bar
  }

  private func miniProviderCard(provider: InsuranceProvider, isLeft: Bool) -> some View {
    VStack(spacing: 4) {
      // Company and plan name centered
      VStack(spacing: 2) {
        Text(provider.companyName)
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.primary)
          .lineLimit(1)

        Text(provider.planName.isEmpty ? provider.insuranceProvider : provider.planName)
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
      if let left = leftProvider {
        providerHeaderCell(provider: left, isLeft: true)
      } else {
        emptyHeaderCell(isLeft: true)
      }

      Divider()

      // Right Provider
      if let right = rightProvider {
        providerHeaderCell(provider: right, isLeft: false)
      } else {
        emptyHeaderCell(isLeft: false)
      }
    }
    .background(Color.white)
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    .padding(.horizontal)
  }

  private func providerHeaderCell(provider: InsuranceProvider, isLeft: Bool) -> some View {
    VStack(spacing: 12) {
      // Placeholder Image
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

        Text(provider.companyName)
          .font(.system(size: 14, weight: .semibold))
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .frame(height: 40, alignment: .top)

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

      // Total Limit
      VStack(spacing: 2) {
        Text("TOTAL LIMIT")
          .font(.system(size: 10, weight: .bold))
          .foregroundColor(.secondary)

        if let limit = insuranceService.getCategoryLimit(forProviderKey: provider.providerKey) {
          Text(limit.coverageAmountHkd == "-" ? "Unlimited" : "HK$\(limit.coverageAmountHkd)")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.primary)
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
        // Mode Tags Row
        HStack(spacing: 0) {
          if let left = leftProvider {
            modeTagView(provider: left)
          } else {
            Spacer()
          }

          if let right = rightProvider {
            modeTagView(provider: right)
              .padding(.leading, 8)
          } else {
            Spacer()
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)

        // Color Bars (Visual Indicator)
        HStack(spacing: 8) {
          Rectangle()
            .fill(leftProvider?.isBigBucket == true ? Color.blue : Color.orange)
            .frame(height: 4)
          Rectangle()
            .fill(rightProvider?.isBigBucket == true ? Color.blue : Color.orange)
            .frame(height: 4)
        }
        .padding(.horizontal)

        // Service List
        LazyVStack(spacing: 0) {
          ForEach(insuranceService.serviceSubcategories) { service in
            serviceRow(service: service)
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
        "Plan A allows you to use the full limit on any service. Plan B has specific caps per service that count toward the total."
      )
      .font(.caption)
      .foregroundColor(.secondary)
      .padding(.horizontal, 24)
      .padding(.top, 12)
      .multilineTextAlignment(.leading)
    }
  }

  private func modeTagView(provider: InsuranceProvider) -> some View {
    HStack {
      Text(provider.isBigBucket ? "“BIG BUCKET”" : "“BENTO BOX”")
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(provider.isBigBucket ? .blue : .orange)

      Spacer()

      Text(provider.isBigBucket ? "Flexible" : "Strict")
        .font(.system(size: 10))
        .foregroundColor(provider.isBigBucket ? .blue : .orange)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
          (provider.isBigBucket ? Color.blue : Color.orange).opacity(0.1)
        )
        .cornerRadius(4)
    }
    .frame(maxWidth: .infinity)
    .padding(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(provider.isBigBucket ? Color.blue : Color.orange, lineWidth: 1)
    )
  }

  private func serviceRow(service: ServiceSubcategory) -> some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        // Left Service Status
        if let left = leftProviderKey {
          serviceStatusCell(providerKey: left, serviceName: service.name, isLeft: true)
        }

        // Right Service Status
        if let right = rightProviderKey {
          serviceStatusCell(providerKey: right, serviceName: service.name, isLeft: false)
        }
      }
      .padding(.vertical, 12)
      .padding(.horizontal)

      Divider().padding(.leading, 16)
    }
  }

  private func serviceStatusCell(providerKey: String, serviceName: String, isLeft: Bool)
    -> some View
  {
    let coverage = insuranceService.getCoverage(forProviderKey: providerKey, service: serviceName)
    let isBigBucket =
      insuranceService.providers.first(where: { $0.providerKey == providerKey })?.isBigBucket
      ?? false
    let highlightColor: Color = isBigBucket ? .blue : .orange

    return VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(serviceName)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Spacer()

        if coverage.covered {
          // Visual bar
          if !isBigBucket {
            // Maybe a small bar or text
          }
        }
      }

      HStack {
        // Checkmark or Dash
        if coverage.covered {
          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(highlightColor)
        } else {
          Text("-")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.gray.opacity(0.5))
        }

        Spacer()

        // Limit Text or "Full Pool"
        if coverage.covered, let limit = coverage.limit {
          Text(limit)
            .font(.system(size: 12, weight: .bold))  // Bold for emphasis
            .foregroundColor(.gray)  // Gray as requested
            .italic(limit == "Full Pool")
        }
      }

      // Progress Bar simulation
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule().fill(Color.gray.opacity(0.1))
          if coverage.covered {
            Capsule().fill(highlightColor)
              .frame(width: isBigBucket ? geo.size.width : geo.size.width * 0.6)  // Mock length
          }
        }
      }
      .frame(height: 4)
      .padding(.top, 4)
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
        "Plan A (Shared) is better if you expect one single high-cost event. Plan B (Sub-limits) might offer higher specialized caps but limits flexibility."
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

// MARK: - Selection View (Simple List)

struct ProviderSelectionView: View {
  @Binding var isPresented: Bool
  let onSelect: (String) -> Void
  @ObservedObject var service = InsuranceService.shared

  var body: some View {
    NavigationView {
      List(service.providers) { provider in
        Button(action: {
          onSelect(provider.providerKey)
          isPresented = false
        }) {
          HStack {
            VStack(alignment: .leading) {
              Text(provider.companyName)
                .font(.headline)
              Text(provider.planName.isEmpty ? provider.insuranceProvider : provider.planName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            Spacer()
            if provider.isBigBucket {
              Text("Big Bucket")
                .font(.caption)
                .padding(4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
            } else {
              Text("Bento Box")
                .font(.caption)
                .padding(4)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(4)
            }
          }
        }
      }
      .navigationTitle("Select Insurance")
      .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
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
