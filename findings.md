# Findings

- **Models**: Currently exist under `Models/InsuranceModels.swift`. We should introduce the `Scenario` models in a designated file `Models/ScenarioModels.swift`.
- **Services**: The insurance data is managed by `InsuranceService.swift`. The `/scenarios` endpoint should be handled similarly by a `ScenarioService.swift` or an extension of `InsuranceService`.
- **Compare View**: The existing `Views/Insurance/InsuranceCompareView.swift` has a solid foundation. We need to introduce a generic selection state (e.g. `compareMode`) using a Segmented Picker (`By Insurance`, `By Scenario`) to conditionally render the current structure vs the newly proposed `ScenarioCompareHomeView`.
