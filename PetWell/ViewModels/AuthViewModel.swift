//
//  AuthViewModel.swift
//  PetWell
//
//  Created by AI Assistant on 2026/03/01.
//

import Combine
import Foundation

@MainActor
class AuthViewModel: ObservableObject {
  @Published var identifier: String = ""  // Email or Phone
  @Published var password: String = ""
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil
  @Published var isLoggedIn: Bool = false
  @Published var hasCompletedOnboarding: Bool = false
  @Published var userName: String = ""

  private let loginURL = "http://localhost:8000/api/auth/login"

  init() {
    // Restore persisted state
    self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
  }

  var isValidInput: Bool {
    !identifier.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
  }

  func signIn() async {
    guard isValidInput else { return }

    isLoading = true
    errorMessage = nil

    do {
      guard let url = URL(string: loginURL) else {
        errorMessage = "Invalid server URL"
        isLoading = false
        return
      }

      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")

      let body: [String: String] = [
        "identifier": identifier.trimmingCharacters(in: .whitespaces),
        "password": password,
      ]
      request.httpBody = try JSONEncoder().encode(body)

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        errorMessage = "Invalid response from server"
        isLoading = false
        return
      }

      let result = try JSONDecoder().decode(LoginAPIResponse.self, from: data)

      if httpResponse.statusCode == 200 && result.success {
        isLoggedIn = true
        userName = result.user?.name ?? "User"
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(userName, forKey: "userName")
      } else {
        errorMessage = result.message ?? "Invalid credentials"
      }
    } catch {
      errorMessage = "Network error: \(error.localizedDescription)"
    }

    isLoading = false
  }

  func signInWithGoogle() async {
    // Placeholder for Google SSO — would use GoogleSignIn SDK
    isLoading = true
    errorMessage = nil
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    errorMessage = "Google Sign-In not yet configured."
    isLoading = false
  }

  func completeOnboarding() {
    hasCompletedOnboarding = true
    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
  }

  func signOut() {
    isLoggedIn = false
    hasCompletedOnboarding = false
    userName = ""
    identifier = ""
    password = ""
    UserDefaults.standard.set(false, forKey: "isLoggedIn")
    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    UserDefaults.standard.removeObject(forKey: "userName")
  }
}

// API response model
struct LoginAPIResponse: Decodable {
  let success: Bool
  let message: String?
  let user: LoginAPIUser?
}

struct LoginAPIUser: Decodable {
  let id: Int
  let email: String
  let phone: String
  let name: String
}
