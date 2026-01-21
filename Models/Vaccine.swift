import Foundation

struct Vaccine: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let petType: String
    let description: String
    let youngInfo: String
    let adultInfo: String
    let isCore: Bool
    let isMandatory: Bool
    let price: Int
    
    var imageName: String {
        return name.replacingOccurrences(of: " ", with: "")
    }
}
