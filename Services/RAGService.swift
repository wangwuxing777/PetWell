import Combine
import Foundation

// MARK: - Models
struct ChatMessage: Identifiable {
  let id = UUID()
  let content: String
  let isUser: Bool
}

struct RAGRequest: Encodable {
  let query: String
}

struct RAGResponse: Decodable {
  let answer: String
  let sources: [String]
}

// MARK: - Service
class RAGService: ObservableObject {
  @Published var messages: [ChatMessage] = []
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  // Configurable endpoint (could be moved to AppConfig later)
  private let endpointURL = "http://localhost:8000/api/chat"

  func askQuestion(query: String, context: String? = nil) {
    // 1. Add User Message immediately to UI
    let userMsg = ChatMessage(content: query, isUser: true)
    messages.append(userMsg)

    guard let url = URL(string: endpointURL) else {
      self.errorMessage = "Invalid URL configuration"
      return
    }

    // 2. Construct Payload (Hidden Context + Question)
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

    let body = RAGRequest(query: fullQuery)
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

      do {
        let decodedResponse = try JSONDecoder().decode(RAGResponse.self, from: data)
        DispatchQueue.main.async {
          let aiMsg = ChatMessage(content: decodedResponse.answer, isUser: false)
          self.messages.append(aiMsg)
        }
      } catch {
        DispatchQueue.main.async {
          self.errorMessage = "Failed to parse response: \(error.localizedDescription)"
        }
      }
    }.resume()
  }
}
