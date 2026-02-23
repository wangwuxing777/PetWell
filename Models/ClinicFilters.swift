import Foundation

enum ClinicRegion: String, CaseIterable, Identifiable {
  case all = "All Regions"
  case hongKongIsland = "HK Island"
  case kowloon = "Kowloon"
  case newTerritories = "New Territories"

  var id: String { rawValue }

  func matches(_ address: String) -> Bool {
    switch self {
    case .all: return true
    case .hongKongIsland:
      return [
        "Hong Kong", "HK", "Central", "Wan Chai", "Causeway Bay", "North Point", "Aberdeen",
        "Repulse Bay", "Stanley", "Kennedy Town", "Pok Fu Lam",
      ].contains { address.localizedCaseInsensitiveContains($0) }
    case .kowloon:
      return [
        "Kowloon", "Tsim Sha Tsui", "Mong Kok", "Kwun Tong", "Hung Hom", "Jordan", "Yau Ma Tei",
        "Sham Shui Po", "Wong Tai Sin", "San Po Kong", "Prince Edward",
      ].contains { address.localizedCaseInsensitiveContains($0) }
    case .newTerritories:
      return [
        "New Territories", "N.T.", "Shatin", "Sha Tin", "Tuen Mun", "Yuen Long", "Tseung Kwan O",
        "Sai Kung", "Tai Po", "Fanling", "Sheung Shui", "Tsuen Wan", "Kwai Chung",
      ].contains { address.localizedCaseInsensitiveContains($0) }
    }
  }
}
