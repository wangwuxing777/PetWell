//
//  PetWellApp.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import Combine
import GoogleMaps
import SwiftData
import SwiftUI

// MARK: - Language Manager

enum AppLanguage: String, CaseIterable, Identifiable {
  case english = "en"
  case traditionalChinese = "zh-HK"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .english: return "English"
    case .traditionalChinese: return "繁體中文"
    }
  }
}

class LanguageManager: ObservableObject {
  @Published var currentLanguage: AppLanguage = .english {
    didSet {
      UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
    }
  }

  init() {
    if let storedLang = UserDefaults.standard.string(forKey: "selectedLanguage"),
      let lang = AppLanguage(rawValue: storedLang)
    {
      self.currentLanguage = lang
    }
  }

  // Helper to get localized string dynamically if not using system localization
  // For simple checking in views
  var isChinese: Bool {
    return currentLanguage == .traditionalChinese
  }
}

@main
struct PetWellApp: App {
  @StateObject private var languageManager = LanguageManager()
  @StateObject private var authViewModel = AuthViewModel()

  init() {
    GMSServices.provideAPIKey("AIzaSyCnsrWuXiYAtx70iTGxOfawqlP84o_i260")
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if !authViewModel.isLoggedIn {
          LoginView(viewModel: authViewModel)
        } else if !authViewModel.hasCompletedOnboarding {
          OnboardingView(authViewModel: authViewModel)
        } else {
          ContentView()
            .environmentObject(languageManager)
            .environment(\.locale, .init(identifier: languageManager.currentLanguage.rawValue))
        }
      }
    }
    .modelContainer(for: [
      PetModel.self,
      ChatSession.self,
      ChatMessageEntity.self,
      VaccinationModel.self,
      MedicalVisitModel.self,
      MedicationModel.self,
      WeightEntryModel.self,
    ])
  }
}
