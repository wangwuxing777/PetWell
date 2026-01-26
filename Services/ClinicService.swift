import Foundation

@MainActor
class ClinicService {
    static let shared = ClinicService()
    
    private let baseUrl = "http://localhost:8000"
    
    func fetchEmergencyClinics() async throws -> [Clinic] {
        guard let url = URL(string: "\(baseUrl)/emergency-clinics") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let clinics = try JSONDecoder().decode([Clinic].self, from: data)
        return clinics
    }
    
    func fetchAllClinics() async throws -> [Clinic] {
        guard let url = URL(string: "\(baseUrl)/clinics") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let clinics = try JSONDecoder().decode([Clinic].self, from: data)
        return clinics
    }
}
