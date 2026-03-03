import SwiftUI

struct VaccineView: View {
  @EnvironmentObject var guideManager: GuideManager
  @State private var searchText = ""
  @State private var vaccines: [Vaccine] = []
  @State private var isLoading = false
  @State private var errorMessage: String?

  var dogVaccines: [Vaccine] {
    vaccines.filter { $0.petType.contains("dog") || $0.petType.contains("dog/cat") }
  }

  var catVaccines: [Vaccine] {
    vaccines.filter { $0.petType.contains("cat") || $0.petType.contains("dog/cat") }
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
                  .font(.system(size: 34, weight: .bold, design: .rounded))
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
                .simultaneousGesture(TapGesture().onEnded {
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

                // "Service Near Me" with Modern Cards
                VStack(alignment: .leading, spacing: 12) {
                  HStack {
                    Text("Services")
                      .font(.title2)
                      .fontWeight(.bold)
                    Spacer()
                    Text("See All")
                      .font(.subheadline)
                      .foregroundColor(.blue)
                  }
                  .padding(.horizontal)

                  ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                      NavigationLink(destination: EmergencyClinicsView()) {
                        ServiceCard(
                          title: "24h Medical", subtitle: "Support", imageName: "cross.case.fill",
                          color: .red)

                      }
                      NavigationLink(destination: HealthCheckView()) {
                        ServiceCard(
                          title: "Health Check", subtitle: "Regular", imageName: "stethoscope",
                          color: .blue)
                      }
                      ServiceCard(
                        title: "Deworming", subtitle: "Treatment", imageName: "pills.fill",
                        color: .green)
                    }
                    .padding(.horizontal)
                  }
                }

                // Dog Vaccination Section
                VStack(alignment: .leading, spacing: 12) {
                  Text("Dog Vaccination")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                  ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                      ForEach(dogVaccines) { vaccine in
                        VaccineCard(vaccine: vaccine)
                          .frame(width: 200)
                      }
                    }
                    .padding(.horizontal)
                  }
                }

                // Cat Vaccination Section
                VStack(alignment: .leading, spacing: 12) {
                  Text("Cat Vaccination")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                  ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                      ForEach(catVaccines) { vaccine in
                        VaccineCard(vaccine: vaccine)
                          .frame(width: 200)
                      }
                    }
                    .padding(.horizontal)
                  }
                }
              }
              .padding(.bottom, 100)
            }
          }
        }
      }
      .background(Color(UIColor.systemGroupedBackground))  // Subtle light gray background
      .task {
        loadData()
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
}

struct ServiceCard: View {
  let title: String
  let subtitle: String
  let imageName: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ZStack {
        Circle()
          .fill(color.opacity(0.1))
          .frame(width: 48, height: 48)
        Image(systemName: imageName)
          .foregroundColor(color)
          .font(.system(size: 24))
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.bold)
          .foregroundColor(.primary)
          .lineLimit(1)

        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(16)
    .frame(width: 140, height: 130)
    .background(Color(UIColor.systemBackground))
    .cornerRadius(20)
    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
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
    .init(name: "General Consultation", subtitle: "Physical exam + symptom review", price: 420, duration: "30 min", petType: "dog/cat"),
    .init(name: "Vaccination Booster", subtitle: "Core booster shot and record update", price: 360, duration: "25 min", petType: "dog/cat"),
    .init(name: "Skin & Allergy Check", subtitle: "Dermatitis and itch diagnostics", price: 480, duration: "35 min", petType: "dog/cat"),
    .init(name: "Dental Checkup", subtitle: "Oral exam and preventive care plan", price: 520, duration: "40 min", petType: "dog/cat"),
  ]

  private var selectedClinic: Clinic {
    clinics.first(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "testclinics" })
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
              NavigationLink(destination: VaccineBookingView(vaccine: item.asVaccine, clinic: selectedClinic)) {
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
