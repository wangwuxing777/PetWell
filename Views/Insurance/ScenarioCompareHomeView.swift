//
//  ScenarioCompareHomeView.swift
//  PetWell
//
//  Created by AI Assistant on 2026/2/24.
//

import SwiftUI

struct ScenarioCompareHomeView: View {
  @StateObject private var scenarioService = ScenarioService.shared
  @State private var expandedScenarioId: String? = nil
  @State private var toggleTask: Task<Void, Never>? = nil

  // 快速收起：无弹跳，布局稳定后再做下一步
  private let collapseAnimation = Animation.spring(response: 0.26, dampingFraction: 1.0)
  // 展开：轻微弹性，有呼吸感
  private let expandAnimation   = Animation.spring(response: 0.46, dampingFraction: 0.84)

  var body: some View {
    ScrollViewReader { proxy in
      ZStack {
        AppTheme.bgBase.ignoresSafeArea()

        if scenarioService.isLoading {
          ProgressView("Loading scenarios...")
        } else if let error = scenarioService.errorMessage {
          VStack {
            Text("Error loading data")
              .font(.headline)
              .foregroundColor(.red)
            Text(error)
              .font(.caption)
              .foregroundColor(.secondary)

            Button("Retry") {
              Task { await scenarioService.fetchScenarios() }
            }
            .padding(.top)
          }
        } else {
          ScrollView {
            VStack(alignment: .leading, spacing: 16) {

              Text("Compare insurance payouts for real-world veterinary scenarios.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

              VStack(spacing: 16) {
                ForEach(scenarioService.scenarios) { scenario in
                  ScenarioAccordionCard(
                    scenario: scenario,
                    isExpanded: expandedScenarioId == scenario.id,
                    onToggle: {
                      handleCardToggle(for: scenario.id, proxy: proxy)
                    }
                  )
                  .id(scenario.id)
                }
              }
              .padding(.horizontal)
              .padding(.bottom, 24)
            }
            .padding(.top, 16)
          }
        }
      }
    }
  }

  private func handleCardToggle(for scenarioId: String, proxy: ScrollViewProxy) {
    // 取消任何未完成的切换操作，防止并发 Task 互相干扰
    toggleTask?.cancel()

    // 点击已展开的卡片 → 直接收起
    if expandedScenarioId == scenarioId {
      withAnimation(collapseAnimation) {
        expandedScenarioId = nil
      }
      return
    }

    // 记录是否有卡片需要先收起（决定是否需要等待布局稳定）
    let hadExpanded = expandedScenarioId != nil

    // Step 1：立即收起当前展开的卡片，让布局先稳定
    withAnimation(collapseAnimation) {
      expandedScenarioId = nil
    }

    toggleTask = Task { @MainActor in
      // Step 2：若有卡片收起，等收起 spring 落定后再滚动（response=0.26s，等 0.28s 确保完全稳定）
      if hadExpanded {
        try? await Task.sleep(nanoseconds: 280_000_000)
      }
      guard !Task.isCancelled else { return }

      // Step 3：滚动到目标卡片顶部
      withAnimation(.easeInOut(duration: 0.30)) {
        proxy.scrollTo(scenarioId, anchor: .top)
      }

      // Step 4：等滚动完成后再展开
      try? await Task.sleep(nanoseconds: 320_000_000)  // 0.32s，覆盖滚动时长并留有余量
      guard !Task.isCancelled else { return }

      withAnimation(expandAnimation) {
        expandedScenarioId = scenarioId
      }

      // Step 5：等展开 spring 落定后，再次锚定到卡片顶部
      // expandAnimation: response=0.46s, dampingFraction=0.84 → ~520ms 完全稳定
      try? await Task.sleep(nanoseconds: 520_000_000)
      guard !Task.isCancelled else { return }

      withAnimation(.easeOut(duration: 0.22)) {
        proxy.scrollTo(scenarioId, anchor: .top)
      }
    }
  }
}

struct ScenarioAccordionCard: View {
  let scenario: Scenario
  let isExpanded: Bool
  let onToggle: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Button(action: onToggle) {
        ScenarioCard(scenario: scenario)
      }
      .buttonStyle(.plain)

      if isExpanded {
        ScenarioDetailView(scenario: scenario)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .background(
      .ultraThinMaterial,
      in: RoundedRectangle(cornerRadius: 18, style: .continuous)
    )
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(Color.white.opacity(0.28), lineWidth: 0.9)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(
          LinearGradient(
            colors: [Color.white.opacity(0.35), Color.clear, Color.white.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 0.8
        )
    )
    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    .animation(.spring(response: 0.46, dampingFraction: 0.84), value: isExpanded)
  }
}

struct ScenarioCard: View {
  let scenario: Scenario

  var body: some View {
    // Use the midpoint between previous card #4 and #5 settings.
    let imageBlurRadius: CGFloat = 1.65
    let darkOverlayStart = 0.85
    let darkOverlayEnd = 0.2
    let whiteHighlight = 0.0
    let materialOpacity = 0.1

    ZStack(alignment: .bottomLeading) {
      // 1. Background Image
      Image(scenario.presentation.imageName)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(height: 180)
        .saturation(0.9)
        .blur(radius: imageBlurRadius)
        .clipped()

      // 2. Glass + gradient overlay to keep text readable while retaining the photo
      Rectangle()
        .fill(.ultraThinMaterial)
        .opacity(materialOpacity)

      LinearGradient(
        gradient: Gradient(
          colors: [Color.black.opacity(darkOverlayStart), Color.black.opacity(darkOverlayEnd)]
        ),
        startPoint: .bottom,
        endPoint: .top
      )

      LinearGradient(
        gradient: Gradient(colors: [Color.white.opacity(whiteHighlight), Color.clear]),
        startPoint: .topLeading,
        endPoint: .center
      )

      // 3. Text Overlay
      VStack(alignment: .leading, spacing: 8) {
        Text(scenario.presentation.title)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .lineLimit(2)

        Text(scenario.presentation.description)
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.9))
          .lineLimit(2)
      }
      .padding(16)
    }
    .frame(height: 180)  // Fixed height to maintain image aspect ratio consistently in the list
    .contentShape(Rectangle())
  }
}
