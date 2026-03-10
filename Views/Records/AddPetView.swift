//
//  AddPetView.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/30.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddPetView: View {

    // ✅ 传入则为编辑模式；不传为新增模式
    let petToEdit: PetModel?
    private var isEditMode: Bool { petToEdit != nil }

    init(petToEdit: PetModel? = nil) {
        self.petToEdit = petToEdit
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var didLoadExisting = false

    // MARK: - Avatar
    @State private var selectedAvatarItem: PhotosPickerItem? = nil
    @State private var avatarImageData: Data? = nil

    // MARK: - Basic Info
    @State private var name: String = ""
    @State private var species: String = "Dog"
    @State private var breed: String = ""
    @State private var sex: String = "Unknown"
    @State private var birthYear: Int = Calendar.current.component(.year, from: Date())

    // MARK: - Health / Identity
    @State private var weightKgText: String = ""
    @State private var isNeutered: Bool = false
    @State private var microchipId: String = ""
    @State private var allergies: String = ""
    @State private var notes: String = ""

    // MARK: - Vaccination
    @State private var isVaccinated: Bool = false
    @State private var vaccineName: String = ""
    @State private var vaccineDate: Date = Date()

    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    private let speciesOptions = ["Dog", "Cat", "Other"]
    private let sexOptions = ["Male", "Female", "Unknown"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Avatar") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(.thinMaterial)
                            if let data = avatarImageData, let uiImg = UIImage(data: data) {
                                Image(uiImage: uiImg)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())

                        PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                            Label("Upload", systemImage: "arrow.up.circle")
                        }

                        if avatarImageData != nil {
                            Spacer()
                            Button(role: .destructive) {
                                avatarImageData = nil
                                selectedAvatarItem = nil
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
                .onChange(of: selectedAvatarItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            await MainActor.run { self.avatarImageData = data }
                        }
                    }
                }

                Section("Basic Info") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Species", selection: $species) {
                        ForEach(speciesOptions, id: \.self) { Text($0) }
                    }

                    TextField("Breed", text: $breed)
                        .textInputAutocapitalization(.words)

                    Picker("Sex", selection: $sex) {
                        ForEach(sexOptions, id: \.self) { Text($0) }
                    }

                    Stepper(value: $birthYear, in: 1980...Calendar.current.component(.year, from: Date())) {
                        Text("Birth Year: \(birthYear)")
                    }
                }

                Section("Health & Identity") {
                    TextField("Weight (kg)", text: $weightKgText)
                        .keyboardType(.decimalPad)

                    Toggle("Neutered", isOn: $isNeutered)

                    TextField("Microchip ID (optional)", text: $microchipId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    TextField("Allergies (optional)", text: $allergies, axis: .vertical)
                        .lineLimit(2...4)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Vaccination") {
                    Toggle("Vaccinated", isOn: $isVaccinated)

                    if isVaccinated {
                        TextField("Vaccine type", text: $vaccineName)
                            .textInputAutocapitalization(.words)

                        DatePicker("Vaccine date", selection: $vaccineDate, displayedComponents: .date)
                    }
                }

                if !isEditMode {
                    Section {
                        Button {
                            save()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Save").bold()
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Pet" : "Add Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEditMode {
                    // Add mode: keep Cancel
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                } else {
                    // Edit mode: no Cancel, Update in top-right
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Update") {
                            save()
                        }
                    }
                }
            }
            .alert("Can’t Save", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .hideTabBarWhenPushed()
            .onAppear {
                guard !didLoadExisting else { return }
                if let pet = petToEdit {
                    avatarImageData = pet.avatarImageData
                    name = pet.name
                    species = speciesOptions.contains(pet.species) ? pet.species : "Other"
                    breed = pet.breed
                    sex = sexOptions.contains(pet.sex) ? pet.sex : "Unknown"
                    birthYear = pet.birthYear
                    weightKgText = pet.weightKg > 0 ? String(pet.weightKg) : ""
                    isNeutered = pet.isNeutered
                    microchipId = pet.microchipId
                    allergies = pet.allergies
                    notes = pet.notes

                    if let latestVaccine = pet.vaccinations.sorted(by: { $0.date > $1.date }).first {
                        isVaccinated = true
                        vaccineName = latestVaccine.name
                        vaccineDate = latestVaccine.date
                    }
                }
                didLoadExisting = true
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            validationMessage = "Please enter a pet name."
            showValidationAlert = true
            return
        }

        let weightKg = parseWeightKg(weightKgText)
        let trimmedVaccineName = vaccineName.trimmingCharacters(in: .whitespacesAndNewlines)

        if isVaccinated && trimmedVaccineName.isEmpty {
            validationMessage = "Please enter the vaccine type."
            showValidationAlert = true
            return
        }

        do {
            if let pet = petToEdit {
                // ✅ 编辑：更新原对象
                pet.name = trimmedName
                pet.species = species
                pet.breed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
                pet.sex = sex
                pet.birthYear = birthYear
                pet.avatarImageData = avatarImageData
                pet.weightKg = weightKg
                pet.isNeutered = isNeutered
                pet.microchipId = microchipId.trimmingCharacters(in: .whitespacesAndNewlines)
                pet.allergies = allergies.trimmingCharacters(in: .whitespacesAndNewlines)
                pet.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                applyVaccinationChanges(to: pet, vaccineName: trimmedVaccineName)

                try modelContext.save()
            } else {
                // ✅ 新增：insert 新对象
                let pet = PetModel(
                    name: trimmedName,
                    species: species,
                    breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
                    sex: sex,
                    birthYear: birthYear,
                    avatarImageData: avatarImageData,
                    weightKg: weightKg,
                    isNeutered: isNeutered,
                    microchipId: microchipId.trimmingCharacters(in: .whitespacesAndNewlines),
                    allergies: allergies.trimmingCharacters(in: .whitespacesAndNewlines),
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                applyVaccinationChanges(to: pet, vaccineName: trimmedVaccineName)
                modelContext.insert(pet)
                try modelContext.save()
            }
            dismiss()
        } catch {
            validationMessage = "Save failed: \(error.localizedDescription)"
            showValidationAlert = true
        }
    }

    private func parseWeightKg(_ text: String) -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private func applyVaccinationChanges(to pet: PetModel, vaccineName: String) {
        guard isVaccinated else {
            // User explicitly marked as not vaccinated in this form.
            if !pet.vaccinations.isEmpty {
                for vaccine in pet.vaccinations {
                    modelContext.delete(vaccine)
                }
                pet.vaccinations.removeAll()
            }
            return
        }

        if let latest = pet.vaccinations.max(by: { $0.date < $1.date }) {
            latest.name = vaccineName
            latest.date = vaccineDate
        } else {
            pet.vaccinations.append(VaccinationModel(name: vaccineName, date: vaccineDate))
        }
    }
}
