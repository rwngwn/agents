#!/bin/bash
# Install SDLC agents for OpenCode
# Flattens all agent .md files from agents/**/ into ~/.config/opencode/agents/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DIR="$HOME/.config/opencode/agents"
CONFIG_DIR="$HOME/.config/opencode"

# Create directories if needed
mkdir -p "$AGENTS_DIR"

# Find all agent .md files under agents/ subdirectory
AGENT_FILES=$(find "$SCRIPT_DIR/agents" -name "*.md" 2>/dev/null)
AGENT_COUNT=$(echo "$AGENT_FILES" | grep -c "." || true)

if [ "$AGENT_COUNT" -eq 0 ]; then
  echo "Error: No agent .md files found under $SCRIPT_DIR/agents/"
  exit 1
fi

# Copy agent files — flatten into agents dir (filenames are unique across subdirs)
echo "Installing $AGENT_COUNT agent files to $AGENTS_DIR/"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  cp "$f" "$AGENTS_DIR/$(basename "$f")"
done <<< "$AGENT_FILES"

# Copy AGENTS.md to config root
if [ -f "$SCRIPT_DIR/AGENTS.md" ]; then
  echo "Installing AGENTS.md to $CONFIG_DIR/"
  cp "$SCRIPT_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
fi

echo ""
echo "Done. Installed $(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') agents to $AGENTS_DIR/"
echo "Restart OpenCode and press Tab to cycle through primary agents."
