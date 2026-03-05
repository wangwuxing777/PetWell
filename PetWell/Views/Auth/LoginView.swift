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
  @State private var showPasswordLogin = false
  @State private var showPassword = false

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

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Button {
            if viewModel.otpSent {
              // Go back from OTP to email input
              viewModel.otpSent = false
              viewModel.verificationCode = ""
            } else {
              dismiss()
            }
          } label: {
            Image(systemName: "chevron.left")
              .font(.title3.weight(.semibold))
              .foregroundColor(.white.opacity(0.95))
              .frame(width: 28, height: 28)
          }
          .padding(.top, 12)

          if showPasswordLogin {
            // Password Login Form
            passwordLoginForm
          } else if viewModel.otpSent {
            // OTP Verification Form
            otpVerificationForm
          } else {
            // Email Verification Form (Send OTP)
            emailVerificationForm
          }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
      }
    }
    .navigationBarBackButtonHidden(true)
    .onAppear {
      viewModel.errorMessage = nil
    }
  }

  // MARK: - Email Verification Form (Send OTP)
  private var emailVerificationForm: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Email Login")
        .font(.title2.weight(.bold))
        .foregroundColor(.white)
        .padding(.top, 26)

      Text("Enter your email to receive a verification code.")
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
        Task { await viewModel.sendOTP() }
      } label: {
        HStack {
          if viewModel.isLoading {
            ProgressView().tint(.white)
          } else {
            Text("Send Verification Code")
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
          .foregroundColor(errorMessage.contains("sent") || errorMessage.contains("Demo") ? Color.white.opacity(0.82) : Color(red: 1, green: 0.84, blue: 0.84))
          .padding(.top, 12)
      }

      // Switch to password login link
      HStack {
        Spacer()
        Button("Use password instead") {
          withAnimation {
            showPasswordLogin = true
          }
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.7))
      }
      .padding(.top, 16)

      Spacer()
    }
  }

  // MARK: - OTP Verification Form
  private var otpVerificationForm: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Enter Code")
        .font(.title2.weight(.bold))
        .foregroundColor(.white)
        .padding(.top, 26)

      Text("We've sent a verification code to \(viewModel.identifier)")
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.72))
        .padding(.top, 8)

      // OTP Input Field
      HStack(spacing: 10) {
        Image(systemName: "lock")
          .foregroundColor(.white.opacity(0.85))
        TextField("Verification code", text: $viewModel.verificationCode)
          .keyboardType(.numberPad)
          .foregroundColor(.white)
          .onChange(of: viewModel.verificationCode) { _, newValue in
            // Limit to 6 digits
            if newValue.count > 6 {
              viewModel.verificationCode = String(newValue.prefix(6))
            }
          }
      }
      .padding(.horizontal, 14)
      .frame(height: 54)
      .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(Color.white.opacity(0.34), lineWidth: 1)
      )
      .padding(.top, 24)

      // Countdown Timer
      if viewModel.countdownSeconds > 0 {
        HStack {
          Image(systemName: "clock")
            .font(.caption)
          Text("Resend in \(viewModel.countdownSeconds)s")
            .font(.caption)
        }
        .foregroundColor(.white.opacity(0.6))
        .padding(.top, 12)
      } else {
        // Resend Button
        Button {
          Task { await viewModel.resendOTP() }
        } label: {
          HStack {
            Image(systemName: "arrow.clockwise")
            Text("Resend Code")
          }
          .font(.caption)
          .foregroundColor(.blue)
        }
        .padding(.top, 12)
        .disabled(viewModel.isLoading)
      }

      // Verify Button
      Button {
        Task { await viewModel.verifyOTP() }
      } label: {
        HStack {
          if viewModel.isLoading {
            ProgressView().tint(.white)
          } else {
            Text("Verify & Login")
          }
        }
        .font(.headline.weight(.semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(viewModel.isValidOTP ? Color.white.opacity(0.16) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
      }
      .disabled(!viewModel.isValidOTP || viewModel.isLoading)
      .padding(.top, 24)

      // Demo hint
      HStack {
        Image(systemName: "info.circle")
          .font(.caption2)
        Text("Demo: Enter any 6-digit code")
          .font(.caption2)
      }
      .foregroundColor(.white.opacity(0.5))
      .padding(.top, 8)

      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(.caption)
          .foregroundColor(Color(red: 1, green: 0.84, blue: 0.84))
          .padding(.top, 12)
      }

      // Back to email button
      HStack {
        Spacer()
        Button("Change email") {
          viewModel.otpSent = false
          viewModel.verificationCode = ""
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.7))
      }
      .padding(.top, 16)

      Spacer()
    }
  }

  // MARK: - Password Login Form
  private var passwordLoginForm: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Password Login")
        .font(.title2.weight(.bold))
        .foregroundColor(.white)
        .padding(.top, 26)

      Text("Enter your email and password to sign in.")
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.72))
        .padding(.top, 8)

      // Email Field
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

      // Password Field
      HStack(spacing: 10) {
        Image(systemName: "lock")
          .foregroundColor(.white.opacity(0.85))
        if showPassword {
          TextField("Password", text: $viewModel.password)
            .foregroundColor(.white)
        } else {
          SecureField("Password", text: $viewModel.password)
            .foregroundColor(.white)
        }
        Button {
          showPassword.toggle()
        } label: {
          Image(systemName: showPassword ? "eye.slash" : "eye")
            .foregroundColor(.white.opacity(0.6))
        }
      }
      .padding(.horizontal, 14)
      .frame(height: 54)
      .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(Color.white.opacity(0.34), lineWidth: 1)
      )
      .padding(.top, 16)

      // Login Button
      Button {
        Task { await viewModel.signInWithPassword() }
      } label: {
        HStack {
          if viewModel.isLoading {
            ProgressView().tint(.white)
          } else {
            Text("Sign In")
          }
        }
        .font(.headline.weight(.semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(viewModel.isValidInput ? Color.white.opacity(0.16) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
      }
      .disabled(!viewModel.isValidInput || viewModel.isLoading)
      .padding(.top, 24)

      // Demo hint
      HStack {
        Image(systemName: "info.circle")
          .font(.caption2)
        Text("Demo: demo@petwell.com / demo123")
          .font(.caption2)
      }
      .foregroundColor(.white.opacity(0.5))
      .padding(.top, 8)

      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(.caption)
          .foregroundColor(Color(red: 1, green: 0.84, blue: 0.84))
          .padding(.top, 12)
      }

      // Switch to email verification link
      HStack {
        Spacer()
        Button("Use verification code instead") {
          withAnimation {
            showPasswordLogin = false
          }
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.7))
      }
      .padding(.top, 16)

      Spacer()
    }
  }
}

#Preview {
  LoginView(viewModel: AuthViewModel())
}
