import Foundation

// MARK: - ContextAssemblerAgent
// Assembles the enriched context string that is passed to the Insurance RAG (Stage 5).
// The string is also stored on ForYouOrchestrator.result.enrichedContext and used
// as the contextString for subsequent user questions in RAGChatView.

enum ContextAssemblerAgent {

    // MARK: - Public API

    static func build(
        pet: PetModel,
        petAgeYears: Int,
        eligibleCount: Int,
        totalCount: Int,
        breedRisks: [BreedRisk],
        isLargeDog: Bool,
        clinicalSummary: String?
    ) -> String {
        var sections: [String] = []

        // ── Pet Profile ──────────────────────────────────────
        var profile: [String] = [
            "Pet Profile:",
            "  Name: \(pet.name)",
            "  Species: \(pet.species)",
            "  Breed: \(pet.breed)",
            "  Age: \(petAgeYears) year(s)",
            "  Weight: \(String(format: "%.1f", pet.weightKg)) kg",
            "  Neutered: \(pet.isNeutered ? "Yes" : "No")",
        ]
        if !pet.allergies.isEmpty {
            profile.append("  Allergies: \(pet.allergies)")
        }
        sections.append(profile.joined(separator: "\n"))

        // ── Age Eligibility ──────────────────────────────────
        sections.append(
            "Insurance Eligibility:\n  \(eligibleCount) of \(totalCount) available plans are age-eligible for this pet."
        )

        // ── Breed Risks ──────────────────────────────────────
        if !breedRisks.isEmpty {
            let riskLines = breedRisks.map {
                "  • \($0.condition) [\($0.abbreviation)] — \($0.severity.rawValue) risk"
            }
            sections.append("Known Breed-Specific Health Risks:\n" + riskLines.joined(separator: "\n"))
        } else {
            sections.append(
                "Known Breed-Specific Health Risks:\n  No specific breed risks identified in database."
            )
        }

        // ── Large Dog Flag ────────────────────────────────────
        if isLargeDog {
            sections.append(
                "Large Breed Notice:\n  This is a large/giant breed dog. Third-party liability insurance may be required or strongly recommended under local regulations."
            )
        }

        // ── Clinical Summary (from Medical RAG) ──────────────
        if let summary = clinicalSummary, !summary.isEmpty {
            sections.append("Medical History Summary (AI-extracted from health reports):\n\(summary)")
        } else {
            sections.append(
                "Medical History:\n  No health reports on file. Recommendation based on breed profile only."
            )
        }

        // ── Instruction for Insurance RAG ────────────────────
        sections.append(
            """
            Task:
              Based on the above pet profile, breed risks, and medical history, recommend the most suitable pet insurance plan(s).
              Consider:
              1. Age eligibility (only recommend age-eligible plans).
              2. Coverage for known breed conditions.
              3. Third-party liability if large breed.
              4. Pre-existing condition exclusions relevant to the clinical summary.
              Please provide a structured recommendation with plan names, key benefits, and any important caveats.
            """
        )

        return sections.joined(separator: "\n\n")
    }
}
