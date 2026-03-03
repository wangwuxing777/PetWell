import Combine
import Foundation

// MARK: - Models

struct ChatMessage: Identifiable {
  let id = UUID()
  let content: String
  let isUser: Bool
  var activeProvider: String?  // Which provider answered (for AI messages)
  var isSystemNotice: Bool = false  // For context-switch banners
}

struct ChatProvider: Decodable, Identifiable, Equatable {
  let id: String
  let name: String
}

struct CreateSessionResponse: Decodable {
  let session_id: String
}

struct RAGRequest: Encodable {
  let query: String
  let session_id: String?
  let model: String?  // "insurance" or "medical"
  let provider: String?  // e.g. "bluecross", "one_degree"
}

struct RAGResponse: Decodable {
  let answer: String
  let sources: [String]
  let active_provider: String?
  let session_id: String?
}

private struct APIErrorResponse: Decodable {
  let detail: String?
}

// MARK: - Chat Model (domain) enum

enum ChatModel: String, CaseIterable, Identifiable {
  case insurance = "insurance"
  case medical = "medical"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .insurance: return "Insurance"
    case .medical: return "Medical"
    }
  }

  var icon: String {
    switch self {
    case .insurance: return "shield.checkered"
    case .medical: return "cross.case.fill"
    }
  }
}

// MARK: - Hardcoded Providers (until backend /providers is ready)

enum ChatProviderOption: String, CaseIterable, Identifiable {
  case all = ""
  case bluecross = "bluecross"
  case oneDegree = "one_degree"
  case prudential = "prudential"
  case bolttech = "bolttech"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .all: return "All"
    case .bluecross: return "Blue Cross"
    case .oneDegree: return "One Degree"
    case .prudential: return "Prudential"
    case .bolttech: return "Bolttech"
    }
  }
}

// MARK: - Service

class RAGService: ObservableObject {
  @Published var messages: [ChatMessage] = []
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  // Session & Selection State
  @Published var sessionId: String?
  @Published var selectedModel: ChatModel = .insurance
  @Published var selectedProvider: ChatProviderOption = .all
  @Published var lastActiveProvider: String?

  // Configurable endpoint
  private let baseURL = "http://localhost:8000"

  // MARK: - Session Management

  /// Create a new chat session on view appear
  func createSession() {
    guard let url = URL(string: "\(baseURL)/api/chat/session") else {
      self.errorMessage = "Invalid session URL"
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONEncoder().encode(["action": "create"])

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }

      if let error = error {
        print("⚠️ Session creation failed: \(error.localizedDescription)")
        return
      }

      guard let data = data else { return }

      do {
        let session = try JSONDecoder().decode(CreateSessionResponse.self, from: data)
        DispatchQueue.main.async {
          self.sessionId = session.session_id
          print("✅ Session created: \(session.session_id)")
        }
      } catch {
        print("⚠️ Failed to parse session response: \(error.localizedDescription)")
      }
    }.resume()
  }

  // MARK: - Provider Selection

  /// Notify backend of provider change
  func selectProvider(_ provider: ChatProviderOption) {
    let previousProvider = selectedProvider
    selectedProvider = provider

    // Notify backend if we have a session
    guard let sessionId = sessionId, !sessionId.isEmpty else { return }
    guard let url = URL(string: "\(baseURL)/api/chat/session/\(sessionId)/provider") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: String] = ["provider": provider.rawValue]
    request.httpBody = try? JSONEncoder().encode(body)

    URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
      if let error = error {
        print("⚠️ Provider selection failed: \(error.localizedDescription)")
        return
      }

      // Add system notice if switched mid-conversation
      if previousProvider != provider && !(self?.messages.isEmpty ?? true) {
        DispatchQueue.main.async {
          let notice = ChatMessage(
            content: "Switched to \(provider.displayName) context",
            isUser: false,
            isSystemNotice: true
          )
          self?.messages.append(notice)
        }
      }

      print("✅ Provider set to: \(provider.displayName)")
    }.resume()
  }

  // MARK: - Ask Question

  func askQuestion(query: String, context: String? = nil) {
    // 1. Add User Message immediately to UI
    let userMsg = ChatMessage(content: query, isUser: true)
    messages.append(userMsg)

    let endpointURL = "\(baseURL)/api/chat"
    guard let url = URL(string: endpointURL) else {
      self.errorMessage = "Invalid URL configuration"
      return
    }

    // 2. Construct Payload with session + model + provider
    let fullQuery: String
    if let ctx = context, !ctx.isEmpty {
      fullQuery = """
        \(ctx)

        User Question: \(query)
        """
    } else {
      fullQuery = query
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = RAGRequest(
      query: fullQuery,
      session_id: sessionId,
      model: selectedModel.rawValue,
      provider: selectedProvider == .all ? nil : selectedProvider.rawValue
    )
    request.httpBody = try? JSONEncoder().encode(body)

    DispatchQueue.main.async {
      self.isLoading = true
      self.errorMessage = nil
    }

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }

      DispatchQueue.main.async {
        self.isLoading = false
      }

      if let error = error {
        DispatchQueue.main.async {
          self.errorMessage = error.localizedDescription
        }
        return
      }

      guard let data = data else {
        DispatchQueue.main.async {
          self.errorMessage = "No data received"
        }
        return
      }

      if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
        let bodyText = String(data: data, encoding: .utf8) ?? ""
        let apiErr = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        let detail = apiErr?.detail?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalMsg = (detail?.isEmpty == false ? detail! : bodyText)
        DispatchQueue.main.async {
          self.errorMessage =
            finalMsg.isEmpty
            ? "RAG service error (HTTP \(http.statusCode))"
            : "RAG service error: \(finalMsg)"
        }
        return
      }

      do {
        let decodedResponse = try JSONDecoder().decode(RAGResponse.self, from: data)
        DispatchQueue.main.async {
          // Check for provider switch
          let newProvider = decodedResponse.active_provider
          if let newP = newProvider, !newP.isEmpty,
            let lastP = self.lastActiveProvider, !lastP.isEmpty,
            newP != lastP
          {
            let notice = ChatMessage(
              content: "Context switched to \(newP)",
              isUser: false,
              isSystemNotice: true
            )
            self.messages.append(notice)
          }
          self.lastActiveProvider = newProvider

          // Add AI message with provider tag
          var aiMsg = ChatMessage(content: decodedResponse.answer, isUser: false)
          aiMsg.activeProvider = newProvider
          self.messages.append(aiMsg)
        }
      } catch {
        let bodyText = String(data: data, encoding: .utf8) ?? ""
        let apiErr = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        let detail = apiErr?.detail?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = detail?.isEmpty == false ? detail! : bodyText
        DispatchQueue.main.async {
          if fallback.isEmpty {
            self.errorMessage = "Failed to parse response: \(error.localizedDescription)"
          } else {
            self.errorMessage = "RAG response format issue: \(fallback)"
          }
        }
      }
    }.resume()
  }
}
