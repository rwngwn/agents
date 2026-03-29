#!/bin/bash
# Install SDLC agents for OpenCode
# Copies agent .md files and AGENTS.md to ~/.config/opencode/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DIR="$HOME/.config/opencode/agents"
CONFIG_DIR="$HOME/.config/opencode"

# Create directories if needed
mkdir -p "$AGENTS_DIR"

# Count agent files (exclude README, AGENTS.md, install.sh, .git)
AGENT_COUNT=$(ls "$SCRIPT_DIR"/*.md 2>/dev/null | grep -v README.md | grep -v AGENTS.md | wc -l | tr -d ' ')

if [ "$AGENT_COUNT" -eq 0 ]; then
  echo "Error: No agent .md files found in $SCRIPT_DIR"
  exit 1
fi

# Copy agent files
echo "Installing $AGENT_COUNT agent files to $AGENTS_DIR/"
for f in "$SCRIPT_DIR"/*.md; do
  basename="$(basename "$f")"
  # Skip non-agent files
  [ "$basename" = "README.md" ] && continue
  [ "$basename" = "AGENTS.md" ] && continue
  cp "$f" "$AGENTS_DIR/$basename"
done

# Copy AGENTS.md to config root
if [ -f "$SCRIPT_DIR/AGENTS.md" ]; then
  echo "Installing AGENTS.md to $CONFIG_DIR/"
  cp "$SCRIPT_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
fi

echo ""
echo "Done. Installed $(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') agents to $AGENTS_DIR/"
echo "Restart OpenCode and press Tab to cycle through primary agents."
