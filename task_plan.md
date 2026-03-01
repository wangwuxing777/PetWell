# Task Plan: Scenario Comparison Feature

## Focus
Develop a new "By Scenario" comparison feature for pet insurance plans, featuring detailed real-world scenarios, cost breakdowns, and payout comparisons.

## Phases

### Phase 1: Planning (Status: `complete`)
- [x] Read `InsuranceCompareView.swift`.
- [x] Read `InsuranceModels.swift`.
- [x] Read `InsuranceService.swift`.
- [x] Create implementation plan.
- [x] Get user approval for the plan.

### Phase 2: Execution (Status: `complete`)
- [x] Create `ScenarioModels.swift` with `ScenarioResponse`, `Scenario`, `CostItem`, `Payout`.
- [x] Create `ScenarioService.swift`.
- [x] Update `InsuranceCompareView.swift` to introduce a toggle mechanism for Direct vs Scenario mode.
- [x] Implement `ScenarioCompareHomeView.swift`.
- [x] Implement `ScenarioDetailView.swift` with Charts and coverage visual cues.

### Phase 3: Verification (Status: `complete`)
- [x] Ensure project compiles cleanly.
- [x] Visually verify UI on Simulator/Previews.

### Phase 4: Redesign Scenario Compare (Status: `complete`)
- [x] Move 5 new images to `Assets.xcassets`.
- [x] Update `ScenarioCompareHomeView` with background images, transparency, description, and cost.
- [x] Slow down accordion animation.

### Phase 5: Additional Verification (Status: `complete`)
- [x] Compilation verify via xcodebuild.
- [x] Document walkthrough.

### Phase 7: Login Interface (Status: `complete`)
- [x] Create `LoginView.swift` with Phone/Email input.
- [x] Implement Google Sign-In button UI.
- [x] Create `AuthViewModel.swift`.

### Phase 8: Auth DB + Login Flow + Onboarding (Status: `complete`)
- [x] Backend: Create `AuthUser` model and `InitAuthDB` in `auth.go`.
- [x] Backend: Create `/api/auth/login` handler.
- [x] Backend: Seed 3 test accounts.
- [x] Backend: Register route in `main.go`.
- [x] Frontend: Connect `LoginView` to backend API.
- [x] Frontend: Wire login gate into `PetWellApp.swift`.
- [x] Frontend: Create `OnboardingView` with 5-step guide.
- [x] Verify end-to-end flow.
