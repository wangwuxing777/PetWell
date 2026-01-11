//
//  PetWellApp.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import SwiftUI
import SwiftData

@main
struct PetWellApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            PetModel.self,
            ChatSession.self,
            ChatMessageEntity.self,
            VaccinationModel.self,
            MedicalVisitModel.self,
            MedicationModel.self,
            WeightEntryModel.self
        ])
    }
}
