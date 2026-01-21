import Foundation

@MainActor
class VaccineService {
    static let shared = VaccineService()
    
    private let urlString = "http://localhost:8000/vaccines"
    
    func fetchVaccines() async throws -> [Vaccine] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let vaccines = try JSONDecoder().decode([Vaccine].self, from: data)
        return vaccines
    }
}
