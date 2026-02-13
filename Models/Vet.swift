import CoreLocation
import Foundation

struct Vet: Codable, Identifiable, Equatable {
  let id: String
  let name: String
  let address: String
  let district: String
  let latitude: Double
  let longitude: Double
  let openingHours: String
  let isOpen: Bool
  let phone: String

  // Helper for CLLocationCoordinate2D
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  // Mock Data for testing
  static let sampleVets: [Vet] = [
    Vet(
      id: "1", name: "Central Animal Hosiptal", address: "123 Queen's Road, Central",
      district: "Central and Western", latitude: 22.2820, longitude: 114.1582,
      openingHours: "09:00 - 20:00", isOpen: true, phone: "2123 4567"),
    Vet(
      id: "2", name: "Wan Chai Vet Clinic", address: "45 Johnston Road, Wan Chai",
      district: "Wan Chai", latitude: 22.2760, longitude: 114.1722, openingHours: "10:00 - 18:00",
      isOpen: false, phone: "2345 6789"),
    Vet(
      id: "3", name: "Causeway Bay 24h Vet", address: "10 Hennessy Road, Causeway Bay",
      district: "Wan Chai", latitude: 22.2800, longitude: 114.1850, openingHours: "24 Hours",
      isOpen: true, phone: "2987 6543"),
    Vet(
      id: "4", name: "Mong Kok Pet Care", address: "88 Nathan Road, Mong Kok",
      district: "Yau Tsim Mong", latitude: 22.3193, longitude: 114.1694,
      openingHours: "09:00 - 21:00", isOpen: true, phone: "2456 7890"),
    Vet(
      id: "5", name: "Shatin Animal Medical", address: "1 Shatin Centre St, Shatin",
      district: "Sha Tin", latitude: 22.3833, longitude: 114.1867, openingHours: "08:30 - 19:30",
      isOpen: true, phone: "2678 9012"),
  ]
}
