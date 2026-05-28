#!/usr/bin/env bash
# Assemble a local LocalMind.app from a SwiftPM build.
#
# This produces an unsigned development bundle that runs on the founder's
# machine. Codesigned + notarized release bundles come from Scripts/notarize.sh
# in Sprint 7. To run an unsigned bundle the first time, right-click → Open,
# or strip the quarantine attribute:
#   xattr -d com.apple.quarantine /Applications/LocalMind.app
#
# Usage:
#   Scripts/build-app.sh [debug|release]   (default: release)
#
# Output:
#   build/LocalMind.app

set -euo pipefail

CONFIG="${1:-release}"
case "$CONFIG" in
    debug|release) ;;
    *) echo "Usage: $0 [debug|release]"; exit 2 ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

BUNDLE_ID="app.localmind.LocalMind"
DISPLAY_NAME="LocalMind"
VERSION="0.2.6-alpha"
BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
MIN_MACOS="15.0"

APP_DIR="build/LocalMind.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
FRAMEWORKS_DIR="$CONTENTS/Frameworks"

echo "==> Building $CONFIG configuration"
swift build -c "$CONFIG"

BUILT_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
BINARY="$BUILT_DIR/LocalMindApp"
LLAMA_FRAMEWORK="$BUILT_DIR/llama.framework"

if [[ ! -x "$BINARY" ]]; then
    echo "error: built binary not found at $BINARY" >&2
    exit 1
fi
if [[ ! -d "$LLAMA_FRAMEWORK" ]]; then
    echo "error: llama.framework not found at $LLAMA_FRAMEWORK" >&2
    exit 1
fi

echo "==> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$CONTENTS/Resources"

cp "$BINARY" "$MACOS_DIR/LocalMind"
chmod +x "$MACOS_DIR/LocalMind"

# Copy llama.framework preserving the symlink structure SwiftPM emits.
ditto "$LLAMA_FRAMEWORK" "$FRAMEWORKS_DIR/llama.framework"

# Copy SwiftPM-generated resource bundles into Contents/Resources/. We can't
# use the .app root (SwiftPM's preferred location for Bundle.module) because
# macOS code signing rejects unsealed contents there. The code-side fallback
# in BundledModelCatalog locates these bundles via Bundle.main.url.
for spm_bundle in "$BUILT_DIR"/*.bundle; do
    [[ -d "$spm_bundle" ]] || continue
    bundle_name="$(basename "$spm_bundle")"
    echo "==> Copying resource bundle $bundle_name into Contents/Resources/"
    ditto "$spm_bundle" "$CONTENTS/Resources/$bundle_name"
done

# Point the binary's runtime search path at the bundled Frameworks/ directory.
# The binary already has @loader_path/llama.framework (from SPM's debug layout),
# so we add @loader_path/../Frameworks to cover the .app layout too.
install_name_tool -add_rpath "@loader_path/../Frameworks" "$MACOS_DIR/LocalMind" 2>/dev/null || true

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>${DISPLAY_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>LocalMind</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${DISPLAY_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>MIT license. See repository for source.</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS/PkgInfo"

# Ad-hoc codesign so the bundle launches without quarantine prompts in dev.
# Replaced by the Developer ID signature in Sprint 7's release.yml.
echo "==> Ad-hoc codesigning (dev only)"
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "==> Done. Bundle at: $APP_DIR"
echo "Run it with: open $APP_DIR"
