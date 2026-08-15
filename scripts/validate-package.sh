#!/usr/bin/env bash

set -euo pipefail

fail() {
  echo "validation error: $*" >&2
  exit 1
}

[[ -f apm.yml ]] || fail "apm.yml is missing"
[[ -d .apm/agents ]] || fail ".apm/agents is missing"
[[ -d .apm/prompts ]] || fail ".apm/prompts is missing"
[[ -f .apm/skills/api-security-checklist/SKILL.md ]] || fail "API security skill is missing"

python3 - <<'PY'
from pathlib import Path

import yaml

for path in sorted(Path(".apm").rglob("*.md")):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit(f"validation error: {path} has no YAML frontmatter")
    try:
        frontmatter = yaml.safe_load(text.split("---", 2)[1])
    except yaml.YAMLError as exc:
        raise SystemExit(f"validation error: invalid frontmatter in {path}: {exc}") from exc
    if not isinstance(frontmatter, dict):
        raise SystemExit(f"validation error: frontmatter in {path} is not a mapping")
PY

agent_count="$(find .apm/agents -type f -name '*.agent.md' | wc -l | tr -d ' ')"
prompt_count="$(find .apm/prompts -type f -name '*.prompt.md' | wc -l | tr -d ' ')"
[[ "$agent_count" == "22" ]] || fail "expected 22 agents, found $agent_count"
[[ "$prompt_count" == "4" ]] || fail "expected 4 prompts, found $prompt_count"

if find .apm/agents -mindepth 2 -type f -name '*.agent.md' | rg -q .; then
  fail "agent files must be direct children of .apm/agents so apm pack includes them"
fi

while IFS= read -r path; do
  frontmatter="$(sed -n '2,/^---$/p' "$path")"
  rg -q '^name: .+' <<<"$frontmatter" || fail "$path has no name"
  rg -q '^description: .+' <<<"$frontmatter" || fail "$path has no description"
done < <(find .apm/agents -type f -name '*.agent.md' | sort)

if rg -n '^(model|temperature|tools):' .apm/agents; then
  fail "agent metadata contains a host-specific model, temperature, or tools field"
fi

if rg -n 'github-copilot/' .apm; then
  fail "package contains a GitHub Copilot model slug"
fi

if rg -n '^(agent|subtask|model):' .apm/prompts; then
  fail "prompt metadata contains a non-portable field"
fi

if rg -n '\$ARGUMENTS' .apm/prompts; then
  fail "prompt uses a host-specific argument placeholder"
fi

if find .apm -type f -name '*security-pre-reviewer*' | rg -q .; then
  fail "deprecated security-pre-reviewer is still packaged"
fi

echo "Validated $agent_count agents, $prompt_count prompts, and 1 skill."
