import Foundation

// MARK: - LargeDogAgent
// Determines whether a pet is a "large dog" per the HK Dangerous Dogs Ordinance:
// any dog exceeding 20 kg is classified as a large dog and typically requires
// third-party liability insurance coverage.

enum LargeDogAgent {

    // MARK: - Threshold

    /// HK Dangerous Dogs Ordinance: dogs over 20 kg are classified as large.
    static let largeWeightThresholdKg: Double = 20.0

    // MARK: - Public API

    /// Returns true if the pet is a dog AND weighs more than 20 kg.
    static func isLargeDog(species: String, weightKg: Double) -> Bool {
        guard species.lowercased().contains("dog") ||
              species.lowercased().contains("canine") else { return false }
        return weightKg > largeWeightThresholdKg
    }
}
