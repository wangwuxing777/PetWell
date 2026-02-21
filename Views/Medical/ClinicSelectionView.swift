import CoreLocation
import SwiftUI

struct ClinicSelectionView: View {
  let vaccine: Vaccine
  @State private var clinics: [Clinic] = []
  @State private var isLoading = true
  @State private var searchText = ""

  // Filters
  @StateObject private var locationManager = LocationManager.shared
  @State private var selectedRegion: ClinicRegion = .all
  @State private var sortOption: ClinicSortOption = .rating

  var filteredClinics: [Clinic] {
    var result = clinics

    // 1. Search
    if !searchText.isEmpty {
      result = result.filter {
        $0.name.localizedCaseInsensitiveContains(searchText)
          || $0.address.localizedCaseInsensitiveContains(searchText)
      }
    }

    // 2. Region
    if selectedRegion != .all {
      result = result.filter { selectedRegion.matches($0.address) }
    }

    // 3. Sort
    switch sortOption {
    case .rating:
      result.sort {
        let r1 = Double($0.rating ?? "0") ?? 0
        let r2 = Double($1.rating ?? "0") ?? 0
        return r1 > r2
      }
    case .distance:
      if let userLoc = locationManager.location {
        result.sort {
          let lat1 = Double($0.latitude ?? "0") ?? 0
          let lon1 = Double($0.longitude ?? "0") ?? 0
          let loc1 = CLLocation(latitude: lat1, longitude: lon1)

          let lat2 = Double($1.latitude ?? "0") ?? 0
          let lon2 = Double($1.longitude ?? "0") ?? 0
          let loc2 = CLLocation(latitude: lat2, longitude: lon2)

          return userLoc.distance(from: loc1) < userLoc.distance(from: loc2)
        }
      }
    }

    return result
  }

  var headerView: some View {
    VStack(spacing: 0) {
      // Search bar
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.gray)
        TextField("Search clinics...", text: $searchText)
      }
      .padding(12)
      .background(Color(UIColor.secondarySystemBackground))
      .cornerRadius(10)
      .padding(.horizontal)
      .padding(.top, 10)

      // Filter Chips
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          // Region Filter
          Menu {
            Picker("Region", selection: $selectedRegion) {
              ForEach(ClinicRegion.allCases) { region in
                Text(region.rawValue).tag(region)
              }
            }
          } label: {
            HStack(spacing: 4) {
              Text(selectedRegion == .all ? "Region" : selectedRegion.rawValue)
              Image(systemName: "chevron.down")
                .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
              selectedRegion == .all
                ? Color(UIColor.secondarySystemBackground) : Color.blue.opacity(0.1)
            )
            .foregroundColor(selectedRegion == .all ? .primary : .blue)
            .cornerRadius(20)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
          }

          // Rating Sort Button
          Button(action: { sortOption = .rating }) {
            Text("Rating")
              .font(.subheadline)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(
                sortOption == .rating
                  ? Color.orange.opacity(0.1) : Color(UIColor.secondarySystemBackground)
              )
              .foregroundColor(sortOption == .rating ? .orange : .primary)
              .cornerRadius(20)
              .overlay(
                RoundedRectangle(cornerRadius: 20)
                  .stroke(
                    sortOption == .rating ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1)
              )
          }

          // Distance Sort Button
          Button(action: { sortOption = .distance }) {
            Text("Distance")
              .font(.subheadline)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(
                sortOption == .distance
                  ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground)
              )
              .foregroundColor(sortOption == .distance ? .blue : .primary)
              .cornerRadius(20)
              .overlay(
                RoundedRectangle(cornerRadius: 20)
                  .stroke(
                    sortOption == .distance ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
              )
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(UIColor.systemGroupedBackground))
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
        // Header info - Not pinned
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("Select a Clinic")
              .font(.largeTitle)
              .fontWeight(.bold)
            Text("Choose where you want to book \(vaccine.name)")
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal)
          .padding(.top)
        }

        // Pinned Section
        Section(header: headerView) {
          Group {
            if isLoading {
              ProgressView()
                .frame(maxWidth: .infinity, minHeight: 100)
            } else if filteredClinics.isEmpty {
              Text("No clinics found")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
            } else {
              LazyVStack(spacing: 16) {
                ForEach(filteredClinics) { clinic in
                  NavigationLink(destination: VaccineBookingView(vaccine: vaccine, clinic: clinic))
                  {
                    ClinicSelectionCard(clinic: clinic, userLocation: locationManager.location)
                  }
                  .buttonStyle(PlainButtonStyle())
                }
              }
              .padding(.horizontal)
              .padding(.top, 10)
            }
          }
        }
      }
      .padding(.bottom)
    }
    .background(Color(UIColor.systemGroupedBackground))
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(Color(UIColor.systemGroupedBackground), for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .task {
      do {
        self.clinics = try await ClinicService.shared.fetchAllClinics()
        self.isLoading = false
      } catch {
        print("Error fetching clinics: \(error)")
        self.isLoading = false
      }
    }
  }
}

struct ClinicSelectionCard: View {
  let clinic: Clinic
  let userLocation: CLLocation?

  // Calculates distance on the fly
  private var distanceString: String? {
    guard let userLoc = userLocation,
      let lat = Double(clinic.latitude ?? ""),
      let lng = Double(clinic.longitude ?? "")
    else { return nil }

    let clinicLoc = CLLocation(latitude: lat, longitude: lng)
    let distanceInMeters = userLoc.distance(from: clinicLoc)

    if distanceInMeters < 1000 {
      return String(format: "%.0fm", distanceInMeters)
    } else {
      return String(format: "%.1fkm", distanceInMeters / 1000)
    }
  }

  init(clinic: Clinic, userLocation: CLLocation? = nil) {
    self.clinic = clinic
    self.userLocation = userLocation
  }

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      // Photo or color strip
      if let urlString = clinic.photoUrl, let url = URL(string: urlString) {
        CachedAsyncImage(url: url) { phase in
          if let image = phase.image {
            image.resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 80)
              .clipped()
          } else if phase.error != nil {
            // Fallback on error
            Rectangle().fill(Color.blue).frame(width: 6)
          } else {
            // Placeholder
            Rectangle().fill(Color.gray.opacity(0.1)).frame(width: 80).overlay(ProgressView())
          }
        }
        .frame(width: 80)
      } else {
        Rectangle()
          .fill(Color.blue)
          .frame(width: 6)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text(clinic.name)
          .font(.headline)
          .foregroundColor(.primary)
          .lineLimit(2)

        HStack(alignment: .top, spacing: 4) {
          Image(systemName: "mappin.and.ellipse")
            .font(.caption)
            .foregroundColor(.gray)
            .offset(y: 1)
          Text(clinic.address)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }

        HStack {
          Label(clinic.openingHours, systemImage: "clock")
            .font(.caption2)
            .foregroundColor(.gray)

          if let rating = clinic.rating, !rating.isEmpty {
            Label(rating, systemImage: "star.fill")
              .font(.caption2)
              .foregroundColor(.orange)
          }

          if let dist = distanceString {
            Text(dist)
              .font(.caption2)
              .foregroundColor(.secondary)
          }

          Spacer()

          Text("Select")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.top, 4)
      }
      .padding(12)
    }
    .background(Color(UIColor.systemBackground))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}
