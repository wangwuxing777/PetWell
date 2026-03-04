import Combine
import SwiftUI

struct VaccineView: View {
  @EnvironmentObject var guideManager: GuideManager
  @State private var searchText = ""
  @State private var vaccines: [Vaccine] = []
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var currentArticleIndex = 0
  @State private var isServiceOrderEditorPresented = false
  @State private var isServicesExpanded = false
  @State private var editableServiceOrder: [ServiceKind] = []
  @AppStorage("medical_service_order_v1") private var serviceOrderRaw = ""

  private let articleTimer = Timer.publish(every: 4.5, on: .main, in: .common).autoconnect()

  var dogVaccines: [Vaccine] {
    vaccines.filter { $0.petType.contains("dog") || $0.petType.contains("dog/cat") }
  }

  var catVaccines: [Vaccine] {
    vaccines.filter { $0.petType.contains("cat") || $0.petType.contains("dog/cat") }
  }

  private let articles: [MedicalArticle] = [
    .init(
      title: "When your pet has diarrhea",
      imageName: "DogBite"
    ),
    .init(
      title: "Post-vaccine care tips",
      imageName: "Rabies"
    ),
    .init(
      title: "Dental checks matter",
      imageName: "Fracture"
    ),
    .init(
      title: "Heat safety for summer",
      imageName: "PatellarLuxation"
    ),
  ]

  private var orderedServiceKinds: [ServiceKind] {
    let stored =
      serviceOrderRaw
      .split(separator: ",")
      .map { ServiceKind(rawValue: String($0)) }
      .compactMap { $0 }

    var seen = Set<ServiceKind>()
    let uniqueStored = stored.filter { seen.insert($0).inserted }
    let missing = ServiceKind.allCases.filter { !uniqueStored.contains($0) }
    return uniqueStored + missing
  }

  var body: some View {
    NavigationStack {
      Group {
        if isLoading {
          ProgressView("Loading vaccines...")
        } else if let error = errorMessage {
          VStack {
            Text("Error loading data")
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
          VStack(spacing: 0) {
            // High-End Header
            VStack(alignment: .leading, spacing: 16) {
              HStack {
                Text("Pet Health Center")
                  .font(.system(size: 34, weight: .bold))
                  .foregroundColor(.primary)

                Spacer()

                NavigationLink(destination: TestClinicEntryView()) {
                  Image(systemName: "cross.case.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                }
                .simultaneousGesture(
                  TapGesture().onEnded {
                    guideManager.mark(.medicalOpenedMap)
                  })
              }
              .padding(.horizontal)
              .padding(.top, 20)

              HStack {
                Image(systemName: "magnifyingglass")
                  .foregroundColor(.gray)
                TextField("Search vaccines, services...", text: $searchText)
              }
              .padding(12)
              .background(Color(UIColor.secondarySystemBackground))
              .cornerRadius(12)
              .padding(.horizontal)
              .padding(.bottom, 10)
            }
            .background(Color(UIColor.systemBackground))
            .zIndex(1)

            ScrollView {
              VStack(alignment: .leading, spacing: 24) {
                // Medical Tips Carousel
                VStack(alignment: .leading, spacing: 12) {
                  ZStack(alignment: .bottom) {
                    TabView(selection: $currentArticleIndex) {
                      ForEach(Array(articles.enumerated()), id: \.offset) { index, article in
                        MedicalArticleCard(article: article)
                          .tag(index)
                      }
                    }
                    .aspectRatio(16.0 / 10.0, contentMode: .fit)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onReceive(articleTimer) { _ in
                      guard !articles.isEmpty else { return }
                      withAnimation(.easeInOut(duration: 0.3)) {
                        currentArticleIndex = (currentArticleIndex + 1) % articles.count
                      }
                    }

                    // Internal Pill Pagination
                    HStack(spacing: 6) {
                      ForEach(articles.indices, id: \.self) { index in
                        Capsule()
                          .fill(
                            index == currentArticleIndex ? Color.white : Color.white.opacity(0.5)
                          )
                          .frame(width: index == currentArticleIndex ? 32 : 8, height: 8)
                          .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                              currentArticleIndex = index
                            }
                          }
                      }
                    }
                    .padding(.bottom, 16)
                  }
                  .padding(.horizontal, 16)
                }

                // Services Grid
                VStack(alignment: .leading, spacing: 12) {
                  HStack {
                    Text("Services")
                      .font(.title2)
                      .fontWeight(.bold)
                    Spacer()
                    Button("Sort") {
                      editableServiceOrder = orderedServiceKinds
                      isServiceOrderEditorPresented = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                  }
                  .padding(.horizontal)

                  let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
                  let displayedServices =
                    isServicesExpanded ? orderedServiceKinds : Array(orderedServiceKinds.prefix(6))

                  LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(displayedServices) { kind in
                      NavigationLink(destination: serviceDestination(for: kind)) {
                        ServiceCard(
                          title: kind.title,
                          subtitle: kind.subtitle,
                          imageName: kind.systemImage,
                          color: kind.color)
                      }
                    }
                  }
                  .padding(.horizontal)

                  Button(action: {
                    withAnimation {
                      isServicesExpanded.toggle()
                    }
                  }) {
                    HStack {
                      Text(isServicesExpanded ? "Show Less" : "Show All Services")
                      Image(systemName: isServicesExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.blue)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)
                  }
                  .padding(.horizontal)
                }
              }
              .padding(.bottom, 100)
            }
          }
        }
      }
      .background(Color.white)
      .task {
        loadData()
      }
      .sheet(isPresented: $isServiceOrderEditorPresented) {
        ServiceOrderEditorView(
          serviceOrder: $editableServiceOrder,
          onSave: {
            saveServiceOrder(editableServiceOrder)
            isServiceOrderEditorPresented = false
          }
        )
      }
    }
  }

  private func loadData() {
    isLoading = true
    Task {
      do {
        self.vaccines = try await VaccineService.shared.fetchVaccines()
        self.errorMessage = nil
      } catch {
        self.errorMessage = error.localizedDescription
      }
      self.isLoading = false
    }
  }

  @ViewBuilder
  private func serviceDestination(for kind: ServiceKind) -> some View {
    switch kind {
    case .vaccination:
      VaccinationHubView(dogVaccines: dogVaccines, catVaccines: catVaccines)
    case .emergency24h:
      EmergencyClinicsView()
    case .healthCheck:
      HealthCheckView()
    case .deworming:
      ServicePlaceholderView(
        title: "Deworming",
        description: "Deworming package list will be added in next update.")
    case .dentalCare:
      ServicePlaceholderView(
        title: "Dental Care",
        description: "Oral exam, scaling, and treatment booking is coming soon.")
    case .labTests:
      ServicePlaceholderView(
        title: "Lab Tests",
        description: "Blood test and diagnostic package booking is coming soon.")
    case .microchip:
      ServicePlaceholderView(
        title: "Microchip",
        description: "Microchip registration and appointment booking is coming soon.")
    case .nutrition:
      ServicePlaceholderView(
        title: "Nutrition",
        description: "Nutrition consultation services will be available soon.")
    case .surgeryCare:
      ServicePlaceholderView(
        title: "Surgery Care",
        description: "Pre-op and post-op care workflow will be available soon.")
    }
  }

  private func saveServiceOrder(_ kinds: [ServiceKind]) {
    let ids = kinds.map(\.rawValue)
    serviceOrderRaw = ids.joined(separator: ",")
  }
}

struct ServiceCard: View {
  let title: String
  let subtitle: String
  let imageName: String
  let color: Color

  var body: some View {
    VStack(alignment: .center, spacing: 10) {
      ZStack {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(color.opacity(0.12))
          .frame(width: 48, height: 48)
        Image(systemName: imageName)
          .foregroundColor(color)
          .font(.system(size: 22, weight: .medium))
      }

      VStack(alignment: .center, spacing: 3) {
        Text(title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(Color(UIColor.label))
          .lineLimit(1)

        Text(subtitle)
          .font(.system(size: 11))
          .foregroundColor(Color(UIColor.secondaryLabel))
          .lineLimit(1)
      }
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 8)
    .frame(maxWidth: .infinity)
    .aspectRatio(1, contentMode: .fill)
    .background(Color(UIColor.systemBackground))
    .cornerRadius(18)
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(Color(UIColor.systemGray5), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
  }
}

private struct MedicalArticle: Identifiable {
  let id = UUID()
  let title: String
  let imageName: String
}

private struct MedicalArticleCard: View {
  let article: MedicalArticle

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      if let image = UIImage(named: article.imageName) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
      } else {
        Rectangle()
          .fill(
            LinearGradient(
              colors: [Color.blue.opacity(0.35), Color.purple.opacity(0.35)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(Color.black.opacity(0.05), lineWidth: 1)
    )
  }
}

private enum VaccinationPetType: String, CaseIterable, Identifiable {
  case dog = "Dog"
  case cat = "Cat"

  var id: String { rawValue }
}

private struct VaccinationHubView: View {
  let dogVaccines: [Vaccine]
  let catVaccines: [Vaccine]

  @State private var selectedType: VaccinationPetType = .dog

  private var currentVaccines: [Vaccine] {
    selectedType == .dog ? dogVaccines : catVaccines
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Picker("Pet Type", selection: $selectedType) {
          ForEach(VaccinationPetType.allCases) { type in
            Text(type.rawValue).tag(type)
          }
        }
        .pickerStyle(.segmented)

        Text(selectedType == .dog ? "Dog Vaccination" : "Cat Vaccination")
          .font(.title3.weight(.bold))

        if currentVaccines.isEmpty {
          VStack(spacing: 10) {
            Image(systemName: "tray.fill")
              .font(.title2)
              .foregroundColor(.secondary)
            Text("No vaccines available right now.")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 30)
        } else {
          LazyVStack(spacing: 14) {
            ForEach(currentVaccines) { vaccine in
              HStack {
                Spacer(minLength: 0)
                VaccineCard(vaccine: vaccine)
                Spacer(minLength: 0)
              }
            }
          }
        }
      }
      .padding()
    }
    .background(Color(UIColor.systemGroupedBackground))
    .navigationTitle("Vaccination")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private enum ServiceKind: String, CaseIterable, Identifiable {
  case vaccination
  case emergency24h
  case healthCheck
  case deworming
  case dentalCare
  case labTests
  case microchip
  case nutrition
  case surgeryCare

  var id: String { rawValue }

  var title: String {
    switch self {
    case .vaccination: return "Vaccination"
    case .emergency24h: return "24h Medical"
    case .healthCheck: return "Health Check"
    case .deworming: return "Deworming"
    case .dentalCare: return "Dental Care"
    case .labTests: return "Lab Tests"
    case .microchip: return "Microchip"
    case .nutrition: return "Nutrition"
    case .surgeryCare: return "Surgery Care"
    }
  }

  var subtitle: String {
    switch self {
    case .vaccination: return "Dog/Cat"
    case .emergency24h: return "Support"
    case .healthCheck: return "Regular"
    case .deworming: return "Treatment"
    case .dentalCare: return "Oral health"
    case .labTests: return "Diagnostics"
    case .microchip: return "ID safety"
    case .nutrition: return "Diet plan"
    case .surgeryCare: return "Pre/Post-op"
    }
  }

  var systemImage: String {
    switch self {
    case .vaccination: return "syringe.fill"
    case .emergency24h: return "cross.case.fill"
    case .healthCheck: return "stethoscope"
    case .deworming: return "pills.fill"
    case .dentalCare: return "mouth.fill"
    case .labTests: return "testtube.2"
    case .microchip: return "wave.3.right"
    case .nutrition: return "leaf.fill"
    case .surgeryCare: return "cross.vial.fill"
    }
  }

  var color: Color {
    switch self {
    case .vaccination: return .purple
    case .emergency24h: return .red
    case .healthCheck: return .blue
    case .deworming: return .green
    case .dentalCare: return .orange
    case .labTests: return .indigo
    case .microchip: return .teal
    case .nutrition: return .mint
    case .surgeryCare: return .pink
    }
  }
}

private struct ServiceOrderEditorView: View {
  @Binding var serviceOrder: [ServiceKind]
  let onSave: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        ForEach(serviceOrder) { kind in
          HStack(spacing: 10) {
            Image(systemName: kind.systemImage)
              .foregroundColor(kind.color)
            VStack(alignment: .leading, spacing: 2) {
              Text(kind.title)
                .font(.body.weight(.semibold))
              Text(kind.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .padding(.vertical, 4)
        }
        .onMove { source, destination in
          serviceOrder.move(fromOffsets: source, toOffset: destination)
        }
      }
      .navigationTitle("Sort Services")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave()
          }
        }
        ToolbarItem(placement: .topBarLeading) {
          EditButton()
        }
      }
    }
  }
}

private struct ServicePlaceholderView: View {
  let title: String
  let description: String

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "clock.badge.exclamationmark")
        .font(.system(size: 44))
        .foregroundColor(.blue.opacity(0.7))
      Text(title)
        .font(.title2.weight(.bold))
      Text(description)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 26)
      Spacer()
    }
    .padding(.top, 60)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct VaccineCard: View {
  let vaccine: Vaccine

  var body: some View {
    VStack(spacing: 0) {
      // 1. Clean Image Area
      ZStack(alignment: .topTrailing) {
        // Background Frame
        Rectangle()
          .fill(Color.white)
          .frame(height: 140)
          .frame(maxWidth: .infinity)

        if let uiImage = UIImage(named: vaccine.imageName) {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()  // Fill the area, cropping if needed
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .clipped()  // Ensure it doesn't bleed out
        } else {
          Rectangle()
            .fill(Color.clear)
            .frame(height: 140)
            .overlay(
              Image(systemName: "pawprint.fill")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.3))
            )
        }

        // Minimal Badge
        if vaccine.isCore {
          Text("CORE")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.6))
            .cornerRadius(6)
            .padding(8)
        }
      }
      .frame(maxWidth: .infinity)

      // 2. Structured Content
      VStack(alignment: .leading, spacing: 10) {
        Text(vaccine.name)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.primary)
          .lineLimit(1)

        HStack(alignment: .center) {
          Text("$\(vaccine.price)")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.blue)

          Spacer()

          NavigationLink(destination: VaccineDetailView(vaccine: vaccine)) {
            Text("Book")
              .font(.system(size: 12, weight: .bold))
              .foregroundColor(.blue)
              .padding(.horizontal, 14)
              .padding(.vertical, 6)
              .background(Color.blue.opacity(0.1))
              .cornerRadius(20)
          }
        }
      }
      .padding(12)
      .background(Color(UIColor.systemBackground))
      .frame(maxWidth: .infinity)  // Ensure content fills the width strictly
    }
    .background(Color(UIColor.systemBackground))  // Add background to the whole card container
    .frame(width: 200, height: 220)  // Specify fixed width again to ensure container is rigid
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
  }
}

private struct TestClinicService: Identifiable {
  let id = UUID()
  let name: String
  let subtitle: String
  let price: Int
  let duration: String
  let petType: String

  var asVaccine: Vaccine {
    Vaccine(
      id: abs(name.hashValue % 100_000) + 10_000,
      name: name,
      petType: petType,
      description: subtitle,
      youngInfo: "Initial assessment and first treatment in one visit.",
      adultInfo: "Revisit or follow-up can be booked based on vet advice.",
      isCore: false,
      isMandatory: false,
      price: price
    )
  }
}

private struct TestClinicEntryView: View {
  @State private var clinics: [Clinic] = []
  @State private var isLoading = true
  @State private var errorText: String?

  private let services: [TestClinicService] = [
    .init(
      name: "General Consultation", subtitle: "Physical exam + symptom review", price: 420,
      duration: "30 min", petType: "dog/cat"),
    .init(
      name: "Vaccination Booster", subtitle: "Core booster shot and record update", price: 360,
      duration: "25 min", petType: "dog/cat"),
    .init(
      name: "Skin & Allergy Check", subtitle: "Dermatitis and itch diagnostics", price: 480,
      duration: "35 min", petType: "dog/cat"),
    .init(
      name: "Dental Checkup", subtitle: "Oral exam and preventive care plan", price: 520,
      duration: "40 min", petType: "dog/cat"),
  ]

  private var selectedClinic: Clinic {
    clinics.first(where: {
      $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "testclinics"
    })
      ?? Clinic(
        id: "testclinics",
        name: "testclinics",
        address: "Petwell Test Clinic - Merchant Sync",
        phoneRegular: "+852 9000 0044",
        phoneEmergency: nil,
        whatsapp: nil,
        openingHours: "Mon-Sun: 09:00-18:00",
        emergency24h: "FALSE",
        websiteUrl: "https://testclinics.petwell.local",
        applemapUrl: "https://maps.apple.com/?q=testclinics",
        latitude: "22.3193",
        longitude: "114.1694",
        rating: "5",
        photoUrl: nil,
        googlePlaceId: nil
      )
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        VStack(alignment: .leading, spacing: 6) {
          Text("testclinics")
            .font(.largeTitle.bold())
          Text("Application ↔ Merchant integration test entry")
            .foregroundColor(.secondary)
        }

        VStack(alignment: .leading, spacing: 10) {
          Label(selectedClinic.address, systemImage: "mappin.and.ellipse")
          Label(selectedClinic.openingHours, systemImage: "clock")
          if let rating = selectedClinic.rating, !rating.isEmpty {
            Label("Rating \(rating)", systemImage: "star.fill")
          }
        }
        .font(.subheadline)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)

        Text("Bookable Services")
          .font(.title2.bold())

        ForEach(services) { item in
          VStack(alignment: .leading, spacing: 10) {
            Text(item.name)
              .font(.headline)
            Text(item.subtitle)
              .font(.subheadline)
              .foregroundColor(.secondary)

            HStack {
              Text("$\(item.price)")
                .font(.headline)
                .foregroundColor(.blue)
              Spacer()
              Text(item.duration)
                .font(.caption)
                .foregroundColor(.secondary)
              NavigationLink(
                destination: VaccineBookingView(vaccine: item.asVaccine, clinic: selectedClinic)
              ) {
                Text("Book Now")
                  .font(.caption.bold())
                  .padding(.horizontal, 12)
                  .padding(.vertical, 8)
                  .background(Color.blue.opacity(0.12))
                  .cornerRadius(12)
              }
            }
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.white)
          .cornerRadius(14)
          .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }

        if let errorText {
          Text("Clinics sync fallback: \(errorText)")
            .font(.caption)
            .foregroundColor(.orange)
        } else if isLoading {
          ProgressView("Syncing clinic data...")
        }
      }
      .padding()
    }
    .navigationTitle("Test Clinic")
    .navigationBarTitleDisplayMode(.inline)
    .background(Color(UIColor.systemGroupedBackground))
    .task {
      do {
        clinics = try await ClinicService.shared.fetchAllClinics()
      } catch {
        errorText = error.localizedDescription
      }
      isLoading = false
    }
  }
}
