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
      imageName: "EarInfection"
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

  private var filteredServiceKinds: [ServiceKind] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return orderedServiceKinds }

    return orderedServiceKinds.filter { kind in
      kind.title.localizedCaseInsensitiveContains(query)
        || kind.subtitle.localizedCaseInsensitiveContains(query)
        || kind.blurb.localizedCaseInsensitiveContains(query)
        || kind.searchKeywords.contains(where: { $0.localizedCaseInsensitiveContains(query) })
    }
  }

  private var displayedServiceKinds: [ServiceKind] {
    isServicesExpanded ? filteredServiceKinds : Array(filteredServiceKinds.prefix(6))
  }

  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          colors: [
            Color(red: 0.95, green: 0.97, blue: 0.95),
            Color(red: 0.99, green: 0.96, blue: 0.92),
            Color.white
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        Circle()
          .fill(Color(red: 0.84, green: 0.91, blue: 0.84).opacity(0.35))
          .frame(width: 320, height: 320)
          .offset(x: 150, y: -290)

        Circle()
          .fill(Color(red: 0.78, green: 0.86, blue: 0.93).opacity(0.22))
          .frame(width: 260, height: 260)
          .offset(x: -160, y: 220)

        Group {
          if isLoading {
            loadingStateView
          } else if let error = errorMessage {
            errorStateView(error)
          } else {
            ScrollView(showsIndicators: false) {
              VStack(alignment: .leading, spacing: 28) {
                heroSection
                articleSection
                servicesSection
              }
              .padding(.horizontal, 18)
              .padding(.top, 12)
              .padding(.bottom, 110)
            }
          }
        }
      }
      .background(AppTheme.bgBase)
      .toolbar(.hidden, for: .navigationBar)
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

  private var loadingStateView: some View {
    VStack(spacing: 18) {
      ProgressView()
        .controlSize(.large)
        .tint(Color(red: 0.16, green: 0.36, blue: 0.42))

      Text("Preparing medical dashboard...")
        .font(.headline)
        .foregroundStyle(Color(red: 0.20, green: 0.26, blue: 0.29))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func errorStateView(_ error: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 28))
        .foregroundStyle(Color(red: 0.79, green: 0.36, blue: 0.17))

      Text("Unable to load medical data")
        .font(.title3.weight(.semibold))

      Text(error)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        loadData()
      }
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(.white)
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .background(Color(red: 0.17, green: 0.35, blue: 0.41), in: Capsule())
    }
    .padding(28)
    .frame(maxWidth: 420)
    .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(Color.white.opacity(0.8), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 22)
  }

  private var heroSection: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .top, spacing: 14) {
        VStack(alignment: .leading, spacing: 10) {
          Text("PETWELL MEDICAL")
            .font(.caption.weight(.semibold))
            .tracking(1.4)
            .foregroundStyle(Color.white.opacity(0.8))

          Text("Vaccination & Preventive Care")
            .font(.system(size: 34, weight: .bold, design: .serif))
            .foregroundStyle(.white)

          Text("A calmer, more curated way to plan boosters, routine checks, and clinic visits.")
            .font(.subheadline)
            .foregroundStyle(Color.white.opacity(0.84))
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 0)

        NavigationLink(destination: TestClinicEntryView()) {
          Image(systemName: "cross.case.fill")
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 46, height: 46)
            .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
        }
        .simultaneousGesture(
          TapGesture().onEnded {
            guideManager.mark(.medicalOpenedMap)
          })
      }

      HStack(spacing: 10) {
        MedicalMetricPill(value: "\(vaccines.count)", label: "Vaccine lines")
        MedicalMetricPill(value: "\(vaccines.filter(\.isCore).count)", label: "Core coverage")
        MedicalMetricPill(value: "\(orderedServiceKinds.count)", label: "Care services")
      }

      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(Color.white.opacity(0.72))

        TextField("Search services, vaccines, clinics...", text: $searchText)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .foregroundStyle(.white)
          .tint(.white)

        if !searchText.isEmpty {
          Button {
            searchText = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(Color.white.opacity(0.72))
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(Color.white.opacity(0.14), lineWidth: 1)
      )

      NavigationLink(destination: VaccinationHubView(dogVaccines: dogVaccines, catVaccines: catVaccines)) {
        HStack(spacing: 14) {
          VStack(alignment: .leading, spacing: 6) {
            Text("Featured")
              .font(.caption.weight(.semibold))
              .foregroundStyle(Color(red: 0.19, green: 0.26, blue: 0.27))

            Text("Open the vaccination planner")
              .font(.headline.weight(.semibold))
              .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.19))

            Text("Compare dog and cat schedules, review core shots, and book in one place.")
              .font(.caption)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }

          Spacer(minLength: 0)

          Image(systemName: "arrow.up.right")
            .font(.headline.weight(.bold))
            .foregroundStyle(Color(red: 0.17, green: 0.35, blue: 0.41))
            .frame(width: 38, height: 38)
            .background(Color(red: 0.91, green: 0.95, blue: 0.93), in: Circle())
        }
        .padding(18)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
      }
      .buttonStyle(.plain)
    }
    .padding(22)
    .background(
      LinearGradient(
        colors: [
          Color(red: 0.14, green: 0.21, blue: 0.26),
          Color(red: 0.21, green: 0.37, blue: 0.40),
          Color(red: 0.46, green: 0.60, blue: 0.54)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      ),
      in: RoundedRectangle(cornerRadius: 32, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .stroke(Color.white.opacity(0.12), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.12), radius: 24, y: 16)
  }

  private var articleSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      MedicalSectionHeader(
        eyebrow: "CARE NOTES",
        title: "Editorial guidance for everyday health",
        subtitle: "A cleaner, more premium reading surface for quick medical literacy."
      )

      ZStack(alignment: .bottom) {
        TabView(selection: $currentArticleIndex) {
          ForEach(Array(articles.enumerated()), id: \.offset) { index, article in
            MedicalArticleCard(article: article)
              .tag(index)
          }
        }
        .frame(height: 236)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onReceive(articleTimer) { _ in
          guard !articles.isEmpty else { return }
          withAnimation(.easeInOut(duration: 0.35)) {
            currentArticleIndex = (currentArticleIndex + 1) % articles.count
          }
        }

        HStack(spacing: 7) {
          ForEach(articles.indices, id: \.self) { index in
            Capsule()
              .fill(index == currentArticleIndex ? Color.white : Color.white.opacity(0.42))
              .frame(width: index == currentArticleIndex ? 30 : 9, height: 9)
              .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                  currentArticleIndex = index
                }
              }
          }
        }
        .padding(.bottom, 16)
      }
    }
  }

  private var servicesSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .bottom) {
        MedicalSectionHeader(
          eyebrow: "SERVICES",
          title: "Precision care, arranged by intent",
          subtitle: "A calmer service grid with stronger hierarchy and clearer affordances."
        )

        Spacer(minLength: 12)

        Button {
          editableServiceOrder = orderedServiceKinds
          isServiceOrderEditorPresented = true
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "arrow.up.arrow.down")
            Text("Sort")
          }
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color(red: 0.17, green: 0.35, blue: 0.41))
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(Color.white.opacity(0.84), in: Capsule())
        }
      }

      let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

      if displayedServiceKinds.isEmpty {
        VStack(spacing: 10) {
          Image(systemName: "sparkle.magnifyingglass")
            .font(.system(size: 26))
            .foregroundStyle(Color(red: 0.35, green: 0.47, blue: 0.48))

          Text("No matching services")
            .font(.headline)

          Text("Try a broader keyword like vaccination, check, dental, or clinic.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
      } else {
        LazyVGrid(columns: columns, spacing: 14) {
          ForEach(displayedServiceKinds) { kind in
            NavigationLink(destination: serviceDestination(for: kind)) {
              ServiceCard(
                title: kind.title,
                subtitle: kind.subtitle,
                detail: kind.blurb,
                imageName: kind.systemImage,
                color: kind.color)
            }
            .buttonStyle(.plain)
          }
        }
      }

      if filteredServiceKinds.count > 6 {
        Button(action: {
          withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            isServicesExpanded.toggle()
          }
        }) {
          HStack(spacing: 8) {
            Text(isServicesExpanded ? "Show Fewer Services" : "Reveal Full Service Directory")
            Image(systemName: isServicesExpanded ? "chevron.up" : "chevron.down")
          }
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color(red: 0.17, green: 0.35, blue: 0.41))
          .padding(.vertical, 14)
          .frame(maxWidth: .infinity)
          .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
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
      MedicalServiceDetailView(category: "deworming", fallbackTitle: "Deworming")
    case .dentalCare:
      MedicalServiceDetailView(category: "dental", fallbackTitle: "Dental Care")
    case .labTests:
      MedicalServiceDetailView(category: "lab_tests", fallbackTitle: "Lab Tests")
    case .microchip:
      MedicalServiceDetailView(category: "microchip", fallbackTitle: "Microchip")
    case .nutrition:
      MedicalServiceDetailView(category: "nutrition", fallbackTitle: "Nutrition")
    case .surgeryCare:
      MedicalServiceDetailView(category: "surgery_care", fallbackTitle: "Surgery Care")
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
  let detail: String
  let imageName: String
  let color: Color
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top) {
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [color.opacity(0.24), color.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 54, height: 54)

          Image(systemName: imageName)
            .foregroundStyle(color)
            .font(.system(size: 22, weight: .semibold))
        }

        Spacer(minLength: 0)

        Image(systemName: "arrow.up.right")
          .font(.caption.weight(.bold))
          .foregroundStyle(Color(red: 0.35, green: 0.41, blue: 0.44))
          .padding(8)
          .background(Color.white.opacity(0.76), in: Circle())
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(subtitle.uppercased())
          .font(.caption2.weight(.semibold))
          .tracking(0.8)
          .foregroundStyle(color)

        Text(title)
          .font(.headline.weight(.semibold))
          .foregroundStyle(Color(red: 0.11, green: 0.15, blue: 0.18))
          .lineLimit(2)

        Text(detail)
          .font(.caption)
          .foregroundStyle(Color(red: 0.36, green: 0.42, blue: 0.44))
          .lineLimit(2)
      }

      Spacer(minLength: 0)

      HStack {
        Text("Open service")
          .font(.caption.weight(.semibold))
          .foregroundStyle(Color(red: 0.20, green: 0.27, blue: 0.29))

        Spacer(minLength: 0)

        Capsule()
          .fill(color.opacity(0.18))
          .frame(width: 34, height: 6)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity)
    .frame(minHeight: 178, alignment: .topLeading)
    .background(
      colorScheme == .dark ? AppTheme.bgCard : Color.white.opacity(0.82),
      in: RoundedRectangle(cornerRadius: 24, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(colorScheme == .dark ? AppTheme.borderSubtle : Color.white.opacity(0.9), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.06), radius: 16, y: 10)
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
      Group {
        if let image = UIImage(named: article.imageName) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
        } else {
          LinearGradient(
            colors: [
              Color(red: 0.28, green: 0.45, blue: 0.51),
              Color(red: 0.68, green: 0.77, blue: 0.66)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(
        LinearGradient(
          colors: [Color.black.opacity(0.02), Color.black.opacity(0.10), Color.black.opacity(0.50)],
          startPoint: .top,
          endPoint: .bottom
        )
      )

      VStack(alignment: .leading, spacing: 10) {
        Text("CARE JOURNAL")
          .font(.caption2.weight(.semibold))
          .tracking(1.1)
          .foregroundStyle(Color.white.opacity(0.78))

        Text(article.title)
          .font(.system(size: 24, weight: .bold, design: .serif))
          .foregroundStyle(.white)

        HStack(spacing: 8) {
          Text("Short read")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.86))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.12), in: Capsule())

          Spacer(minLength: 0)

          Image(systemName: "arrow.right")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Color.white.opacity(0.12), in: Circle())
        }
      }
      .padding(22)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(Color.white.opacity(0.35), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.12), radius: 18, y: 10)
  }
}

private struct MedicalMetricPill: View {
  let value: String
  let label: String

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(value)
        .font(.title3.weight(.bold))
        .foregroundStyle(.white)

      Text(label)
        .font(.caption)
        .foregroundStyle(Color.white.opacity(0.78))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(Color.white.opacity(0.12), lineWidth: 1)
    )
  }
}

private struct MedicalSectionHeader: View {
  let eyebrow: String
  let title: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(eyebrow)
        .font(.caption2.weight(.semibold))
        .tracking(1)
        .foregroundStyle(Color(red: 0.33, green: 0.46, blue: 0.47))

      Text(title)
        .font(.title3.weight(.bold))
        .foregroundStyle(Color(red: 0.11, green: 0.15, blue: 0.18))

      Text(subtitle)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
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

  private var currentCoreCount: Int {
    currentVaccines.filter { $0.isCore }.count
  }

  private var currentMandatoryCount: Int {
    currentVaccines.filter { $0.isMandatory }.count
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        plannerHeaderCard

        if currentVaccines.isEmpty {
          emptyPlannerState
        } else {
          vaccineListSection
        }
      }
      .padding(20)
    }
    .background(
      LinearGradient(
        colors: [Color(red: 0.96, green: 0.98, blue: 0.97), Color(red: 1.00, green: 0.98, blue: 0.95)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    )
    .navigationTitle("Vaccination")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .hideTabBarWhenPushed()
  }

  private var plannerHeaderCard: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Vaccination Planner")
        .font(.system(size: 34, weight: .bold, design: .serif))
        .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.19))

      Text("Compare species-specific schedules, review key protection, and move into booking with less friction.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      petTypeSelector

      HStack(spacing: 12) {
        hubStatCard(value: "\(currentVaccines.count)", label: "available")
        hubStatCard(value: "\(currentCoreCount)", label: "core")
        hubStatCard(value: "\(currentMandatoryCount)", label: "mandatory")
      }
    }
    .padding(22)
    .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(Color.white.opacity(0.9), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.07), radius: 18, y: 10)
  }

  private var petTypeSelector: some View {
    HStack(spacing: 10) {
      ForEach(VaccinationPetType.allCases) { type in
        VaccinationTypePill(
          title: type.rawValue,
          isSelected: selectedType == type,
          action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
              selectedType = type
            }
          }
        )
      }
    }
  }

  private var emptyPlannerState: some View {
    VStack(spacing: 12) {
      Image(systemName: "tray.fill")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text("No vaccines available right now.")
        .font(.headline)

      Text("Once data is available, this planner will surface curated options here.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(.vertical, 36)
    .frame(maxWidth: .infinity)
    .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
  }

  private var vaccineListSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(selectedType == .dog ? "Dog vaccination schedule" : "Cat vaccination schedule")
        .font(.headline.weight(.semibold))
        .foregroundStyle(Color(red: 0.14, green: 0.18, blue: 0.21))

      Text("Built for quick comparison with cleaner pricing, schedule notes, and direct booking actions.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      LazyVStack(spacing: 16) {
        ForEach(currentVaccines) { vaccine in
          VaccineCard(vaccine: vaccine)
        }
      }
    }
  }

  private func hubStatCard(value: String, label: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(value)
        .font(.headline.weight(.bold))
        .foregroundStyle(Color(red: 0.14, green: 0.20, blue: 0.22))

      Text(label.uppercased())
        .font(.caption2.weight(.semibold))
        .tracking(0.8)
        .foregroundStyle(Color(red: 0.39, green: 0.48, blue: 0.50))
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(red: 0.95, green: 0.97, blue: 0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
  }
}

private struct VaccinationTypePill: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(isSelected ? .white : Color(red: 0.25, green: 0.33, blue: 0.35))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(backgroundFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private var backgroundFill: some ShapeStyle {
    if isSelected {
      return AnyShapeStyle(
        LinearGradient(
          colors: [Color(red: 0.17, green: 0.35, blue: 0.41), Color(red: 0.43, green: 0.57, blue: 0.52)],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
    }

    return AnyShapeStyle(Color.white.opacity(0.86))
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

  var blurb: String {
    switch self {
    case .vaccination: return "Primary and booster protection with schedule clarity."
    case .emergency24h: return "Immediate access pathways for urgent support."
    case .healthCheck: return "Routine preventive reviews and baseline health checks."
    case .deworming: return "Parasite prevention and treatment guidance."
    case .dentalCare: return "Oral health reviews, scaling, and follow-up support."
    case .labTests: return "Diagnostics for bloodwork, panels, and deeper screening."
    case .microchip: return "Permanent pet identification and registration support."
    case .nutrition: return "Diet planning for growth, weight, and chronic conditions."
    case .surgeryCare: return "Pre-op preparation and post-op care planning."
    }
  }

  var searchKeywords: [String] {
    switch self {
    case .vaccination: return ["vaccine", "booster", "shot", "rabies"]
    case .emergency24h: return ["emergency", "urgent", "24h", "hospital"]
    case .healthCheck: return ["checkup", "wellness", "exam", "routine"]
    case .deworming: return ["parasite", "worm", "heartworm", "flea"]
    case .dentalCare: return ["teeth", "oral", "gum", "cleaning"]
    case .labTests: return ["blood", "diagnostic", "panel", "test"]
    case .microchip: return ["chip", "id", "tracking", "registration"]
    case .nutrition: return ["diet", "food", "weight", "feeding"]
    case .surgeryCare: return ["surgery", "operation", "recovery", "post-op"]
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
    .background(AppTheme.bgBase)
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct VaccineCard: View {
  let vaccine: Vaccine
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(
            LinearGradient(
              colors: [Color(red: 0.98, green: 0.98, blue: 0.96), Color.white],
              startPoint: .top,
              endPoint: .bottom
            )
          )

        Group {
          if let uiImage = UIImage(named: vaccine.imageName) {
            Image(uiImage: uiImage)
              .resizable()
              .scaledToFill()
          } else {
            LinearGradient(
              colors: [Color(red: 0.79, green: 0.88, blue: 0.88), Color(red: 0.93, green: 0.96, blue: 0.94)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
            .overlay(
              Image(systemName: "pawprint.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color.white.opacity(0.55))
            )
          }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 212)
        .clipped()

        VStack(alignment: .leading, spacing: 8) {
          VStack(alignment: .leading, spacing: 8) {
            if vaccine.isCore {
              vaccineBadge(title: "Core", tint: Color(red: 0.99, green: 0.93, blue: 0.78), foreground: Color(red: 0.61, green: 0.39, blue: 0.10))
            }

            if vaccine.isMandatory {
              vaccineBadge(title: "Mandatory", tint: Color(red: 1.00, green: 0.90, blue: 0.90), foreground: Color(red: 0.73, green: 0.22, blue: 0.22))
            }
          }

          Spacer(minLength: 0)

          Text(vaccine.petType.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.44))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.9), in: Capsule())
        }
        .padding(16)
      }
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

      VStack(alignment: .leading, spacing: 12) {
        Text(vaccine.name)
          .font(.title3.weight(.bold))
          .foregroundStyle(Color(red: 0.10, green: 0.15, blue: 0.18))
          .lineLimit(2)

        Text(vaccine.description)
          .font(.subheadline)
          .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.44))
          .lineLimit(3)

        HStack(spacing: 10) {
          summaryChip(icon: "calendar", text: vaccine.youngInfo)
          summaryChip(icon: "arrow.clockwise", text: vaccine.adultInfo)
        }

        HStack(alignment: .bottom) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Estimated")
              .font(.caption)
              .foregroundStyle(.secondary)

            Text("$\(vaccine.price)")
              .font(.title3.weight(.bold))
              .foregroundStyle(Color(red: 0.17, green: 0.35, blue: 0.41))
          }

          Spacer(minLength: 0)

          NavigationLink(destination: VaccineDetailView(vaccine: vaccine)) {
            HStack(spacing: 8) {
              Text("Review & Book")
              Image(systemName: "arrow.right")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
              LinearGradient(
                colors: [Color(red: 0.16, green: 0.34, blue: 0.40), Color(red: 0.44, green: 0.58, blue: 0.52)],
                startPoint: .leading,
                endPoint: .trailing
              ),
              in: Capsule()
            )
          }
        }
      }
      .padding(18)
    }
    .background(
      colorScheme == .dark ? AppTheme.bgCard : Color.white.opacity(0.85),
      in: RoundedRectangle(cornerRadius: 28, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(colorScheme == .dark ? AppTheme.borderSubtle : Color.white.opacity(0.92), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.08), radius: 18, y: 10)
  }

  private func vaccineBadge(title: String, tint: Color, foreground: Color) -> some View {
    Text(title)
      .font(.caption2.weight(.bold))
      .foregroundStyle(foreground)
      .padding(.horizontal, 9)
      .padding(.vertical, 6)
      .background(tint, in: Capsule())
  }

  private func summaryChip(icon: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 6) {
      Image(systemName: icon)
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color(red: 0.24, green: 0.38, blue: 0.41))
        .padding(.top, 2)

      Text(text)
        .font(.caption)
        .foregroundStyle(Color(red: 0.33, green: 0.39, blue: 0.42))
        .lineLimit(2)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 9)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(red: 0.95, green: 0.97, blue: 0.96), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
          .background(AppTheme.bgCard)
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
    .hideTabBarWhenPushed()
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
