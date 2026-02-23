//
//  InsuranceLandingView.swift
//  PetWell
//

import SwiftUI

// MARK: - Hand-drawn / Sketch Modifiers
struct SketchCardModifier: ViewModifier {
  var rotation: Double
  var backgroundColor: Color
  var borderColor: Color = Color.sketchBlue900
  var shadowOffset: CGFloat = 4

  // Scale down all hardcoded rotations for a subtle tilt
  private var tilt: Double {
    rotation * 0.3
  }

  func body(content: Content) -> some View {
    content
      .background(backgroundColor)
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(borderColor, lineWidth: 2.5)
      )
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(borderColor)
          .offset(x: shadowOffset, y: shadowOffset)
      )
      .rotationEffect(.degrees(tilt))
  }
}

extension View {
  func sketchCard(
    rotation: Double = 0, bg: Color = .white, border: Color = Color.sketchBlue900,
    shadow: CGFloat = 4
  ) -> some View {
    self.modifier(
      SketchCardModifier(
        rotation: rotation, backgroundColor: bg, borderColor: border, shadowOffset: shadow))
  }
}

// Custom Colors
extension Color {
  static let sketchBlue900 = Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255)
  static let sketchBlue50 = Color(red: 239 / 255, green: 246 / 255, blue: 255 / 255)
  static let sketchBlue100 = Color(red: 219 / 255, green: 234 / 255, blue: 254 / 255)
  static let sketchBlue200 = Color(red: 191 / 255, green: 219 / 255, blue: 254 / 255)
  static let sketchBlue300 = Color(red: 147 / 255, green: 197 / 255, blue: 253 / 255)
  static let sketchBlue600 = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)

  // Make advanced coverage clearly distinct (use vivid Purple instead of Indigo)
  static let sketchIndigo50 = Color(red: 250 / 255, green: 245 / 255, blue: 255 / 255)
  static let sketchIndigo100 = Color(red: 243 / 255, green: 232 / 255, blue: 255 / 255)
  static let sketchIndigo200 = Color(red: 233 / 255, green: 213 / 255, blue: 255 / 255)
  static let sketchIndigo600 = Color(red: 147 / 255, green: 51 / 255, blue: 234 / 255)

  static let sketchEmerald50 = Color(red: 236 / 255, green: 253 / 255, blue: 245 / 255)
  static let sketchEmerald200 = Color(red: 167 / 255, green: 243 / 255, blue: 208 / 255)
  static let sketchEmerald800 = Color(red: 6 / 255, green: 95 / 255, blue: 70 / 255)

  static let sketchYellow200 = Color(red: 254 / 255, green: 240 / 255, blue: 138 / 255)
  static let sketchYellow300 = Color(red: 253 / 255, green: 224 / 255, blue: 71 / 255)
  static let sketchYellow400 = Color(red: 250 / 255, green: 204 / 255, blue: 21 / 255)

  static let sketchRose50 = Color(red: 255 / 255, green: 241 / 255, blue: 242 / 255)
  static let sketchRose200 = Color(red: 254 / 255, green: 205 / 255, blue: 211 / 255)
  static let sketchRose600 = Color(red: 225 / 255, green: 29 / 255, blue: 72 / 255)
}

struct DottedBackground: View {
  var body: some View {
    Canvas { context, size in
      let dotSize: CGFloat = 1.5
      let spacing: CGFloat = 20

      context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.98)))

      for x in stride(from: 0, to: size.width, by: spacing) {
        for y in stride(from: 0, to: size.height, by: spacing) {
          let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
          context.fill(Path(ellipseIn: rect), with: .color(Color.gray.opacity(0.3)))
        }
      }
    }
    .ignoresSafeArea()
  }
}

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
    scrollOffset > fullHeaderHeight - 80  // Show slightly before it fully disappears
  }

  var body: some View {
    NavigationStack {
      ZStack(alignment: .top) {
        // Base background pattern
        DottedBackground()
          .ignoresSafeArea()

        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 0) {
            // Top level header that scrolls away
            fullHeader

            // New Sketch Style Content
            VStack(spacing: 50) {
              headerSection
                .padding(.top, 40)

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
                  .sketchCard(rotation: 0, bg: .sketchBlue600, border: .sketchBlue900, shadow: 4)
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 60)
            }
          }
          .background(
            GeometryReader { geo in
              Color.clear
                .preference(
                  key: ScrollOffsetPreferenceKey.self,
                  value: -geo.frame(in: .named("scroll")).origin.y
                )
            }
          )
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
          scrollOffset = value
        }

        // Sticky Mini Header overlay
        if showMiniHeader {
          miniHeader
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(100)
        }
      }
      .animation(.easeInOut(duration: 0.25), value: showMiniHeader)
      .ignoresSafeArea(edges: .top)
      .navigationBarHidden(true)
      .fullScreenCover(isPresented: $isShowingRecommendation) {
        RAGChatView(
          contextString: languageManager.isChinese ? "為我推薦寵物保險" : "Pet Insurance Recommendation",
          isPresented: $isShowingRecommendation)
      }
    }
  }

  // MARK: - Full Header (Scroll Away)
  private var fullHeader: some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottomLeading) {
        // If dragging down, stretch the image (bouncy scroll effect)
        let minY = geometry.frame(in: .global).minY
        let isScrollingDown = minY > 0

        Image("InsuranceHero")
          .resizable()
          .scaledToFill()
          .frame(
            width: geometry.size.width,
            height: isScrollingDown ? fullHeaderHeight + minY : fullHeaderHeight
          )
          .offset(y: isScrollingDown ? -minY : 0)
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
        .frame(height: fullHeaderHeight)  // Gradient shouldn't stretch

        VStack(alignment: .leading, spacing: 6) {
          Text(languageManager.isChinese ? "寵物保險" : "Pet Insurance")
            .font(.system(size: 24, weight: .bold))
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
        .padding(.bottom, 20)
      }
    }
    .frame(height: fullHeaderHeight)
  }

  // MARK: - Mini Header (Sticky)
  private var miniHeader: some View {
    HStack {
      Text(languageManager.isChinese ? "寵物保險" : "Pet Insurance")
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(.primary)

      Spacer()

      HStack(spacing: 8) {
        // Compare Button
        NavigationLink(destination: InsuranceCompareView()) {
          Text(languageManager.isChinese ? "比較" : "Compare")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(18)
        }

        // For You Button (AI Style)
        Button(action: {
          isShowingRecommendation = true
        }) {
          HStack(spacing: 6) {
            Image(systemName: "sparkles")
              .font(.system(size: 14, weight: .semibold))
            Text(languageManager.isChinese ? "為我推薦" : "For Me")
              .font(.system(size: 14, weight: .semibold))
          }
          .foregroundColor(.white)
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .background(
            LinearGradient(
              colors: [.blue, .purple],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .cornerRadius(18)
          .shadow(color: .purple.opacity(0.4), radius: 4, x: 0, y: 2)
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 54)  // Safe area inset
    .padding(.bottom, 12)
    .background(
      Color(.systemGray6).opacity(0.9)
    )
    .background(.ultraThinMaterial)
  }

  // MARK: - Sections

  private var headerSection: some View {
    VStack(spacing: 12) {
      ZStack {
        Text(languageManager.isChinese ? "一眼看懂保障範圍" : "Understand Coverage")
          .font(.system(size: 28, weight: .black))
          .foregroundColor(.sketchBlue900)
          .zIndex(1)

        Rectangle()
          .fill(Color.sketchYellow400)
          .frame(height: 12)
          .offset(y: 12)
          .padding(.horizontal, 10)
          .rotationEffect(.degrees(-1))
      }

      HStack(spacing: 8) {
        Text("🐾")
        Text(languageManager.isChinese ? "寵物保險通常涵蓋以下項目" : "Pet insurance usually covers:")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.sketchBlue900)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .sketchCard(rotation: -2, bg: .white, shadow: 2)
      .padding(.top, 10)
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
          desc: languageManager.isChinese ? "感冒、腸胃炎" : "Flu, GI issues", isAdvanced: false,
          rotation: 1)
        coverageItem(
          icon: "bed.double.fill", title: languageManager.isChinese ? "住院" : "Hospitalize",
          desc: languageManager.isChinese ? "留醫床位" : "Bed & Care", isAdvanced: false, rotation: -2)
        coverageItem(
          icon: "scissors", title: languageManager.isChinese ? "手術" : "Surgery",
          desc: languageManager.isChinese ? "開刀、麻醉" : "Procedures", isAdvanced: false, rotation: 2)
        coverageItem(
          icon: "magnifyingglass", title: languageManager.isChinese ? "檢查" : "Diagnostics",
          desc: languageManager.isChinese ? "X光、超聲波" : "X-ray, Ultra", isAdvanced: false,
          rotation: -1)
        coverageItem(
          icon: "pills.fill", title: languageManager.isChinese ? "藥物" : "Meds",
          desc: languageManager.isChinese ? "處方藥" : "Prescriptions", isAdvanced: false, rotation: 1)
        coverageItem(
          icon: "person.2.fill", title: languageManager.isChinese ? "第三者責任" : "3rd Party Lib",
          desc: languageManager.isChinese ? "咬傷人" : "Biting, dmg", isAdvanced: true, rotation: -1)
        coverageItem(
          icon: "airplane", title: languageManager.isChinese ? "海外旅行" : "Travel",
          desc: languageManager.isChinese ? "旅行期間" : "Vacation cvg", isAdvanced: true, rotation: 2)
        coverageItem(
          icon: "heart.text.square.fill", title: languageManager.isChinese ? "慢性病" : "Chronic",
          desc: languageManager.isChinese ? "長期疾病" : "Long-term", isAdvanced: true, rotation: -2)
      }
      .padding(.horizontal, 20)

      HStack(spacing: 16) {
        HStack(spacing: 6) {
          Circle().fill(Color.sketchBlue200).frame(width: 12, height: 12).overlay(
            Circle().stroke(Color.sketchBlue900, lineWidth: 2))
          Text(languageManager.isChinese ? "核心保障" : "Core")
            .font(.system(size: 14, weight: .bold))
        }
        HStack(spacing: 6) {
          Circle().fill(Color.sketchIndigo200).frame(width: 12, height: 12).overlay(
            Circle().stroke(Color.sketchBlue900, lineWidth: 2))
          Text(languageManager.isChinese ? "進階保障" : "Advanced")
            .font(.system(size: 14, weight: .bold))
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .sketchCard(rotation: 1, bg: .white)
    }
  }

  private func coverageItem(
    icon: String, title: String, desc: String, isAdvanced: Bool, rotation: Double
  ) -> some View {
    let bg = isAdvanced ? Color.sketchIndigo50 : Color.sketchBlue50
    let iconBg = isAdvanced ? Color.sketchIndigo100 : Color.sketchBlue100
    let iconColor = isAdvanced ? Color.sketchIndigo600 : Color.sketchBlue600

    return VStack(alignment: .leading, spacing: 8) {
      ZStack {
        Circle()
          .fill(iconBg)
          .frame(width: 40, height: 40)
          .overlay(Circle().stroke(Color.sketchBlue900, lineWidth: 2))
          .shadow(color: .sketchBlue900, radius: 0, x: 2, y: 2)

        Image(systemName: icon)
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(iconColor)
      }
      .rotationEffect(.degrees(rotation > 0 ? -4 : 4))
      .padding(.bottom, 4)

      Text(title)
        .font(.system(size: 16, weight: .black))
        .foregroundColor(.sketchBlue900)

      Text(desc)
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(isAdvanced ? .sketchIndigo600 : .sketchBlue600)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .sketchCard(rotation: rotation, bg: bg, shadow: 4)
  }

  private var threeStepsSection: some View {
    VStack(alignment: .leading, spacing: 24) {
      ZStack(alignment: .bottomTrailing) {
        Text(languageManager.isChinese ? "三步選保險" : "3 Steps to Choose")
          .font(.system(size: 24, weight: .black))
          .foregroundColor(.sketchBlue900)

        Circle()
          .fill(Color.sketchYellow300)
          .frame(width: 30, height: 30)
          .offset(x: 10, y: 5)
          .zIndex(-1)
      }
      .padding(.horizontal, 20)

      VStack(spacing: 20) {
        stepRow(
          num: "1", title: languageManager.isChinese ? "想清楚你最擔心什麼" : "Know What You Worry About",
          desc: languageManager.isChinese ? "大病手術？常常小病？" : "Surgery? frequent small ill?",
          bg: .sketchBlue50, rot: -1)
        stepRow(
          num: "2", title: languageManager.isChinese ? "用 4 大指標比較" : "Compare 4 Metrics",
          desc: languageManager.isChinese
            ? "保障範圍、賠償比例、自負額、年上限" : "Coverage, ratio, deductible, limit", bg: .sketchBlue100, rot: 2
        )
        stepRow(
          num: "3", title: languageManager.isChinese ? "用真實情境試算" : "Use Real Scenarios",
          desc: languageManager.isChinese ? "例如：20K 手術我要付多少？" : "e.g. 20k surgery, how much I pay?",
          bg: .sketchBlue200, rot: -2)
      }
      .padding(.horizontal, 20)
    }
  }

  private func stepRow(num: String, title: String, desc: String, bg: Color, rot: Double)
    -> some View
  {
    HStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(Color.sketchBlue600)
          .frame(width: 44, height: 44)
          .overlay(Circle().stroke(Color.sketchBlue900, lineWidth: 2))
          .shadow(color: .sketchBlue900, radius: 0, x: 2, y: 2)

        Text(num)
          .font(.system(size: 20, weight: .black))
          .foregroundColor(.white)
      }
      .rotationEffect(.degrees(rot * -2))

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.sketchBlue900)
        Text(desc)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.sketchBlue900.opacity(0.8))
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .sketchCard(rotation: rot, bg: bg, shadow: 3)
    }
  }

  private var keyTermsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      ZStack(alignment: .bottomLeading) {
        Text(languageManager.isChinese ? "關鍵條款對比" : "Key Terms")
          .font(.system(size: 24, weight: .black))
          .foregroundColor(.sketchBlue900)

        Rectangle()
          .fill(Color.sketchEmerald200)
          .frame(height: 8)
          .offset(y: 4)
      }
      .padding(.horizontal, 20)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
          termCard(
            icon: "chart.line.uptrend.xyaxis",
            title: languageManager.isChinese ? "賠償比例" : "Cov. Ratio",
            impact: languageManager.isChinese ? "影響每次你自付多少" : "Affects how much you pay",
            good: languageManager.isChinese ? "≥70%, 愈高愈好" : "≥70%, higher is better", rot: 1)
          termCard(
            icon: "exclamationmark.shield.fill",
            title: languageManager.isChinese ? "年度上限" : "Annual Limit",
            impact: languageManager.isChinese ? "大病時會不會「報唔晒」" : "Will it cover big surgeries?",
            good: languageManager.isChinese ? "至少覆蓋一至兩次大手術" : "Cover 1-2 major bounds", rot: -1)
          termCard(
            icon: "minus.forwardslash.plus",
            title: languageManager.isChinese ? "自負額" : "Deductible",
            impact: languageManager.isChinese ? "小額醫療要不要自己吞" : "Do you pay for small bills?",
            good: languageManager.isChinese ? "常看門診，自負額不要太高" : "Frequent OP, keep it low", rot: 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
      }
    }
  }

  private func termCard(icon: String, title: String, impact: String, good: String, rot: Double)
    -> some View
  {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(Color.sketchEmerald200)
            .frame(width: 44, height: 44)
            .overlay(Circle().stroke(Color.sketchBlue900, lineWidth: 2))

          Image(systemName: icon)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.sketchEmerald800)
        }
        .rotationEffect(.degrees(rot > 0 ? 3 : -3))

        Text(title)
          .font(.system(size: 18, weight: .black))
          .foregroundColor(.sketchBlue900)
      }

      VStack(alignment: .leading, spacing: 0) {
        VStack(alignment: .leading, spacing: 4) {
          Text(languageManager.isChinese ? "對你有什麼影響" : "IMPACT")
            .font(.system(size: 10, weight: .black))
            .foregroundColor(.gray)
          Text(impact)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.black)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(Rectangle().stroke(Color.sketchBlue900, lineWidth: 2))

        VStack(alignment: .leading, spacing: 4) {
          Text(languageManager.isChinese ? "如何算「不錯」" : "GOOD STANDARD")
            .font(.system(size: 10, weight: .black))
            .foregroundColor(.sketchEmerald800)
          Text(good)
            .font(.system(size: 14, weight: .black))
            .foregroundColor(.sketchEmerald800)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sketchEmerald200)
        .overlay(Rectangle().stroke(Color.sketchBlue900, lineWidth: 2))
        .rotationEffect(.degrees(1))
        .offset(y: -2)
      }
    }
    .padding(16)
    .frame(width: 260)
    .sketchCard(rotation: rot, bg: .sketchEmerald50, shadow: 4)
  }

  private var notCoveredSection: some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(Color.white)
            .frame(width: 36, height: 36)
            .overlay(Circle().stroke(Color.sketchBlue900, lineWidth: 2))
            .shadow(color: .sketchBlue900, radius: 0, x: 2, y: 2)

          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.sketchRose600)
            .font(.system(size: 16))
        }
        .rotationEffect(.degrees(-6))

        VStack(alignment: .leading) {
          Text(languageManager.isChinese ? "這些情況通常不受保" : "Usually Not Covered")
            .font(.system(size: 18, weight: .black))
            .foregroundColor(.sketchBlue900)
          Text(languageManager.isChinese ? "很容易踩雷 💣" : "Watch out 💣")
            .font(.system(size: 12, weight: .black))
            .foregroundColor(.sketchRose600)
        }
        Spacer()
      }
      .padding(16)
      .background(Color.sketchRose200)
      .overlay(
        VStack {
          Spacer()
          Rectangle().frame(height: 2).foregroundColor(.sketchBlue900)
        }
      )

      VStack(spacing: 16) {
        notCoveredItem(
          title: languageManager.isChinese ? "既往病 & 等候期" : "Pre-existing & Waiting",
          desc: languageManager.isChinese
            ? "投保前已有的疾病，以及等候期內發現的疾病通常不保"
            : "Conditions before or during waiting period are excluded.", rot: 1)
        notCoveredItem(
          title: languageManager.isChinese ? "日常護理" : "Routine Care",
          desc: languageManager.isChinese
            ? "疫苗、洗牙、美容等預防性及日常護理不在保障範圍" : "Vaccines, cleaning, grooming are not covered.", rot: -1)
        notCoveredItem(
          title: languageManager.isChinese ? "配種、懷孕、主人疏忽" : "Breeding & Neglect",
          desc: languageManager.isChinese
            ? "配種相關費用、懷孕分娩，以及主人蓄意或嚴重疏忽的情況" : "Breeding, pregnancy, or intentional neglect.", rot: 0)
      }
      .padding(20)
    }
    .sketchCard(rotation: 1, bg: .sketchRose50, shadow: 4)
    .padding(.horizontal, 20)
  }

  private func notCoveredItem(title: String, desc: String, rot: Double) -> some View {
    HStack(alignment: .top, spacing: 12) {
      ZStack {
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.sketchRose200)
          .frame(width: 24, height: 24)
          .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.sketchBlue900, lineWidth: 2))

        Image(systemName: "xmark")
          .font(.system(size: 12, weight: .black))
          .foregroundColor(.sketchRose600)
      }
      .rotationEffect(.degrees(rot > 0 ? 3 : -3))

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 14, weight: .black))
          .foregroundColor(.sketchBlue900)
        Text(desc)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.gray)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .sketchCard(rotation: rot, bg: .white, shadow: 2)
  }

  private var whyInsuranceSection: some View {
    VStack(alignment: .leading, spacing: 20) {
      ZStack(alignment: .bottomLeading) {
        Text(languageManager.isChinese ? "為什麼需要保險？" : "Why Insurance?")
          .font(.system(size: 24, weight: .black))
          .foregroundColor(.sketchBlue900)

        Circle()
          .fill(Color.sketchBlue200)
          .frame(width: 30, height: 30)
          .offset(x: -10, y: -10)
          .zIndex(-1)
      }
      .padding(.horizontal, 20)

      // No Insurance Card
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 12) {
          ZStack {
            Circle()
              .fill(Color(white: 0.8))
              .frame(width: 44, height: 44)
              .overlay(Circle().stroke(Color.sketchBlue900, lineWidth: 2))

            Image(systemName: "xmark")
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.black)
          }
          .rotationEffect(.degrees(-6))

          Text(languageManager.isChinese ? "沒有保險" : "No Insurance")
            .font(.system(size: 20, weight: .black))
            .foregroundColor(.sketchBlue900)
        }

        Text(
          languageManager.isChinese ? "狗狗突發椎間盤問題，手術+住院 30,000" : "Dog IVDD surgery + hospital 30k"
        )
        .font(.system(size: 14, weight: .bold))
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sketchCard(rotation: 1, bg: .white, shadow: 0)

        HStack {
          Text("⚠️")
          Text(languageManager.isChinese ? "一次過全數自付：30,000" : "Pay all at once: 30,000")
            .font(.system(size: 16, weight: .black))
            .foregroundColor(Color(red: 153 / 255, green: 27 / 255, blue: 27 / 255))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sketchCard(rotation: 1, bg: .sketchRose200, shadow: 2)
      }
      .padding(16)
      .sketchCard(rotation: -1, bg: Color(white: 0.95), shadow: 4)
      .padding(.horizontal, 20)
      .overlay(
        Text(languageManager.isChinese ? "好痛！💸" : "Ouch! 💸")
          .font(.system(size: 12, weight: .black))
          .foregroundColor(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .sketchCard(rotation: 6, bg: .sketchRose600, shadow: 2)
          .offset(x: -10, y: -10),
        alignment: .topTrailing
      )

      // Has Insurance Card
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 12) {
          ZStack {
            Circle()
              .fill(Color.sketchBlue300)
              .frame(width: 44, height: 44)
              .overlay(Circle().stroke(Color.sketchBlue900, lineWidth: 2))

            Image(systemName: "checkmark")
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.sketchBlue900)
          }
          .rotationEffect(.degrees(6))

          Text(languageManager.isChinese ? "有保險 (70% 保障)" : "Insured (70% Cov)")
            .font(.system(size: 20, weight: .black))
            .foregroundColor(.sketchBlue900)
        }

        Text(languageManager.isChinese ? "同一情況，手術+住院 30,000" : "Same case, surgery + hospital 30k")
          .font(.system(size: 14, weight: .bold))
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .sketchCard(rotation: 1, bg: .white, shadow: 2)

        VStack(spacing: 12) {
          HStack {
            Text(languageManager.isChinese ? "保險承擔：" : "Insurance pays:")
              .font(.system(size: 14, weight: .bold))
            Spacer()
            Text("21,000")
              .font(.system(size: 18, weight: .black))
          }
          .foregroundColor(.sketchBlue900)
          .padding(12)
          .sketchCard(rotation: 0, bg: .sketchBlue200, shadow: 0)

          HStack {
            HStack(spacing: 6) {
              Circle()
                .fill(Color.sketchBlue100)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color.sketchBlue900, lineWidth: 2))
                .overlay(
                  Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                    .foregroundColor(.sketchBlue900))

              Text(languageManager.isChinese ? "你只需自付：" : "You only pay:")
                .font(.system(size: 14, weight: .bold))
            }
            Spacer()
            Text("9,000")
              .font(.system(size: 24, weight: .black))
          }
          .foregroundColor(Color(red: 29 / 255, green: 78 / 255, blue: 216 / 255))
          .padding(16)
          .sketchCard(rotation: -1, bg: .white, shadow: 4)
        }
      }
      .padding(16)
      .sketchCard(rotation: 2, bg: .sketchBlue100, shadow: 4)
      .padding(.horizontal, 20)
      .overlay(
        Text(languageManager.isChinese ? "省下 21,000! 🎉" : "Saved 21k! 🎉")
          .font(.system(size: 12, weight: .black))
          .foregroundColor(.sketchBlue900)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .sketchCard(rotation: -6, bg: .sketchYellow300, shadow: 2)
          .offset(x: -10, y: -10),
        alignment: .topTrailing
      )
    }
  }
}

#Preview {
  InsuranceLandingView()
    .environmentObject(LanguageManager())
}
