# Application Data Policy

## Commit these
- fixture/seed inputs (CSV/JSON/SQL scripts)
- config templates (`config/env.example`)
- setup docs/scripts

## Do not commit these
- real API keys / local env files
- runtime databases and local caches
- machine-specific build artifacts/logs

## Team testing guideline
- Share deterministic fixture files in git.
- Recreate local runtime DB from fixtures/scripts instead of sharing ad-hoc local DB snapshots.
