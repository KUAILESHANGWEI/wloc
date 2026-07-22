#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-${root_dir}/release-assets}"
mkdir -p "${output_dir}"

command -v shortcuts >/dev/null 2>&1 || {
  echo "Apple's shortcuts command is required; run this script on macOS." >&2
  exit 1
}

shortcuts sign --mode anyone \
  --input "${root_dir}/shortcuts/unsigned/WLOC-Set-Location.shortcut" \
  --output "${output_dir}/WLOC-Set-Location.shortcut"

shortcuts sign --mode anyone \
  --input "${root_dir}/shortcuts/unsigned/WLOC-Clear-Location.shortcut" \
  --output "${output_dir}/WLOC-Clear-Location.shortcut"

echo "Signed shortcuts written to ${output_dir}"
