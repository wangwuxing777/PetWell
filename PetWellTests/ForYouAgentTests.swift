//
//  ForYouAgentTests.swift
//  PetWellTests
//
//  Unit tests for the 5 ForYou local agents:
//    • AgeFilterAgent   (pure logic, no SwiftData)
//    • LargeDogAgent    (pure logic, no SwiftData)
//    • BreedRiskAgent   (pure logic, no SwiftData)
//    • HealthReportExtractor  (uses HealthReportModel @Model)
//    • ContextAssemblerAgent  (uses PetModel @Model)
//
//  Setup (one-time, Human Lead):
//    1. In Xcode → File → New → Target → Unit Testing Bundle
//    2. Name it "PetWellTests", Language Swift, ensure "Target to be Tested" = PetWell
//    3. Delete the default PetWellTests.swift that Xcode generates
//    4. Drag *this* file into the PetWellTests group in the Project Navigator
//    5. "Add to targets" ✓ PetWellTests
//    Run with: ⌘U or terminal command at bottom of TEST_PLAN_FOR_YOU.md
//

import XCTest
@testable import PetWell

// MARK: - Helpers

private extension InsuranceProduct {
    /// Minimal InsuranceProduct for testing (only minAge / maxAge matter for AgeFilterAgent).
    static func stub(id: Int = 1,
                     name: String = "Test Plan",
                     minAge: String? = nil,
                     maxAge: String? = nil) -> InsuranceProduct {
        InsuranceProduct(
            insuranceId: id,
            providerId: 1,
            insuranceName: name,
            insuranceNameZh: nil,
            remark: nil,
            remarkZh: nil,
            minAge: minAge,
            minAgeZh: nil,
            maxAge: maxAge,
            maxAgeZh: nil,
            coinsurance: nil,
            coinsuranceZh: nil,
            suitablePetType: nil,
            suitablePetTypeZh: nil,
            catBreedType: nil,
            catBreedTypeZh: nil,
            dogBreedType: nil,
            dogBreedTypeZh: nil,
            breedTypeRemark: nil,
            breedTypeRemarkZh: nil,
            paymentMode: nil,
            paymentModeZh: nil,
            waitingPeriod: nil,
            waitingPeriodZh: nil,
            informationLink: nil,
            informationLinkZh: nil,
            updateTime: nil,
            tag: nil,
            tagZh: nil
        )
    }
}

// MARK: - ================================================================
// MARK: AgeFilterAgent Tests
// MARK: ================================================================

final class AgeFilterAgentParseTests: XCTestCase {

    // ── parseToYears ────────────────────────────────────────────────────

    func test_parseYears_years() {
        XCTAssertEqual(AgeFilterAgent.parseToYears("11 years"), 11.0)
        XCTAssertEqual(AgeFilterAgent.parseToYears("1 year"),    1.0)
        XCTAssertEqual(AgeFilterAgent.parseToYears("0 years"),   0.0)
    }

    func test_parseYears_months() {
        XCTAssertEqual(AgeFilterAgent.parseToYears("6 months"),  6.0 / 12.0,  accuracy: 1e-9)
        XCTAssertEqual(AgeFilterAgent.parseToYears("12 months"), 12.0 / 12.0, accuracy: 1e-9)
        XCTAssertEqual(AgeFilterAgent.parseToYears("3 month"),   3.0 / 12.0,  accuracy: 1e-9)
    }

    func test_parseYears_weeks() {
        XCTAssertEqual(AgeFilterAgent.parseToYears("8 weeks"), 8.0 / 52.0,  accuracy: 1e-9)
        XCTAssertEqual(AgeFilterAgent.parseToYears("1 week"),  1.0 / 52.0,  accuracy: 1e-9)
    }

    func test_parseYears_noLimit_returnsNil() {
        XCTAssertNil(AgeFilterAgent.parseToYears("no limit"))
        XCTAssertNil(AgeFilterAgent.parseToYears("No Limit"))
        XCTAssertNil(AgeFilterAgent.parseToYears("no maximum"))
        XCTAssertNil(AgeFilterAgent.parseToYears("none"))
    }

    func test_parseYears_nilInput_returnsNil() {
        XCTAssertNil(AgeFilterAgent.parseToYears(nil))
    }

    func test_parseYears_emptyString_returnsNil() {
        XCTAssertNil(AgeFilterAgent.parseToYears(""))
        XCTAssertNil(AgeFilterAgent.parseToYears("   "))
    }

    func test_parseYears_unknownUnit_returnsNil() {
        XCTAssertNil(AgeFilterAgent.parseToYears("5 decades"))
        XCTAssertNil(AgeFilterAgent.parseToYears("2 days"))
    }

    func test_parseYears_missingNumber_returnsNil() {
        XCTAssertNil(AgeFilterAgent.parseToYears("years"))
        XCTAssertNil(AgeFilterAgent.parseToYears("old"))
    }
}

final class AgeFilterAgentFilterTests: XCTestCase {

    // ── filter ──────────────────────────────────────────────────────────

    func test_filter_petInRange_returnsProduct() {
        let product = InsuranceProduct.stub(minAge: "8 weeks", maxAge: "11 years")
        let result = AgeFilterAgent.filter(petAgeYears: 3, products: [product])
        XCTAssertEqual(result.count, 1)
    }

    func test_filter_petTooYoung_excludesProduct() {
        // minAge = 1 year, pet is 0 → should be excluded
        let product = InsuranceProduct.stub(minAge: "1 year", maxAge: nil)
        let result = AgeFilterAgent.filter(petAgeYears: 0, products: [product])
        XCTAssertTrue(result.isEmpty)
    }

    func test_filter_petTooOld_excludesProduct() {
        // maxAge = 5 years, pet is 6 → excluded
        let product = InsuranceProduct.stub(minAge: nil, maxAge: "5 years")
        let result = AgeFilterAgent.filter(petAgeYears: 6, products: [product])
        XCTAssertTrue(result.isEmpty)
    }

    func test_filter_noUpperLimit_eligibleWhenOld() {
        // maxAge = "no limit", pet is 15 → eligible
        let product = InsuranceProduct.stub(minAge: "8 weeks", maxAge: "no limit")
        let result = AgeFilterAgent.filter(petAgeYears: 15, products: [product])
        XCTAssertEqual(result.count, 1)
    }

    func test_filter_nilMaxAge_eligibleWhenOld() {
        let product = InsuranceProduct.stub(minAge: nil, maxAge: nil)
        let result = AgeFilterAgent.filter(petAgeYears: 20, products: [product])
        XCTAssertEqual(result.count, 1)
    }

    func test_filter_emptyProducts_returnsEmpty() {
        let result = AgeFilterAgent.filter(petAgeYears: 3, products: [])
        XCTAssertTrue(result.isEmpty)
    }

    func test_filter_returnsOnlyEligible() {
        let young  = InsuranceProduct.stub(id: 1, name: "Young Plan",  minAge: "8 weeks", maxAge: "3 years")
        let senior = InsuranceProduct.stub(id: 2, name: "Senior Plan", minAge: "6 years", maxAge: nil)
        let all    = InsuranceProduct.stub(id: 3, name: "All Ages",    minAge: nil,       maxAge: nil)
        // Pet is 5 years old: eligible for senior(no — min=6), all(yes), young(no — max=3)
        let result = AgeFilterAgent.filter(petAgeYears: 5, products: [young, senior, all])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.insuranceName, "All Ages")
    }

    func test_filter_exactBoundary_inclusive() {
        // maxAge = 11 years, pet is exactly 11 → eligible (≤ not <)
        let product = InsuranceProduct.stub(minAge: nil, maxAge: "11 years")
        XCTAssertEqual(AgeFilterAgent.filter(petAgeYears: 11, products: [product]).count, 1)
        // pet is 12 → excluded
        XCTAssertEqual(AgeFilterAgent.filter(petAgeYears: 12, products: [product]).count, 0)
    }
}

// MARK: - ================================================================
// MARK: LargeDogAgent Tests
// MARK: ================================================================

final class LargeDogAgentTests: XCTestCase {

    func test_largeDog_returnsTrueForKnownLargeBreed() {
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "Dog",    breed: "Labrador"))
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "Dog",    breed: "Golden Retriever"))
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "Dog",    breed: "German Shepherd"))
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "Dog",    breed: "Great Dane"))
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "Dog",    breed: "Rottweiler"))
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "Dog",    breed: "Siberian Husky"))
    }

    func test_largeDog_returnsFalseForSmallBreed() {
        XCTAssertFalse(LargeDogAgent.isLargeDog(species: "Dog", breed: "Chihuahua"))
        XCTAssertFalse(LargeDogAgent.isLargeDog(species: "Dog", breed: "Pomeranian"))
        XCTAssertFalse(LargeDogAgent.isLargeDog(species: "Dog", breed: "Shih Tzu"))
        XCTAssertFalse(LargeDogAgent.isLargeDog(species: "Dog", breed: "Corgi"))
    }

    func test_largeDog_returnsFalseForCatSpecies() {
        // Cats are never large dogs, even with a dog-sounding breed name
        XCTAssertFalse(LargeDogAgent.isLargeDog(species: "Cat",    breed: "Maine Coon"))
        XCTAssertFalse(LargeDogAgent.isLargeDog(species: "Cat",    breed: "Labrador"))  // absurd, but safe
        XCTAssertFalse(LargeDogAgent.isLargeDog(species: "Feline", breed: "Rottweiler"))
    }

    func test_largeDog_acceptsCanineSpecies() {
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "Canine", breed: "German Shepherd"))
    }

    func test_largeDog_caseInsensitive() {
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "DOG",  breed: "LABRADOR"))
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "dog",  breed: "rottweiler"))
    }

    func test_largeDog_hyphenatedBreedNormalized() {
        // "flat-coated retriever" → hyphen stripped → matches "flat-coated retriever" in list
        XCTAssertTrue(LargeDogAgent.isLargeDog(species: "Dog", breed: "flat-coated retriever"))
    }

    func test_largeDog_emptyBreed_returnsFalse() {
        XCTAssertFalse(LargeDogAgent.isLargeDog(species: "Dog", breed: ""))
    }
}

// MARK: - ================================================================
// MARK: BreedRiskAgent Tests
// MARK: ================================================================

final class BreedRiskAgentTests: XCTestCase {

    // ── risks(forBreed:) ─────────────────────────────────────────────

    func test_risks_knownCat_returnsCorrectConditions() {
        let risks = BreedRiskAgent.risks(forBreed: "Maine Coon")
        let abbrs = risks.map { $0.abbreviation }
        XCTAssertTrue(abbrs.contains("HCM"), "Maine Coon should have HCM risk")
        XCTAssertTrue(abbrs.contains("HD"),  "Maine Coon should have HD risk")
    }

    func test_risks_knownDog_returnsCorrectConditions() {
        let risks = BreedRiskAgent.risks(forBreed: "French Bulldog")
        let abbrs = risks.map { $0.abbreviation }
        XCTAssertTrue(abbrs.contains("BOAS"), "French Bulldog should have BOAS risk")
        XCTAssertTrue(abbrs.contains("IVDD"), "French Bulldog should have IVDD risk")
    }

    func test_risks_unknownBreed_returnsEmpty() {
        let risks = BreedRiskAgent.risks(forBreed: "Unknown Mix")
        XCTAssertTrue(risks.isEmpty)
    }

    func test_risks_caseInsensitive() {
        let upper = BreedRiskAgent.risks(forBreed: "LABRADOR")
        let lower = BreedRiskAgent.risks(forBreed: "labrador")
        let mixed = BreedRiskAgent.risks(forBreed: "Labrador")
        XCTAssertFalse(upper.isEmpty, "Case-insensitive match should work")
        XCTAssertEqual(upper.map { $0.abbreviation }, lower.map { $0.abbreviation })
        XCTAssertEqual(upper.map { $0.abbreviation }, mixed.map { $0.abbreviation })
    }

    func test_risks_partialMatch_golden() {
        // "Golden Retriever Mix" should match the "golden retriever" pattern
        let risks = BreedRiskAgent.risks(forBreed: "Golden Retriever Mix")
        XCTAssertFalse(risks.isEmpty, "Partial match should work for 'Golden Retriever Mix'")
    }

    func test_risks_allHaveNonEmptyFields() {
        // Sanity check: every populated breed entry should have valid data
        let breeds = ["Maine Coon", "Pug", "Cavalier King Charles Spaniel", "Dachshund", "Labrador"]
        for breed in breeds {
            let risks = BreedRiskAgent.risks(forBreed: breed)
            for risk in risks {
                XCTAssertFalse(risk.condition.isEmpty,    "\(breed): condition should not be empty")
                XCTAssertFalse(risk.abbreviation.isEmpty, "\(breed): abbreviation should not be empty")
            }
        }
    }

    // ── riskSummary(forBreed:) ────────────────────────────────────────

    func test_riskSummary_knownBreed_returnsNonNilString() {
        let summary = BreedRiskAgent.riskSummary(forBreed: "Maine Coon")
        XCTAssertNotNil(summary)
        XCTAssertFalse(summary!.isEmpty)
    }

    func test_riskSummary_unknownBreed_returnsNil() {
        let summary = BreedRiskAgent.riskSummary(forBreed: "Unknown Mix")
        XCTAssertNil(summary)
    }

    func test_riskSummary_containsAbbreviation() {
        let summary = BreedRiskAgent.riskSummary(forBreed: "Pug")
        XCTAssertNotNil(summary)
        XCTAssertTrue(summary!.contains("BOAS"), "Pug summary should mention BOAS")
    }
}

// MARK: - ================================================================
// MARK: HealthReportExtractor Tests
// MARK: ================================================================

final class HealthReportExtractorTests: XCTestCase {

    private let now = Date()

    /// Creates a HealthReportModel instance WITHOUT inserting into a SwiftData container.
    /// The @Model initializer works as a regular class init; properties are readable.
    private func makeReport(
        markdownContent: String,
        date: Date? = nil,
        category: String = "Checkup"
    ) -> HealthReportModel {
        HealthReportModel(
            date: date ?? now,
            category: category,
            markdownContent: markdownContent,
            originalFileType: "pdf",
            originalFileData: Data()
        )
    }

    func test_extract_emptyList_returnsNil() {
        XCTAssertNil(HealthReportExtractor.extract(from: []))
    }

    func test_extract_allEmptyContent_returnsNil() {
        let reports = [
            makeReport(markdownContent: ""),
            makeReport(markdownContent: "   "),
        ]
        XCTAssertNil(HealthReportExtractor.extract(from: reports))
    }

    func test_extract_singleReport_returnsFormattedString() {
        let report = makeReport(markdownContent: "Blood work normal. Weight stable.")
        let result = HealthReportExtractor.extract(from: [report])
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("Health Report 1"), "Should include label")
        XCTAssertTrue(result!.contains("Blood work normal"), "Should include content")
    }

    func test_extract_sortsNewestFirst() {
        let old   = makeReport(markdownContent: "OLD REPORT",  date: Date(timeIntervalSinceNow: -365 * 24 * 3600))
        let newer = makeReport(markdownContent: "NEWER REPORT", date: Date(timeIntervalSinceNow: -30 * 24 * 3600))
        let result = HealthReportExtractor.extract(from: [old, newer])!
        // The first report label should correspond to the newer content
        let firstLabelRange   = result.range(of: "[Health Report 1]")!
        let olderContentRange = result.range(of: "OLD REPORT")!
        let newerContentRange = result.range(of: "NEWER REPORT")!
        XCTAssertTrue(newerContentRange.lowerBound < olderContentRange.lowerBound,
                      "NEWER REPORT should appear before OLD REPORT in the output")
        XCTAssertTrue(firstLabelRange.lowerBound < newerContentRange.lowerBound,
                      "Health Report 1 label should precede NEWER REPORT content")
    }

    func test_extract_limitsToThreeReports() {
        let reports = (1...5).map { i in
            makeReport(markdownContent: "Report \(i)",
                       date: Date(timeIntervalSinceNow: -Double(i) * 86400))
        }
        let result = HealthReportExtractor.extract(from: reports)!
        XCTAssertTrue(result.contains("[Health Report 1]"), "Should have report 1")
        XCTAssertTrue(result.contains("[Health Report 2]"), "Should have report 2")
        XCTAssertTrue(result.contains("[Health Report 3]"), "Should have report 3")
        XCTAssertFalse(result.contains("[Health Report 4]"), "Should NOT have report 4 (limit=3)")
        XCTAssertFalse(result.contains("[Health Report 5]"), "Should NOT have report 5 (limit=3)")
    }

    func test_extract_truncatesLongContent() {
        let longText = String(repeating: "X", count: 800)  // 800 chars, limit is 400
        let result = HealthReportExtractor.extract(from: [makeReport(markdownContent: longText)])!
        // The total length of "XXXX..." in the result should be ≤ 400
        let xCount = result.filter { $0 == "X" }.count
        XCTAssertLessThanOrEqual(xCount, 400, "Content should be truncated to 400 chars")
    }

    func test_extract_multipleReports_separatedByDivider() {
        let r1 = makeReport(markdownContent: "First report",  date: Date(timeIntervalSinceNow: -1))
        let r2 = makeReport(markdownContent: "Second report", date: Date(timeIntervalSinceNow: -2))
        let result = HealthReportExtractor.extract(from: [r1, r2])!
        XCTAssertTrue(result.contains("---"), "Multiple reports should be separated by ---")
    }

    func test_extract_categoryIncludedInLabel() {
        let report = makeReport(markdownContent: "content", category: "Blood Test")
        let result = HealthReportExtractor.extract(from: [report])!
        XCTAssertTrue(result.contains("Blood Test"), "Category should appear in the label")
    }

    func test_extract_skipsEmptyReports_butIncludesNonEmpty() {
        let empty    = makeReport(markdownContent: "",      date: Date(timeIntervalSinceNow: -1))
        let nonEmpty = makeReport(markdownContent: "Valid", date: Date(timeIntervalSinceNow: -2))
        let result = HealthReportExtractor.extract(from: [empty, nonEmpty])
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("Valid"))
    }
}

// MARK: - ================================================================
// MARK: ContextAssemblerAgent Tests
// MARK: ================================================================

final class ContextAssemblerAgentTests: XCTestCase {

    /// Minimal PetModel for testing (no SwiftData container needed for read-only property access).
    private func makePet(
        name: String = "Buddy",
        species: String = "Dog",
        breed: String = "Labrador",
        birthYear: Int = 2020,
        weightKg: Double = 25.0,
        isNeutered: Bool = true,
        allergies: String = ""
    ) -> PetModel {
        PetModel(
            name: name,
            species: species,
            breed: breed,
            sex: "Male",
            birthYear: birthYear,
            avatarImageData: nil,
            weightKg: weightKg,
            isNeutered: isNeutered,
            microchipId: "",
            allergies: allergies,
            notes: ""
        )
    }

    private func buildContext(
        pet: PetModel? = nil,
        petAgeYears: Int = 4,
        eligibleCount: Int = 3,
        totalCount: Int = 5,
        breedRisks: [BreedRisk] = [],
        isLargeDog: Bool = false,
        clinicalSummary: String? = nil
    ) -> String {
        ContextAssemblerAgent.build(
            pet: pet ?? makePet(),
            petAgeYears: petAgeYears,
            eligibleCount: eligibleCount,
            totalCount: totalCount,
            breedRisks: breedRisks,
            isLargeDog: isLargeDog,
            clinicalSummary: clinicalSummary
        )
    }

    func test_build_containsPetName() {
        let ctx = buildContext(pet: makePet(name: "Whiskers"))
        XCTAssertTrue(ctx.contains("Whiskers"), "Context should include pet name")
    }

    func test_build_containsSpeciesAndBreed() {
        let ctx = buildContext(pet: makePet(species: "Cat", breed: "Persian"))
        XCTAssertTrue(ctx.contains("Cat"),    "Context should include species")
        XCTAssertTrue(ctx.contains("Persian"), "Context should include breed")
    }

    func test_build_containsAge() {
        let ctx = buildContext(petAgeYears: 7)
        XCTAssertTrue(ctx.contains("7 year"), "Context should include age")
    }

    func test_build_containsWeight() {
        let ctx = buildContext(pet: makePet(weightKg: 18.5))
        XCTAssertTrue(ctx.contains("18.5"), "Context should include weight")
    }

    func test_build_neuteredFlag() {
        let neuteredCtx   = buildContext(pet: makePet(isNeutered: true))
        let uneuteredCtx  = buildContext(pet: makePet(isNeutered: false))
        XCTAssertTrue(neuteredCtx.contains("Yes"),  "Neutered pet should show Yes")
        XCTAssertTrue(uneuteredCtx.contains("No"), "Unneutered pet should show No")
    }

    func test_build_containsEligibilityCount() {
        let ctx = buildContext(eligibleCount: 4, totalCount: 7)
        XCTAssertTrue(ctx.contains("4 of 7"), "Context should include eligibility count")
    }

    func test_build_withBreedRisks_containsConditionAbbreviations() {
        let risks = [
            BreedRisk(condition: "Mitral Valve Disease", abbreviation: "MVD", severity: .high),
            BreedRisk(condition: "Syringomyelia",        abbreviation: "SM",  severity: .high),
        ]
        let ctx = buildContext(breedRisks: risks)
        XCTAssertTrue(ctx.contains("MVD"),              "Context should mention MVD abbreviation")
        XCTAssertTrue(ctx.contains("Mitral Valve"),     "Context should mention full condition")
        XCTAssertTrue(ctx.contains("SM"),               "Context should mention SM abbreviation")
    }

    func test_build_noBreedRisks_showsFallbackText() {
        let ctx = buildContext(breedRisks: [])
        XCTAssertTrue(ctx.contains("No specific breed risks"), "No-risks fallback text should appear")
    }

    func test_build_largeDogFlag_includedWhenTrue() {
        let ctx = buildContext(isLargeDog: true)
        XCTAssertTrue(ctx.contains("third-party liability") ||
                      ctx.contains("Large Breed"),
                      "Large dog context should mention liability or Large Breed")
    }

    func test_build_largeDogFlag_notIncludedWhenFalse() {
        let ctx = buildContext(isLargeDog: false)
        XCTAssertFalse(ctx.contains("Large Breed Notice"),
                       "Non-large-dog context should NOT include Large Breed Notice")
    }

    func test_build_clinicalSummaryIncluded() {
        let summary = "Key finding: elevated ALT, possible liver inflammation."
        let ctx = buildContext(clinicalSummary: summary)
        XCTAssertTrue(ctx.contains(summary), "Context should embed the clinical summary verbatim")
    }

    func test_build_noClinicalSummary_showsFallbackText() {
        let ctx = buildContext(clinicalSummary: nil)
        XCTAssertTrue(ctx.contains("No health reports on file"),
                      "Context without medical data should show fallback text")
    }

    func test_build_allergiesIncluded_whenPresent() {
        let ctx = buildContext(pet: makePet(allergies: "chicken, dust mites"))
        XCTAssertTrue(ctx.contains("chicken, dust mites"), "Allergies should appear in context")
    }

    func test_build_allergiesNotShown_whenEmpty() {
        let ctx = buildContext(pet: makePet(allergies: ""))
        XCTAssertFalse(ctx.contains("Allergies:"), "Empty allergies should not produce Allergies: line")
    }

    func test_build_containsTaskInstruction() {
        let ctx = buildContext()
        XCTAssertTrue(ctx.contains("Task:"), "Context should always end with Task instruction")
        XCTAssertTrue(ctx.contains("Age eligibility"), "Task instruction should mention age eligibility")
    }

    func test_build_sectionsJoinedWithDoubleNewline() {
        // Sections are joined by "\n\n" — result must have multiple sections
        let ctx = buildContext()
        XCTAssertTrue(ctx.contains("\n\n"), "Context sections should be separated by double newline")
    }
}
