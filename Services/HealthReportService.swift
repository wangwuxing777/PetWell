//
//  HealthReportService.swift
//  PetWell
//

import Foundation
import UIKit

// MARK: - Response Models

private struct HealthReportAPIResponse: Codable {
  let markdownContent: String?
  let extractionMode: String?

  enum CodingKeys: String, CodingKey {
    case markdownContent = "markdown_content"
    case extractionMode = "extraction_mode"
  }
}

// MARK: - Service

@MainActor
final class HealthReportService {
  static let shared = HealthReportService()

  private let baseURL = "https://pawrd-backend.zeabur.app"

  /// Convert image to base64 and send directly to AI analysis.
  /// Vendors are external — they cannot reach localhost URLs,
  /// so we bypass the /media/upload step and use image_base64 instead.
  func uploadAndAnalyze(image: UIImage, petID: String) async throws -> [String] {
    let combined = try await analyzeReport(image: image, petID: petID)
    return splitByVendorBoundary(combined)
  }

  /// Split combined markdown into per-vendor sections.
  ///
  /// combineMarkdown() on the Go server produces:
  ///   "## vendor_a (model)\n\n{md_a}\n\n---\n\n## vendor_b (model)\n\n{md_b}"
  ///
  /// A vendor's own markdown content can contain "---" horizontal rules,
  /// so splitting on "\n\n---\n\n" alone would break those into false segments.
  /// Instead we split on "\n\n---\n\n## " — the separator immediately followed
  /// by the next vendor's "## header", which is unique to the boundary.
  private func splitByVendorBoundary(_ combined: String) -> [String] {
    let boundary = "\n\n---\n\n## "
    let raw = combined.components(separatedBy: boundary)
    return raw.enumerated().compactMap { index, segment in
      // The first segment already starts with "## vendor_a"; subsequent ones
      // had their "## " stripped by the split, so we restore it.
      let restored = index == 0 ? segment : "## " + segment
      let trimmed = restored.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
  }

  // MARK: - Private

  private func analyzeReport(image: UIImage, petID: String) async throws -> String {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      throw HealthReportError.imageConversionFailed
    }
    // Backend's buildVendorPayload prepends "data:image/jpeg;base64," automatically,
    // so we send the raw base64 string only.
    let base64String = imageData.base64EncodedString()

    let url = URL(string: "\(baseURL)/api/profile/health-reports")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 90  // AI extraction can be slow

    let body: [String: Any] = [
      "pet_id": petID,
      "extraction_mode": "markdown",
      "image_base64": [base64String],
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)
    try assertHTTP200(response, data: data, context: "health-reports")

    let resp = try JSONDecoder().decode(HealthReportAPIResponse.self, from: data)
    return resp.markdownContent ?? "(No content returned by server)"
  }

  private func assertHTTP200(_ response: URLResponse, data: Data, context: String) throws {
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
      let code = (response as? HTTPURLResponse)?.statusCode ?? -1
      let body = String(data: data, encoding: .utf8) ?? ""
      throw HealthReportError.httpError(code: code, context: context, body: body)
    }
  }
}

// MARK: - Errors

enum HealthReportError: LocalizedError {
  case imageConversionFailed
  case httpError(code: Int, context: String, body: String)

  var errorDescription: String? {
    switch self {
    case .imageConversionFailed:
      return "Failed to convert image to JPEG."
    case .httpError(let code, let context, let body):
      return "[\(context)] Server returned \(code): \(body.prefix(200))"
    }
  }
}
