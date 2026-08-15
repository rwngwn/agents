#!/usr/bin/env bash

# Backward-compatible global installer. For project-scoped installs, run the
# `apm install rwngwn/agents ...` command from the target project instead.

set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS="${APM_TARGETS:-claude,opencode}"

if ! command -v apm >/dev/null 2>&1; then
  echo "APM is required. Install it from https://microsoft.github.io/apm/getting-started/installation/" >&2
  exit 1
fi

apm install "$PACKAGE_DIR" --global --target "$TARGETS" "$@"
apm compile --global

echo "Installed sdlc-agents globally for: $TARGETS"
echo "Restart Claude Code and/or OpenCode before first use."
