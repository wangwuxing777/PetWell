//
//  HealthReportsListView.swift
//  PetWell
//

import SwiftUI
import SwiftData
import PhotosUI

struct HealthReportsListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \PetModel.name) private var pets: [PetModel]
  @State private var selectedPet: PetModel?
  @State private var showAddReport = false

  init(initialPet: PetModel? = nil) {
    _selectedPet = State(initialValue: initialPet)
  }

  var body: some View {
    VStack(spacing: 0) {
      if pets.isEmpty {
        ContentUnavailableView(
          "No Pets Found",
          systemImage: "pawprint",
          description: Text("Please add a pet first to view health reports.")
        )
      } else {
        // Compact Pet Selector
        petSelector
          .padding(.horizontal)
          .padding(.top, 8)
          .padding(.bottom, 8)
          .background(Color(.systemBackground))

        Divider()

        if let pet = selectedPet ?? pets.first {
          reportsList(for: pet)
        } else {
          Spacer()
        }
      }
    }
    .navigationTitle("Pet Health Reports")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          showAddReport = true
        } label: {
          Image(systemName: "plus")
        }
      }
    }
    .sheet(isPresented: $showAddReport) {
      if let pet = selectedPet ?? pets.first {
        AddHealthReportView(pet: pet)
      }
    }
    .onAppear {
      if selectedPet == nil {
        selectedPet = pets.first
      }
    }
    .onChange(of: pets.count) { _, _ in
      guard let selectedPet else {
        self.selectedPet = pets.first
        return
      }

      if !pets.contains(where: { $0.persistentModelID == selectedPet.persistentModelID }) {
        self.selectedPet = pets.first
      }
    }
  }

  private var petSelector: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        ForEach(pets) { pet in
          PetAvatarButton(
            pet: pet,
            isSelected: isSelected(pet),
            onTap: { selectedPet = pet }
          )
        }
      }
      .padding(.top, 4)
      .padding(.bottom, 8)
    }
  }

  private func isSelected(_ pet: PetModel) -> Bool {
    selectedPet?.persistentModelID == pet.persistentModelID
  }

  @ViewBuilder
  private func reportsList(for pet: PetModel) -> some View {
    let sortedReports = pet.healthReports.sorted { $0.date > $1.date }

    if sortedReports.isEmpty {
      ContentUnavailableView(
        "No Reports",
        systemImage: "doc.text.magnifyingglass",
        description: Text("Tap the + button to upload a health report for \(pet.name).")
      )
    } else {
      List {
        ForEach(sortedReports) { report in
          NavigationLink(value: report) {
            HStack {
              Image(systemName: "doc.text")
                .foregroundColor(.accentColor)
                .font(.title2)

              VStack(alignment: .leading, spacing: 4) {
                Text(report.category.isEmpty ? "General Report" : report.category)
                  .font(.headline)
                Text(report.date, style: .date)
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
            }
            .padding(.vertical, 4)
          }
        }
        .onDelete { indexSet in
          for i in indexSet {
            let item = sortedReports[i]
            modelContext.delete(item)
          }
        }
      }
      .navigationDestination(for: HealthReportModel.self) { report in
        HealthReportDetailView(report: report)
      }
    }
  }
}

// MARK: - Pet Avatar Button
private struct PetAvatarButton: View {
  let pet: PetModel
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 6) {
        // Avatar
        ZStack {
          Circle()
            .fill(isSelected ? Color.blue : Color(.systemGray3))
            .frame(width: 50, height: 50)

          if let data = pet.avatarImageData,
             let uiImg = UIImage(data: data) {
            Image(uiImage: uiImg)
              .resizable()
              .scaledToFill()
              .frame(width: 50, height: 50)
              .clipShape(Circle())
          } else {
            Image(systemName: pet.species.lowercased().contains("cat") ? "cat.fill" : "dog.fill")
              .font(.system(size: 20))
              .foregroundColor(.white)
          }
        }
        .overlay(
          Circle()
            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )

        // Name
        Text(pet.name)
          .font(.caption.weight(isSelected ? .semibold : .medium))
          .foregroundColor(isSelected ? .blue : .primary)
          .lineLimit(1)
          .frame(width: 60)
      }
    }
    .frame(width: 70)
    .buttonStyle(.plain)
  }
}

// MARK: - Add Health Report View
struct AddHealthReportView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let pet: PetModel

  @State private var category = ""
  @State private var selectedDate = Date()
  @State private var notes = ""
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var selectedImage: UIImage?
  @State private var isAnalyzing = false

  private let categories = [
    "General Checkup",
    "Blood Test",
    "X-Ray",
    "Ultrasound",
    "Vaccination",
    "Dental",
    "Surgery",
    "Other"
  ]

  var body: some View {
    NavigationStack {
      Form {
        // Pet Info
        Section("Pet") {
          HStack {
            Text(pet.name)
            Spacer()
            Text(pet.species)
              .foregroundColor(.secondary)
          }
        }

        // Report Category
        Section("Report Type") {
          Picker("Category", selection: $category) {
            Text("Select a type").tag("")
            ForEach(categories, id: \.self) { cat in
              Text(cat).tag(cat)
            }
          }
        }

        // Date
        Section("Date") {
          DatePicker("Report Date", selection: $selectedDate, displayedComponents: .date)
        }

        // Photo Upload
        Section("Document Image") {
          if let image = selectedImage {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(maxHeight: 200)
              .cornerRadius(8)

            Button("Remove Image") {
              selectedImage = nil
              selectedPhotoItem = nil
            }
            .foregroundColor(.red)
          } else {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
              Label("Select Image", systemImage: "photo")
            }
          }
        }

        // Notes
        Section("Notes") {
          TextEditor(text: $notes)
            .frame(minHeight: 80)
        }
      }
      .navigationTitle("Add Report")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button {
            saveReport()
          } label: {
            if isAnalyzing {
              ProgressView()
            } else {
              Text("Save")
            }
          }
          .disabled(category.isEmpty || isAnalyzing)
        }
      }
      .onChange(of: selectedPhotoItem) { _, item in
        guard let item else { return }
        Task {
          if let data = try? await item.loadTransferable(type: Data.self),
             let image = UIImage(data: data) {
            await MainActor.run {
              selectedImage = image
            }
          }
        }
      }
    }
  }

  private func saveReport() {
    isAnalyzing = true

    // Convert image to data if available
    let imageData = selectedImage?.jpegData(compressionQuality: 0.8) ?? Data()

    // Create new health report
    let newReport = HealthReportModel(
      date: selectedDate,
      category: category,
      markdownContent: notes.isEmpty ? "No additional notes" : notes,
      originalFileType: "image",
      originalFileData: imageData
    )

    // Associate with pet
    pet.healthReports.append(newReport)

    // Save to context
    do {
      try modelContext.save()
      dismiss()
    } catch {
      print("Error saving report: \(error)")
      isAnalyzing = false
    }
  }
}
