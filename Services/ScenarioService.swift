//
//  ScenarioService.swift
//  PetWell
//
//  Created by AI Assistant on 2026/2/24.
//

import Combine
import Foundation

@MainActor
final class ScenarioService: ObservableObject {
  static let shared = ScenarioService()

  @Published var scenarios: [Scenario] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let baseURL = "https://pawrd-backend.zeabur.app"

  init() {
    Task {
      await fetchScenarios()
    }
  }

  func fetchScenarios() async {
    isLoading = true
    errorMessage = nil

    let urlString = "\(baseURL)/api/v1/scenarios"
    print("🔄 ScenarioService: Fetching from \(urlString)")
    
    guard let url = URL(string: urlString) else {
      errorMessage = "Invalid URL"
      isLoading = false
      return
    }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)

      if let httpResponse = response as? HTTPURLResponse {
        print("📥 ScenarioService: Response Status \(httpResponse.statusCode)")
        if !(200...299).contains(httpResponse.statusCode) {
          errorMessage = "Server error: \(httpResponse.statusCode)"
          isLoading = false
          return
        }
      }

      let decodedResponse = try JSONDecoder().decode(ScenarioResponse.self, from: data)
      self.scenarios = decodedResponse.scenarios
      print("✅ ScenarioService: Loaded \(self.scenarios.count) scenarios.")

    } catch {
      errorMessage = "Failed to load scenarios: \(error.localizedDescription)"
      print("❌ ScenarioService error: \(error)")
    }

    isLoading = false
  }
}
