import CoreLocation
import GoogleMaps
import SwiftUI
import UIKit

// MARK: - HK District Mapping (18 Districts)
enum HKDistrict: String, CaseIterable {
  case centralAndWestern = "Central & Western"
  case eastern = "Eastern"
  case southern = "Southern"
  case wanChai = "Wan Chai"
  case kowloonCity = "Kowloon City"
  case kwunTong = "Kwun Tong"
  case shamShuiPo = "Sham Shui Po"
  case wongTaiSin = "Wong Tai Sin"
  case yauTsimMong = "Yau Tsim Mong"
  case islands = "Islands"
  case kwaiTsing = "Kwai Tsing"
  case north = "North"
  case saiKung = "Sai Kung"
  case shaTin = "Sha Tin"
  case taiPo = "Tai Po"
  case tsuenWan = "Tsuen Wan"
  case tuenMun = "Tuen Mun"
  case yuenLong = "Yuen Long"

  var keywords: [String] {
    switch self {
    case .centralAndWestern:
      return ["Central", "Sheung Wan", "Sai Ying Pun", "Kennedy Town", "Mid-Levels", "The Peak"]
    case .eastern:
      return [
        "North Point", "Quarry Bay", "Sai Wan Ho", "Shau Kei Wan", "Chai Wan", "Taikoo",
        "Kornhill",
      ]
    case .southern:
      return ["Aberdeen", "Ap Lei Chau", "Stanley", "Repulse Bay", "Pok Fu Lam", "Wong Chuk Hang"]
    case .wanChai:
      return ["Wan Chai", "Causeway Bay", "Happy Valley", "Tin Hau", "Tai Hang"]
    case .kowloonCity:
      return [
        "Kowloon City", "Ho Man Tin", "Hung Hom", "Kowloon Tong", "To Kwa Wan", "Kai Tak",
      ]
    case .kwunTong:
      return ["Kwun Tong", "Lam Tin", "Yau Tong", "Sau Mau Ping", "Ngau Tau Kok"]
    case .shamShuiPo:
      return ["Sham Shui Po", "Cheung Sha Wan", "Lai Chi Kok", "Shek Kip Mei", "Prince Edward"]
    case .wongTaiSin:
      return ["Wong Tai Sin", "Diamond Hill", "San Po Kong", "Lok Fu", "Tsz Wan Shan"]
    case .yauTsimMong:
      return [
        "Tsim Sha Tsui", "Jordan", "Yau Ma Tei", "Mong Kok", "Prince Edward", "Olympic",
      ]
    case .islands:
      return ["Tung Chung", "Lantau", "Discovery Bay", "Mui Wo", "Cheung Chau", "Lamma"]
    case .kwaiTsing:
      return ["Kwai Chung", "Kwai Fong", "Tsing Yi"]
    case .north:
      return ["Fanling", "Sheung Shui", "Luen Wo Hui"]
    case .saiKung:
      return ["Sai Kung", "Tseung Kwan O", "Hang Hau", "Po Lam", "Lohas Park"]
    case .shaTin:
      return ["Sha Tin", "Shatin", "Ma On Shan", "Fo Tan", "Tai Wai"]
    case .taiPo:
      return ["Tai Po", "Tai Wo"]
    case .tsuenWan:
      return ["Tsuen Wan"]
    case .tuenMun:
      return ["Tuen Mun"]
    case .yuenLong:
      return ["Yuen Long", "Tin Shui Wai", "Kam Tin"]
    }
  }

  func matches(_ address: String) -> Bool {
    keywords.contains { address.localizedCaseInsensitiveContains($0) }
  }
}

// MARK: - Sort Selection
enum SortSelection: Equatable {
  case none
  case rating
  case distance
}

// MARK: - Sheet Position
enum SheetPosition {
  case half  // Default: map visible ~48%
  case full  // Expanded: map barely visible

  func topOffset(in totalHeight: CGFloat) -> CGFloat {
    switch self {
    case .half: return totalHeight * 0.62  // Updated to match lower position
    case .full: return 140  // Below search bar (80 + ~50 height + 10 padding)
    }
  }
}

// MARK: - Main View
struct EmergencyClinicsView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var clinics: [Clinic] = []
  @State private var isLoading = false
  @State private var errorMessage: String?

  @StateObject private var locationManager = LocationManager.shared
  @State private var searchText = ""

  // Sort
  @State private var sortSelection: SortSelection = .none
  @State private var appliedSort: SortSelection = .none
  @State private var showSortSheet = false

  // Sheet drag
  @State private var sheetPosition: SheetPosition = .half
  // Explicit offset state for silky smooth animation
  // User feedback: "Card is too high". Lowering it significantly.
  // 0.48 was ~half. 0.62 puts it lower, revealing more map.
  @State private var currentSheetOffset: CGFloat = UIScreen.main.bounds.height * 0.62
  @State private var showAIChat = false

  // Map markers: highest-rated clinic per district
  var topClinicPerDistrict: [Clinic] {
    var best: [HKDistrict: Clinic] = [:]
    for clinic in clinics {
      for district in HKDistrict.allCases {
        if district.matches(clinic.address) {
          let existing = best[district]
          let existingRating = Double(existing?.rating ?? "0") ?? 0
          let newRating = Double(clinic.rating ?? "0") ?? 0
          if existing == nil || newRating > existingRating {
            best[district] = clinic
          }
          break
        }
      }
    }
    return Array(best.values)
  }

  var filteredClinics: [Clinic] {
    var result = clinics

    // Search filter
    if !searchText.isEmpty {
      result = result.filter {
        $0.name.localizedCaseInsensitiveContains(searchText)
          || $0.address.localizedCaseInsensitiveContains(searchText)
      }
    }

    // Sort
    switch appliedSort {
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
    case .none:
      result.sort {
        let r1 = Double($0.rating ?? "0") ?? 0
        let r2 = Double($1.rating ?? "0") ?? 0
        return r1 > r2
      }
    }
    return result
  }

  var body: some View {
    GeometryReader { geo in
      let halfOffset = sheetPosition.topOffset(in: geo.size.height)
      ZStack(alignment: .top) {
        // ── MAP (full screen behind everything, shows through sheet rounded corners) ──
        ClinicMapView(clinics: topClinicPerDistrict)
          .ignoresSafeArea(.all, edges: .top)

        // ── FLOATING SEARCH BAR ──
        HStack(spacing: 10) {
          // Back button
          Button {
            presentationMode.wrappedValue.dismiss()
          } label: {
            Image(systemName: "chevron.left")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(.black)
              .frame(width: 38, height: 38)
              .background(Color.white)
              .clipShape(Circle())
              .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
          }

          searchBarView
        }
        .padding(.horizontal, 12)
        // Standard Nav Bar is ~44pt tall. Button is 38. (44-38)/2 = 3pt padding to center.
        // User requested stricter reference to InsuranceCompare (Standard Nav).
        // "No Change" reported. Layout likely stuck under Dynamic Island or safeArea is 0.
        // Force absolute position 80pt from top (approx safeArea 59 + 21).
        .padding(.top, 80)

        // ── BOTTOM SHEET ──
        VStack(spacing: 0) {
          // Drag Handle
          VStack(spacing: 0) {
            Capsule()
              .fill(Color(UIColor.systemGray3))
              .frame(width: 36, height: 5)
              .padding(.top, 10)
              .padding(.bottom, 8)
          }
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())

          // Filter Buttons Row
          filterButtonsRow
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)

          // Venue Count
          Text("\(filteredClinics.count) clinics nearby")
            .font(.system(size: 13))
            .foregroundColor(Color(UIColor.systemGray))
            .padding(.top, 10)
            .padding(.bottom, 8)

          // Clinic List
          Divider().opacity(0.3)

          if isLoading {
            Spacer()
            ProgressView("Loading clinics...")
              .tint(.blue)
            Spacer()
          } else if let error = errorMessage {
            Spacer()
            VStack(spacing: 12) {
              Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.gray)
              Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
              Button("Retry") { loadData() }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
            .padding()
            Spacer()
          } else {
            ScrollView {
              LazyVStack(spacing: 16) {
                ForEach(filteredClinics) { clinic in
                  NavigationLink(destination: ClinicDetailView(clinic: clinic)) {
                    ClinicCard(clinic: clinic, userLocation: locationManager.location)
                  }
                  .buttonStyle(PlainButtonStyle())
                }
              }
              .padding(.horizontal, 16)
              .padding(.top, 12)
              .padding(.bottom, 24)
            }
            .overlay(alignment: .bottomTrailing) {
              Button {
                showAIChat = true
              } label: {
                Image(systemName: "sparkles")
                  .font(.system(size: 24, weight: .semibold))
                  .foregroundColor(.white)
                  .frame(width: 56, height: 56)
                  .background(Color.blue)
                  .clipShape(Circle())
                  .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
              }
              .padding(.trailing, 20)
              .padding(.bottom, 30)
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -3)
        .offset(y: currentSheetOffset)
        .gesture(
          DragGesture()
            .onChanged { value in
              // Calculate target offset during drag
              let startY = sheetPosition.topOffset(in: geo.size.height)
              let newY = startY + value.translation.height
              // Apply rubber banding or clamping if needed, but simple clamping is smoothest for this UI
              // Allow dragging up to 140 (Stop below search bar), down to 0.75
              currentSheetOffset = max(130, min(geo.size.height * 0.75, newY))
            }
            .onEnded { value in
              let velocity = value.predictedEndTranslation.height - value.translation.height
              let threshold: CGFloat = geo.size.height * 0.12

              let targetPosition: SheetPosition

              if value.translation.height < -threshold || velocity < -500 {
                targetPosition = .full
              } else if value.translation.height > threshold || velocity > 500 {
                targetPosition = .half
              } else {
                targetPosition = sheetPosition  // Snap back
              }

              let targetY = targetPosition.topOffset(in: geo.size.height)

              withAnimation(
                .interpolatingSpring(stiffness: 280, damping: 28, initialVelocity: velocity / 100)
              ) {
                currentSheetOffset = targetY
                sheetPosition = targetPosition
              }
            }
        )
        .onAppear {
          // Initialize offset correctly on appear
          // Ensure this matches the initial state logic
          currentSheetOffset = UIScreen.main.bounds.height * 0.62
        }
      }
    }
    .sheet(isPresented: $showAIChat) {
      if #available(iOS 16.0, *) {
        RAGChatView(
          contextString: "Finding emergency vet clinics in Hong Kong", isPresented: $showAIChat
        )
        .presentationDetents([.medium, .large])
      } else {
        RAGChatView(
          contextString: "Finding emergency vet clinics in Hong Kong", isPresented: $showAIChat)
      }
    }
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .tabBar)
    .ignoresSafeArea(.all, edges: [.top, .bottom])
    .sheet(isPresented: $showSortSheet) {
      SortSheetView(
        selection: $sortSelection,
        appliedSort: $appliedSort,
        onDismiss: { showSortSheet = false }
      )
      .presentationDetents([.height(280)])
      .presentationDragIndicator(.visible)
    }
    .task {
      loadData()
    }
  }

  // MARK: - Search Bar
  var searchBarView: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 20, weight: .medium))
        .foregroundColor(.black)

      ZStack(alignment: .leading) {
        // Placeholder when empty
        if searchText.isEmpty {
          VStack(alignment: .leading, spacing: 1) {
            Text("All hospitals")
              .font(.system(size: 15, weight: .medium))
              .foregroundColor(.black)
            Text("Map area")
              .font(.system(size: 12))
              .foregroundColor(Color(UIColor.systemGray))
          }
        }

        // Actual text field (transparent when showing placeholder)
        TextField("Search hospitals...", text: $searchText)
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(.black)
          .opacity(searchText.isEmpty ? 0.01 : 1)
      }

      Spacer()

      if !searchText.isEmpty {
        Button {
          searchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 18))
            .foregroundColor(Color(UIColor.systemGray3))
        }
      }
    }
    .padding(.leading, 16)
    .padding(.trailing, 8)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 28)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
    )
  }

  // MARK: - Filter Buttons Row
  var filterButtonsRow: some View {
    HStack(spacing: 10) {
      // Filter icon button
      Button {
      } label: {
        Image(systemName: "slider.horizontal.3")
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(.black)
          .frame(width: 40, height: 36)
          .background(
            RoundedRectangle(cornerRadius: 20)
              .stroke(Color(UIColor.systemGray4), lineWidth: 1)
          )
      }

      // Sort Button
      Button {
        sortSelection = appliedSort
        showSortSheet = true
      } label: {
        HStack(spacing: 4) {
          Text("Sort")
            .font(.system(size: 14, weight: .medium))
          Image(systemName: "chevron.down")
            .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(appliedSort != .none ? .blue : .black)
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .stroke(
              appliedSort != .none ? Color.blue : Color(UIColor.systemGray4),
              lineWidth: appliedSort != .none ? 1.5 : 1
            )
        )
      }

      // Options Button
      Button {
      } label: {
        HStack(spacing: 4) {
          Text("Options")
            .font(.system(size: 14, weight: .medium))
          Image(systemName: "chevron.down")
            .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .stroke(Color(UIColor.systemGray4), lineWidth: 1)
        )
      }
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

// MARK: - Sort Sheet View
struct SortSheetView: View {
  @Binding var selection: SortSelection
  @Binding var appliedSort: SortSelection
  var onDismiss: () -> Void

  @State private var lastRatingTap: Date = .distantPast
  @State private var lastDistanceTap: Date = .distantPast

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Sort By")
          .font(.system(size: 18, weight: .bold))
        Spacer()
        Button {
          onDismiss()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 24))
            .foregroundColor(Color(UIColor.systemGray3))
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 16)

      // Two options
      VStack(spacing: 12) {
        sortOptionRow(
          icon: "star.fill",
          title: "Rating",
          subtitle: "Highest rated first",
          isSelected: selection == .rating
        ) {
          handleTap(for: .rating, lastTap: $lastRatingTap)
        }

        sortOptionRow(
          icon: "location.fill",
          title: "Distance",
          subtitle: "Nearest first",
          isSelected: selection == .distance
        ) {
          handleTap(for: .distance, lastTap: $lastDistanceTap)
        }
      }
      .padding(.horizontal, 20)

      Spacer()

      // Apply Button
      Button {
        appliedSort = selection
        onDismiss()
      } label: {
        Text("Apply")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(
            RoundedRectangle(cornerRadius: 14)
              .fill(Color.blue)
          )
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .background(Color.white)
  }

  private func handleTap(for option: SortSelection, lastTap: Binding<Date>) {
    let now = Date()
    let interval = now.timeIntervalSince(lastTap.wrappedValue)

    if interval < 0.4 && selection == option {
      // Double tap: deselect
      selection = .none
      lastTap.wrappedValue = .distantPast
    } else {
      selection = option
      lastTap.wrappedValue = now
    }
  }

  private func sortOptionRow(
    icon: String, title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 14) {
        Image(systemName: icon)
          .font(.system(size: 16))
          .foregroundColor(isSelected ? .blue : .gray)
          .frame(width: 24)

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.primary)
          Text(subtitle)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }

        Spacer()

        // Selection indicator ring
        ZStack {
          Circle()
            .strokeBorder(isSelected ? Color.blue : Color(UIColor.systemGray4), lineWidth: 2)
            .frame(width: 22, height: 22)
          if isSelected {
            Circle()
              .fill(Color.blue)
              .frame(width: 12, height: 12)
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(isSelected ? Color.blue.opacity(0.04) : Color(UIColor.systemGray6))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1.5)
      )
    }
  }
}

// MARK: - Embedded Map View
struct ClinicMapView: UIViewRepresentable {
  let clinics: [Clinic]

  func makeUIView(context: Context) -> GMSMapView {
    let camera = GMSCameraPosition.camera(
      withLatitude: 22.32,
      longitude: 114.17,
      zoom: 11
    )
    let mapID = GMSMapID(identifier: "a644dbe938291feb93f79c1d")
    let mapView = GMSMapView(frame: .zero, mapID: mapID, camera: camera)
    mapView.isMyLocationEnabled = true
    mapView.settings.myLocationButton = false
    mapView.settings.compassButton = false
    mapView.settings.scrollGestures = true
    mapView.settings.zoomGestures = true
    return mapView
  }

  func updateUIView(_ mapView: GMSMapView, context: Context) {
    mapView.clear()

    for clinic in clinics {
      guard let latStr = clinic.latitude, let lngStr = clinic.longitude,
        let lat = Double(latStr), let lng = Double(lngStr)
      else { continue }

      let marker = GMSMarker()
      marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
      marker.title = clinic.name
      marker.snippet = clinic.address
      marker.icon = renderWhiteBubble(rating: clinic.rating)
      marker.map = mapView
    }
  }

  func renderWhiteBubble(rating: String?) -> UIImage {
    let text = rating ?? "-"
    let containerWidth: CGFloat = 44
    let containerHeight: CGFloat = 38
    let bubbleHeight: CGFloat = 28

    let container = UIView(
      frame: CGRect(x: 0, y: 0, width: containerWidth, height: containerHeight))

    let bubble = UIView(
      frame: CGRect(x: 0, y: 0, width: containerWidth, height: bubbleHeight))
    bubble.backgroundColor = .white
    bubble.layer.cornerRadius = bubbleHeight / 2
    bubble.layer.shadowColor = UIColor.black.cgColor
    bubble.layer.shadowOpacity = 0.15
    bubble.layer.shadowOffset = CGSize(width: 0, height: 2)
    bubble.layer.shadowRadius = 4
    container.addSubview(bubble)

    let label = UILabel(frame: bubble.bounds)
    label.text = text
    label.textColor = .darkGray
    label.font = UIFont.boldSystemFont(ofSize: 12)
    label.textAlignment = .center
    bubble.addSubview(label)

    let path = UIBezierPath()
    let cx = containerWidth / 2
    path.move(to: CGPoint(x: cx - 5, y: bubbleHeight - 1))
    path.addLine(to: CGPoint(x: cx, y: containerHeight))
    path.addLine(to: CGPoint(x: cx + 5, y: bubbleHeight - 1))
    path.close()

    let shapeLayer = CAShapeLayer()
    shapeLayer.path = path.cgPath
    shapeLayer.fillColor = UIColor.white.cgColor
    shapeLayer.shadowColor = UIColor.black.cgColor
    shapeLayer.shadowOpacity = 0.1
    shapeLayer.shadowOffset = CGSize(width: 0, height: 2)
    shapeLayer.shadowRadius = 2
    container.layer.addSublayer(shapeLayer)

    let renderer = UIGraphicsImageRenderer(bounds: container.bounds)
    return renderer.image { ctx in
      container.layer.render(in: ctx.cgContext)
    }
  }
}

// MARK: - Clinic Card (full-width photo style)
struct ClinicCard: View {
  let clinic: Clinic
  let userLocation: CLLocation?

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
    VStack(alignment: .leading, spacing: 0) {
      // Large Photo
      ZStack(alignment: .topLeading) {
        if let urlString = clinic.photoUrl, let url = URL(string: urlString) {
          CachedAsyncImage(url: url) { phase in
            switch phase {
            case .empty:
              Rectangle()
                .fill(Color(UIColor.systemGray5))
                .overlay(ProgressView().tint(.gray))
            case .success(let image):
              image.resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
            case .failure:
              ZStack {
                Rectangle().fill(Color(UIColor.systemGray5))
                Image(systemName: "photo.fill")
                  .font(.system(size: 30))
                  .foregroundColor(.gray.opacity(0.3))
              }
            @unknown default:
              EmptyView()
            }
          }
        } else {
          ZStack {
            Rectangle()
              .fill(Color(UIColor.systemGray5))
            Image(systemName: "cross.case.fill")
              .font(.system(size: 36))
              .foregroundColor(.gray.opacity(0.2))
          }
        }

        // Badge
        if clinic.emergency24h.uppercased() == "TRUE" {
          Text("24H Emergency")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
              Capsule()
                .fill(Color.black.opacity(0.7))
            )
            .padding(12)
        }
      }
      .frame(height: 200)
      .frame(maxWidth: .infinity)
      .clipped()
      .cornerRadius(14, corners: [.topLeft, .topRight])

      // Info Row
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text(clinic.name)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          HStack(spacing: 4) {
            if let dist = distanceString {
              Text(dist)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
              Text("·")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            Text(clinic.address)
              .font(.system(size: 12))
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
        }

        Spacer(minLength: 8)

        // Rating
        if let rating = clinic.rating, !rating.isEmpty {
          HStack(spacing: 3) {
            Image(systemName: "star.fill")
              .font(.system(size: 12))
              .foregroundColor(.orange)
            Text(rating)
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(.primary)
          }
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
    }
    .background(Color.white)
    .cornerRadius(14)
    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
  }
}
