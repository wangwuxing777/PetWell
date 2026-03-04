//
//  PetDetailView.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/30.
//

import SwiftUI
import SwiftData
import UIKit

struct PetDetailView: View {

    @Bindable var pet: PetModel

    @State private var showEdit = false
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - Avatar Header (read-only)
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(.thinMaterial)

                        if let data = pet.avatarImageData,
                           let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: pet.species.lowercased().contains("cat") ? "cat" : "dog")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(.separator).opacity(0.15), lineWidth: 1)
                    )
                }
                .padding(.top, 12)

                // MARK: - Basic Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Basic Info")
                        .font(.headline)

                    infoRow(title: "Name", value: pet.name)
                    infoRow(title: "Species", value: pet.species)
                    infoRow(title: "Breed", value: pet.breed.isEmpty ? "—" : pet.breed)
                    infoRow(title: "Sex", value: pet.sex)
                    infoRow(title: "Birth Year", value: String(pet.birthYear))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                // MARK: - Health
                VStack(alignment: .leading, spacing: 12) {
                    Text("Health")
                        .font(.headline)

                    let weightText = pet.weightKg > 0 ? String(format: "%.1f kg", pet.weightKg) : "—"
                    infoRow(title: "Weight", value: weightText)
                    infoRow(title: "Neutered", value: pet.isNeutered ? "Yes" : "No")
                    infoRow(title: "Microchip", value: pet.microchipId.isEmpty ? "—" : pet.microchipId)
                    infoRow(title: "Allergies", value: pet.allergies.isEmpty ? "—" : pet.allergies)
                    infoRow(title: "Notes", value: pet.notes.isEmpty ? "—" : pet.notes)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                Spacer(minLength: 24)
            }
            .padding(.horizontal)
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button("Edit") {
                        showEdit = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showEdit) {
            AddPetView(petToEdit: pet)
        }
        .sheet(isPresented: $showShareSheet) {
            SharePetProfileView(petId: pet.persistentModel.identifier.uuidString, petName: pet.name)
        }
    }

    // MARK: - Helper

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

#Preview {
    PetDetailView(
        pet: PetModel(
            name: "Buddy",
            species: "Dog",
            breed: "Golden Retriever",
            sex: "Male",
            birthYear: 2020,
            avatarImageData: nil,
            weightKg: 28.5,
            isNeutered: true,
            microchipId: "123456789",
            allergies: "None",
            notes: ""
        )
    )
    .modelContainer(for: [PetModel.self], inMemory: true)
}
