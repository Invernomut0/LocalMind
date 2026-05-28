#!/usr/bin/env bash
# Rebuild the llama.cpp xcframework used by LocalMindCore.
#
# Run locally when the upstream llama.cpp commit changes; CI does not invoke
# this on every build to keep PR feedback fast — the resulting xcframework is
# attached to a GitHub Release and consumed via the package manifest.
#
# Sprint 1 implements this. Sprint 0 ships only the stub.

set -euo pipefail

echo "build-llama.sh: placeholder. Sprint 1 wires up the actual build."
exit 0
