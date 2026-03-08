//
//  HealthReportsListView.swift
//  PetWell
//

import SwiftUI
import SwiftData

struct HealthReportsListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \PetModel.name) private var pets: [PetModel]
  @State private var selectedPet: PetModel?

  init(initialPet: PetModel? = nil) {
    _selectedPet = State(initialValue: initialPet)
  }

  var body: some View {
    VStack {
      if pets.isEmpty {
        ContentUnavailableView(
          "No Pets Found",
          systemImage: "pawprint",
          description: Text("Please add a pet first to view health reports.")
        )
      } else {
        // Pet Selector
        if pets.count > 1 {
          Picker("Select Pet", selection: $selectedPet) {
            ForEach(pets) { pet in
              Text(pet.name).tag(pet as PetModel?)
            }
          }
          .pickerStyle(.segmented)
          .padding()
        }

        if let pet = selectedPet ?? pets.first {
          reportsList(for: pet)
        } else {
          Spacer()
        }
      }
    }
    .navigationTitle("Pet Health Reports")
    .onAppear {
      if selectedPet == nil {
        selectedPet = pets.first
      }
    }
  }

  @ViewBuilder
  private func reportsList(for pet: PetModel) -> some View {
    let sortedReports = pet.healthReports.sorted { $0.date > $1.date }

    if sortedReports.isEmpty {
      ContentUnavailableView(
        "No Reports",
        systemImage: "doc.text.magnifyingglass",
        description: Text("Upload and analyze clinic reports from your pet's profile.")
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
