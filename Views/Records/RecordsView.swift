//
//  RecordsView.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

// MARK: - Records (Pet Profile + Vaccination) — SwiftData Persisted

struct RecordsView: View {

  @EnvironmentObject var languageManager: LanguageManager
  @EnvironmentObject var guideManager: GuideManager
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \PetModel.name) private var pets: [PetModel]

  @State private var showAddPet = false
  @State private var showPetIDFor: PetModel? = nil
  @State private var petPendingDelete: PetModel? = nil
  @State private var showDeleteConfirm: Bool = false
  @State private var showOwnerEditor = false
  @State private var ownerProfile: OwnerProfile = OwnerProfileStore.shared.load()

  private let gridCols: [GridItem] = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12),
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {

          // MARK: Header
          HStack(alignment: .center, spacing: 12) {
            Button {
              showOwnerEditor = true
            } label: {
              if let data = ownerProfile.avatarImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 52, height: 52)
                  .clipShape(Circle())
              } else {
                Image(systemName: "person.crop.circle")
                  .font(.system(size: 44))
                  .foregroundStyle(.secondary)
              }
            }

            VStack(alignment: .leading, spacing: 2) {
              Text(languageManager.isChinese ? "個人檔案" : "Profile")
                .font(.title2).bold()
              Text(ownerProfile.name.isEmpty ? (languageManager.isChinese ? "點擊頭像補齊主人資料" : "Tap avatar to complete owner profile") : ownerProfile.name)
              .font(.subheadline)
              .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
              Picker("Language", selection: $languageManager.currentLanguage) {
                ForEach(AppLanguage.allCases) { language in
                  Text(language.displayName).tag(language)
                }
              }
            } label: {
              Image(systemName: "globe")
                .font(.system(size: 20))
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
            }

            Button {
              showAddPet = true
              guideManager.mark(.profileTappedAddPet)
            } label: {
              Image(systemName: "plus")
                .font(.headline)
                .padding(10)
                .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel("Add Pet")
          }
          .padding(.horizontal)
          .padding(.top, 8)

          // MARK: Pet Profile list
          VStack(alignment: .leading, spacing: 10) {
            Text("Pet Profile")
              .font(.headline)
              .padding(.horizontal)

            if pets.isEmpty {
              ContentUnavailableView(
                "No Pets",
                systemImage: "pawprint",
                description: Text("Add your first pet to start tracking health records.")
              )
              .padding(.horizontal)
            } else {
              LazyVStack(spacing: 12) {
                ForEach(pets) { pet in
                  PetProfileCard(
                    pet: pet,
                    onShowPetID: { showPetIDFor = pet }
                  )
                  .padding(.horizontal)
                  .contextMenu {
                    Button(role: .destructive) {
                      petPendingDelete = pet
                      showDeleteConfirm = true
                    } label: {
                      Label("Delete", systemImage: "trash")
                    }
                  }
                }
              }
            }
          }

          // MARK: Pet Management
          VStack(alignment: .leading, spacing: 10) {
            Text("Pet Management")
              .font(.headline)
              .padding(.horizontal)

            LazyVGrid(columns: gridCols, spacing: 12) {
              ModuleTile(title: "Booking Record", systemImage: "calendar.badge.clock") {
                BookingRecordView()
              }

              ModuleTile(title: "Recent Purchase", systemImage: "cart") {
                RecentPurchaseView()
              }

              ModuleTile(title: "Insurance", systemImage: "shield") {
                InsuranceLandingView()
              }

              ModuleTile(title: "Activity Tracking", systemImage: "figure.walk") {
                ActivityTrackingView()
              }

              ModuleTile(title: "Travel Document", systemImage: "doc.text") {
                TravelDocumentView()
              }

              ModuleTile(title: "Pet Care Tips", systemImage: "lightbulb") {
                PetCareTipsView()
              }
            }
            .padding(.horizontal)
          }

          Spacer(minLength: 24)
        }
        .padding(.bottom, 18)
      }
      .navigationBarTitleDisplayMode(.inline)
      .sheet(isPresented: $showAddPet) {
        AddPetView()
      }
      .sheet(isPresented: $showOwnerEditor) {
        OwnerProfileEditorSheet(isMandatory: false) { updated in
          ownerProfile = updated
        }
      }
      .sheet(item: $showPetIDFor) { pet in
        PetIDSheet(pet: pet)
      }
      .confirmationDialog(
        "Delete this pet profile?",
        isPresented: $showDeleteConfirm,
        titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          guard let pet = petPendingDelete else { return }
          modelContext.delete(pet)
          try? modelContext.save()
          petPendingDelete = nil
        }
        Button("Cancel", role: .cancel) {
          petPendingDelete = nil
        }
      } message: {
        if let pet = petPendingDelete {
          Text("This will permanently remove \(pet.name) and all related records.")
        }
      }
      .onAppear {
        ownerProfile = OwnerProfileStore.shared.load()
      }
    }
  }
}

// MARK: - Profile UI Components

private struct PetProfileCard: View {

  let pet: PetModel
  let onShowPetID: () -> Void

  private var ageText: String {
    let year = Calendar.current.component(.year, from: Date())
    let age = max(0, year - pet.birthYear)
    return "\(age) Year\(age == 1 ? "" : "s") Old"
  }

  private var sexSymbol: String {
    switch pet.sex.lowercased() {
    case "male": return "♂"
    case "female": return "♀"
    default: return ""
    }
  }

  private var latestVaccination: VaccinationModel? {
    pet.vaccinations.sorted(by: { $0.date > $1.date }).first
  }

  private var nextVaccinationDate: Date? {
    guard let latest = latestVaccination?.date else { return nil }
    return Calendar.current.date(byAdding: .year, value: 1, to: latest)
  }

  private var vaccinationStatusText: String {
    guard let next = nextVaccinationDate else { return "No vaccine record" }
    let today = Calendar.current.startOfDay(for: Date())
    let due = Calendar.current.startOfDay(for: next)
    if due < today { return "Vaccination Overdue" }
    // Within 30 days considered due soon
    let days = Calendar.current.dateComponents([.day], from: today, to: due).day ?? 0
    if days <= 30 { return "Vaccination Due Soon" }
    return "Fully Vaccinated"
  }

  private var vaccinationProgress: Double {
    // A simple 1-year cycle progress from last vaccination to next vaccination.
    guard let last = latestVaccination?.date, let next = nextVaccinationDate else { return 0 }
    let start = last.timeIntervalSince1970
    let end = next.timeIntervalSince1970
    let now = Date().timeIntervalSince1970
    if end <= start { return 0 }
    let p = (now - start) / (end - start)
    return min(max(p, 0), 1)
  }

  private var nextVaccinationLabel: String {
    guard let next = nextVaccinationDate else { return "—" }
    return next.formatted(date: .numeric, time: .omitted)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 12) {
        ZStack {
          Circle().fill(.thinMaterial)

          if let data = pet.avatarImageData,
            let uiImg = UIImage(data: data)
          {
            Image(uiImage: uiImg)
              .resizable()
              .scaledToFill()
          } else {
            Image(systemName: pet.species.lowercased().contains("cat") ? "cat" : "dog")
              .font(.system(size: 28))
              .foregroundStyle(.secondary)
          }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(pet.name)
              .font(.headline)
            if !sexSymbol.isEmpty {
              Text(sexSymbol)
                .font(.headline)
                .foregroundStyle(.secondary)
            }
          }

          let weightStr = pet.weightKg > 0 ? String(format: "%.1fkg", pet.weightKg) : "—"
          Text("\(weightStr) | \(ageText)")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          HStack(spacing: 6) {
            Text(vaccinationStatusText)
              .font(.subheadline)
              .foregroundStyle(vaccinationStatusText == "Fully Vaccinated" ? .green : .orange)
            Image(
              systemName: vaccinationStatusText == "Fully Vaccinated"
                ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .font(.subheadline)
            .foregroundStyle(vaccinationStatusText == "Fully Vaccinated" ? .green : .orange)
          }
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 10) {
          Button {
            onShowPetID()
          } label: {
            Image(systemName: "qrcode")
              .font(.headline)
              .padding(8)
              .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
          }
          .accessibilityLabel("Pet ID")

          NavigationLink {
            PetDetailView(pet: pet)
          } label: {
            Image(systemName: "heart.text.square")
              .font(.headline)
              .padding(8)
              .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
          }
          .accessibilityLabel("Health Profile")
        }
      }

      HStack {
        Text("Next Vaccination:")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Text(nextVaccinationLabel)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ProgressView(value: vaccinationProgress)
        .tint(.green)
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(Color(.separator).opacity(0.15), lineWidth: 1)
    )
  }
}

private struct ModuleTile<Destination: View>: View {

  let title: String
  let systemImage: String
  @ViewBuilder let destination: Destination

  init(title: String, systemImage: String, @ViewBuilder destination: () -> Destination) {
    self.title = title
    self.systemImage = systemImage
    self.destination = destination()
  }

  var body: some View {
    NavigationLink {
      destination
    } label: {
      HStack(spacing: 10) {
        Image(systemName: systemImage)
          .font(.title3)
          .frame(width: 34)

        Text(title)
          .font(.subheadline)
          .foregroundStyle(.primary)

        Spacer()
      }
      .padding(14)
      .frame(height: 80)  // Fixed height to ensure uniform size
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(Color(.secondarySystemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }
}

private struct PlaceholderView: View {
  let title: String

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "wrench.and.screwdriver")
        .font(.system(size: 44))
        .foregroundStyle(.secondary)
      Text(title)
        .font(.title3).bold()
      Text("Coming soon")
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .background(Color(.systemBackground))
  }
}

// MARK: - Pet ID (QR)

private struct PetIDSheet: View {

  @Environment(\.dismiss) private var dismiss
  let pet: PetModel

  private var payload: String {
    // Keep it stable and human readable.
    var parts: [String] = []
    parts.append("PetWell")
    parts.append("name=\(pet.name)")
    parts.append("species=\(pet.species)")
    parts.append("birthYear=\(pet.birthYear)")
    if !pet.microchipId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      parts.append("microchip=\(pet.microchipId)")
    }
    return parts.joined(separator: "|")
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 14) {
        Text("Pet ID")
          .font(.title2).bold()

        QRCodeView(text: payload)
          .frame(width: 220, height: 220)
          .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .stroke(Color(.separator).opacity(0.15), lineWidth: 1)
          )

        VStack(spacing: 6) {
          Text(pet.name)
            .font(.headline)
          Text("\(pet.species) · \(pet.breed.isEmpty ? "—" : pet.breed) · \(pet.birthYear)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          if !pet.microchipId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("Microchip: \(pet.microchipId)")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }

        Text("Scan this QR to quickly share your pet profile.")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)

        Spacer()
      }
      .padding()
      .navigationTitle("Pet ID")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

private struct QRCodeView: View {

  let text: String

  var body: some View {
    if let img = QRCodeGenerator.makeQRCode(from: text) {
      Image(uiImage: img)
        .interpolation(.none)
        .resizable()
        .scaledToFit()
        .padding(12)
    } else {
      ContentUnavailableView("QR unavailable", systemImage: "qrcode")
    }
  }
}

private enum QRCodeGenerator {

  static func makeQRCode(from string: String) -> UIImage? {
    let data = Data(string.utf8)
    guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")
    guard let outputImage = filter.outputImage else { return nil }

    // Scale up to avoid blurriness
    let transform = CGAffineTransform(scaleX: 10, y: 10)
    let scaled = outputImage.transformed(by: transform)
    let context = CIContext()
    guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
    return UIImage(cgImage: cgImage)
  }
}

// MARK: - Pet Detail
// NOTE: `PetDetailView` is defined in `PetDetailView.swift`.

// MARK: - Add/Edit Pet + Add Records
// NOTE: `AddPetView` is defined in `AddPetView.swift`.

struct EditPetView: View {

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @Bindable var pet: PetModel

  @State private var birthYearText: String
  @State private var weightText: String

  @State private var showSaveError = false
  @State private var saveErrorMessage = ""

  init(pet: PetModel) {
    self._pet = Bindable(wrappedValue: pet)
    self._birthYearText = State(initialValue: String(pet.birthYear))
    self._weightText = State(initialValue: String(format: "%.1f", pet.weightKg))
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Basic") {
          TextField("Pet Name", text: $pet.name)
          TextField("Species (Dog, Cat...)", text: $pet.species)
          TextField("Breed (optional)", text: $pet.breed)

          Picker("Sex", selection: $pet.sex) {
            Text("Unknown").tag("Unknown")
            Text("Male").tag("Male")
            Text("Female").tag("Female")
          }
        }

        Section("Birth") {
          TextField("Birth Year", text: $birthYearText)
            .keyboardType(.numberPad)
        }

        Section("Health / Identity") {
          TextField("Weight (kg)", text: $weightText)
            .keyboardType(.decimalPad)

          Toggle("Neutered", isOn: $pet.isNeutered)

          TextField("Microchip ID (optional)", text: $pet.microchipId)
          TextField("Allergies (optional)", text: $pet.allergies)
          TextField("Notes (optional)", text: $pet.notes, axis: .vertical)
            .lineLimit(3, reservesSpace: true)
        }
      }
      .navigationTitle("Edit Pet")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let trimmedName = pet.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedSpecies = pet.species.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedBirthYear = birthYearText.trimmingCharacters(in: .whitespacesAndNewlines)

            guard
              !trimmedName.isEmpty,
              !trimmedSpecies.isEmpty,
              let year = Int(trimmedBirthYear)
            else {
              saveErrorMessage = "Please enter a valid name, species, and birth year."
              showSaveError = true
              return
            }

            let w =
              Double(
                weightText.trimmingCharacters(in: .whitespacesAndNewlines)
                  .replacingOccurrences(of: ",", with: ".")) ?? 0

            // Commit validated fields
            pet.name = trimmedName
            pet.species = trimmedSpecies
            pet.birthYear = year
            pet.weightKg = w

            do {
              try modelContext.save()
              dismiss()
            } catch {
              saveErrorMessage = "Failed to save changes: \(error.localizedDescription)"
              showSaveError = true
            }
          }
        }

        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .alert("Save Error", isPresented: $showSaveError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(saveErrorMessage)
      }
    }
  }
}

struct AddVaccinationView: View {

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let pet: PetModel

  @State private var name = ""
  @State private var date = Date()

  @State private var showSaveError = false
  @State private var saveErrorMessage = ""

  var body: some View {
    NavigationStack {
      Form {
        Section("Vaccine") {
          TextField("Vaccine name", text: $name)
          DatePicker("Date", selection: $date, displayedComponents: .date)
        }
      }
      .navigationTitle("Add Vaccination")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
              saveErrorMessage = "Please enter a vaccine name."
              showSaveError = true
              return
            }

            let v = VaccinationModel(name: trimmed, date: date)
            pet.vaccinations.append(v)

            do {
              try modelContext.save()
              dismiss()
            } catch {
              saveErrorMessage = "Failed to save vaccination: \(error.localizedDescription)"
              showSaveError = true
            }
          }
        }

        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .alert("Save Error", isPresented: $showSaveError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(saveErrorMessage)
      }
    }
  }
}

struct AddMedicalVisitView: View {

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let pet: PetModel

  @State private var date = Date()
  @State private var clinic = ""
  @State private var vet = ""
  @State private var reason = ""
  @State private var diagnosis = ""
  @State private var treatment = ""
  @State private var costText = ""
  @State private var notes = ""

  @State private var showSaveError = false
  @State private var saveErrorMessage = ""

  var body: some View {
    NavigationStack {
      Form {
        Section("Visit") {
          DatePicker("Date", selection: $date, displayedComponents: .date)
          TextField("Clinic (optional)", text: $clinic)
          TextField("Vet (optional)", text: $vet)
          TextField("Reason", text: $reason)
        }

        Section("Outcome") {
          TextField("Diagnosis (optional)", text: $diagnosis)
          TextField("Treatment (optional)", text: $treatment)
          TextField("Cost (optional)", text: $costText)
            .keyboardType(.decimalPad)
          TextField("Notes (optional)", text: $notes, axis: .vertical)
            .lineLimit(3, reservesSpace: true)
        }
      }
      .navigationTitle("Add Visit")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedReason.isEmpty else {
              saveErrorMessage = "Please enter a reason for the visit."
              showSaveError = true
              return
            }

            let cost =
              Double(
                costText.trimmingCharacters(in: .whitespacesAndNewlines)
                  .replacingOccurrences(of: ",", with: ".")) ?? 0

            let visit = MedicalVisitModel(
              date: date,
              clinic: clinic.trimmingCharacters(in: .whitespacesAndNewlines),
              vet: vet.trimmingCharacters(in: .whitespacesAndNewlines),
              reason: trimmedReason,
              diagnosis: diagnosis.trimmingCharacters(in: .whitespacesAndNewlines),
              treatment: treatment.trimmingCharacters(in: .whitespacesAndNewlines),
              cost: cost,
              notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            pet.medicalVisits.append(visit)

            do {
              try modelContext.save()
              dismiss()
            } catch {
              saveErrorMessage = "Failed to save visit: \(error.localizedDescription)"
              showSaveError = true
            }
          }
        }

        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .alert("Save Error", isPresented: $showSaveError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(saveErrorMessage)
      }
    }
  }
}

struct AddMedicationView: View {

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let pet: PetModel

  @State private var name = ""
  @State private var dosage = ""
  @State private var frequency = ""
  @State private var startDate = Date()
  @State private var hasEndDate = false
  @State private var endDate = Date()
  @State private var notes = ""

  @State private var showSaveError = false
  @State private var saveErrorMessage = ""

  var body: some View {
    NavigationStack {
      Form {
        Section("Medication") {
          TextField("Name", text: $name)
          TextField("Dosage (e.g., 1 tablet)", text: $dosage)
          TextField("Frequency (e.g., 2x/day)", text: $frequency)
        }

        Section("Dates") {
          DatePicker("Start", selection: $startDate, displayedComponents: .date)
          Toggle("Has end date", isOn: $hasEndDate)
          if hasEndDate {
            DatePicker("End", selection: $endDate, displayedComponents: .date)
          }
        }

        Section("Notes") {
          TextField("Notes (optional)", text: $notes, axis: .vertical)
            .lineLimit(3, reservesSpace: true)
        }
      }
      .navigationTitle("Add Medication")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
              saveErrorMessage = "Please enter a medication name."
              showSaveError = true
              return
            }

            let med = MedicationModel(
              name: trimmedName,
              dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
              frequency: frequency.trimmingCharacters(in: .whitespacesAndNewlines),
              startDate: startDate,
              endDate: hasEndDate ? endDate : nil,
              notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            pet.medications.append(med)

            do {
              try modelContext.save()
              dismiss()
            } catch {
              saveErrorMessage = "Failed to save medication: \(error.localizedDescription)"
              showSaveError = true
            }
          }
        }

        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .alert("Save Error", isPresented: $showSaveError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(saveErrorMessage)
      }
    }
  }
}

struct AddWeightEntryView: View {

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let pet: PetModel

  @State private var date = Date()
  @State private var weightText = ""
  @State private var notes = ""

  @State private var showSaveError = false
  @State private var saveErrorMessage = ""

  var body: some View {
    NavigationStack {
      Form {
        Section("Weight") {
          DatePicker("Date", selection: $date, displayedComponents: .date)
          TextField("Weight (kg)", text: $weightText)
            .keyboardType(.decimalPad)
          TextField("Notes (optional)", text: $notes, axis: .vertical)
            .lineLimit(3, reservesSpace: true)
        }
      }
      .navigationTitle("Add Weight")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let w = Double(
              weightText.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: "."))

            guard let weight = w, weight > 0 else {
              saveErrorMessage = "Please enter a valid weight (kg)."
              showSaveError = true
              return
            }

            let entry = WeightEntryModel(
              date: date,
              weightKg: weight,
              notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            pet.weightEntries.append(entry)

            // Optionally update current weight
            pet.weightKg = weight

            do {
              try modelContext.save()
              dismiss()
            } catch {
              saveErrorMessage = "Failed to save weight entry: \(error.localizedDescription)"
              showSaveError = true
            }
          }
        }

        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .alert("Save Error", isPresented: $showSaveError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(saveErrorMessage)
      }
    }
  }
}

// NOTE: OwnerProfileEditorSheet is defined in ViewModifiers.swift

// MARK: - PetModel Guardian Context Extension

extension PetModel {
  var guardianContextText: String {
    var lines: [String] = []
    lines.append("Pet Profile")
    lines.append("- Name: \(name)")
    lines.append("- Species: \(species)")
    if !breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      lines.append("- Breed: \(breed)")
    }
    lines.append("- Sex: \(sex)")
    lines.append("- Birth Year: \(birthYear)")
    if weightKg > 0 { lines.append(String(format: "- Weight: %.1f kg", weightKg)) }
    lines.append("- Neutered: \(isNeutered ? "Yes" : "No")")
    if !microchipId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      lines.append("- Microchip ID: \(microchipId)")
    }
    if !allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      lines.append("- Allergies: \(allergies)")
    }
    if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      lines.append("- Notes: \(notes)")
    }

    // Recent vaccination
    if let latestVax = vaccinations.sorted(by: { $0.date > $1.date }).first {
      lines.append("")
      lines.append("Latest Vaccination")
      lines.append(
        "- \(latestVax.name) on \(latestVax.date.formatted(date: .abbreviated, time: .omitted))")
    }

    // Recent visit
    if let latestVisit = medicalVisits.sorted(by: { $0.date > $1.date }).first {
      lines.append("")
      lines.append("Latest Medical Visit")
      lines.append("- Date: \(latestVisit.date.formatted(date: .abbreviated, time: .omitted))")
      if !latestVisit.reason.isEmpty { lines.append("- Reason: \(latestVisit.reason)") }
      if !latestVisit.diagnosis.isEmpty { lines.append("- Dx: \(latestVisit.diagnosis)") }
      if !latestVisit.treatment.isEmpty { lines.append("- Treatment: \(latestVisit.treatment)") }
      if !latestVisit.notes.isEmpty { lines.append("- Notes: \(latestVisit.notes)") }
    }

    // Current meds
    let currentMeds = medications.sorted(by: { $0.startDate > $1.startDate }).prefix(5)
    if !currentMeds.isEmpty {
      lines.append("")
      lines.append("Medications (recent)")
      for m in currentMeds {
        let endText = m.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "—"
        lines.append(
          "- \(m.name) (\(m.dosage), \(m.frequency)) from \(m.startDate.formatted(date: .abbreviated, time: .omitted)) to \(endText)"
        )
      }
    }

    // Weight trend
    if let latestWeight = weightEntries.sorted(by: { $0.date > $1.date }).first {
      lines.append("")
      lines.append("Latest Weight")
      lines.append(
        String(
          format: "- %.1f kg on %@", latestWeight.weightKg,
          latestWeight.date.formatted(date: .abbreviated, time: .omitted)))
      if !latestWeight.notes.isEmpty { lines.append("- Notes: \(latestWeight.notes)") }
    }

    lines.append("")
    lines.append("User Question:")
    lines.append(
      "- (Describe symptoms, duration, appetite, energy, vomiting/diarrhea, urination, breathing, and any triggers.)"
    )

    return lines.joined(separator: "\n")
  }
}
