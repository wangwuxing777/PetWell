import Foundation

// MARK: - AgeFilterAgent
// Filters InsuranceProduct list to those whose age range covers the pet's age.
// minAge / maxAge format examples: "8 weeks", "6 months", "11 years", "no limit"

enum AgeFilterAgent {

    // MARK: - Public API

    /// Returns products that are eligible for `petAgeYears`.
    static func filter(
        petAgeYears: Int,
        products: [InsuranceProduct]
    ) -> [InsuranceProduct] {
        products.filter { product in
            isEligible(petAgeYears: petAgeYears, product: product)
        }
    }

    // MARK: - Helpers

    private static func isEligible(petAgeYears: Int, product: InsuranceProduct) -> Bool {
        let petAgeDouble = Double(petAgeYears)
        let minYears = parseToYears(product.minAge) ?? 0.0
        let maxYears = parseToYears(product.maxAge)   // nil = no upper limit

        guard petAgeDouble >= minYears else { return false }
        if let max = maxYears, petAgeDouble > max { return false }
        return true
    }

    /// Converts age strings like "8 weeks", "6 months", "11 years", "no limit"
    /// into fractional years for comparison.  Returns nil for "no limit" / unparseable.
    static func parseToYears(_ raw: String?) -> Double? {
        guard let raw = raw?.trimmingCharacters(in: .whitespaces).lowercased(),
              !raw.isEmpty,
              raw != "no limit",
              raw != "no maximum",
              raw != "none"
        else { return nil }

        // Tokenise: expect "<number> <unit>"
        let parts = raw.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2, let value = Double(parts[0]) else { return nil }

        let unit = parts[1]
        switch true {
        case unit.hasPrefix("year"):  return value
        case unit.hasPrefix("month"): return value / 12.0
        case unit.hasPrefix("week"):  return value / 52.0
        default:                      return nil
        }
    }
}
