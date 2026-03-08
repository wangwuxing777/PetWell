//
//  HealthReportUploadView.swift
//  PetWell
//

import PhotosUI
import SwiftUI
import VisionKit
import PDFKit
import SwiftData

// MARK: - VisionKit Document Scanner Wrapper

/// Wraps VNDocumentCameraViewController — the same scanner used in Apple Notes.
/// Provides perspective correction, edge detection, and contrast enhancement automatically.
private struct DocumentScannerView: UIViewControllerRepresentable {
  var onScan: (UIImage?) -> Void

  func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
    let vc = VNDocumentCameraViewController()
    vc.delegate = context.coordinator
    return vc
  }

  func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

  func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

  final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    let onScan: (UIImage?) -> Void
    init(onScan: @escaping (UIImage?) -> Void) { self.onScan = onScan }

    func documentCameraViewController(
      _ controller: VNDocumentCameraViewController,
      didFinishWith scan: VNDocumentCameraScan
    ) {
      // For a health report the key content is typically on the first page.
      // Send page 0; multi-page support can be added later.
      onScan(scan.pageCount > 0 ? scan.imageOfPage(at: 0) : nil)
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
      onScan(nil)
    }

    func documentCameraViewController(
      _ controller: VNDocumentCameraViewController,
      didFailWithError error: Error
    ) {
      onScan(nil)
    }
  }
}

// MARK: - Main View

struct HealthReportUploadView: View {
  let pet: PetModel

  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImage: UIImage?
  @State private var originalFileType: String?
  @State private var originalFileData: Data?
  @State private var showScanner = false
  @State private var showFileImporter = false
  @State private var isLoading = false
  @State private var agentResults: [String] = []
  @State private var errorMessage: String?

  private let service = HealthReportService.shared
  private var scannerSupported: Bool { VNDocumentCameraViewController.isSupported }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {

        petInfoHeader
        Divider().padding(.horizontal)
        imageInputSection
        analyzeButton

        if let err = errorMessage {
          Text(err)
            .font(.subheadline)
            .foregroundStyle(.red)
            .padding(.horizontal)
        }

        if !agentResults.isEmpty {
          resultsSection
        }

        Spacer(minLength: 40)
      }
      .padding(.top, 16)
    }
    .navigationTitle("Upload Report")
    .navigationBarTitleDisplayMode(.inline)
    // Present the document scanner full-screen (same as Notes)
    .fullScreenCover(isPresented: $showScanner) {
      DocumentScannerView { scanned in
        showScanner = false
        if let img = scanned {
          selectedImage = img
          agentResults = []
          errorMessage = nil
        }
      }
      .ignoresSafeArea()
    }
    .fileImporter(
      isPresented: $showFileImporter,
      allowedContentTypes: [.pdf, .image],
      allowsMultipleSelection: false
    ) { result in
      switch result {
      case .success(let urls):
        guard let url = urls.first else { return }
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
          let data = try Data(contentsOf: url)
          originalFileData = data
          if url.pathExtension.lowercased() == "pdf" {
            originalFileType = "pdf"
            if let pdfDoc = PDFDocument(data: data), let page = pdfDoc.page(at: 0) {
              let pageRect = page.bounds(for: .mediaBox)
              let format = UIGraphicsImageRendererFormat()
              format.scale = 2.0 // High res
              let renderer = UIGraphicsImageRenderer(size: pageRect.size, format: format)
              let img = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: ctx.cgContext)
              }
              selectedImage = img
            }
          } else {
            originalFileType = "image"
            selectedImage = UIImage(data: data)
          }
          agentResults = []
          errorMessage = nil
        } catch {
          errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
      case .failure(let error):
        errorMessage = error.localizedDescription
      }
    }
  }

  // MARK: - Pet info header

  private var petInfoHeader: some View {
    HStack(spacing: 10) {
      if let data = pet.avatarImageData, let uiImg = UIImage(data: data) {
        Image(uiImage: uiImg)
          .resizable().scaledToFill()
          .frame(width: 36, height: 36)
          .clipShape(Circle())
      } else {
        Image(systemName: pet.species.lowercased().contains("cat") ? "cat" : "dog")
          .font(.title3)
          .frame(width: 36, height: 36)
          .foregroundStyle(.secondary)
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(pet.name).font(.headline)
        Text("ID: \(pet.petID)")
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(1)
      }
    }
    .padding(.horizontal)
  }

  // MARK: - Image input section

  @ViewBuilder
  private var imageInputSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Report Photo")
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal)

      // Preview — shown once an image is selected
      if let image = selectedImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity)
          .frame(height: 220)
          .clipped()
          .cornerRadius(12)
          .padding(.horizontal)

        // Allow re-selecting
        inputButtons(isReplacing: true)
      } else {
        inputButtons(isReplacing: false)
      }
      
      // File Importer Option
      Button {
        showFileImporter = true
      } label: {
        Label("Import from File", systemImage: "folder")
          .font(.subheadline.weight(.semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 13)
          .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
          .foregroundStyle(.primary)
      }
      .padding(.horizontal)
    }
  }

  /// Primary action buttons for input. `isReplacing` changes the label copy.
  @ViewBuilder
  private func inputButtons(isReplacing: Bool) -> some View {
    VStack(spacing: 10) {
      // Scan (primary) — only on real devices; simulator returns isSupported = false
      if scannerSupported {
        Button {
          showScanner = true
        } label: {
          Label(
            isReplacing ? "Re-scan Document" : "Scan Document",
            systemImage: "doc.viewfinder"
          )
          .font(.subheadline.weight(.semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 13)
          .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
          .foregroundStyle(.white)
        }
        .padding(.horizontal)
      }

      // Photo library (secondary / fallback)
      PhotosPicker(selection: $selectedItem, matching: .images) {
        Label(
          isReplacing ? "Choose Different Photo" : "Choose from Library",
          systemImage: "photo"
        )
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(
          Color(.secondarySystemBackground),
          in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .foregroundStyle(.primary)
      }
      .padding(.horizontal)
      .onChange(of: selectedItem) { _, newItem in
        Task {
          if let data = try? await newItem?.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
          {
            selectedImage = uiImage
            originalFileType = "image"
            originalFileData = data
            agentResults = []
            errorMessage = nil
          }
        }
      }

      // Hint shown only before any image is picked
      if !isReplacing && !scannerSupported {
        Text("Tip: Use \"Scan Document\" on a real device for best results.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
      }
    }
  }

  // MARK: - Analyze button

  private var analyzeButton: some View {
    Button {
      Task { await analyze() }
    } label: {
      HStack {
        Spacer()
        if isLoading {
          ProgressView().tint(.white)
          Text("Analyzing…")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
        } else {
          Text("Analyze Report")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
        }
        Spacer()
      }
      .padding(.vertical, 14)
      .background(
        (selectedImage == nil || isLoading) ? Color.gray : Color.accentColor,
        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
      )
    }
    .disabled(selectedImage == nil || isLoading)
    .padding(.horizontal)
  }

  // MARK: - Results

  private var resultsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("AI Analysis Results (\(agentResults.count) Agents)")
        .font(.headline)
        .padding(.horizontal)

      ForEach(Array(agentResults.enumerated()), id: \.offset) { index, markdown in
        VStack(alignment: .leading, spacing: 8) {
          Text("Agent \(index + 1)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal)

          ScrollView {
            Text(markdown)
              .font(.system(.caption, design: .monospaced))
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(12)
          }
          .frame(maxHeight: 320)
          .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
          )
          .padding(.horizontal)
        }

        if index < agentResults.count - 1 {
          Divider().padding(.horizontal)
        }
      }
    }
  }

  // MARK: - Actions

  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  private func extractDateAndCategory(from markdown: String) -> (Date, String) {
    var date = Date()
    var category = "General"
    
    // Very simple heuristic parser: look for "Date: YYYY-MM-DD" or similar
    let lines = markdown.components(separatedBy: .newlines)
    for line in lines {
      let lowerLine = line.lowercased()
      if lowerLine.contains("date:") {
        let scanner = Scanner(string: line)
        _ = scanner.scanUpToCharacters(from: .decimalDigits)
        if let y = scanner.scanInt() {
           _ = scanner.scanCharacter()
           if let m = scanner.scanInt() {
              _ = scanner.scanCharacter()
              if let d = scanner.scanInt() {
                var comps = DateComponents()
                comps.year = y
                comps.month = m
                comps.day = d
                if let parsedDate = Calendar.current.date(from: comps) {
                  date = parsedDate
                }
              }
           }
        }
      }
      if lowerLine.contains("category:") || lowerLine.contains("type:") {
        let parts = line.split(separator: ":")
        if parts.count > 1 {
          category = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
    }
    return (date, category)
  }

  private func analyze() async {
    guard let image = selectedImage else { return }
    isLoading = true
    errorMessage = nil
    agentResults = []
    defer { isLoading = false }

    do {
      agentResults = try await service.uploadAndAnalyze(image: image, petID: pet.petID)
      
      // Save results
      if let markdown = agentResults.first {
        let (extractedDate, extCategory) = extractDateAndCategory(from: markdown)
        let type = originalFileType ?? "image"
        let fallbackData = image.jpegData(compressionQuality: 0.8) ?? Data()
        
        let report = HealthReportModel(
          date: extractedDate,
          category: extCategory,
          markdownContent: agentResults.joined(separator: "\n\n---\n\n"),
          originalFileType: type,
          originalFileData: originalFileData ?? fallbackData
        )
        
        pet.healthReports.append(report)
        try modelContext.save()
      }
      
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
