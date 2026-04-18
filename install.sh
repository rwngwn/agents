#!/bin/bash
# Install SDLC agents for OpenCode
# Flattens all agent .md files from agents/**/ into ~/.config/opencode/agents/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DIR="$HOME/.config/opencode/agents"
SKILLS_DIR="$HOME/.config/opencode/skills"
COMMANDS_DIR="$HOME/.config/opencode/commands"
CONFIG_DIR="$HOME/.config/opencode"

# Create directories if needed
mkdir -p "$AGENTS_DIR"
mkdir -p "$SKILLS_DIR"
mkdir -p "$COMMANDS_DIR"

# --- Agents ---
AGENT_FILES=$(find "$SCRIPT_DIR/agents" -name "*.md" 2>/dev/null)
AGENT_COUNT=$(echo "$AGENT_FILES" | grep -c "." || true)

if [ "$AGENT_COUNT" -eq 0 ]; then
  echo "Error: No agent .md files found under $SCRIPT_DIR/agents/"
  exit 1
fi

echo "Installing $AGENT_COUNT agent files to $AGENTS_DIR/"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  cp "$f" "$AGENTS_DIR/$(basename "$f")"
done <<< "$AGENT_FILES"

# --- Skills ---
# Each skill lives in skills/<name>/SKILL.md — preserve the subdirectory structure
if [ -d "$SCRIPT_DIR/skills" ]; then
  SKILL_DIRS=$(find "$SCRIPT_DIR/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  SKILL_COUNT=0
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    skill_name=$(basename "$d")
    mkdir -p "$SKILLS_DIR/$skill_name"
    cp "$d/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md"
    SKILL_COUNT=$((SKILL_COUNT + 1))
  done <<< "$SKILL_DIRS"
  echo "Installing $SKILL_COUNT skill(s) to $SKILLS_DIR/"
fi

# --- Commands ---
COMMAND_FILES=$(find "$SCRIPT_DIR/commands" -name "*.md" 2>/dev/null)
COMMAND_COUNT=$(echo "$COMMAND_FILES" | grep -c "." 2>/dev/null || true)

if [ "$COMMAND_COUNT" -gt 0 ]; then
  echo "Installing $COMMAND_COUNT command(s) to $COMMANDS_DIR/"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    cp "$f" "$COMMANDS_DIR/$(basename "$f")"
  done <<< "$COMMAND_FILES"
fi

# --- AGENTS.md ---
if [ -f "$SCRIPT_DIR/AGENTS.md" ]; then
  echo "Installing AGENTS.md to $CONFIG_DIR/"
  cp "$SCRIPT_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
fi

echo ""
echo "Done."
echo "  Agents:   $(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "  Skills:   $(ls "$SKILLS_DIR" 2>/dev/null | wc -l | tr -d ' ')"
echo "  Commands: $(ls "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "Restart OpenCode. Press Tab to cycle primary agents. Type /audit-security to run a full API security audit."
