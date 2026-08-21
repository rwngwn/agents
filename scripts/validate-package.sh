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
[[ -f .apm/instructions/artifact-contract.instructions.md ]] || fail "AISDLC artifact contract is missing"
[[ -f .apm/agents/change-spec-writer.agent.md ]] || fail "change-spec-writer is missing"
[[ -f .apm/agents/threat-modeler.agent.md ]] || fail "threat-modeler is missing"
[[ -f .apm/agents/release-verifier.agent.md ]] || fail "release-verifier is missing"

python3 - <<'PY'
from pathlib import Path
import re

import yaml

frontmatters = {}
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
    frontmatters[path] = frontmatter

agent_paths = sorted(Path(".apm/agents").glob("*.agent.md"))
agent_names = {}
for path in agent_paths:
    name = frontmatters[path].get("name")
    if not isinstance(name, str) or not name:
        raise SystemExit(f"validation error: {path} has no agent name")
    if name in agent_names:
        raise SystemExit(
            f"validation error: duplicate agent name {name!r} in {agent_names[name]} and {path}"
        )
    agent_names[name] = path

host_builtin_agents = {"explore"}
for path in agent_paths:
    task_permissions = (
        frontmatters[path].get("permission", {}).get("task", {})
    )
    if not isinstance(task_permissions, dict):
        continue
    for delegated_name in task_permissions:
        if delegated_name == "*" or delegated_name in host_builtin_agents:
            continue
        if delegated_name not in agent_names:
            raise SystemExit(
                f"validation error: {path} delegates to missing agent {delegated_name!r}"
            )

for path in sorted(Path(".apm/prompts").glob("*.prompt.md")):
    body = path.read_text(encoding="utf-8").split("---", 2)[2]
    for delegated_name in re.findall(r"to the `([^`]+)` agent", body):
        if delegated_name not in agent_names:
            raise SystemExit(
                f"validation error: {path} delegates to missing agent {delegated_name!r}"
            )
PY

agent_count="$(find .apm/agents -type f -name '*.agent.md' | wc -l | tr -d ' ')"
prompt_count="$(find .apm/prompts -type f -name '*.prompt.md' | wc -l | tr -d ' ')"
instruction_count="$(find .apm/instructions -type f -name '*.instructions.md' | wc -l | tr -d ' ')"
[[ "$agent_count" == "25" ]] || fail "expected 25 agents, found $agent_count"
[[ "$prompt_count" == "7" ]] || fail "expected 7 prompts, found $prompt_count"
[[ "$instruction_count" == "2" ]] || fail "expected 2 instruction files, found $instruction_count"

if find .apm/agents -mindepth 2 -type f -name '*.agent.md' | grep -q .; then
  fail "agent files must be direct children of .apm/agents so apm pack includes them"
fi

while IFS= read -r path; do
  frontmatter="$(sed -n '2,/^---$/p' "$path")"
  grep -Eq '^name: .+' <<<"$frontmatter" || fail "$path has no name"
  grep -Eq '^description: .+' <<<"$frontmatter" || fail "$path has no description"
done < <(find .apm/agents -type f -name '*.agent.md' | sort)

if grep -R -n -E --include='*.agent.md' '^(model|temperature|tools):' .apm/agents; then
  fail "agent metadata contains a host-specific model, temperature, or tools field"
fi

if grep -R -n 'github-copilot/' .apm; then
  fail "package contains a GitHub Copilot model slug"
fi

if grep -R -n -E --include='*.prompt.md' '^(agent|subtask|model):' .apm/prompts; then
  fail "prompt metadata contains a non-portable field"
fi

if grep -R -n --include='*.prompt.md' '\$ARGUMENTS' .apm/prompts; then
  fail "prompt uses a host-specific argument placeholder"
fi

if find .apm -type f -name '*security-pre-reviewer*' | grep -q .; then
  fail "deprecated security-pre-reviewer is still packaged"
fi

if grep -R -n 'docs/prd-' .apm/agents/pm-writer.agent.md; then
  fail "pm-writer still uses the obsolete docs/prd-* path"
fi

if grep -R -n 'docs/specs/' \
  .apm/agents/spec-archaeologist.agent.md \
  .apm/prompts/spec-archaeology.prompt.md; then
  fail "spec archaeology still writes the obsolete docs/specs/ taxonomy"
fi

for path in \
  .apm/agents/sdlc-plan.agent.md \
  .apm/agents/sdlc-build.agent.md \
  .apm/agents/spec.agent.md \
  .apm/agents/builder-reviewer.agent.md; do
  grep -q 'docs/changes/<issue-id>.md' "$path" || fail "$path does not reference the canonical change artifact"
done

echo "Validated $agent_count agents, $prompt_count prompts, $instruction_count instructions, and 1 skill."
