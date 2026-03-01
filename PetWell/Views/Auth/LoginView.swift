//
//  LoginView.swift
//  PetWell
//
//  Created by AI Assistant on 2026/03/01.
//

import SwiftUI

struct LoginView: View {
  @ObservedObject var viewModel: AuthViewModel

  var body: some View {
    ZStack {
      Color(hex: "F8F9FA").ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 28) {

          // Welcome Header
          VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to PetWell")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.primary)

            Text("Sign in to manage your pet's insurance and health records.")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.top, 60)

          // Input Fields
          VStack(spacing: 20) {
            // Identifier Field
            VStack(alignment: .leading, spacing: 8) {
              Text("Email or Phone Number")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

              TextField("Enter email or phone", text: $viewModel.identifier)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }

            // Password Field
            VStack(alignment: .leading, spacing: 8) {
              Text("Password")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

              SecureField("Enter your password", text: $viewModel.password)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

              HStack {
                Spacer()
                Button("Forgot Password?") {}
                  .font(.caption)
                  .fontWeight(.medium)
                  .foregroundColor(.blue)
                  .padding(.top, 4)
              }
            }
          }

          // Error Message
          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(.caption)
              .foregroundColor(.red)
              .frame(maxWidth: .infinity, alignment: .center)
          }

          // Main Sign In Button
          Button(action: {
            Task { await viewModel.signIn() }
          }) {
            HStack {
              if viewModel.isLoading {
                ProgressView()
                  .tint(.white)
              } else {
                Text("Sign In")
              }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isValidInput ? Color.orange : Color.orange.opacity(0.5))
            .cornerRadius(12)
          }
          .disabled(!viewModel.isValidInput || viewModel.isLoading)

          // Divider
          HStack {
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
            Text("OR")
              .font(.caption)
              .foregroundColor(.gray)
              .padding(.horizontal, 8)
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
          }

          // Google Sign In
          Button(action: {
            Task { await viewModel.signInWithGoogle() }
          }) {
            HStack(spacing: 12) {
              Image(systemName: "g.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)

              Text("Continue with Google")
                .font(.headline)
                .foregroundColor(.black.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
          }
          .disabled(viewModel.isLoading)

          Spacer()

          // Sign Up Link
          HStack {
            Text("Don't have an account?")
              .foregroundColor(.secondary)
            Button("Sign Up") {}
              .fontWeight(.bold)
              .foregroundColor(.orange)
          }
          .font(.subheadline)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
      }
    }
  }
}

#Preview {
  LoginView(viewModel: AuthViewModel())
}
