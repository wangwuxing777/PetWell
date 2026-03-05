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
    static let baseURL = "http://localhost:8000"

    enum Endpoints {
        static let login    = "\(baseURL)/api/auth/login"
        static let register = "\(baseURL)/api/auth/register"
        static let googleAuth = "\(baseURL)/auth/google"
        static let sendOTP    = "\(baseURL)/auth/otp/send"
        static let verifyOTP  = "\(baseURL)/auth/otp/verify"
    }
}

// MARK: - Token Manager
class TokenManager {
    static let shared = TokenManager()

    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userDataKey = "userData"

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: accessTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: accessTokenKey) }
    }

    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshTokenKey) }
    }

    var isAuthenticated: Bool {
        accessToken != nil
    }

    func saveTokens(accessToken: String, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: userDataKey)
    }

    func saveUser(_ user: APIUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDataKey)
        }
    }

    func getUser() -> APIUser? {
        guard let data = UserDefaults.standard.data(forKey: userDataKey) else { return nil }
        return try? JSONDecoder().decode(APIUser.self, from: data)
    }
}

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var identifier: String = ""  // Email
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var userName: String = ""

    // OTP Flow State
    @Published var verificationCode: String = ""
    @Published var otpSent: Bool = false
    @Published var otpId: String = ""
    @Published var countdownSeconds: Int = 0
    @Published var currentUser: APIUser?

    private var countdownTimer: Timer?
    private let tokenManager = TokenManager.shared

    // MARK: - Initialization
    init() {
        // Restore persisted state
        self.isLoggedIn = tokenManager.isAuthenticated
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if let user = tokenManager.getUser() {
            self.userName = user.displayName
            self.currentUser = user
            // Re-propagate identity so BlogService knows who is logged in after app restart
            syncIdentityToServices(user: user)
        }
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

    // MARK: - Google Sign-In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        // TODO: Integrate GoogleSignIn SDK
        // Step 1: Present Google Sign-In UI using GoogleSignIn SDK
        // Step 2: Get ID Token from Google result
        // Step 3: Call sendGoogleAuthToBackend with the ID token

        // Example GoogleSignIn SDK integration:
        /*
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GCLIENT_ID") as? String else {
            errorMessage = "Google Client ID not configured"
            isLoading = false
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google ID token"
                isLoading = false
                return
            }

            // Send to backend
            try await sendGoogleAuthToBackend(idToken: idToken)
        } catch {
            errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
        }
        */

        // Demo mode fallback - simulate successful Google sign-in
        await simulateGoogleSignIn()

        isLoading = false
    }

    // MARK: - Google Auth Backend Call
    /**
     POST /api/auth/google
     Headers:
         Authorization: Bearer {id_token}
         Content-Type: application/json
     Body: {
         "id_token": "string",
         "device_id": "string (optional)"
     }
     Response: {
         "success": true,
         "data": {
             "user": { "id", "email", "display_name", "avatar_url", "created_at" },
             "access_token": "jwt_token",
             "refresh_token": "refresh_token",
             "expires_in": 3600
         }
     }
     */
    private func sendGoogleAuthToBackend(idToken: String, deviceId: String? = nil) async throws {
        guard let url = URL(string: AuthAPI.Endpoints.googleAuth) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: String] = ["id_token": idToken]
        if let deviceId = deviceId {
            body["device_id"] = deviceId
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.serverError
        }

        if httpResponse.statusCode == 200 {
            let result = try JSONDecoder().decode(GoogleAuthResponse.self, from: data)
            if result.success, let data = result.data {
                await handleSuccessfulAuth(
                    accessToken: data.accessToken,
                    refreshToken: data.refreshToken,
                    user: data.user
                )
            } else {
                throw AuthError.authenticationFailed
            }
        } else {
            throw AuthError.serverError
        }
    }

    // MARK: - Apple Sign-In
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        // TODO: Integrate Apple Sign-In with AuthenticationServices framework
        /*
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
        */

        // Placeholder
        try? await Task.sleep(nanoseconds: 800_000_000)
        errorMessage = "Apple Sign-In not yet configured."
        isLoading = false
    }

    // MARK: - X (Twitter) Sign-In
    func signInWithX() async {
        isLoading = true
        errorMessage = nil

        // TODO: Implement X/Twitter OAuth
        try? await Task.sleep(nanoseconds: 800_000_000)
        errorMessage = "X Sign-In not yet configured."
        isLoading = false
    }

    // MARK: - Email OTP Flow

    /**
     POST /api/auth/otp/send
     Body: { "email": "user@example.com", "purpose": "login | register" }
     Response: {
         "success": true,
         "data": {
             "otp_id": "uuid",
             "expires_in": 300,
             "message": "验证码已发送"
         }
     }
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

            let body: [String: String] = [
                "email": identifier.trimmingCharacters(in: .whitespaces),
                "purpose": "login"
            ]
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.serverError
            }

            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(OTPSendResponse.self, from: data)
                if result.success, let data = result.data {
                    otpId = data.otpId
                    otpSent = true
                    startCountdown(seconds: data.expiresIn)
                    errorMessage = "Verification code sent to your email."
                } else {
                    errorMessage = result.data?.message ?? "Failed to send verification code"
                }
            } else {
                // Demo mode fallback
                otpSent = true
                otpId = UUID().uuidString
                startCountdown(seconds: 300)
                errorMessage = "Demo: Verification code would be sent"
            }
        } catch {
            // Demo mode fallback
            otpSent = true
            otpId = UUID().uuidString
            startCountdown(seconds: 300)
            errorMessage = "Demo mode: Verification code sent (API unavailable)"
        }

        isLoading = false
    }

    /**
     POST /api/auth/otp/verify
     Body: { "otp_id": "uuid", "code": "123456", "device_id": "string (optional)" }
     Response: {
         "success": true,
         "data": {
             "user": { "id", "email", "display_name", "avatar_url", "created_at" },
             "access_token": "jwt_token",
             "refresh_token": "refresh_token",
             "expires_in": 3600,
             "is_new_user": false
         }
     }
     */
    func verifyOTP() async {
        guard isValidOTP else {
            errorMessage = "Please enter the verification code."
            return
        }

        guard !otpId.isEmpty else {
            errorMessage = "Please request a verification code first."
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
                "otp_id": otpId,
                "code": verificationCode
            ]
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.serverError
            }

            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(OTPVerifyResponse.self, from: data)
                if result.success, let data = result.data {
                    await handleSuccessfulAuth(
                        accessToken: data.accessToken,
                        refreshToken: data.refreshToken,
                        user: data.user
                    )
                } else {
                    errorMessage = "Invalid verification code"
                }
            } else {
                // Demo mode fallback - accept any 6-digit code
                if verificationCode.count >= 6 {
                    let demoUser = APIUser(
                        id: UUID().uuidString,
                        email: identifier,
                        displayName: "Email User",
                        avatarUrl: nil,
                        createdAt: ""
                    )
                    await handleSuccessfulAuth(
                        accessToken: "demo_access_token",
                        refreshToken: "demo_refresh_token",
                        user: demoUser
                    )
                }
            }
        } catch {
            // Demo mode fallback
            if verificationCode.count >= 6 {
                let demoUser = APIUser(
                    id: UUID().uuidString,
                    email: identifier,
                    displayName: "Email User",
                    avatarUrl: nil,
                    createdAt: ""
                )
                await handleSuccessfulAuth(
                    accessToken: "demo_access_token",
                    refreshToken: "demo_refresh_token",
                    user: demoUser
                )
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
    private func handleSuccessfulAuth(accessToken: String, refreshToken: String?, user: APIUser) async {
        tokenManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
        tokenManager.saveUser(user)

        isLoggedIn = true
        userName = user.displayName
        currentUser = user

        // Propagate identity to BlogService and OwnerProfile
        syncIdentityToServices(user: user)

        // Reset form
        identifier = ""
        password = ""
        verificationCode = ""
        otpSent = false
        otpId = ""

        countdownTimer?.invalidate()
        countdownSeconds = 0
    }

    // MARK: - Identity Sync
    // After every successful login/register, push the real user info into
    // BlogService (so posts show the correct author) and pre-fill OwnerProfile.
    private func syncIdentityToServices(user: APIUser) {
        // Update BlogService author identity
        BlogService.shared.setCurrentUser(
            id: user.id,
            name: user.displayName,
            avatarUrl: user.avatarUrl ?? ""
        )

        // Pre-fill OwnerProfile only if it hasn't been set by the user yet
        var profile = OwnerProfileStore.shared.load()
        if profile.name.isEmpty {
            profile.name = user.displayName
            profile.email = user.email
            OwnerProfileStore.shared.save(profile)
        }
    }

    // MARK: - Demo/Simulation
    private func simulateGoogleSignIn() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let demoUser = APIUser(
            id: UUID().uuidString,
            email: "demo@petwell.com",
            displayName: "Demo User",
            avatarUrl: nil,
            createdAt: ""
        )

        await handleSuccessfulAuth(
            accessToken: "demo_google_access_token",
            refreshToken: "demo_google_refresh_token",
            user: demoUser
        )
    }

    // MARK: - Email + Password Login (calls real backend)
    func signInWithPassword() async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: AuthAPI.Endpoints.login) else { isLoading = false; return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["identifier": identifier, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError }

            if http.statusCode == 200 {
                let result = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
                await handleSuccessfulAuth(accessToken: result.token, refreshToken: nil, user: result.user.toAPIUser())
            } else {
                let err = try? JSONDecoder().decode([String: String].self, from: data)
                errorMessage = err?["error"] ?? "Invalid email or password"
            }
        } catch {
            errorMessage = "Could not connect to server. Check that the backend is running."
        }
        isLoading = false
    }

    // MARK: - Email + Password Registration (calls real backend)
    func registerWithPassword(name: String) async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: AuthAPI.Endpoints.register) else { isLoading = false; return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["name": name, "email": identifier, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError }

            if http.statusCode == 201 {
                let result = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
                await handleSuccessfulAuth(accessToken: result.token, refreshToken: nil, user: result.user.toAPIUser())
            } else {
                let err = try? JSONDecoder().decode([String: String].self, from: data)
                errorMessage = err?["error"] ?? "Registration failed"
            }
        } catch {
            errorMessage = "Could not connect to server. Check that the backend is running."
        }
        isLoading = false
    }

    func signIn() async {
        await signInWithPassword()
    }

    func requestEmailVerification() async {
        await sendOTP()
    }

    // MARK: - Onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    // MARK: - Sign Out
    func signOut() {
        tokenManager.clearTokens()

        isLoggedIn = false
        hasCompletedOnboarding = false
        userName = ""
        currentUser = nil
        identifier = ""
        password = ""
        verificationCode = ""
        otpSent = false
        otpId = ""

        countdownTimer?.invalidate()
        countdownSeconds = 0

        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    // MARK: - Guest Login
    func continueAsGuest() {
        isLoggedIn = true
        userName = "Guest"
        tokenManager.saveTokens(accessToken: "guest_token", refreshToken: nil)
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

// APIUser matches the backend AuthUserResponse JSON shape:
// { "id", "email", "name", "avatar_url", "created_at" }
struct APIUser: Codable {
    let id: String
    let email: String
    let displayName: String   // mapped from "name"
    let avatarUrl: String?
    let createdAt: String     // keep as String to avoid date-format issues

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "name"
        case avatarUrl   = "avatar_url"
        case createdAt   = "created_at"
    }
}

// AuthTokenResponse matches { "token": "...", "user": { ... } }
struct AuthTokenResponse: Decodable {
    let token: String
    let user: BackendUser
}

// BackendUser is the raw shape from Go (id as string, name not display_name)
struct BackendUser: Decodable {
    let id: String
    let email: String
    let name: String
    let avatarUrl: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }

    func toAPIUser() -> APIUser {
        APIUser(id: id, email: email, displayName: name, avatarUrl: avatarUrl, createdAt: createdAt)
    }
}

struct GoogleAuthResponse: Decodable {
    let success: Bool
    let data: GoogleAuthData?
}

struct GoogleAuthData: Decodable {
    let user: APIUser
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

struct OTPSendResponse: Decodable {
    let success: Bool
    let data: OTPSendData?
}

struct OTPSendData: Decodable {
    let otpId: String
    let expiresIn: Int
    let message: String?

    enum CodingKeys: String, CodingKey {
        case otpId = "otp_id"
        case expiresIn = "expires_in"
        case message
    }
}

struct OTPVerifyResponse: Decodable {
    let success: Bool
    let data: OTPVerifyData?
}

struct OTPVerifyData: Decodable {
    let user: APIUser
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let isNewUser: Bool

    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case isNewUser = "is_new_user"
    }
}
