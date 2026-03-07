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
  @State private var pendingExpandId: String? = nil
  private let accordionAnimation = Animation.spring(
    response: 0.62,
    dampingFraction: 0.9,
    blendDuration: 0.3
  )

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

              LazyVStack(spacing: 16) {
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
    if expandedScenarioId == scenarioId {
      pendingExpandId = nil
      withAnimation(accordionAnimation) {
        expandedScenarioId = nil
      }
      return
    }

    pendingExpandId = scenarioId
    withAnimation(.easeInOut(duration: 0.4)) {
      proxy.scrollTo(scenarioId, anchor: .top)
    }

    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 240_000_000)
      guard pendingExpandId == scenarioId else { return }
      withAnimation(accordionAnimation) {
        expandedScenarioId = scenarioId
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
    .animation(.spring(response: 0.62, dampingFraction: 0.9, blendDuration: 0.3), value: isExpanded)
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
