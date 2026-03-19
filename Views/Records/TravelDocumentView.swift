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

    @State private var folders: [TravelFolder] = []
    @State private var documents: [PetDocument] = []
    @State private var isLoading = false
    @State private var showAddDocument = false
    @State private var showFolderDetail: TravelFolder? = nil
    @State private var selectedDocumentType: DocumentType = .healthCert
    @State private var showChecklistView = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // Get checklist folder separately
    private var checklistFolder: TravelFolder? {
        folders.first { $0.type == .checklists }
    }

    // Get other folders (excluding checklist)
    private var otherFolders: [TravelFolder] {
        folders.filter { $0.type != .checklists }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    folderGridView
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
                    organizeDocumentsIntoFolders()
                }
            }
            .sheet(item: $showFolderDetail) { folder in
                FolderDetailView(folder: folder, pet: pet)
            }
            .sheet(isPresented: $showChecklistView) {
                CountryChecklistView(pet: pet)
            }
            .onAppear {
                loadFolders()
            }
        }
        .hideTabBarWhenPushed()
    }

    // MARK: - Folder Grid View
    private var folderGridView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Warning Section
                if hasExpiringDocuments {
                    expiryWarningSection
                }

                // Checklist Card - Always First
                if let checklist = checklistFolder {
                    ChecklistCard(folder: checklist) {
                        showChecklistView = true
                    }
                    .padding(.horizontal)
                }

                // Other Folders Grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(otherFolders) { folder in
                        FolderCard(folder: folder) {
                            showFolderDetail = folder
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Expiry Warning Section
    private var expiryWarningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(languageManager.isChinese ? "需要注意" : "Attention Needed")
                    .font(.headline)
                Spacer()
            }

            if let expiredCount = expiredDocumentsCount, expiredCount > 0 {
                Text("\(expiredCount) \(languageManager.isChinese ? "份證件已過期" : "document(s) expired")")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            if let expiringCount = expiringSoonDocumentsCount, expiringCount > 0 {
                Text("\(expiringCount) \(languageManager.isChinese ? "份證件即將過期" : "document(s) expiring soon")")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Computed Properties
    private var hasExpiringDocuments: Bool {
        folders.contains { $0.hasExpiringSoon || $0.hasExpired }
    }

    private var expiredDocumentsCount: Int? {
        let count = folders.reduce(0) { $0 + $1.documents.filter { $0.isExpired }.count }
        return count > 0 ? count : nil
    }

    private var expiringSoonDocumentsCount: Int? {
        let count = folders.reduce(0) { $0 + $1.documents.filter { $0.isExpiringSoon && !$0.isExpired }.count }
        return count > 0 ? count : nil
    }

    // MARK: - Actions
    private func loadFolders() {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Create default empty folders
            folders = TravelFolder.createDefaultFolders()

            // Load documents
            if let pet = pet {
                documents = PetDocument.mockData.filter { $0.petName == pet.name }
            } else {
                documents = PetDocument.mockData
            }

            organizeDocumentsIntoFolders()
            isLoading = false
        }
    }

    private func organizeDocumentsIntoFolders() {
        // Group documents by their folder type
        var updatedFolders = folders

        for (index, var folder) in updatedFolders.enumerated() {
            folder.documents = documents.filter { $0.folderType == folder.type }
            folder.updatedAt = Date()
            updatedFolders[index] = folder
        }

        folders = updatedFolders
    }
}

// MARK: - Checklist Card (Prominent First Item)
private struct ChecklistCard: View {
    let folder: TravelFolder
    let onTap: () -> Void

    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with Icon and Title
                HStack(spacing: 16) {
                    // Large Emoji
                    Text(folder.emoji)
                        .font(.system(size: 50))
                        .frame(width: 80, height: 80)
                        .background(folder.type.color.opacity(0.15))
                        .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(languageManager.isChinese ? "旅行文件清單" : "Travel Checklist")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)

                        Text(languageManager.isChinese
                             ? "選擇目的地國家，查看所需文件"
                             : "Select destination country to see required documents")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    // Arrow indicator
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(folder.type.color)
                }

                // Progress indicator
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(folder.type.color)
                    Text(languageManager.isChinese
                         ? "查看各國入境要求"
                         : "View entry requirements by country")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(folder.type.color.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Folder Card
private struct FolderCard: View {
    let folder: TravelFolder
    let onTap: () -> Void

    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Emoji/Thumbnail Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(folder.type.color.opacity(0.15))
                        .frame(height: 100)

                    Text(folder.emoji)
                        .font(.system(size: 50))

                    // Badge for document count
                    if !folder.isEmpty {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(folder.documents.count)")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(folder.type.color)
                                    .clipShape(Capsule())
                                    .offset(x: -8, y: 8)
                            }
                            Spacer()
                        }
                    }

                    // Status indicators
                    VStack {
                        HStack {
                            if folder.hasExpired {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }

                // Folder Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(folder.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(folder.isEmpty
                        ? (languageManager.isChinese ? "點擊添加" : "Tap to add")
                        : "\(folder.documents.count) \(languageManager.isChinese ? "份文件" : "file(s)")")
                        .font(.caption)
                        .foregroundColor(folder.isEmpty ? .secondary : folder.type.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Folder Detail View
private struct FolderDetailView: View {
    let folder: TravelFolder
    let pet: PetModel?

    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAddDocument = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Folder Header with Emoji
                    folderHeader

                    // Documents List
                    if folder.documents.isEmpty {
                        emptyDocumentsView
                    } else {
                        documentsList
                    }
                }
                .padding()
            }
            .navigationTitle(folder.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(languageManager.isChinese ? "完成" : "Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddDocument = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var folderHeader: some View {
        VStack(spacing: 16) {
            // Large Emoji
            Text(folder.emoji)
                .font(.system(size: 80))
                .frame(width: 140, height: 140)
                .background(folder.type.color.opacity(0.15))
                .cornerRadius(20)

            VStack(spacing: 8) {
                Text(folder.displayName)
                    .font(.title2.weight(.bold))

                Text(folder.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var documentsList: some View {
        VStack(spacing: 12) {
            ForEach(folder.documents) { doc in
                DocumentCard(document: doc)
            }
        }
    }

    private var emptyDocumentsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text(languageManager.isChinese ? "此文件夾是空的" : "This folder is empty")
                .font(.headline)

            Text(languageManager.isChinese
                ? "點擊右上角 + 按鈕添加文件"
                : "Tap the + button to add documents")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddDocument = true
            } label: {
                Label(languageManager.isChinese ? "添加文件" : "Add Document", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(folder.type.color)
                    .cornerRadius(12)
            }
            Spacer()
        }
        .padding()
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

        // Map document type to folder type
        let folderType: TravelFolderType? = {
            switch selectedType {
            case .healthCert: return .healthCertificate
            case .vaccineCert: return .vaccinationRecord
            case .importPermit: return .importPermit
            case .microchip: return .chipCertificate
            case .passport: return .exportPermit
            }
        }()

        // Simulate upload
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let newDoc = PetDocument(
                id: UUID().uuidString,
                petId: "1",
                petName: selectedPet,
                name: selectedType.displayName,
                type: selectedType,
                folderType: folderType,
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

// MARK: - Travel Folder Type
enum TravelFolderType: String, CaseIterable, Identifiable {
    // Core Documents
    case chipCertificate = "chip_certificate"
    case vaccinationRecord = "vaccination_record"
    case rabiesTiterTest = "rabies_titer_test"
    case healthCertificate = "health_certificate"
    case exportPermit = "export_permit"
    case importPermit = "import_permit"
    // Folders
    case airlineDocuments = "airline_documents"
    case checklists = "checklists"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .chipCertificate: return "🆔"
        case .vaccinationRecord: return "💉"
        case .rabiesTiterTest: return "🧪"
        case .healthCertificate: return "🏥"
        case .exportPermit: return "📤"
        case .importPermit: return "📥"
        case .airlineDocuments: return "✈️"
        case .checklists: return "✅"
        }
    }

    var icon: String {
        switch self {
        case .chipCertificate: return "cpu"
        case .vaccinationRecord: return "syringe"
        case .rabiesTiterTest: return "testtube.2"
        case .healthCertificate: return "heart.text.square"
        case .exportPermit: return "arrow.up.doc"
        case .importPermit: return "arrow.down.doc"
        case .airlineDocuments: return "airplane"
        case .checklists: return "checklist"
        }
    }

    var color: Color {
        switch self {
        case .chipCertificate: return .blue
        case .vaccinationRecord: return .green
        case .rabiesTiterTest: return .purple
        case .healthCertificate: return .red
        case .exportPermit: return .orange
        case .importPermit: return .cyan
        case .airlineDocuments: return .indigo
        case .checklists: return .pink
        }
    }

    var displayName: String {
        switch self {
        case .chipCertificate: return "Chip Certificate"
        case .vaccinationRecord: return "Vaccination Record"
        case .rabiesTiterTest: return "Rabies Titer Test"
        case .healthCertificate: return "Health Certificate"
        case .exportPermit: return "Export Permit"
        case .importPermit: return "Import Permit"
        case .airlineDocuments: return "Airline Documents"
        case .checklists: return "Checklists"
        }
    }

    var displayNameZh: String {
        switch self {
        case .chipCertificate: return "晶片證書"
        case .vaccinationRecord: return "疫苗接種記錄"
        case .rabiesTiterTest: return "狂犬病抗體檢測"
        case .healthCertificate: return "健康證明書"
        case .exportPermit: return "出口許可證"
        case .importPermit: return "進口許可證"
        case .airlineDocuments: return "航空公司文件"
        case .checklists: return "檢查清單"
        }
    }

    var isFolder: Bool {
        self == .airlineDocuments || self == .checklists
    }

    var description: String {
        switch self {
        case .chipCertificate:
            return "Microchip registration and certification"
        case .vaccinationRecord:
            return "All vaccination records and certificates"
        case .rabiesTiterTest:
            return "Rabies antibody titer test results"
        case .healthCertificate:
            return "Official health certificate from veterinarian"
        case .exportPermit:
            return "Export permit from origin country"
        case .importPermit:
            return "Import permit for destination country"
        case .airlineDocuments:
            return "Booking confirmation, pet carrier specs, etc."
        case .checklists:
            return "Travel preparation checklists"
        }
    }

    var descriptionZh: String {
        switch self {
        case .chipCertificate:
            return "晶片登記和認證文件"
        case .vaccinationRecord:
            return "所有疫苗接種記錄和證書"
        case .rabiesTiterTest:
            return "狂犬病抗體檢測結果"
        case .healthCertificate:
            return "獸醫簽發的官方健康證明"
        case .exportPermit:
            return "原產國出口許可證"
        case .importPermit:
            return "目的地國家進口許可證"
        case .airlineDocuments:
            return "預訂確認、寵物籠規格等"
        case .checklists:
            return "旅行準備清單"
        }
    }
}

// MARK: - Legacy Document Type (for backward compatibility)
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

// MARK: - Travel Folder Model
struct TravelFolder: Identifiable {
    let id: String
    let type: TravelFolderType
    var documents: [PetDocument]
    var emoji: String // Placeholder emoji, can be replaced with actual PDF thumbnail later
    let createdAt: Date
    var updatedAt: Date

    var displayName: String {
        LanguageManager().isChinese ? type.displayNameZh : type.displayName
    }

    var description: String {
        LanguageManager().isChinese ? type.descriptionZh : type.description
    }

    var isEmpty: Bool {
        documents.isEmpty
    }

    var hasExpiringSoon: Bool {
        documents.contains { $0.isExpiringSoon && !$0.isExpired }
    }

    var hasExpired: Bool {
        documents.contains { $0.isExpired }
    }

    static func createDefaultFolders() -> [TravelFolder] {
        TravelFolderType.allCases.map { folderType in
            TravelFolder(
                id: UUID().uuidString,
                type: folderType,
                documents: [],
                emoji: folderType.emoji,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
}

struct PetDocument: Identifiable {
    let id: String
    let petId: String
    let petName: String?
    let name: String
    let type: DocumentType
    let folderType: TravelFolderType? // New: link to folder category
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
                folderType: .healthCertificate,
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
                folderType: .vaccinationRecord,
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
                folderType: .chipCertificate,
                documentNumber: "MC-987654321",
                issueDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                expiryDate: Date().addingTimeInterval(-25 * 24 * 60 * 60),
                fileUrl: nil,
                uploadedAt: Date().addingTimeInterval(-365 * 24 * 60 * 60)
            )
        ]
    }
}

// MARK: - Country Checklist Data
enum Country: String, CaseIterable, Identifiable {
    case usa = "usa"
    case uk = "uk"
    case japan = "japan"
    case australia = "australia"
    case canada = "canada"
    case eu = "eu"
    case china = "china"
    case singapore = "singapore"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .usa: return "🇺🇸"
        case .uk: return "🇬🇧"
        case .japan: return "🇯🇵"
        case .australia: return "🇦🇺"
        case .canada: return "🇨🇦"
        case .eu: return "🇪🇺"
        case .china: return "🇨🇳"
        case .singapore: return "🇸🇬"
        }
    }

    var displayName: String {
        switch self {
        case .usa: return "United States"
        case .uk: return "United Kingdom"
        case .japan: return "Japan"
        case .australia: return "Australia"
        case .canada: return "Canada"
        case .eu: return "European Union"
        case .china: return "China"
        case .singapore: return "Singapore"
        }
    }

    var displayNameZh: String {
        switch self {
        case .usa: return "美國"
        case .uk: return "英國"
        case .japan: return "日本"
        case .australia: return "澳洲"
        case .canada: return "加拿大"
        case .eu: return "歐盟"
        case .china: return "中國"
        case .singapore: return "新加坡"
        }
    }
}

struct ChecklistItem: Identifiable {
    let id: String
    let documentType: TravelFolderType
    let title: String
    let titleZh: String
    let description: String
    let descriptionZh: String
    var isChecked: Bool
    let isRequired: Bool
}

struct CountryRequirement {
    let country: Country
    var items: [ChecklistItem]

    static func getRequirements(for country: Country) -> CountryRequirement {
        let commonItems: [ChecklistItem] = [
            ChecklistItem(
                id: "microchip_\(country.rawValue)",
                documentType: .chipCertificate,
                title: "Microchip Certificate",
                titleZh: "晶片證書",
                description: "ISO 11784/11785 compliant 15-digit microchip",
                descriptionZh: "符合 ISO 11784/11785 標準的15位數晶片",
                isChecked: false,
                isRequired: true
            ),
            ChecklistItem(
                id: "rabies_vaccine_\(country.rawValue)",
                documentType: .vaccinationRecord,
                title: "Rabies Vaccination",
                titleZh: "狂犬病疫苗接種",
                description: "Valid rabies vaccination certificate",
                descriptionZh: "有效的狂犬病疫苗接種證明",
                isChecked: false,
                isRequired: true
            ),
            ChecklistItem(
                id: "health_cert_\(country.rawValue)",
                documentType: .healthCertificate,
                title: "Health Certificate",
                titleZh: "健康證明書",
                description: "Official health certificate from licensed veterinarian",
                descriptionZh: "由持牌獸醫簽發的官方健康證明書",
                isChecked: false,
                isRequired: true
            )
        ]

        var countrySpecificItems: [ChecklistItem] = []

        switch country {
        case .usa:
            countrySpecificItems = [
                ChecklistItem(
                    id: "cdc_permit_usa",
                    documentType: .importPermit,
                    title: "CDC Import Permit",
                    titleZh: "CDC 進口許可證",
                    description: "Required for dogs from high-risk rabies countries",
                    descriptionZh: "來自狂犬病高風險國家的犬隻需要",
                    isChecked: false,
                    isRequired: false
                )
            ]
        case .uk, .eu:
            countrySpecificItems = [
                ChecklistItem(
                    id: "titer_test_uk",
                    documentType: .rabiesTiterTest,
                    title: "Rabies Titer Test",
                    titleZh: "狂犬病抗體檢測",
                    description: "Blood test showing adequate rabies antibody levels (≥0.5 IU/ml)",
                    descriptionZh: "血液檢測顯示足夠的狂犬病抗體水平 (≥0.5 IU/ml)",
                    isChecked: false,
                    isRequired: true
                ),
                ChecklistItem(
                    id: "pet_passport_uk",
                    documentType: .exportPermit,
                    title: "Pet Passport / TRACES",
                    titleZh: "寵物護照 / TRACES",
                    description: "EU pet passport or TRACES certificate",
                    descriptionZh: "歐盟寵物護照或 TRACES 證書",
                    isChecked: false,
                    isRequired: true
                )
            ]
        case .japan:
            countrySpecificItems = [
                ChecklistItem(
                    id: "advance_notice_jp",
                    documentType: .airlineDocuments,
                    title: "Advance Import Notification",
                    titleZh: "進口事前申告",
                    description: "Notify Animal Quarantine Service 40 days before arrival",
                    descriptionZh: "抵達前40天通知動物檢疫所",
                    isChecked: false,
                    isRequired: true
                ),
                ChecklistItem(
                    id: "titer_test_jp",
                    documentType: .rabiesTiterTest,
                    title: "Rabies Titer Test",
                    titleZh: "狂犬病抗體檢測",
                    description: "Must be done at designated laboratory, 180 days wait required",
                    descriptionZh: "必須在指定實驗室進行，需等待180天",
                    isChecked: false,
                    isRequired: true
                )
            ]
        case .australia:
            countrySpecificItems = [
                ChecklistItem(
                    id: "import_permit_au",
                    documentType: .importPermit,
                    title: "Import Permit",
                    titleZh: "進口許可證",
                    description: "Required import permit from Department of Agriculture",
                    descriptionZh: "農業部要求的進口許可證",
                    isChecked: false,
                    isRequired: true
                ),
                ChecklistItem(
                    id: "titer_test_au",
                    documentType: .rabiesTiterTest,
                    title: "Rabies Titer Test",
                    titleZh: "狂犬病抗體檢測",
                    description: "180 days wait after positive titer test result",
                    descriptionZh: "抗體檢測陽性後需等待180天",
                    isChecked: false,
                    isRequired: true
                ),
                ChecklistItem(
                    id: "quarantine_au",
                    documentType: .airlineDocuments,
                    title: "Quarantine Reservation",
                    titleZh: "隔離預訂",
                    description: "Book quarantine facility (10 days minimum)",
                    descriptionZh: "預訂隔離設施（最少10天）",
                    isChecked: false,
                    isRequired: true
                )
            ]
        case .canada:
            countrySpecificItems = [
                ChecklistItem(
                    id: "cfia_cert_ca",
                    documentType: .healthCertificate,
                    title: "CFIA Endorsed Certificate",
                    titleZh: "CFIA 認證證書",
                    description: "Health certificate endorsed by CFIA veterinarian",
                    descriptionZh: "由 CFIA 獸醫認證的健康證書",
                    isChecked: false,
                    isRequired: true
                )
            ]
        case .china:
            countrySpecificItems = [
                ChecklistItem(
                    id: "export_cert_cn",
                    documentType: .exportPermit,
                    title: "Export Health Certificate",
                    titleZh: "出口健康證明",
                    description: "Official export certificate from origin country",
                    descriptionZh: "原產國官方出口證明",
                    isChecked: false,
                    isRequired: true
                ),
                ChecklistItem(
                    id: "customs_decl_cn",
                    documentType: .airlineDocuments,
                    title: "Customs Declaration",
                    titleZh: "海關申報",
                    description: "Complete customs declaration form",
                    descriptionZh: "填寫海關申報表",
                    isChecked: false,
                    isRequired: true
                )
            ]
        case .singapore:
            countrySpecificItems = [
                ChecklistItem(
                    id: "avs_permit_sg",
                    documentType: .importPermit,
                    title: "AVS Import License",
                    titleZh: "AVS 進口許可證",
                    description: "Animal & Veterinary Service import license",
                    descriptionZh: "動物與獸醫服務進口許可證",
                    isChecked: false,
                    isRequired: true
                ),
                ChecklistItem(
                    id: "titer_test_sg",
                    documentType: .rabiesTiterTest,
                    title: "Rabies Titer Test",
                    titleZh: "狂犬病抗體檢測",
                    description: "Required for certain countries, 6 months quarantine if not done",
                    descriptionZh: "某些國家需要，如未檢測需隔離6個月",
                    isChecked: false,
                    isRequired: false
                )
            ]
        }

        return CountryRequirement(country: country, items: commonItems + countrySpecificItems)
    }
}

// MARK: - Country Checklist View
private struct CountryChecklistView: View {
    let pet: PetModel?

    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCountry: Country = .usa
    @State private var requirements: [ChecklistItem] = []
    @State private var completedCount: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Country Selector
                    countrySelector

                    // Progress Summary
                    progressSummary

                    // Checklist Items
                    checklistItemsSection
                }
                .padding()
            }
            .navigationTitle(languageManager.isChinese ? "旅行文件清單" : "Travel Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(languageManager.isChinese ? "完成" : "Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRequirements()
            }
            .onChange(of: selectedCountry) { _, _ in
                loadRequirements()
            }
        }
    }

    private var countrySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.isChinese ? "選擇目的地國家" : "Select Destination Country")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Country.allCases) { country in
                        CountryButton(
                            country: country,
                            isSelected: selectedCountry == country
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCountry = country
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var progressSummary: some View {
        HStack(spacing: 16) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.pink.opacity(0.2), lineWidth: 8)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: CGFloat(completedCount) / CGFloat(max(requirements.count, 1)))
                    .stroke(Color.pink, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(completedCount)")
                        .font(.title2.weight(.bold))
                    Text("/\(requirements.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.isChinese ? "完成進度" : "Completion Progress")
                    .font(.headline)

                let percentage = requirements.isEmpty ? 0 : Int(Double(completedCount) / Double(requirements.count) * 100)
                Text(languageManager.isChinese
                     ? "已完成 \(percentage)% 的文件準備"
                     : "\(percentage)% of documents prepared")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pink.opacity(0.1))
        )
    }

    private var checklistItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.isChinese ? "所需文件" : "Required Documents")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach($requirements) { $item in
                    ChecklistItemRow(item: $item) {
                        toggleItem(item.id)
                    }
                }
            }
        }
    }

    private func loadRequirements() {
        let countryReq = CountryRequirement.getRequirements(for: selectedCountry)
        requirements = countryReq.items
        updateCompletedCount()
    }

    private func toggleItem(_ id: String) {
        if let index = requirements.firstIndex(where: { $0.id == id }) {
            requirements[index].isChecked.toggle()
            updateCompletedCount()
        }
    }

    private func updateCompletedCount() {
        completedCount = requirements.filter { $0.isChecked }.count
    }
}

// MARK: - Country Button
private struct CountryButton: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(country.flag)
                    .font(.system(size: 36))

                Text(country.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.pink : Color(UIColor.tertiarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Checklist Item Row
private struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem
    let onToggle: () -> Void

    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        HStack(spacing: 16) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.isChecked ? Color.pink : Color.clear)
                        .frame(width: 28, height: 28)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(item.isChecked ? Color.pink : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(languageManager.isChinese ? item.titleZh : item.title)
                        .font(.subheadline.weight(.semibold))
                        .strikethrough(item.isChecked)
                        .foregroundColor(item.isChecked ? .secondary : .primary)

                    if item.isRequired {
                        Text("Required")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }

                Text(languageManager.isChinese ? item.descriptionZh : item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Document Type Icon
            Image(systemName: item.documentType.icon)
                .font(.title3)
                .foregroundColor(item.documentType.color)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(item.isChecked ? 0.7 : 1)
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
