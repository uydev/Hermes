#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Hermes"
SCHEME="Hermes"
PROJECT="$ROOT_DIR/client-macos/Hermes.xcodeproj"

mkdir -p "$DIST_DIR"

echo "[1/3] Building Release…"
if command -v xcpretty >/dev/null 2>&1; then
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'platform=macOS' \
    build \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty
else
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'platform=macOS' \
    build \
    CODE_SIGNING_ALLOWED=NO
fi

echo "Resolving built .app path…"
BUILD_SETTINGS="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -showBuildSettings 2>/dev/null)"
TARGET_BUILD_DIR="$(echo "$BUILD_SETTINGS" | awk -F' = ' '/\bTARGET_BUILD_DIR\b/ {print $2; exit}')"
WRAPPER_NAME="$(echo "$BUILD_SETTINGS" | awk -F' = ' '/\bWRAPPER_NAME\b/ {print $2; exit}')"

APP_PATH="$TARGET_BUILD_DIR/$WRAPPER_NAME"

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: Could not find built app at: $APP_PATH" >&2
  echo "Try building once in Xcode (Release) and re-run this script." >&2
  exit 1
fi

OUT_APP="$DIST_DIR/$APP_NAME.app"
OUT_ZIP="$DIST_DIR/$APP_NAME-macos.zip"

echo "[2/3] Copying .app to dist/…"
rm -rf "$OUT_APP" "$OUT_ZIP"
cp -R "$APP_PATH" "$OUT_APP"

echo "[3/3] Creating zip…"
(cd "$DIST_DIR" && ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$APP_NAME-macos.zip")

echo "Done:"
echo "- $OUT_APP"
echo "- $OUT_ZIP"

echo "Note: This build is unsigned (portfolio/demo)."
