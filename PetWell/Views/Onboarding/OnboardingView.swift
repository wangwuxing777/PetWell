//
//  OnboardingView.swift
//  PetWell
//
//  Created by AI Assistant on 2026/03/01.
//

import SwiftUI

struct OnboardingStep {
  let icon: String
  let title: String
  let description: String
  let color: Color
}

struct OnboardingView: View {
  @ObservedObject var authViewModel: AuthViewModel
  @State private var currentStep = 0

  let steps: [OnboardingStep] = [
    OnboardingStep(
      icon: "bubble.left.and.bubble.right.fill",
      title: "Blog",
      description:
        "Share your pet's daily stories, discover tips from other pet owners, and connect with the pet-loving community.",
      color: .blue
    ),
    OnboardingStep(
      icon: "bag",
      title: "Shop",
      description:
        "Browse and purchase premium pet products — food, toys, accessories, and health essentials, all in one place.",
      color: .green
    ),
    OnboardingStep(
      icon: "cross.case",
      title: "Medical",
      description:
        "Track your pet's vaccinations, schedule vet visits, and keep a complete medical history for easy reference.",
      color: .red
    ),
    OnboardingStep(
      icon: "shield",
      title: "Insurance",
      description:
        "Compare pet insurance plans side-by-side, understand coverage scenarios, and find the best protection for your furry friend.",
      color: .orange
    ),
    OnboardingStep(
      icon: "person.circle",
      title: "Profile",
      description:
        "Manage your pet's profile, view health records, track weight trends, and keep all important information organized.",
      color: .purple
    ),
  ]

  var isLastStep: Bool { currentStep == steps.count - 1 }

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        colors: [
          steps[currentStep].color.opacity(0.15),
          Color(.systemBackground),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
      .animation(.easeInOut(duration: 0.5), value: currentStep)

      VStack(spacing: 0) {
        // Skip button
        HStack {
          Spacer()
          if !isLastStep {
            Button("Skip") {
              authViewModel.completeOnboarding()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.trailing, 24)
            .padding(.top, 16)
          }
        }

        Spacer()

        // Icon
        ZStack {
          Circle()
            .fill(steps[currentStep].color.opacity(0.15))
            .frame(width: 160, height: 160)

          Circle()
            .fill(steps[currentStep].color.opacity(0.25))
            .frame(width: 120, height: 120)

          Image(systemName: steps[currentStep].icon)
            .font(.system(size: 48, weight: .medium))
            .foregroundColor(steps[currentStep].color)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)

        Spacer().frame(height: 48)

        // Title
        Text(steps[currentStep].title)
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.primary)
          .id("title-\(currentStep)")  // Force re-render for transition
          .transition(
            .asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            ))

        Spacer().frame(height: 16)

        // Description
        Text(steps[currentStep].description)
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
          .id("desc-\(currentStep)")
          .transition(
            .asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            ))

        Spacer()

        // Progress Dots
        HStack(spacing: 8) {
          ForEach(0..<steps.count, id: \.self) { index in
            Circle()
              .fill(index == currentStep ? steps[currentStep].color : Color.gray.opacity(0.3))
              .frame(width: index == currentStep ? 10 : 6, height: index == currentStep ? 10 : 6)
              .animation(.easeInOut(duration: 0.3), value: currentStep)
          }
        }
        .padding(.bottom, 32)

        // Counter + Next button
        HStack {
          Text("\(currentStep + 1) / \(steps.count)")
            .font(.subheadline)
            .foregroundColor(.secondary)

          Spacer()

          Button(action: {
            withAnimation(.easeInOut(duration: 0.4)) {
              if isLastStep {
                authViewModel.completeOnboarding()
              } else {
                currentStep += 1
              }
            }
          }) {
            HStack(spacing: 8) {
              Text(isLastStep ? "Get Started" : "Next")
                .font(.headline)

              Image(systemName: isLastStep ? "checkmark" : "arrow.right")
                .font(.subheadline.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(steps[currentStep].color)
            .cornerRadius(28)
            .shadow(color: steps[currentStep].color.opacity(0.4), radius: 8, x: 0, y: 4)
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
      }
    }
  }
}
