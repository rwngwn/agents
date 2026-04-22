#!/bin/bash
# Install SDLC agents for OpenCode
# Flattens all agent .md files from agents/**/ into ~/.config/opencode/agents/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DIR="$HOME/.config/opencode/agents"
COMMANDS_DIR="$HOME/.config/opencode/commands"
SKILLS_DIR="$HOME/.config/opencode/skills"
CONFIG_DIR="$HOME/.config/opencode"

# Create directories if needed
mkdir -p "$AGENTS_DIR"
mkdir -p "$COMMANDS_DIR"
mkdir -p "$SKILLS_DIR"

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

# Copy command files to commands dir
COMMAND_FILES=$(find "$SCRIPT_DIR/commands" -name "*.md" 2>/dev/null)
COMMAND_COUNT=$(echo "$COMMAND_FILES" | grep -c "." 2>/dev/null || true)

if [ "$COMMAND_COUNT" -gt 0 ]; then
  echo "Installing $COMMAND_COUNT command files to $COMMANDS_DIR/"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    cp "$f" "$COMMANDS_DIR/$(basename "$f")"
  done <<< "$COMMAND_FILES"
fi

# Copy AGENTS.md to config root
if [ -f "$SCRIPT_DIR/AGENTS.md" ]; then
  echo "Installing AGENTS.md to $CONFIG_DIR/"
  cp "$SCRIPT_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
fi

# Copy skills — preserve directory structure (SKILL.md + resources/)
if [ -d "$SCRIPT_DIR/skills" ]; then
  SKILL_DIRS=$(find "$SCRIPT_DIR/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  SKILL_COUNT=$(echo "$SKILL_DIRS" | grep -c "." 2>/dev/null || true)
  if [ "$SKILL_COUNT" -gt 0 ]; then
    echo "Installing $SKILL_COUNT skills to $SKILLS_DIR/"
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      skill_name=$(basename "$d")
      rm -rf "$SKILLS_DIR/$skill_name"
      cp -R "$d" "$SKILLS_DIR/$skill_name"
    done <<< "$SKILL_DIRS"
  fi
fi

echo ""
echo "Done. Installed $(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') agents to $AGENTS_DIR/"
echo "       Installed $(ls "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') commands to $COMMANDS_DIR/"
echo "       Installed $(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') skills to $SKILLS_DIR/"
echo "Restart OpenCode and press Tab to cycle through primary agents."
