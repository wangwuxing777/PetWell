import Foundation

/// Model matching backend JSON from /api/vets
struct VetClinic: Codable, Identifiable, Equatable {
  let name: String
  let address: String
  let lat: Double
  let lng: Double
  let businessStatus: String
  let openNow: Bool?
  let rating: Double?
  let userRatingsTotal: Int?

  var id: String { "\(lat)-\(lng)-\(name)" }

  /// Display-friendly business status
  var isOpen: Bool {
    openNow ?? false
  }
}
