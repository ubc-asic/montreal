#!/usr/bin/env bash
# Installs volare (if needed) and enables the SKY130 PDK version pinned in
# flows/common.mk. Run this once per machine before `make area`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMON_MK="$REPO_ROOT/flows/common.mk"

PDK_VERSION="$(grep -oP 'PDK_VERSION\s*\?=\s*\K\S+' "$COMMON_MK")"
if [ -z "$PDK_VERSION" ]; then
  echo "error: could not read PDK_VERSION from $COMMON_MK" >&2
  exit 1
fi

if ! command -v volare >/dev/null 2>&1; then
  echo "volare not found on PATH, installing via pipx..."
  if ! command -v pipx >/dev/null 2>&1; then
    echo "pipx not found, installing via apt..."
    sudo apt-get update && sudo apt-get install -y pipx
  fi
  pipx install volare
  pipx ensurepath
  echo
  echo "volare installed. Open a new shell (or 'source ~/.bashrc') so the"
  echo "updated PATH takes effect, then re-run this script."
  exit 0
fi

echo "Enabling SKY130 PDK version $PDK_VERSION (this downloads several hundred MB)..."
volare enable --pdk sky130 "$PDK_VERSION"

echo
echo "Done. PDK_ROOT resolves to:"
volare path --pdk sky130 "$PDK_VERSION"
