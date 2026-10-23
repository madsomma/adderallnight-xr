#!/usr/bin/env bash
# Builds a release .app, ad-hoc signs it, zips it for a GitHub Release, prints the SHA-256.
#   ./scripts/release.sh            full release: dist/AdderAllNight XR.app + AdderAllNight-XR.zip + SHA-256
#   ./scripts/release.sh --no-zip   local bundle only: dist/AdderAllNight XR.app
# VERSION=1.2.3 stamps that version into the bundle's Info.plist.
set -euo pipefail

ZIP=1
[[ "${1:-}" == "--no-zip" ]] && ZIP=0

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCT="AdderAllNightXR"
APP_NAME="AdderAllNight XR"
DIST="$ROOT/dist"
APP_DIR="$DIST/$APP_NAME.app"
# No space in the zip name: GitHub rewrites spaces in release asset names to dots.
ZIP_PATH="$DIST/AdderAllNight-XR.zip"

cd "$ROOT"

echo "==> swift build -c release"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

echo "==> Assembling $APP_NAME.app"
rm -rf "$APP_DIR" "$ZIP_PATH"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BIN_DIR/$PRODUCT" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Info.plist" "$APP_DIR/Contents/Info.plist"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$ROOT/resources/app_icon/app_icon.icns" "$APP_DIR/Contents/Resources/app_icon.icns"

# Fail early if the bundle is misconfigured.
plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null
[[ "$(/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$APP_DIR/Contents/Info.plist")" == "true" ]] \
    || { echo "error: LSUIElement is not true" >&2; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_DIR/Contents/Info.plist")" == "$APP_NAME" ]] \
    || { echo "error: CFBundleExecutable does not match $APP_NAME" >&2; exit 1; }

# Optional: stamp the version from a tag (e.g. VERSION=1.2.3 ./scripts/release.sh)
if [[ -n "${VERSION:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_DIR/Contents/Info.plist"
fi

echo "==> Ad-hoc codesigning"
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

if [[ "$ZIP" -eq 0 ]]; then
    echo
    echo "App: $APP_DIR"
    exit 0
fi

echo "==> Zipping"
# ditto preserves the signature and bundle metadata (plain `zip` can break them).
ditto -c -k --norsrc --noextattr --keepParent "$APP_DIR" "$ZIP_PATH"

echo "==> SHA-256"
HASH="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
echo "$HASH  $(basename "$ZIP_PATH")"
echo
echo "Artifact: $ZIP_PATH"
