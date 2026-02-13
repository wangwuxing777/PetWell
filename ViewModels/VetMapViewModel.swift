import Combine
import CoreLocation
import Foundation
import GoogleMaps
import SwiftUI

class VetMapViewModel: ObservableObject {
  @Published var clinics: [VetClinic] = []
  @Published var selectedRegion: Region = .hongKongIsland
  @Published var selectedDistrict: String = "wan_chai"
  @Published var searchText: String = ""
  @Published var showOpenOnly: Bool = false
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  private var cancellables = Set<AnyCancellable>()

  // Selected marker for displaying details
  @Published var selectedClinic: VetClinic?

  // For controlling the map camera
  @Published var cameraLatitude: Double = 22.28  // Default: Hong Kong
  @Published var cameraLongitude: Double = 114.17
  @Published var zoomLevel: Float = 14
  @Published var shouldAnimateCamera: Bool = false

  enum Region: String, CaseIterable {
    case hongKongIsland = "Hong Kong Island"
    case kowloon = "Kowloon"
    case newTerritories = "New Territories"
  }

  // Grouped districts
  let districtsByRegion: [Region: [(display: String, slug: String)]] = [
    .hongKongIsland: [
      ("Central & Western", "central_and_western"),
      ("Eastern", "eastern"),
      ("Southern", "southern"),
      ("Wan Chai", "wan_chai"),
    ],
    .kowloon: [
      ("Kowloon City", "kowloon_city"),
      ("Kwun Tong", "kwun_tong"),
      ("Sham Shui Po", "sham_shui_po"),
      ("Wong Tai Sin", "wong_tai_sin"),
      ("Yau Tsim Mong", "yau_tsim_mong"),
    ],
    .newTerritories: [
      ("Islands", "islands"),
      ("Kwai Tsing", "kwai_tsing"),
      ("North", "north"),
      ("Sai Kung", "sai_kung"),
      ("Sha Tin", "sha_tin"),
      ("Tai Po", "tai_po"),
      ("Tsuen Wan", "tsuen_wan"),
      ("Tuen Mun", "tuen_mun"),
      ("Yuen Long", "yuen_long"),
    ],
  ]

  init() {
    setupSearchSubscription()
    loadVets()
  }

  private func setupSearchSubscription() {
    $searchText
      .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
      .removeDuplicates()
      .sink { [weak self] _ in
        self?.loadVets()
      }
      .store(in: &cancellables)
  }

  func loadVets() {
    isLoading = true
    errorMessage = nil

    Task { @MainActor in
      do {
        let results: [VetClinic]

        if !searchText.isEmpty {
          results = try await VetService.fetchVets(query: searchText, openNow: showOpenOnly)
        } else {
          results = try await VetService.fetchVets(
            district: selectedDistrict, openNow: showOpenOnly)
        }

        self.clinics = results
        self.isLoading = false

        // Center map on first result
        if let first = results.first {
          self.moveCamera(lat: first.lat, lon: first.lng, zoom: 14)
        }
      } catch {
        self.isLoading = false
        self.errorMessage = error.localizedDescription
        print("Error loading vets: \(error)")
      }
    }
  }

  func selectRegion(_ region: Region) {
    selectedRegion = region
    // Default to first district in region
    if let firstDistrict = districtsByRegion[region]?.first {
      selectDistrict(firstDistrict.slug)
    }
  }

  func selectDistrict(_ slug: String) {
    selectedDistrict = slug
    searchText = ""  // Clear search when picking district
    loadVets()
  }

  func toggleOpenOnly() {
    // Don't call .toggle() here — the SwiftUI binding already changed the value
    loadVets()
  }

  func moveCamera(lat: Double, lon: Double, zoom: Float = 15) {
    self.cameraLatitude = lat
    self.cameraLongitude = lon
    self.zoomLevel = zoom
    self.shouldAnimateCamera = true
  }
}
