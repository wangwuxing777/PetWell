//
//  LoginView.swift
//  PetWell
//
//  Created by AI Assistant on 2026/03/01.
//

import SwiftUI

struct LoginView: View {
  @ObservedObject var viewModel: AuthViewModel
  @State private var showEmailLogin = false

  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          colors: [
            Color(red: 0.04, green: 0.10, blue: 0.25),
            Color(red: 0.11, green: 0.28, blue: 0.58),
            Color(red: 0.23, green: 0.47, blue: 0.82)
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        Ellipse()
          .fill(Color.white.opacity(0.24))
          .frame(width: 360, height: 120)
          .blur(radius: 30)
          .rotationEffect(.degrees(-8))
          .offset(x: -30, y: -190)

        Ellipse()
          .fill(Color.white.opacity(0.12))
          .frame(width: 320, height: 110)
          .blur(radius: 38)
          .rotationEffect(.degrees(15))
          .offset(x: 90, y: -120)

        VStack(spacing: 0) {
          HStack {
            Spacer()
            Button("Skip") {
              viewModel.continueAsGuest()
            }
            .font(.callout.weight(.semibold))
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
          }
          .padding(.horizontal, 24)
          .padding(.top, 16)

          Spacer()

          VStack(spacing: 10) {
            Text("PetWell")
              .font(.system(size: 56, weight: .bold))
              .foregroundColor(.white)
            Text("Protect every moment")
              .font(.subheadline.weight(.medium))
              .foregroundColor(.white.opacity(0.72))
          }

          Spacer()

          VStack(spacing: 12) {
            Button {
              Task { await viewModel.signInWithGoogle() }
            } label: {
              AuthWideButton(title: "Continue with Google", icon: "g.circle.fill")
            }
            .disabled(viewModel.isLoading)

            Button {
              Task { await viewModel.signInWithX() }
            } label: {
              AuthWideButton(title: "Continue with X", icon: "xmark")
            }
            .disabled(viewModel.isLoading)

            HStack(spacing: 12) {
              Button {
                Task { await viewModel.signInWithApple() }
              } label: {
                AuthHalfButton(icon: "apple.logo", title: "Apple")
              }
              .disabled(viewModel.isLoading)

              Button {
                showEmailLogin = true
              } label: {
                AuthHalfButton(icon: "envelope.fill", title: "Email")
              }
              .disabled(viewModel.isLoading)
            }
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 28)

          Text("By continuing you agree to the Terms of Service and Privacy Policy")
            .font(.caption2)
            .foregroundColor(.white.opacity(0.55))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 26)
            .padding(.bottom, 10)

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(.caption)
              .foregroundColor(Color(red: 1, green: 0.84, blue: 0.84))
              .padding(.bottom, 12)
          }
        }
      }
      .navigationBarHidden(true)
      .navigationDestination(isPresented: $showEmailLogin) {
        EmailLoginView(viewModel: viewModel)
      }
    }
  }
}

private struct AuthWideButton: View {
  let title: String
  let icon: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
      Text(title)
        .font(.headline.weight(.semibold))
    }
    .foregroundColor(.white.opacity(0.96))
    .frame(maxWidth: .infinity)
    .frame(height: 52)
    .background(Color.white.opacity(0.12), in: Capsule())
    .overlay(Capsule().stroke(Color.white.opacity(0.34), lineWidth: 1))
  }
}

private struct AuthHalfButton: View {
  let icon: String
  let title: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
      Text(title)
        .font(.headline.weight(.semibold))
    }
    .foregroundColor(.white.opacity(0.96))
    .frame(maxWidth: .infinity)
    .frame(height: 50)
    .background(Color.white.opacity(0.10), in: Capsule())
    .overlay(Capsule().stroke(Color.white.opacity(0.34), lineWidth: 1))
  }
}

private struct EmailLoginView: View {
  @ObservedObject var viewModel: AuthViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.04, green: 0.10, blue: 0.25),
          Color(red: 0.11, green: 0.28, blue: 0.58),
          Color(red: 0.23, green: 0.47, blue: 0.82)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      Ellipse()
        .fill(Color.white.opacity(0.20))
        .frame(width: 320, height: 100)
        .blur(radius: 30)
        .rotationEffect(.degrees(-8))
        .offset(x: -40, y: -250)

      VStack(alignment: .leading, spacing: 0) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.title3.weight(.semibold))
            .foregroundColor(.white.opacity(0.95))
            .frame(width: 28, height: 28)
        }
        .padding(.top, 12)

        Text("Email Login")
          .font(.title2.weight(.bold))
          .foregroundColor(.white)
          .padding(.top, 26)

        Text("If this email exists in our system, we'll send a verification link.")
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.72))
          .padding(.top, 8)

        HStack(spacing: 10) {
          Image(systemName: "envelope")
            .foregroundColor(.white.opacity(0.85))
          TextField("Email address", text: $viewModel.identifier)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
        .padding(.top, 24)

        Button {
          Task { await viewModel.requestEmailVerification() }
        } label: {
          HStack {
            if viewModel.isLoading {
              ProgressView().tint(.white)
            } else {
              Text("Verify and Login")
            }
          }
          .font(.headline.weight(.semibold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 54)
          .background(viewModel.isValidEmail ? Color.white.opacity(0.16) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .stroke(Color.white.opacity(0.34), lineWidth: 1)
          )
        }
        .disabled(!viewModel.isValidEmail || viewModel.isLoading)
        .padding(.top, 34)

        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
            .font(.caption)
            .foregroundColor(errorMessage.contains("sent") ? Color.white.opacity(0.82) : Color(red: 1, green: 0.84, blue: 0.84))
            .padding(.top, 12)
        }

        Spacer()
      }
      .padding(.horizontal, 28)
      .padding(.bottom, 24)
    }
    .navigationBarBackButtonHidden(true)
    .onAppear {
      viewModel.errorMessage = nil
    }
  }
}

#Preview {
  LoginView(viewModel: AuthViewModel())
}
