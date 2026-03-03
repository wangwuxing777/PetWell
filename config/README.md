# Application Config

## Files
- `env.example`: committed template for local setup.
- `local.env`: machine-specific values (must stay untracked).

## Usage
1. `cp config/env.example config/local.env`
2. Fill keys in `config/local.env`.
3. Load it before local scripts if needed:
   `set -a; source config/local.env; set +a`

## Notes
- Current iOS code still contains some hardcoded values.
- This config folder is the new source-of-truth for future cleanup and CI.
