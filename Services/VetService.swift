import Foundation

/// Service to fetch vet clinic data from the Go backend
class VetService {
  static let baseURL = "http://localhost:8000"

  /// - Parameters:
  ///   - district: The district slug (optional if query is provided)
  ///   - query: Text search query
  ///   - openNow: If true, only return currently open clinics
  /// - Returns: Array of VetClinic
  static func fetchVets(district: String? = nil, query: String? = nil, openNow: Bool = false)
    async throws -> [VetClinic]
  {
    var urlComponents = URLComponents(string: "\(baseURL)/api/vets")!
    var queryItems: [URLQueryItem] = []

    if let query = query, !query.isEmpty {
      queryItems.append(URLQueryItem(name: "q", value: query))
    } else if let district = district {
      queryItems.append(URLQueryItem(name: "district", value: district))
    }

    if openNow {
      queryItems.append(URLQueryItem(name: "open_now", value: "true"))
    }

    urlComponents.queryItems = queryItems

    guard let url = urlComponents.url else {
      throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw URLError(.badServerResponse)
    }

    // Backend returns `null` when no results found — handle gracefully
    let decoded = try JSONDecoder().decode([VetClinic]?.self, from: data)
    return decoded ?? []
  }
}
