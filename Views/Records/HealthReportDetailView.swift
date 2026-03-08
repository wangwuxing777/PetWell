//
//  HealthReportDetailView.swift
//  PetWell
//

import SwiftUI
import PDFKit

struct HealthReportDetailView: View {
  let report: HealthReportModel
  @State private var selectedTab: Int = 0

  var body: some View {
    VStack(spacing: 0) {
      Picker("View Mode", selection: $selectedTab) {
        Text("Markdown").tag(0)
        Text("Original File").tag(1)
      }
      .pickerStyle(.segmented)
      .padding()

      TabView(selection: $selectedTab) {
        // Tab 0: Markdown
        ScrollView {
          Text(report.markdownContent)
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .tag(0)

        // Tab 1: Original File
        VStack {
          if report.originalFileType == "pdf" {
            PDFKitRepresentedView(data: report.originalFileData)
          } else if let uiImage = UIImage(data: report.originalFileData) {
            ScrollView {
              Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .padding()
            }
          } else {
            Text("Unsupported original file format.")
              .foregroundColor(.secondary)
          }
        }
        .tag(1)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
    }
    .navigationTitle("Report Details")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// Simple PDFKit view wrapper for SwiftUI
struct PDFKitRepresentedView: UIViewRepresentable {
  let data: Data

  func makeUIView(context: Context) -> PDFView {
    let pdfView = PDFView()
    pdfView.autoScales = true
    return pdfView
  }

  func updateUIView(_ uiView: PDFView, context: Context) {
    if let document = PDFDocument(data: data) {
      uiView.document = document
    }
  }
}
