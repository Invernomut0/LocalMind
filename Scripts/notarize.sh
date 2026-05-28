#!/usr/bin/env bash
# Build, sign, notarize, and package LocalMind into a DMG ready for release.
#
# Requirements at runtime (CI provides these via secrets):
#   APPLE_NOTARY_API_KEY_BASE64  — App Store Connect API key (.p8) base64-encoded
#   APPLE_NOTARY_API_KEY_ID
#   APPLE_NOTARY_API_ISSUER_ID
#   APPLE_DEV_ID_APPLICATION     — Developer ID Application identity, e.g. "Developer ID Application: Name (TEAMID)"
#
# Outputs:
#   out/LocalMind-<version>.dmg
#
# This is a Sprint 7 deliverable. Sprint 0 ships only this stub so the release
# workflow can be wired up; the actual build pipeline (xcodebuild archive →
# exportArchive → create-dmg → notarytool submit → stapler staple) lands later.

set -euo pipefail

OUT_DIR="${OUT_DIR:-out}"
mkdir -p "$OUT_DIR"

echo "notarize.sh: placeholder. Sprint 7 implements the full pipeline."
exit 0
