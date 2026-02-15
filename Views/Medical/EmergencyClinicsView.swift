import SwiftUI
import CoreLocation

struct EmergencyClinicsView: View {
    @State private var clinics: [Clinic] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Filters & Sorting
    @StateObject private var locationManager = LocationManager.shared
    @State private var searchText = ""
    @State private var selectedRegion: ClinicRegion = .all
    @State private var sortOption: ClinicSortOption = .rating
    
    var filteredClinics: [Clinic] {
        var result = clinics
        
        // 1. Search Text
        if !searchText.isEmpty {
            result = result.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.address.localizedCaseInsensitiveContains(searchText)
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
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search...", text: $searchText)
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 10)
            
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
                        .background(selectedRegion == .all ? Color(UIColor.systemBackground) : Color.blue.opacity(0.1))
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
                            .background(sortOption == .rating ? Color.orange.opacity(0.1) : Color(UIColor.systemBackground))
                            .foregroundColor(sortOption == .rating ? .orange : .primary)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(sortOption == .rating ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Distance Sort Button
                    Button(action: { sortOption = .distance }) {
                        Text("Distance")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(sortOption == .distance ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground))
                            .foregroundColor(sortOption == .distance ? .blue : .primary)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(sortOption == .distance ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading clinics...")
            } else if let error = errorMessage {
                VStack {
                    Text("Error loading clinics")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Button("Retry") {
                        loadData()
                    }
                    .padding()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section(header: headerView) {
                            LazyVStack(spacing: 20) {
                                ForEach(filteredClinics) { clinic in
                                    NavigationLink(destination: ClinicDetailView(clinic: clinic)) {
                                        ClinicCard(clinic: clinic, userLocation: locationManager.location)
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Remove default link styling
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("24h Emergency Clinics")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(UIColor.systemGroupedBackground))
                .toolbarBackground(Color(UIColor.systemGroupedBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
        .task {
            loadData()
        }
    }
    
    private func loadData() {
        if clinics.isEmpty {
            isLoading = true
        }
        Task {
            do {
                self.clinics = try await ClinicService.shared.fetchEmergencyClinics()
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}

struct ClinicCard: View {
    let clinic: Clinic
    let userLocation: CLLocation?
    
    // Calculates distance on the fly
    private var distanceString: String? {
        guard let userLoc = userLocation,
              let lat = Double(clinic.latitude ?? ""),
              let lng = Double(clinic.longitude ?? "") else { return nil }
        
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
        HStack(spacing: 0) {
            // 1. Photo Placeholder (Left)
            ZStack {
                if let urlString = clinic.photoUrl, let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(ProgressView())
                        case .success(let image):
                            image.resizable()
                                 .aspectRatio(contentMode: .fill)
                                 .frame(width: 110, height: 140)
                                 .clipped()
                        case .failure:
                            ZStack {
                                Rectangle().fill(Color.gray.opacity(0.1))
                                Image(systemName: "photo.fill") // Fallback icon
                                    .foregroundColor(.gray)
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.3))
                }
                
                // Status Badge
                VStack {
                    HStack {
                        Text("24H")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red)
                            .cornerRadius(4)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(width: 110)
            
            // 2. Content (Right)
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clinic.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        // Removed fixedSize to respect parent frame
                    
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .offset(y: 1)
                        Text(clinic.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            // Removed fixedSize to respect parent frame
                    }
                }
                
                Spacer(minLength: 0)
                
                HStack {
                    HStack(spacing: 8) {
                        if let rating = clinic.rating, !rating.isEmpty {
                            Label(rating, systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if let dist = distanceString {
                            Text(dist)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("Details >")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue.opacity(0.8))
                }
            }
            .padding(12)
        }
        .frame(height: 140) // Fixed height for compact look
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}