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
    @State private var showAddVaccination = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                // MARK: - Poster Header (iOS Contacts Style)
                ZStack(alignment: .bottom) {
                    // Background Poster Image – full bleed, no GeometryReader for smooth scrolling
                    if let data = pet.avatarImageData,
                       let uiImg = UIImage(data: data) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 520)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 520)
                            .overlay(
                                Image(systemName: pet.species.lowercased().contains("cat") ? "cat.fill" : "dog.fill")
                                    .font(.system(size: 100, weight: .thin))
                                    .foregroundStyle(.white.opacity(0.5))
                            )
                    }

                    // Bottom gradient overlay for readability
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .clear, location: 0.35),
                            .init(color: .black.opacity(0.25), location: 0.55),
                            .init(color: .black.opacity(0.65), location: 0.85),
                            .init(color: .black.opacity(0.8), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 520)

                    // Text + Buttons layered over poster
                    VStack(spacing: 20) {
                        // Pet Name
                        Text(pet.name)
                            .font(.system(size: 40, weight: .bold, design: .default))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)

                        // Action Buttons row
                        HStack(spacing: 12) {
                            NavigationLink(destination: HealthReportsListView(initialPet: pet)) {
                                ContactActionButton(icon: "doc.text.magnifyingglass", title: "Reports")
                            }

                            NavigationLink(destination: PetInsurancePlaceholderView(pet: pet)) {
                                ContactActionButton(icon: "shield.fill", title: "Insurance")
                            }

                            NavigationLink(destination: TravelDocumentView(pet: pet)) {
                                ContactActionButton(icon: "airplane", title: "Travel")
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 28)
                }

                // MARK: - Content Cards Below Poster
                VStack(spacing: 16) {

                    // MARK: Basic Info
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

                    // MARK: Health
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Health")
                            .font(.headline)

                        let weightText = pet.weightKg > 0 ? String(format: "%.1f kg", pet.weightKg) : "Not provided"
                        infoRow(title: "Weight", value: weightText)
                        infoRow(title: "Neutered", value: pet.isNeutered ? "Yes" : "No")
                        infoRow(title: "Microchip", value: pet.microchipId.isEmpty ? "Not provided" : pet.microchipId)
                        infoRow(title: "Allergies", value: pet.allergies.isEmpty ? "Not provided" : pet.allergies)
                        infoRow(title: "Notes", value: pet.notes.isEmpty ? "Not provided" : pet.notes)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // MARK: Vaccinations
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Vaccinations")
                                .font(.headline)
                            Spacer()
                            Button {
                                showAddVaccination = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }

                        if pet.vaccinations.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("No vaccine record")
                                    .foregroundStyle(.orange)
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 4)
                        } else {
                            let sortedVaccines = pet.vaccinations.sorted { $0.date > $1.date }
                            ForEach(sortedVaccines) { vaccine in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(vaccine.name)
                                            .font(.subheadline.weight(.medium))
                                        Text(vaccine.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                if vaccine != sortedVaccines.last {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

            } // VStack(spacing: 0)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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
            SharePetProfileView(petId: pet.persistentModelID.chatSessionKey, petName: pet.name)
        }
        .sheet(isPresented: $showAddVaccination) {
            AddVaccinationView(pet: pet)
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

// MARK: - Contact Action Button Helper
private struct ContactActionButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
            Text(title)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.white) // High contrast against the dark glass
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(Color.black.opacity(0.4)) // Darker tint to mimic iOS Contacts dark mode glass
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
