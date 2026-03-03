#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_FILE="$ROOT_DIR/config/env.example"
LOCAL_FILE="$ROOT_DIR/config/local.env"

if [[ ! -f "$EXAMPLE_FILE" ]]; then
  echo "[verify] Missing $EXAMPLE_FILE"
  exit 1
fi

if [[ ! -f "$LOCAL_FILE" ]]; then
  echo "[verify] Missing $LOCAL_FILE"
  echo "[verify] Run: cp config/env.example config/local.env"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$LOCAL_FILE"
set +a

required_vars=(
  APP_BACKEND_BASE_URL
  MERCHANT_BACKEND_BASE_URL
  GOOGLE_MAPS_IOS_API_KEY
  SHOPIFY_SHOP_DOMAIN
  SHOPIFY_STOREFRONT_TOKEN
  MINIMAX_API_KEY
)

for key in "${required_vars[@]}"; do
  value="${!key:-}"
  if [[ -z "$value" ]]; then
    echo "[verify] Required var is empty: $key"
    exit 1
  fi
  if [[ "$value" == REPLACE_WITH_* ]]; then
    echo "[verify] Placeholder not replaced: $key"
    exit 1
  fi
done

echo "[verify] Environment looks good."
