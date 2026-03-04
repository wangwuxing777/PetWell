//
//  PetModels.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import Foundation
import SwiftData

struct OwnerProfile: Codable {
  var id: String
  var name: String
  var email: String
  var phone: String
  var avatarImageData: Data?

  static let empty = OwnerProfile(id: UUID().uuidString, name: "", email: "", phone: "", avatarImageData: nil)
}

final class OwnerProfileStore {
  static let shared = OwnerProfileStore()

  private let key = "petwell_owner_profile_v1"
  private let defaults = UserDefaults.standard

  func load() -> OwnerProfile {
    guard let data = defaults.data(forKey: key),
      let profile = try? JSONDecoder().decode(OwnerProfile.self, from: data)
    else {
      return .empty
    }
    return profile
  }

  func save(_ profile: OwnerProfile) {
    if let data = try? JSONEncoder().encode(profile) {
      defaults.set(data, forKey: key)
    }
  }

  func hasRequiredContact() -> Bool {
    let profile = load()
    return !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !profile.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !profile.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}

@Model
final class PetModel {
  // Basic
  var name: String
  var species: String  // Dog / Cat / etc.
  var breed: String  // e.g., Golden Retriever
  var sex: String  // Male / Female / Unknown
  var birthYear: Int

  // Avatar
  var avatarImageData: Data?  // stored as jpeg/png data

  // Health / identity
  var weightKg: Double  // current weight
  var isNeutered: Bool
  var microchipId: String
  var allergies: String  // free text
  var notes: String  // free text

  @Relationship(deleteRule: .cascade)
  var vaccinations: [VaccinationModel] = []

  @Relationship(deleteRule: .cascade)
  var medicalVisits: [MedicalVisitModel] = []

  @Relationship(deleteRule: .cascade)
  var medications: [MedicationModel] = []

  @Relationship(deleteRule: .cascade)
  var weightEntries: [WeightEntryModel] = []

  init(
    name: String,
    species: String,
    breed: String,
    sex: String,
    birthYear: Int,
    avatarImageData: Data? = nil,
    weightKg: Double,
    isNeutered: Bool,
    microchipId: String,
    allergies: String,
    notes: String,
    medicalVisits: [MedicalVisitModel] = [],
    medications: [MedicationModel] = [],
    weightEntries: [WeightEntryModel] = []
  ) {
    self.name = name
    self.species = species
    self.breed = breed
    self.sex = sex
    self.birthYear = birthYear
    self.avatarImageData = avatarImageData
    self.weightKg = weightKg
    self.isNeutered = isNeutered
    self.microchipId = microchipId
    self.allergies = allergies
    self.notes = notes
    self.medicalVisits = medicalVisits
    self.medications = medications
    self.weightEntries = weightEntries
  }
}

@Model
final class VaccinationModel {
  var name: String
  var date: Date

  init(name: String, date: Date) {
    self.name = name
    self.date = date
  }
}

@Model
final class MedicalVisitModel {
  var date: Date
  var clinic: String
  var vet: String
  var reason: String
  var diagnosis: String
  var treatment: String
  var cost: Double
  var notes: String

  init(
    date: Date,
    clinic: String,
    vet: String,
    reason: String,
    diagnosis: String,
    treatment: String,
    cost: Double,
    notes: String
  ) {
    self.date = date
    self.clinic = clinic
    self.vet = vet
    self.reason = reason
    self.diagnosis = diagnosis
    self.treatment = treatment
    self.cost = cost
    self.notes = notes
  }
}

@Model
final class MedicationModel {
  var name: String
  var dosage: String
  var frequency: String
  var startDate: Date
  var endDate: Date?
  var notes: String

  init(
    name: String,
    dosage: String,
    frequency: String,
    startDate: Date,
    endDate: Date?,
    notes: String
  ) {
    self.name = name
    self.dosage = dosage
    self.frequency = frequency
    self.startDate = startDate
    self.endDate = endDate
    self.notes = notes
  }
}

@Model
final class WeightEntryModel {
  var date: Date
  var weightKg: Double
  var notes: String

  init(date: Date, weightKg: Double, notes: String) {
    self.date = date
    self.weightKg = weightKg
    self.notes = notes
  }
}
