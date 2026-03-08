import Foundation

// MARK: - LargeDogAgent
// Detects whether a pet is a "large dog" based on its species + breed name.
// Large dogs typically need third-party liability insurance (e.g. HK laws).

enum LargeDogAgent {

    // MARK: - Public API

    /// Returns true if the pet qualifies as a large/giant breed dog.
    static func isLargeDog(species: String, breed: String) -> Bool {
        guard species.lowercased().contains("dog") ||
              species.lowercased().contains("canine") else { return false }

        let normalised = breed.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)

        return largeDogBreeds.contains(where: { normalised.contains($0) })
    }

    // MARK: - Breed List

    // Recognised large / giant dog breeds.
    // Source: general veterinary / HK Dangerous Dogs Ordinance + popular large breeds.
    private static let largeDogBreeds: [String] = [
        // Giant breeds
        "great dane", "saint bernard", "mastiff", "neapolitan mastiff", "tibetan mastiff",
        "great pyrenees", "newfoundland", "leonberger", "irish wolfhound", "scottish deerhound",
        "anatolian shepherd", "kangal", "caucasian shepherd", "boerboel",

        // Large working / sport breeds
        "rottweiler", "german shepherd", "belgian malinois", "doberman", "dobermann",
        "labrador", "golden retriever", "flat-coated retriever", "curly-coated retriever",
        "standard poodle", "weimaraner", "vizsla", "rhodesian ridgeback",
        "boxer", "bernese mountain dog", "greater swiss mountain dog",
        "alaskan malamute", "siberian husky", "samoyed",
        "belgian shepherd", "bouvier des flandres", "briard",

        // HK Dangerous Dogs Ordinance restricted breeds
        "pit bull", "american pit bull", "american staffordshire", "staffordshire bull",
        "japanese tosa", "dogo argentino", "fila brasileiro",

        // Large hound / scenthound
        "bloodhound", "coonhound", "greyhound", "irish setter", "gordon setter",
        "english setter", "clumber spaniel",

        // Giant mixed / cross
        "great dane mix", "mastiff mix", "malinois mix",
    ]
}
