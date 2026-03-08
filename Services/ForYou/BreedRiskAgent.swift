import Foundation

// MARK: - BreedRiskAgent
// Returns a list of known genetic / breed-specific health risks for a given breed.
// ⚠️  This is a PLACEHOLDER database — Human Lead should add / verify breed entries.

struct BreedRisk {
    let condition: String       // e.g. "Hypertrophic Cardiomyopathy (HCM)"
    let abbreviation: String    // e.g. "HCM"
    let severity: RiskSeverity

    enum RiskSeverity: String {
        case high   = "high"
        case medium = "medium"
        case low    = "low"
    }
}

enum BreedRiskAgent {

    // MARK: - Public API

    /// Returns known breed risks for the given breed name (case-insensitive partial match).
    static func risks(forBreed breed: String) -> [BreedRisk] {
        let key = breed.lowercased()
        for (pattern, risks) in breedRiskDatabase {
            if key.contains(pattern) { return risks }
        }
        return []
    }

    /// Convenience: returns a comma-separated string of abbreviations, or nil if none.
    static func riskSummary(forBreed breed: String) -> String? {
        let r = risks(forBreed: breed)
        guard !r.isEmpty else { return nil }
        return r.map { $0.abbreviation }.joined(separator: ", ")
    }

    // MARK: - Placeholder Database
    // Keys are lowercase partial breed name patterns.
    // TODO (Human Lead): verify conditions, add more breeds, link to insurance exclusion lists.

    private static let breedRiskDatabase: [String: [BreedRisk]] = [

        // ── CATS ──────────────────────────────────────────────
        "maine coon": [
            BreedRisk(condition: "Hypertrophic Cardiomyopathy", abbreviation: "HCM", severity: .high),
            BreedRisk(condition: "Hip Dysplasia", abbreviation: "HD", severity: .medium),
        ],
        "ragdoll": [
            BreedRisk(condition: "Hypertrophic Cardiomyopathy", abbreviation: "HCM", severity: .high),
        ],
        "british shorthair": [
            BreedRisk(condition: "Hypertrophic Cardiomyopathy", abbreviation: "HCM", severity: .medium),
            BreedRisk(condition: "Polycystic Kidney Disease", abbreviation: "PKD", severity: .medium),
        ],
        "persian": [
            BreedRisk(condition: "Polycystic Kidney Disease", abbreviation: "PKD", severity: .high),
            BreedRisk(condition: "Brachycephalic Syndrome", abbreviation: "BOAS", severity: .medium),
        ],
        "scottish fold": [
            BreedRisk(condition: "Osteochondrodysplasia", abbreviation: "OCD", severity: .high),
            BreedRisk(condition: "Hypertrophic Cardiomyopathy", abbreviation: "HCM", severity: .medium),
        ],
        "sphynx": [
            BreedRisk(condition: "Hypertrophic Cardiomyopathy", abbreviation: "HCM", severity: .high),
        ],
        "bengal": [
            BreedRisk(condition: "Progressive Retinal Atrophy", abbreviation: "PRA", severity: .medium),
            BreedRisk(condition: "Hypertrophic Cardiomyopathy", abbreviation: "HCM", severity: .low),
        ],
        "siamese": [
            BreedRisk(condition: "Progressive Retinal Atrophy", abbreviation: "PRA", severity: .medium),
            BreedRisk(condition: "Asthma / Bronchial Disease", abbreviation: "ASTHMA", severity: .medium),
        ],
        "burmese": [
            BreedRisk(condition: "Hypertrophic Cardiomyopathy", abbreviation: "HCM", severity: .medium),
            BreedRisk(condition: "Hypokalaemia", abbreviation: "HK", severity: .medium),
        ],

        // ── DOGS ──────────────────────────────────────────────
        "labrador": [
            BreedRisk(condition: "Hip / Elbow Dysplasia", abbreviation: "HD/ED", severity: .high),
            BreedRisk(condition: "Exercise-Induced Collapse", abbreviation: "EIC", severity: .medium),
            BreedRisk(condition: "Progressive Retinal Atrophy", abbreviation: "PRA", severity: .medium),
        ],
        "golden retriever": [
            BreedRisk(condition: "Hip / Elbow Dysplasia", abbreviation: "HD/ED", severity: .high),
            BreedRisk(condition: "Haemangiosarcoma", abbreviation: "HSA", severity: .high),
            BreedRisk(condition: "Progressive Retinal Atrophy", abbreviation: "PRA", severity: .medium),
        ],
        "german shepherd": [
            BreedRisk(condition: "Hip / Elbow Dysplasia", abbreviation: "HD/ED", severity: .high),
            BreedRisk(condition: "Degenerative Myelopathy", abbreviation: "DM", severity: .high),
        ],
        "bulldog": [
            BreedRisk(condition: "Brachycephalic Obstructive Airway Syndrome", abbreviation: "BOAS", severity: .high),
            BreedRisk(condition: "Hip Dysplasia", abbreviation: "HD", severity: .medium),
            BreedRisk(condition: "Skin Fold Dermatitis", abbreviation: "SFD", severity: .medium),
        ],
        "french bulldog": [
            BreedRisk(condition: "Brachycephalic Obstructive Airway Syndrome", abbreviation: "BOAS", severity: .high),
            BreedRisk(condition: "Intervertebral Disc Disease", abbreviation: "IVDD", severity: .high),
        ],
        "pug": [
            BreedRisk(condition: "Brachycephalic Obstructive Airway Syndrome", abbreviation: "BOAS", severity: .high),
            BreedRisk(condition: "Pug Dog Encephalitis", abbreviation: "PDE", severity: .high),
        ],
        "poodle": [
            BreedRisk(condition: "Progressive Retinal Atrophy", abbreviation: "PRA", severity: .medium),
            BreedRisk(condition: "Addison's Disease", abbreviation: "AD", severity: .medium),
        ],
        "cavalier": [
            BreedRisk(condition: "Mitral Valve Disease", abbreviation: "MVD", severity: .high),
            BreedRisk(condition: "Syringomyelia", abbreviation: "SM", severity: .high),
        ],
        "dachshund": [
            BreedRisk(condition: "Intervertebral Disc Disease", abbreviation: "IVDD", severity: .high),
        ],
        "corgi": [
            BreedRisk(condition: "Intervertebral Disc Disease", abbreviation: "IVDD", severity: .high),
            BreedRisk(condition: "Progressive Retinal Atrophy", abbreviation: "PRA", severity: .medium),
        ],
        "rottweiler": [
            BreedRisk(condition: "Hip / Elbow Dysplasia", abbreviation: "HD/ED", severity: .high),
            BreedRisk(condition: "Osteosarcoma", abbreviation: "OSA", severity: .high),
        ],
        "great dane": [
            BreedRisk(condition: "Dilated Cardiomyopathy", abbreviation: "DCM", severity: .high),
            BreedRisk(condition: "Gastric Dilatation-Volvulus", abbreviation: "GDV", severity: .high),
            BreedRisk(condition: "Osteosarcoma", abbreviation: "OSA", severity: .high),
        ],
        "shiba inu": [
            BreedRisk(condition: "Allergies / Atopic Dermatitis", abbreviation: "ATOPY", severity: .medium),
        ],
        "samoyed": [
            BreedRisk(condition: "Samoyed Hereditary Glomerulopathy", abbreviation: "SHG", severity: .high),
            BreedRisk(condition: "Hip Dysplasia", abbreviation: "HD", severity: .medium),
        ],
        "border collie": [
            BreedRisk(condition: "Collie Eye Anomaly", abbreviation: "CEA", severity: .medium),
            BreedRisk(condition: "Progressive Retinal Atrophy", abbreviation: "PRA", severity: .medium),
        ],
    ]
}
