//
//  TravelDocumentView.swift
//  PetWell
//
//  Created by Frontend Engineer on 2026/03/04.
//

import SwiftUI
import PhotosUI

struct TravelDocumentView: View {
    @EnvironmentObject var languageManager: LanguageManager
    let pet: PetModel?

    @State private var documents: [PetDocument] = []
    @State private var isLoading = false
    @State private var showAddDocument = false
    @State private var selectedDocumentType: DocumentType = .healthCert

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if documents.isEmpty {
                    emptyStateView
                } else {
                    documentListView
                }
            }
            .navigationTitle(languageManager.isChinese ? "旅行證件" : "Travel Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddDocument = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddDocument) {
                AddDocumentView(initialPetName: pet?.name) { newDoc in
                    documents.append(newDoc)
                }
            }
            .onAppear {
                loadDocuments()
            }
        }
        .hideTabBarWhenPushed()
    }

    // MARK: - Document List
    private var documentListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Upcoming Expiry Warning
                if let upcomingDocs = documents.filter({ $0.isExpiringSoon }).first {
                    expiryWarningCard(doc: upcomingDocs)
                }

                // Document Cards
                ForEach(documents) { doc in
                    DocumentCard(document: doc)
                }
            }
            .padding()
        }
    }

    // MARK: - Expiry Warning
    private func expiryWarningCard(doc: PetDocument) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(languageManager.isChinese ? "證件即將過期" : "Document Expiring Soon")
                    .font(.headline)
                Text("\(doc.name) - \(languageManager.isChinese ? "過期日期" : "Expires"): \(doc.expiryDateFormatted)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(languageManager.isChinese ? "暫無旅行證件" : (pet != nil ? "No Travel Documents for \(pet!.name)" : "No Travel Documents"))
                .font(.headline)
            Text(languageManager.isChinese ? "添加寵物的健康證明和疫苗證書" : "Add health certificates and vaccination records for your pet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddDocument = true
            } label: {
                Label(languageManager.isChinese ? "添加證件" : "Add Document", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Actions
    private func loadDocuments() {
        isLoading = true
        // Load documents for specific pet, or all if no pet specified
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let pet = pet {
                // Filter documents for this pet by name
                documents = PetDocument.mockData.filter { $0.petName == pet.name }
            } else {
                // Show all documents if no specific pet
                documents = PetDocument.mockData
            }
            isLoading = false
        }
    }
}

// MARK: - Document Card
private struct DocumentCard: View {
    let document: PetDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Type Icon
                ZStack {
                    Circle()
                        .fill(document.type.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: document.type.icon)
                        .foregroundColor(document.type.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.name)
                        .font(.headline)
                    Text(document.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status Badge
                if document.isExpired {
                    Text(languageManager.isChinese ? "已過期" : "Expired")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(12)
                } else if document.isExpiringSoon {
                    Text(languageManager.isChinese ? "即將過期" : "Expiring")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(12)
                }
            }

            Divider()

            // Details
            VStack(alignment: .leading, spacing: 8) {
                if let number = document.documentNumber, !number.isEmpty {
                    DetailRow(
                        icon: "number",
                        title: languageManager.isChinese ? "證件號碼" : "Document Number",
                        value: number
                    )
                }

                DetailRow(
                    icon: "calendar",
                    title: languageManager.isChinese ? "發證日期" : "Issue Date",
                    value: document.issueDateFormatted
                )

                DetailRow(
                    icon: "calendar.badge.exclamationmark",
                    title: languageManager.isChinese ? "過期日期" : "Expiry Date",
                    value: document.expiryDateFormatted,
                    valueColor: document.isExpired ? .red : (document.isExpiringSoon ? .orange : .primary)
                )
            }

            // Pet Info
            if let petName = document.petName {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .font(.caption)
                    Text(petName)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var languageManager: LanguageManager {
        LanguageManager()
    }
}

// MARK: - Detail Row
private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Add Document View
private struct AddDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager

    let initialPetName: String?
    @State private var selectedType: DocumentType = .healthCert
    @State private var documentNumber: String = ""
    @State private var issueDate: Date = Date()
    @State private var expiryDate: Date = Date().addingTimeInterval(365 * 24 * 60 * 60)
    @State private var selectedPet: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading = false

    let pets = ["Max", "Bella", "Charlie"]

    let onSave: (PetDocument) -> Void

    init(initialPetName: String? = nil, onSave: @escaping (PetDocument) -> Void) {
        self.initialPetName = initialPetName
        self.onSave = onSave
        _selectedPet = State(initialValue: initialPetName ?? "Max")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Document Type
                Section(languageManager.isChinese ? "證件類型" : "Document Type") {
                    ForEach(DocumentType.allCases) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                // Document Details
                Section(languageManager.isChinese ? "證件詳情" : "Document Details") {
                    TextField(
                        languageManager.isChinese ? "證件號碼 (可選)" : "Document Number (Optional)",
                        text: $documentNumber
                    )

                    DatePicker(
                        languageManager.isChinese ? "發證日期" : "Issue Date",
                        selection: $issueDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        languageManager.isChinese ? "過期日期" : "Expiry Date",
                        selection: $expiryDate,
                        in: issueDate...,
                        displayedComponents: .date
                    )
                }

                // Pet Selection
                Section(languageManager.isChinese ? "適用寵物" : "Pet") {
                    Picker(languageManager.isChinese ? "選擇寵物" : "Select Pet", selection: $selectedPet) {
                        ForEach(pets, id: \.self) { pet in
                            Text(pet).tag(pet)
                        }
                    }
                }

                // Document Image
                Section(languageManager.isChinese ? "證件掃描" : "Document Scan") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(
                            languageManager.isChinese ? "選擇圖片" : "Select Image",
                            systemImage: "photo"
                        )
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
            .navigationTitle(languageManager.isChinese ? "添加證件" : "Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.isChinese ? "取消" : "Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveDocument()
                    } label: {
                        if isUploading {
                            ProgressView()
                        } else {
                            Text(languageManager.isChinese ? "保存" : "Save")
                        }
                    }
                    .disabled(isUploading)
                }
            }
        }
    }

    private func saveDocument() {
        isUploading = true

        // Simulate upload
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let newDoc = PetDocument(
                id: UUID().uuidString,
                petId: "1",
                petName: selectedPet,
                name: selectedType.displayName,
                type: selectedType,
                documentNumber: documentNumber.isEmpty ? nil : documentNumber,
                issueDate: issueDate,
                expiryDate: expiryDate,
                fileUrl: nil,
                uploadedAt: Date()
            )

            onSave(newDoc)
            isUploading = false
            dismiss()
        }
    }
}

// MARK: - Models
enum DocumentType: String, CaseIterable, Identifiable {
    case healthCert = "health_cert"
    case vaccineCert = "vaccine_cert"
    case importPermit = "import_permit"
    case microchip = "microchip"
    case passport = "passport"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .healthCert: return "heart.text.square"
        case .vaccineCert: return "syringe"
        case .importPermit: return "doc.text"
        case .microchip: return "cpu"
        case .passport: return "book.closed"
        }
    }

    var color: Color {
        switch self {
        case .healthCert: return .green
        case .vaccineCert: return .blue
        case .importPermit: return .orange
        case .microchip: return .purple
        case .passport: return .red
        }
    }

    var displayName: String {
        switch self {
        case .healthCert: return "Health Certificate"
        case .vaccineCert: return "Vaccination Certificate"
        case .importPermit: return "Import Permit"
        case .microchip: return "Microchip"
        case .passport: return "Pet Passport"
        }
    }

    var displayNameZh: String {
        switch self {
        case .healthCert: return "健康證明書"
        case .vaccineCert: return "疫苗證書"
        case .importPermit: return "入境許可證"
        case .microchip: return "晶片"
        case .passport: return "寵物護照"
        }
    }
}

struct PetDocument: Identifiable {
    let id: String
    let petId: String
    let petName: String?
    let name: String
    let type: DocumentType
    let documentNumber: String?
    let issueDate: Date
    let expiryDate: Date
    let fileUrl: String?
    let uploadedAt: Date

    var isExpired: Bool {
        expiryDate < Date()
    }

    var isExpiringSoon: Bool {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return expiryDate > Date() && expiryDate < thirtyDaysFromNow
    }

    var issueDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: issueDate)
    }

    var expiryDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: expiryDate)
    }

    static var mockData: [PetDocument] {
        [
            PetDocument(
                id: "1",
                petId: "1",
                petName: "Max",
                name: "Health Certificate",
                type: .healthCert,
                documentNumber: "HC-2024-001",
                issueDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                expiryDate: Date().addingTimeInterval(185 * 24 * 60 * 60),
                fileUrl: nil,
                uploadedAt: Date().addingTimeInterval(-180 * 24 * 60 * 60)
            ),
            PetDocument(
                id: "2",
                petId: "1",
                petName: "Max",
                name: "Rabies Vaccination",
                type: .vaccineCert,
                documentNumber: "RV-2024-12345",
                issueDate: Date().addingTimeInterval(-90 * 24 * 60 * 60),
                expiryDate: Date().addingTimeInterval(275 * 24 * 60 * 60),
                fileUrl: nil,
                uploadedAt: Date().addingTimeInterval(-90 * 24 * 60 * 60)
            ),
            PetDocument(
                id: "3",
                petId: "2",
                petName: "Bella",
                name: "Microchip Registration",
                type: .microchip,
                documentNumber: "MC-987654321",
                issueDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                expiryDate: Date().addingTimeInterval(-25 * 24 * 60 * 60), // Expired
                fileUrl: nil,
                uploadedAt: Date().addingTimeInterval(-365 * 24 * 60 * 60)
            )
        ]
    }
}

// MARK: - Document Service
class DocumentService {
    // TODO: Connect to backend API
    // POST /api/documents/upload

    static func uploadDocument(
        petId: String,
        documentType: String,
        documentNumber: String?,
        image: UIImage?
    ) async throws -> PetDocument {
        // Placeholder implementation
        throw DocumentError.notImplemented
    }

    static func fetchDocuments(petId: String? = nil) async -> [PetDocument] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return PetDocument.mockData
    }
}

enum DocumentError: Error {
    case notImplemented
    case uploadFailed
}

#Preview {
    TravelDocumentView(pet: nil)
        .environmentObject(LanguageManager())
}
