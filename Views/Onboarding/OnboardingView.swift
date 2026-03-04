//
//  OnboardingView.swift
//  PetWell
//
//  Created by AI Assistant on 2026/03/01.
//

import SwiftUI

private struct OnboardingSlide {
  let title: String
  let subtitle: String
  let accent: Color
}

struct OnboardingView: View {
  @ObservedObject var authViewModel: AuthViewModel
  @State private var currentIndex = 0

  private let slides: [OnboardingSlide] = [
    OnboardingSlide(
      title: "Blog",
      subtitle: "Post daily updates, photos, and tips with the pet community.",
      accent: .blue
    ),
    OnboardingSlide(
      title: "Shop · For You",
      subtitle: "Use smart recommendations to find products for your pet faster.",
      accent: .mint
    ),
    OnboardingSlide(
      title: "Insurance Compare",
      subtitle: "Scroll, tap compare, and quickly check plans under different scenarios.",
      accent: .orange
    ),
    OnboardingSlide(
      title: "Medical",
      subtitle: "Find clinics, check vaccines, and manage your pet health timeline.",
      accent: .red
    ),
    OnboardingSlide(
      title: "Profile",
      subtitle: "Keep owner + pet records complete and ready whenever needed.",
      accent: .purple
    ),
  ]

  private var isLastPage: Bool { currentIndex == slides.count - 1 }

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.04, green: 0.10, blue: 0.25),
          Color(red: 0.11, green: 0.28, blue: 0.58),
          Color(red: 0.23, green: 0.47, blue: 0.82),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      Ellipse()
        .fill(Color.white.opacity(0.18))
        .frame(width: 360, height: 120)
        .blur(radius: 30)
        .rotationEffect(.degrees(-8))
        .offset(x: -20, y: -280)

      Ellipse()
        .fill(Color.white.opacity(0.1))
        .frame(width: 300, height: 110)
        .blur(radius: 36)
        .rotationEffect(.degrees(12))
        .offset(x: 110, y: -140)

      VStack(spacing: 0) {
        HStack {
          Spacer()
          Button("Skip") {
            authViewModel.completeOnboarding()
          }
          .font(.callout.weight(.semibold))
          .foregroundColor(.white.opacity(0.92))
          .padding(.horizontal, 16)
          .padding(.vertical, 9)
          .background(Color.white.opacity(0.14), in: Capsule())
          .overlay(Capsule().stroke(Color.white.opacity(0.34), lineWidth: 1))
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)

        Spacer()

        demoCard(for: currentIndex)
          .padding(.horizontal, 24)

        Spacer().frame(height: 28)

        Text(slides[currentIndex].title)
          .font(.system(size: 34, weight: .bold))
          .foregroundColor(.white)

        Text(slides[currentIndex].subtitle)
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.78))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 34)
          .padding(.top, 8)

        Spacer()

        HStack(spacing: 8) {
          ForEach(slides.indices, id: \.self) { index in
            Circle()
              .fill(index == currentIndex ? slides[currentIndex].accent : Color.white.opacity(0.32))
              .frame(width: index == currentIndex ? 10 : 7, height: index == currentIndex ? 10 : 7)
          }
        }
        .padding(.bottom, 24)

        Button {
          if isLastPage {
            authViewModel.completeOnboarding()
          } else {
            withAnimation(.easeInOut(duration: 0.28)) {
              currentIndex += 1
            }
          }
        } label: {
          HStack(spacing: 8) {
            Text(isLastPage ? "Get Started" : "Next")
              .font(.headline.weight(.bold))
            Image(systemName: isLastPage ? "checkmark" : "arrow.right")
              .font(.subheadline.weight(.bold))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 54)
          .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .stroke(Color.white.opacity(0.38), lineWidth: 1)
          )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
      }
    }
  }

  @ViewBuilder
  private func demoCard(for index: Int) -> some View {
    GlassDemoCard {
      switch index {
      case 0: blogDemo
      case 1: shopDemo
      case 2: insuranceDemo
      case 3: medicalDemo
      default: profileDemo
      }
    }
  }

  private var blogDemo: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Explore")
          .font(.headline.weight(.bold))
        Spacer()
        Image(systemName: "plus.square.fill")
          .foregroundColor(.blue)
      }
      Rectangle().fill(Color.blue.opacity(0.2)).frame(height: 70).cornerRadius(10)
      HStack(spacing: 10) {
        Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 56).cornerRadius(8)
        Rectangle().fill(Color.gray.opacity(0.18)).frame(height: 56).cornerRadius(8)
      }
    }
  }

  private var shopDemo: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Shop")
          .font(.headline.weight(.bold))
        Spacer()
        Image(systemName: "line.3.horizontal.decrease.circle.fill")
          .foregroundColor(.mint)
      }
      HStack(spacing: 8) {
        Text("For my pet")
          .font(.caption.weight(.bold))
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Color.blue.opacity(0.16), in: Capsule())
        Text("Food")
          .font(.caption)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Color.gray.opacity(0.15), in: Capsule())
      }
      HStack(spacing: 10) {
        Rectangle().fill(Color.gray.opacity(0.18)).frame(height: 78).cornerRadius(10)
        Rectangle().fill(Color.gray.opacity(0.18)).frame(height: 78).cornerRadius(10)
      }
    }
  }

  private var insuranceDemo: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Pet Insurance")
        .font(.headline.weight(.bold))
      Rectangle().fill(Color.orange.opacity(0.2)).frame(height: 80).cornerRadius(10)
      HStack {
        Text("Compare")
          .font(.caption.weight(.bold))
          .foregroundColor(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 7)
          .background(Color.blue, in: Capsule())
        Spacer()
        Text("For Me")
          .font(.caption.weight(.semibold))
          .padding(.horizontal, 12)
          .padding(.vertical, 7)
          .background(Color.gray.opacity(0.15), in: Capsule())
      }
      Rectangle().fill(Color.gray.opacity(0.16)).frame(height: 52).cornerRadius(8)
    }
  }

  private var medicalDemo: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Pet Health Center")
          .font(.headline.weight(.bold))
        Spacer()
        Image(systemName: "map.fill")
          .foregroundColor(.blue)
      }
      HStack(spacing: 10) {
        serviceTile("24h", color: .red)
        serviceTile("Check", color: .blue)
        serviceTile("Care", color: .green)
      }
      Rectangle().fill(Color.gray.opacity(0.16)).frame(height: 48).cornerRadius(8)
    }
  }

  private var profileDemo: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Profile")
          .font(.headline.weight(.bold))
        Spacer()
        Image(systemName: "plus.circle.fill")
          .foregroundColor(.blue)
      }
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.gray.opacity(0.16))
        .frame(height: 64)
        .overlay(alignment: .leading) {
          HStack(spacing: 10) {
            Circle().fill(Color.gray.opacity(0.26)).frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 4) {
              RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.35)).frame(width: 80, height: 8)
              RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.25)).frame(width: 120, height: 8)
            }
          }
          .padding(.horizontal, 10)
        }
      Rectangle().fill(Color.gray.opacity(0.14)).frame(height: 46).cornerRadius(8)
    }
  }

  private func serviceTile(_ title: String, color: Color) -> some View {
    VStack(spacing: 8) {
      Circle().fill(color.opacity(0.22)).frame(width: 26, height: 26)
      Text(title).font(.caption2)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
    .background(Color.gray.opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

private struct GlassDemoCard<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    VStack {
      content
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .frame(height: 270)
    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(
          LinearGradient(
            colors: [Color.white.opacity(0.75), Color.white.opacity(0.22)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .shadow(color: .black.opacity(0.2), radius: 22, x: 0, y: 10)
  }
}
