#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Bootstrapping Hermes…"

if [[ ! -f "$ROOT_DIR/backend/.env" ]]; then
  echo "Creating backend/.env from backend/env.example"
  cp "$ROOT_DIR/backend/env.example" "$ROOT_DIR/backend/.env"
  echo "Edit backend/.env with your LiveKit Cloud credentials."
fi

echo "Installing backend deps…"
(cd "$ROOT_DIR/backend" && npm install)

echo "Done. Next:"
echo "- Start backend:   make backend-dev"
echo "- Open Xcode:      open client-macos/Hermes.xcodeproj"
