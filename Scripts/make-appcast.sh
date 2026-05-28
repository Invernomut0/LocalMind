#!/usr/bin/env bash
# Generate or update the Sparkle appcast for the current release.
#
# Expects:
#   - A signed, notarized, stapled DMG in $OUT_DIR.
#   - SPARKLE_EDDSA_PRIV_PEM env var with the EdDSA private key (CI secret).
#
# Sprint 7 implements this. Sprint 0 ships only the stub.

set -euo pipefail

OUT_DIR="${OUT_DIR:-out}"
mkdir -p "$OUT_DIR"

echo "make-appcast.sh: placeholder. Sprint 7 wires up the actual appcast generation."
exit 0
