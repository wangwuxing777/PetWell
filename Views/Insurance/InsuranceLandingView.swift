//
//  InsuranceLandingView.swift
//  PetWell
//

import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

// MARK: - Main View
struct InsuranceLandingView: View {
  @EnvironmentObject var languageManager: LanguageManager
  @State private var scrollOffset: CGFloat = 0
  @State private var isShowingRecommendation = false

  // Header heights
  private let fullHeaderHeight: CGFloat = 280

  private var showMiniHeader: Bool {
    scrollOffset > fullHeaderHeight / 2
  }

  var body: some View {
    NavigationStack {
      ZStack(alignment: .top) {
        // Scrollable content
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()

        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 0) {
            // Hero image header that scrolls away
            fullHeader

            // Content
            VStack(spacing: 40) {
              headerSection
                .padding(.top, 32)

              coverageSection

              threeStepsSection

              keyTermsSection

              notCoveredSection

              whyInsuranceSection

              // CTA
              NavigationLink(destination: InsuranceCompareView()) {
                Text(languageManager.isChinese ? "探索精選計劃" : "Explore Plans")
                  .font(.system(size: 18, weight: .bold))
                  .foregroundColor(.white)
                  .padding(.vertical, 16)
                  .frame(maxWidth: .infinity)
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
              .padding(.horizontal, 20)
              .padding(.bottom, 60)
            }
          }
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
        .ignoresSafeArea(edges: .top)

        // Sticky Mini Header (appears when scrolled past hero)
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
      .navigationBarHidden(true)
    }
    .fullScreenCover(isPresented: $isShowingRecommendation) {
      RAGChatView(
        contextString: languageManager.isChinese ? "為我推薦寵物保險" : "Pet Insurance Recommendation",
        isPresented: $isShowingRecommendation)
    }
  }

  // MARK: - Full Header (Scroll Away)
  private var fullHeader: some View {
    ZStack(alignment: .bottomLeading) {
      Image("InsuranceHero")
        .resizable()
        .scaledToFill()
        .frame(height: fullHeaderHeight)
        .clipped()

      LinearGradient(
        colors: [
          Color.black.opacity(0.0),
          Color.black.opacity(0.3),
          Color.black.opacity(0.6),
        ],
        startPoint: .top,
        endPoint: .bottom
      )

      VStack(alignment: .leading, spacing: 6) {
        Text(languageManager.isChinese ? "寵物保險" : "Pet Insurance")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)

        Text(
          languageManager.isChinese
            ? "為毛孩的健康保障第一步" : "The first step to protect your pet's health"
        )
        .font(.system(size: 16))
        .foregroundStyle(.white.opacity(0.9))
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .frame(height: fullHeaderHeight)
  }

  // MARK: - Mini Header (Sticky)
  private var miniHeader: some View {
    VStack(spacing: 0) {
      HStack {
        Text(languageManager.isChinese ? "寵物保險" : "Pet Insurance")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.primary)

        Spacer()

        HStack(spacing: 8) {
          // Compare Button
          NavigationLink(destination: InsuranceCompareView()) {
            Text(languageManager.isChinese ? "比較" : "Compare")
              .font(.system(size: 13, weight: .semibold))
              .foregroundColor(.white)
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(Color.blue)
              .clipShape(Capsule())
          }
          .fixedSize()

          // For You Button
          Button(action: {
            isShowingRecommendation = true
          }) {
            HStack(spacing: 4) {
              Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
              Text(languageManager.isChinese ? "為我推薦" : "For Me")
                .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
              Capsule()
                .stroke(
                  LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  ),
                  lineWidth: 1.5
                )
            )
          }
          .fixedSize()
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .frame(maxWidth: .infinity)
    .background(Color(UIColor.systemBackground))
  }

  // MARK: - Sections

  private var headerSection: some View {
    VStack(spacing: 8) {
      Text(languageManager.isChinese ? "一眼看懂保障範圍" : "Understand Coverage")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)

      HStack(spacing: 8) {
        Text("🐾")
        Text(languageManager.isChinese ? "寵物保險通常涵蓋以下項目" : "Pet insurance usually covers:")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.secondary)
        Spacer()
      }
      .padding(.horizontal, 24)
    }
  }

  private var coverageSection: some View {
    VStack(spacing: 20) {
      LazyVGrid(
        columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
        spacing: 16
      ) {
        coverageItem(
          icon: "cross.case.fill", title: languageManager.isChinese ? "醫療門診" : "Outpatient",
          desc: languageManager.isChinese ? "感冒、腸胃炎" : "Flu, GI issues", isAdvanced: false)
        coverageItem(
          icon: "bed.double.fill", title: languageManager.isChinese ? "住院" : "Hospitalize",
          desc: languageManager.isChinese ? "留醫床位" : "Bed & Care", isAdvanced: false)
        coverageItem(
          icon: "scissors", title: languageManager.isChinese ? "手術" : "Surgery",
          desc: languageManager.isChinese ? "開刀、麻醉" : "Procedures", isAdvanced: false)
        coverageItem(
          icon: "magnifyingglass", title: languageManager.isChinese ? "檢查" : "Diagnostics",
          desc: languageManager.isChinese ? "X光、超聲波" : "X-ray, Ultra", isAdvanced: false)
        coverageItem(
          icon: "pills.fill", title: languageManager.isChinese ? "藥物" : "Meds",
          desc: languageManager.isChinese ? "處方藥" : "Prescriptions", isAdvanced: false)
        coverageItem(
          icon: "person.2.fill", title: languageManager.isChinese ? "第三者責任" : "3rd Party Lib",
          desc: languageManager.isChinese ? "咬傷人" : "Biting, dmg", isAdvanced: true)
        coverageItem(
          icon: "airplane", title: languageManager.isChinese ? "海外旅行" : "Travel",
          desc: languageManager.isChinese ? "旅行期間" : "Vacation cvg", isAdvanced: true)
        coverageItem(
          icon: "heart.text.square.fill", title: languageManager.isChinese ? "慢性病" : "Chronic",
          desc: languageManager.isChinese ? "長期疾病" : "Long-term", isAdvanced: true)
      }
      .padding(.horizontal, 20)

      HStack(spacing: 16) {
        HStack(spacing: 6) {
          Circle().fill(Color.blue.opacity(0.1)).frame(width: 8, height: 8)
          Text(languageManager.isChinese ? "核心保障" : "Core")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
        }
        HStack(spacing: 6) {
          Circle().fill(Color.purple.opacity(0.1)).frame(width: 8, height: 8)
          Text(languageManager.isChinese ? "進階保障" : "Advanced")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
        }
      }
      .padding(.top, 4)
    }
  }

  private func coverageItem(
    icon: String, title: String, desc: String, isAdvanced: Bool
  ) -> some View {
    let bg = isAdvanced ? Color.purple.opacity(0.05) : Color.blue.opacity(0.05)
    let iconColor = isAdvanced ? Color.purple : Color.blue

    return VStack(alignment: .leading, spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(iconColor)
        .frame(width: 44, height: 44)
        .background(Color.white)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 15, weight: .bold))
          .foregroundColor(.primary)

        Text(desc)
          .font(.system(size: 13, weight: .regular))
          .foregroundColor(.secondary)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(bg)
    .cornerRadius(16)
  }

  private var threeStepsSection: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(languageManager.isChinese ? "三步選保險" : "3 Steps to Choose")
        .font(.system(size: 22, weight: .bold))
        .foregroundColor(.primary)
        .padding(.horizontal, 20)

      VStack(spacing: 12) {
        stepRow(
          num: "1", title: languageManager.isChinese ? "想清楚你最擔心什麼" : "Know What You Worry About",
          desc: languageManager.isChinese ? "大病手術？常常小病？" : "Surgery? frequent small ill?")
        stepRow(
          num: "2", title: languageManager.isChinese ? "用 4 大指標比較" : "Compare 4 Metrics",
          desc: languageManager.isChinese
            ? "保障範圍、賠償比例、自負額、年上限" : "Coverage, ratio, deductible, limit"
        )
        stepRow(
          num: "3", title: languageManager.isChinese ? "用真實情境試算" : "Use Real Scenarios",
          desc: languageManager.isChinese ? "例如：20K 手術我要付多少？" : "e.g. 20k surgery, how much I pay?")
      }
      .padding(.horizontal, 20)
    }
  }

  private func stepRow(num: String, title: String, desc: String) -> some View {
    HStack(spacing: 16) {
      Text(num)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(.blue)
        .frame(width: 32, height: 32)
        .background(Color.blue.opacity(0.1))
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(.primary)
        Text(desc)
          .font(.system(size: 13))
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 0)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white)
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
  }

  private var keyTermsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(languageManager.isChinese ? "關鍵條款對比" : "Key Terms")
        .font(.system(size: 22, weight: .bold))
        .foregroundColor(.primary)
        .padding(.horizontal, 20)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          termCard(
            icon: "chart.line.uptrend.xyaxis",
            title: languageManager.isChinese ? "賠償比例" : "Cov. Ratio",
            impact: languageManager.isChinese ? "影響每次你自付多少" : "Affects how much you pay",
            good: languageManager.isChinese ? "≥70%, 愈高愈好" : "≥70%, higher is better")
          termCard(
            icon: "shield.fill",
            title: languageManager.isChinese ? "年度上限" : "Annual Limit",
            impact: languageManager.isChinese ? "大病時會不會「報唔晒」" : "Will it cover big surgeries?",
            good: languageManager.isChinese ? "至少覆蓋1-2次大手術" : "Cover 1-2 major bounds")
          termCard(
            icon: "minus.forwardslash.plus",
            title: languageManager.isChinese ? "自負額" : "Deductible",
            impact: languageManager.isChinese ? "小額醫療要不要自己吞" : "Do you pay for small bills?",
            good: languageManager.isChinese ? "常看門診，自負額不要太高" : "Frequent OP, keep it low")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
      }
    }
  }

  private func termCard(icon: String, title: String, impact: String, good: String) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.blue)
          .frame(width: 40, height: 40)
          .background(Color.blue.opacity(0.1))
          .clipShape(Circle())

        Text(title)
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.primary)
      }

      VStack(alignment: .leading, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(languageManager.isChinese ? "影響" : "Impact")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
          Text(impact)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)
        }

        Divider()

        VStack(alignment: .leading, spacing: 4) {
          Text(languageManager.isChinese ? "良好標準" : "Good Standard")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.green)
          Text(good)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)
        }
      }
    }
    .padding(20)
    .frame(width: 260)
    .background(Color.white)
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
  }

  private var notCoveredSection: some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundColor(.red)
          .font(.system(size: 20))

        VStack(alignment: .leading, spacing: 2) {
          Text(languageManager.isChinese ? "這些情況通常不受保" : "Usually Not Covered")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.primary)
          Text(languageManager.isChinese ? "選購前請留意條款" : "Watch out for exclusions")
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.secondary)
        }
        Spacer()
      }
      .padding(20)
      .background(Color.white)
      .clipShape(
        RoundedRectangle(cornerRadius: 16)
          .path(in: CGRect(x: 0, y: 0, width: 1000, height: 1000))  // rough approximation for top corners
      )

      VStack(spacing: 16) {
        notCoveredItem(
          title: languageManager.isChinese ? "既往病 & 等候期" : "Pre-existing & Waiting",
          desc: languageManager.isChinese
            ? "投保前已有的疾病，以及等候期內發現的疾病通常不保"
            : "Conditions before or during waiting period are excluded.")
        notCoveredItem(
          title: languageManager.isChinese ? "日常護理" : "Routine Care",
          desc: languageManager.isChinese
            ? "疫苗、洗牙、美容等預防性及日常護理不在保障範圍" : "Vaccines, cleaning, grooming are not covered.")
        notCoveredItem(
          title: languageManager.isChinese ? "配種、懷孕、主人疏忽" : "Breeding & Neglect",
          desc: languageManager.isChinese
            ? "配種相關費用、懷孕分娩，以及主人蓄意或嚴重疏忽的情況" : "Breeding, pregnancy, or intentional neglect.")
      }
      .padding(20)
      .background(Color.red.opacity(0.03))
    }
    .background(Color.white)
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    .padding(.horizontal, 20)
  }

  private func notCoveredItem(title: String, desc: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "xmark.circle.fill")
        .font(.system(size: 16))
        .foregroundColor(.red.opacity(0.8))
        .padding(.top, 2)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.primary)
        Text(desc)
          .font(.system(size: 13))
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer()
    }
  }

  private var whyInsuranceSection: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(languageManager.isChinese ? "為什麼需要保險？" : "Why Insurance?")
        .font(.system(size: 22, weight: .bold))
        .foregroundColor(.primary)
        .padding(.horizontal, 20)

      VStack(spacing: 16) {
        // No Insurance Card
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            Image(systemName: "xmark.viewfinder")
              .foregroundColor(.red)
            Text(languageManager.isChinese ? "沒有保險" : "No Insurance")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.primary)
          }

          Text(
            languageManager.isChinese
              ? "狗狗突發椎間盤問題，手術+住院 $30,000" : "Dog IVDD surgery + hospital $30k"
          )
          .font(.system(size: 14))
          .foregroundColor(.secondary)

          HStack {
            Text(languageManager.isChinese ? "一次全數自付" : "Pay all at once")
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(.red)
            Spacer()
            Text("$30,000")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.red)
          }
          .padding(12)
          .background(Color.red.opacity(0.05))
          .cornerRadius(8)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)

        // Has Insurance Card
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            Image(systemName: "checkmark.shield.fill")
              .foregroundColor(.blue)
            Text(languageManager.isChinese ? "有保險 (70% 保障)" : "Insured (70% Cov)")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.primary)
          }

          Text(languageManager.isChinese ? "同一情況，費用 $30,000" : "Same case, surgery + hospital 30k")
            .font(.system(size: 14))
            .foregroundColor(.secondary)

          VStack(spacing: 12) {
            HStack {
              Text(languageManager.isChinese ? "保險賠付：" : "Insurance pays:")
                .font(.system(size: 13))
              Spacer()
              Text("$21,000")
                .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.secondary)

            Divider()

            HStack {
              Text(languageManager.isChinese ? "你只需自付：" : "You only pay:")
                .font(.system(size: 14, weight: .bold))
              Spacer()
              Text("$9,000")
                .font(.system(size: 20, weight: .bold))
            }
            .foregroundColor(.blue)
          }
          .padding(16)
          .background(Color.blue.opacity(0.05))
          .cornerRadius(12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
      }
      .padding(.horizontal, 20)
    }
  }
}

#Preview {
  InsuranceLandingView()
    .environmentObject(LanguageManager())
}
