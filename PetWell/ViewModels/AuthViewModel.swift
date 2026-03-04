//
//  AuthViewModel.swift
//  PetWell
//
//  Created by AI Assistant on 2026/03/01.
//

import Combine
import Foundation

// MARK: - API Configuration
enum AuthAPI {
    // TODO: Replace with actual backend URL when available
    static let baseURL = "http://localhost:8000/api/auth"

    enum Endpoints {
        static let login = "\(baseURL)/login"
        static let googleAuth = "\(baseURL)/google"
        static let appleAuth = "\(baseURL)/apple"
        static let sendOTP = "\(baseURL)/otp/send"
        static let verifyOTP = "\(baseURL)/otp/verify"
        static let refreshToken = "\(baseURL)/refresh"
    }
}

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var identifier: String = ""  // Email or Phone
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var userName: String = ""

    // OTP Flow State
    @Published var verificationCode: String = ""
    @Published var otpSent: Bool = false
    @Published var otpVerified: Bool = false
    @Published var countdownSeconds: Int = 0

    // Google Sign-In State
    @Published var googleIdToken: String? = nil
    @Published var googleAccessToken: String? = nil

    private var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        // Restore persisted state
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
    }

    // MARK: - Validation
    var isValidInput: Bool {
        !identifier.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
    }

    var isValidEmail: Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    var isValidOTP: Bool {
        verificationCode.count >= 6
    }

    // MARK: - Password Login (Email + Password)
    func signInWithPassword() async {
        guard isValidInput else { return }

        isLoading = true
        errorMessage = nil

        do {
            // TODO: Connect to actual API when backend is ready
            // POST /api/auth/login
            // Request: { "email": "...", "password": "..." }
            // Response: { "success": true, "token": "...", "user": {...} }

            guard let url = URL(string: AuthAPI.Endpoints.login) else {
                errorMessage = "Invalid server URL"
                isLoading = false
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: String] = [
                "email": identifier.trimmingCharacters(in: .whitespaces),
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
                await handleSuccessfulLogin(user: result.user)
            } else {
                errorMessage = result.message ?? "Invalid credentials"
            }
        } catch {
            // For demo purposes, allow mock login when API is unavailable
            if identifier.lowercased() == "demo@petwell.com" && password == "demo123" {
                await handleSuccessfulLogin(user: LoginAPIUser(id: 1, email: "demo@petwell.com", phone: "", name: "Demo User"))
            } else {
                errorMessage = "Network error: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    // MARK: - Google Sign-In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        // TODO: Integrate GoogleSignIn SDK
        // Step 1: Present Google Sign-In UI
        // Step 2: Get ID Token from Google
        // Step 3: Send ID Token to backend for verification

        // Example GoogleSignIn SDK integration:
        /*
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String else {
            errorMessage = "Google Client ID not configured"
            isLoading = false
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let idToken = result.user.idToken?.tokenString
            let accessToken = result.user.accessToken.tokenString

            // Send to backend
            try await sendGoogleAuthToBackend(idToken: idToken, accessToken: accessToken)
        } catch {
            errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
        }
        */

        // Placeholder: Mock Google Sign-In for demo
        // TODO: Remove when GoogleSignIn SDK is integrated
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Demo: Accept any Google sign-in attempt
        // In production, this would be handled by GoogleSignIn SDK
        await handleSuccessfulLogin(user: LoginAPIUser(
            id: Int.random(in: 1000...9999),
            email: "google user",
            phone: "",
            name: "Google User"
        ))

        isLoading = false
    }

    // MARK: - Google Auth Backend Call (Placeholder)
    /**
     Send Google ID Token to backend for verification

     POST /api/auth/google
     Request: {
         "idToken": "eyJ...",
         "accessToken": "ya29..."
     }
     Response: {
         "success": true,
         "token": "jwt_token",
         "user": { "id": 1, "email": "...", "name": "..." }
     }
     */
    private func sendGoogleAuthToBackend(idToken: String?, accessToken: String?) async throws {
        guard let url = URL(string: AuthAPI.Endpoints.googleAuth) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "idToken": idToken ?? "",
            "accessToken": accessToken ?? ""
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError
        }

        let result = try JSONDecoder().decode(LoginAPIResponse.self, from: data)

        if result.success, let user = result.user {
            await handleSuccessfulLogin(user: user)
        } else {
            throw AuthError.authenticationFailed
        }
    }

    // MARK: - Apple Sign-In
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        // TODO: Integrate Apple Sign-In with AuthenticationServices framework
        /*
        let authorization = try await ASAuthorizationController.performRequests([
            ASAuthorizationAppleIDProvider().createRequest()
        ])

        guard let credential = authorization.credentials.first as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Apple Sign-In failed"
            isLoading = false
            return
        }

        let idToken = String(data: credential.identityToken ?? Data(), encoding: .utf8)
        try await sendAppleAuthToBackend(idToken: idToken)
        */

        // Placeholder
        try? await Task.sleep(nanoseconds: 800_000_000)
        errorMessage = "Apple Sign-In not yet configured."
        isLoading = false
    }

    // MARK: - Apple Auth Backend Call (Placeholder)
    /**
     Send Apple ID Token to backend for verification

     POST /api/auth/apple
     Request: { "idToken": "..." }
     Response: { "success": true, "token": "...", "user": {...} }
     */
    private func sendAppleAuthToBackend(idToken: String?) async throws {
        guard let url = URL(string: AuthAPI.Endpoints.appleAuth) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["idToken": idToken ?? ""]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(LoginAPIResponse.self, from: data)

        if result.success, let user = result.user {
            await handleSuccessfulLogin(user: user)
        }
    }

    // MARK: - X (Twitter) Sign-In
    func signInWithX() async {
        isLoading = true
        errorMessage = nil

        // TODO: Implement X/Twitter OAuth
        // X OAuth requires:
        // 1. Create Twitter App at https://developer.twitter.com
        // 2. Use TwitterKit or OAuth flow
        // 3. Send token to backend for verification

        try? await Task.sleep(nanoseconds: 800_000_000)
        errorMessage = "X Sign-In not yet configured."
        isLoading = false
    }

    // MARK: - Email OTP Flow

    /**
     Send OTP to user's email

     POST /api/auth/otp/send
     Request: { "email": "user@example.com" }
     Response: { "success": true, "message": "OTP sent", "expiresIn": 300 }
     */
    func sendOTP() async {
        guard isValidEmail else {
            errorMessage = "Please enter a valid email."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            guard let url = URL(string: AuthAPI.Endpoints.sendOTP) else {
                throw AuthError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["email": identifier.trimmingCharacters(in: .whitespaces)]
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.serverError
            }

            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(OTPResponse.self, from: data)
                if result.success {
                    otpSent = true
                    startCountdown(seconds: result.expiresIn ?? 300)
                    errorMessage = "OTP sent to your email."
                } else {
                    errorMessage = result.message ?? "Failed to send OTP"
                }
            } else {
                // Demo mode: allow OTP verification even without backend
                otpSent = true
                startCountdown(seconds: 300)
                errorMessage = "Demo: OTP would be sent (backend not connected)"
            }
        } catch {
            // Demo mode fallback
            otpSent = true
            startCountdown(seconds: 300)
            errorMessage = "Demo mode: OTP sent (backend unavailable)"
        }

        isLoading = false
    }

    /**
     Verify OTP and complete login

     POST /api/auth/otp/verify
     Request: { "email": "user@example.com", "code": "123456" }
     Response: { "success": true, "token": "jwt_token", "user": {...} }
     */
    func verifyOTP() async {
        guard isValidOTP else {
            errorMessage = "Please enter the verification code."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            guard let url = URL(string: AuthAPI.Endpoints.verifyOTP) else {
                throw AuthError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: String] = [
                "email": identifier.trimmingCharacters(in: .whitespaces),
                "code": verificationCode
            ]
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.serverError
            }

            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(LoginAPIResponse.self, from: data)
                if result.success, let user = result.user {
                    await handleSuccessfulLogin(user: user)
                } else {
                    errorMessage = result.message ?? "Invalid verification code"
                }
            } else {
                // Demo mode: accept any 6-digit code
                if verificationCode.count >= 6 {
                    otpVerified = true
                    await handleSuccessfulLogin(user: LoginAPIUser(
                        id: Int.random(in: 1000...9999),
                        email: identifier,
                        phone: "",
                        name: "Email User"
                    ))
                }
            }
        } catch {
            // Demo mode fallback
            if verificationCode.count >= 6 {
                otpVerified = true
                await handleSuccessfulLogin(user: LoginAPIUser(
                    id: Int.random(in: 1000...9999),
                    email: identifier,
                    phone: "",
                    name: "Email User"
                ))
            } else {
                errorMessage = "Invalid verification code"
            }
        }

        isLoading = false
    }

    // Resend OTP
    func resendOTP() async {
        guard countdownSeconds == 0 else { return }

        verificationCode = ""
        await sendOTP()
    }

    // MARK: - Countdown Timer
    private func startCountdown(seconds: Int) {
        countdownSeconds = seconds
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.countdownSeconds > 0 {
                    self.countdownSeconds -= 1
                } else {
                    self.countdownTimer?.invalidate()
                }
            }
        }
    }

    // MARK: - Login Success Handler
    private func handleSuccessfulLogin(user: LoginAPIUser) async {
        isLoggedIn = true
        userName = user.name
        identifier = ""
        password = ""

        // Save state
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(userName, forKey: "userName")

        // Reset OTP state
        otpSent = false
        otpVerified = false
        verificationCode = ""
        countdownTimer?.invalidate()
        countdownSeconds = 0
    }

    // MARK: - Onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    // MARK: - Sign Out
    func signOut() {
        // TODO: Revoke Google/Apple tokens if applicable

        isLoggedIn = false
        hasCompletedOnboarding = false
        userName = ""
        identifier = ""
        password = ""
        verificationCode = ""
        otpSent = false
        otpVerified = false

        countdownTimer?.invalidate()
        countdownSeconds = 0

        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "userName")
    }

    // MARK: - Guest Login
    func continueAsGuest() {
        isLoggedIn = true
        userName = "Guest"
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(userName, forKey: "userName")
    }
}

// MARK: - Error Types
enum AuthError: Error, LocalizedError {
    case invalidURL
    case serverError
    case authenticationFailed
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .serverError:
            return "Server error occurred"
        case .authenticationFailed:
            return "Authentication failed"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - API Response Models
struct LoginAPIResponse: Decodable {
    let success: Bool
    let message: String?
    let user: LoginAPIUser?
    let token: String?
}

struct LoginAPIUser: Decodable {
    let id: Int
    let email: String
    let phone: String
    let name: String
}

struct OTPResponse: Decodable {
    let success: Bool
    let message: String?
    let expiresIn: Int?  // Seconds until OTP expires
}
