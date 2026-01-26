import Foundation

struct Clinic: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let address: String
    let phoneRegular: String?
    let phoneEmergency: String?
    let whatsapp: String?
    let openingHours: String
    let emergency24h: String
    let websiteUrl: String?
    let applemapUrl: String?
    let latitude: String?
    let longitude: String?
    let rating: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "clinic_id"
        case name
        case address
        case phoneRegular = "phone_regular"
        case phoneEmergency = "phone_emergency"
        case whatsapp
        case openingHours = "opening_hours"
        case emergency24h = "emergency_24h"
        case websiteUrl = "website_url"
        case applemapUrl = "applemap_url"
        case latitude
        case longitude
        case rating
    }
}
