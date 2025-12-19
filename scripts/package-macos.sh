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
    CODE_SIGNING_ALLOWED=YES \
    | xcpretty
else
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'platform=macOS' \
    build \
    CODE_SIGNING_ALLOWED=YES
fi

echo "Resolving built .app path…"
BUILD_SETTINGS="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -showBuildSettings 2>/dev/null)"
# NOTE: awk '\b' is not a word-boundary in awk regex (it's a backspace). Use explicit key matching.
TARGET_BUILD_DIR="$(echo "$BUILD_SETTINGS" | awk -F' = ' '$1 ~ /^[[:space:]]*TARGET_BUILD_DIR$/ {print $2; exit}')"
WRAPPER_NAME="$(echo "$BUILD_SETTINGS" | awk -F' = ' '$1 ~ /^[[:space:]]*WRAPPER_NAME$/ {print $2; exit}')"

APP_PATH="$TARGET_BUILD_DIR/$WRAPPER_NAME"

if [[ -z "${TARGET_BUILD_DIR}" || -z "${WRAPPER_NAME}" ]]; then
  echo "ERROR: Could not resolve TARGET_BUILD_DIR/WRAPPER_NAME from xcodebuild settings." >&2
  echo "Refusing to package to avoid copying the wrong path." >&2
  exit 1
fi

if [[ "$APP_PATH" == "/" || "$APP_PATH" == "$HOME" || "$APP_PATH" == "" ]]; then
  echo "ERROR: Refusing to package unsafe path: '$APP_PATH'." >&2
  exit 1
fi

if [[ "$APP_PATH" != *.app ]]; then
  echo "ERROR: Resolved app path does not look like a .app bundle: '$APP_PATH'." >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: Could not find built app at: $APP_PATH" >&2
  echo "Try building once in Xcode (Release) and re-run this script." >&2
  exit 1
fi

OUT_APP="$DIST_DIR/$APP_NAME.app"
OUT_ZIP="$DIST_DIR/$APP_NAME-macos.zip"
OUT_DMG="$DIST_DIR/$APP_NAME-macos.dmg"
DMG_TEMP_DIR="$DIST_DIR/dmg-temp"

echo "[2/4] Copying .app to dist/…"
rm -rf "$OUT_APP" "$OUT_ZIP" "$OUT_DMG" "$DMG_TEMP_DIR"
cp -R "$APP_PATH" "$OUT_APP"

echo "[3/4] Creating zip…"
(cd "$DIST_DIR" && ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$APP_NAME-macos.zip")

echo "[4/4] Creating DMG…"
mkdir -p "$DMG_TEMP_DIR"
cp -R "$OUT_APP" "$DMG_TEMP_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# Calculate DMG size (app size + 100MB overhead)
APP_SIZE=$(du -sm "$OUT_APP" | cut -f1)
DMG_SIZE=$((APP_SIZE + 100))

# Create DMG
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$DMG_TEMP_DIR" \
  -ov -format UDZO \
  -fs HFS+ \
  -size "${DMG_SIZE}m" \
  "$OUT_DMG"

# Clean up temp directory
rm -rf "$DMG_TEMP_DIR"

echo ""
echo "✅ Done:"
echo "- $OUT_APP"
echo "- $OUT_ZIP"
echo "- $OUT_DMG"
echo ""
echo "Note: This build is signed if your Xcode signing is configured."
