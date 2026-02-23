# Findings & Decisions - 2026-02-11

## Research Findings
- **RAG Integration**: Successfully integrated a new `RAGService` in Swift to handle AI-powered chat queries.
- **UI Updates**: Implemented `RAGChatView` and integrated it into `InsuranceCompareView` via a sparkle icon/button.
- **Git State**: The repository was in a dirty state with several untracked files before the final push.

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| Integrated RAG in InsuranceCompareView | To provide users with AI-powered insurance comparison assistance. |
| Pushed to main directly | User requested a direct push to the main branch for current updates. |

## Resources
- `Services/RAGService.swift`
- `Views/Insurance/RAGChatView.swift`
- `Views/Insurance/InsuranceCompareView.swift`
- **Color Distinctions:** To prevent blending, Advanced Coverage metrics use a purple overlay instead of the standard blue used in Core Coverage.
- **Doodle UI Rotations:** Reduced hardcoded rotations (`rotation * 0.3` multiplier) inside `SketchCardModifier` because absolute values caused UI unbalance and exaggerated tilted appearance.
