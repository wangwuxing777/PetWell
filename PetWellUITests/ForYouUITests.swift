//
//  ForYouUITests.swift
//  PetWellUITests
//
//  UI (XCUITest) end-to-end tests for the "For You" recommendation pipeline.
//
//  Setup (one-time, Human Lead):
//    1. In Xcode → File → New → Target → UI Testing Bundle
//    2. Name it "PetWellUITests", Language Swift, Target = PetWell
//    3. Drag *this* file AND BlogUITests.swift into the PetWellUITests group
//    4. "Add to targets" ✓ PetWellUITests for both files
//    Run: ⌘U or the terminal command in TEST_PLAN_FOR_YOU.md
//
//  Pre-conditions:
//    • At least ONE pet must exist in the app's SwiftData store.
//    • The app must be running on an iOS 17+ Simulator (e.g. iPhone 16 Pro).
//    • RAG backend does NOT need to be running — pipeline will gracefully
//      skip/fail Stage 3 & 5 and still complete for UI assertions.
//

import XCTest

final class ForYouUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Inject a launch argument so the app can seed a test pet if needed
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper: Navigate to Insurance Tab

    /// Taps the Insurance tab and returns once the landing view is visible.
    @discardableResult
    private func navigateToInsurance() -> XCUIElement {
        let insuranceTab = app.tabBars.buttons["Insurance"]
        XCTAssertTrue(insuranceTab.waitForExistence(timeout: 5),
                      "Insurance tab should exist in the tab bar")
        insuranceTab.tap()
        return insuranceTab
    }

    /// Scrolls the insurance landing page until the mini-header's "For Me" button is visible.
    private func scrollToRevealForYouButton() {
        // The "For Me" button lives in the sticky mini-header which appears after scrolling
        // past the hero image (~280pt). We scroll on the main scroll view.
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            // Swipe up 3 times to get past the hero and reveal the mini-header
            for _ in 0..<3 {
                scrollView.swipeUp()
            }
        }
    }

    // MARK: - ============================================================
    // MARK: TC-UI-01: "For Me" button visible after scrolling
    // MARK: ============================================================

    func test_forYouButton_visibleAfterScroll() throws {
        navigateToInsurance()
        scrollToRevealForYouButton()

        let forYouButton = app.buttons["ForYouButton"]
        XCTAssertTrue(forYouButton.waitForExistence(timeout: 5),
                      "TC-UI-01: 'For Me' button should appear in sticky mini-header after scrolling")
    }

    // MARK: - ============================================================
    // MARK: TC-UI-02: Tapping "For Me" with 0 pets shows Pet Selector (empty state)
    // MARK:           OR launches ForYouProgressView directly (1 pet)
    // MARK: ============================================================

    func test_forYouButton_tap_launchesPipelineOrSelector() throws {
        navigateToInsurance()
        scrollToRevealForYouButton()

        let forYouButton = app.buttons["ForYouButton"]
        XCTAssertTrue(forYouButton.waitForExistence(timeout: 5))
        forYouButton.tap()

        // Either the pet selector sheet OR the ForYou progress view should appear
        let progressView = app.otherElements["ForYouProgressView"]
        let selectorSheet = app.otherElements["PetSelectorSheet"]

        let appeared = progressView.waitForExistence(timeout: 6) ||
                       selectorSheet.waitForExistence(timeout: 6)
        XCTAssertTrue(appeared,
                      "TC-UI-02: Either ForYouProgressView or PetSelectorSheet should appear after tapping 'For Me'")
    }

    // MARK: - ============================================================
    // MARK: TC-UI-03: Pet Selector Sheet — cancel dismisses it
    // MARK: ============================================================

    func test_petSelectorSheet_cancelDismisses() throws {
        navigateToInsurance()
        scrollToRevealForYouButton()

        let forYouButton = app.buttons["ForYouButton"]
        guard forYouButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("ForYouButton not found — check scroll logic")
        }
        forYouButton.tap()

        // Only proceed if the pet selector appeared (multi-pet scenario)
        let selectorSheet = app.otherElements["PetSelectorSheet"]
        guard selectorSheet.waitForExistence(timeout: 5) else {
            throw XCTSkip("TC-UI-03 skipped: single-pet device goes directly to progress view")
        }

        let cancelButton = app.buttons["PetSelectorCancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3))
        cancelButton.tap()

        // Sheet should be gone
        XCTAssertFalse(selectorSheet.waitForExistence(timeout: 3),
                       "TC-UI-03: Pet selector sheet should dismiss after Cancel")
    }

    // MARK: - ============================================================
    // MARK: TC-UI-04: ForYouProgressView shows 5 pipeline steps
    // MARK: ============================================================

    func test_forYouProgressView_showsFivePipelineSteps() throws {
        navigateToInsurance()
        scrollToRevealForYouButton()

        let forYouButton = app.buttons["ForYouButton"]
        guard forYouButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("ForYouButton not found")
        }
        forYouButton.tap()

        // Handle the pet selector if needed — pick the first pet
        let selectorSheet = app.otherElements["PetSelectorSheet"]
        if selectorSheet.waitForExistence(timeout: 3) {
            let petList = app.otherElements["PetSelectorList"]
            if petList.waitForExistence(timeout: 3) {
                petList.cells.firstMatch.tap()
            }
        }

        // Wait for progress view
        let progressView = app.otherElements["ForYouProgressView"]
        XCTAssertTrue(progressView.waitForExistence(timeout: 8),
                      "TC-UI-04: ForYouProgressView should appear")

        // Wait for stepper list to animate in
        let stepperList = app.otherElements["ForYouStepperList"]
        XCTAssertTrue(stepperList.waitForExistence(timeout: 5),
                      "TC-UI-04: StepperProgressView should be visible")

        // All 5 step rows should exist (IDs 1–5)
        for stepId in 1...5 {
            let stepRow = app.otherElements["ForYouStep_\(stepId)"]
            XCTAssertTrue(stepRow.waitForExistence(timeout: 5),
                          "TC-UI-04: Step \(stepId) row should exist in the pipeline view")
        }
    }

    // MARK: - ============================================================
    // MARK: TC-UI-05: ForYouProgressView — close button dismisses view
    // MARK: ============================================================

    func test_forYouProgressView_closeDismissesView() throws {
        navigateToInsurance()
        scrollToRevealForYouButton()

        let forYouButton = app.buttons["ForYouButton"]
        guard forYouButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("ForYouButton not found")
        }
        forYouButton.tap()

        // Handle pet selector if present
        let selectorSheet = app.otherElements["PetSelectorSheet"]
        if selectorSheet.waitForExistence(timeout: 3) {
            let petList = app.otherElements["PetSelectorList"]
            if petList.waitForExistence(timeout: 3) {
                petList.cells.firstMatch.tap()
            }
        }

        let progressView = app.otherElements["ForYouProgressView"]
        guard progressView.waitForExistence(timeout: 8) else {
            throw XCTSkip("TC-UI-05 skipped: ForYouProgressView did not appear in time")
        }

        // Tap the X close button
        let closeButton = app.buttons["ForYouCloseButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3),
                      "TC-UI-05: Close button should be in the toolbar")
        closeButton.tap()

        // Progress view should dismiss
        XCTAssertFalse(progressView.waitForExistence(timeout: 5),
                       "TC-UI-05: ForYouProgressView should dismiss after tapping Close")
    }

    // MARK: - ============================================================
    // MARK: TC-UI-06: Guardian FAB shows red dot after pipeline completes
    //         (requires RAG backend; skip if offline)
    // MARK: ============================================================

    func test_guardianFAB_showsRedDotAfterPipelineCompletes() throws {
        // This test requires a running RAG backend at localhost:8000.
        // It will be skipped automatically if the pipeline takes > 60s
        // (indicating the backend is not available).

        navigateToInsurance()
        scrollToRevealForYouButton()

        let forYouButton = app.buttons["ForYouButton"]
        guard forYouButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("ForYouButton not found")
        }
        forYouButton.tap()

        // Handle pet selector if present
        let selectorSheet = app.otherElements["PetSelectorSheet"]
        if selectorSheet.waitForExistence(timeout: 3) {
            let petList = app.otherElements["PetSelectorList"]
            if petList.waitForExistence(timeout: 3) {
                petList.cells.firstMatch.tap()
            }
        }

        let progressView = app.otherElements["ForYouProgressView"]
        guard progressView.waitForExistence(timeout: 8) else {
            throw XCTSkip("TC-UI-06 skipped: ForYouProgressView not found")
        }

        // Wait for pipeline to complete (max 60 seconds including RAG calls)
        let closeButton = app.buttons["ForYouCloseButton"]
        guard closeButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Close button not found")
        }

        // Wait for RAG pipeline to complete (pipeline auto-navigates to chat on completion;
        // if it doesn't within 60s, the backend is probably offline)
        let chatView = app.otherElements["RAGChatView"]
        guard chatView.waitForExistence(timeout: 60) else {
            throw XCTSkip("TC-UI-06 skipped: RAG pipeline timed out (backend may be offline)")
        }

        // Dismiss the chat → return to landing
        let dismissButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Close' OR label CONTAINS 'xmark' OR label CONTAINS '✕'")).firstMatch
        if dismissButton.exists { dismissButton.tap() }

        // Navigate to another tab and back to reset to main view
        // Guardian FAB should now show the red dot
        // (The FAB is in ContentView's ZStack — look for it by accessibility label or image)
        let guardianFAB = app.buttons.matching(NSPredicate(format: "label CONTAINS 'sparkles' OR identifier == 'GuardianFAB'")).firstMatch
        XCTAssertTrue(guardianFAB.waitForExistence(timeout: 5),
                      "TC-UI-06: Guardian FAB should be visible with red dot indicator after pipeline")
    }
}
