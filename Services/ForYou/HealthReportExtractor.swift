import Foundation

// MARK: - HealthReportExtractor
// Reads pet.healthReports (SwiftData @Relationship) and produces a compact
// text blob for injection into the Medical RAG query.
// Strategy: latest 3 reports × first 400 chars of markdownContent.

enum HealthReportExtractor {

    private static let maxReports = 3
    private static let maxCharsPerReport = 400

    // MARK: - Public API

    /// Returns nil if the pet has no health reports with content.
    static func extract(from reports: [HealthReportModel]) -> String? {
        let sorted = reports
            .filter { !$0.markdownContent.isEmpty }
            .sorted { $0.date > $1.date }   // newest first
            .prefix(maxReports)

        guard !sorted.isEmpty else { return nil }

        let chunks = sorted.enumerated().map { (index, report) -> String in
            let label = reportLabel(report: report, index: index)
            let trimmed = String(report.markdownContent.prefix(maxCharsPerReport))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(label)\n\(trimmed)"
        }

        return chunks.joined(separator: "\n\n---\n\n")
    }

    // MARK: - Helpers

    private static func reportLabel(report: HealthReportModel, index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        var parts: [String] = [
            "[Health Report \(index + 1)]",
            formatter.string(from: report.date),
        ]
        if !report.category.isEmpty {
            parts.append("(\(report.category))")
        }
        return parts.joined(separator: " ")
    }
}
