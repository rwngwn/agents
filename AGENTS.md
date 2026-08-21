# SDLC Agent System

This repository is the canonical Microsoft Agent Package Manager (APM) source
for an SDLC workflow that runs in Claude Code and OpenCode.

## Repository contract

- Author package primitives only under `.apm/`.
- Agent files live directly under `.apm/agents/` and end in `.agent.md`. Keep
  this directory flat so both installation and plugin packing include them.
- Prompt files live under `.apm/prompts/` and end in `.prompt.md`.
- Skills use `.apm/skills/<name>/SKILL.md`.
- Shared instructions use `.apm/instructions/*.instructions.md`.
- Do not commit deployed `.claude/` or `.opencode/` output to this package repo.
- Do not reintroduce provider-specific model slugs into shared agent metadata.
- Do not add a shared `tools` field: Claude Code and OpenCode require different
  YAML shapes. OpenCode permission boundaries belong in `permission`; Claude
  permissions belong in the consuming project's host configuration.

Run all package checks before claiming a change is complete:

```bash
bash scripts/validate-package.sh
apm compile --validate
apm compile --dry-run --target claude,opencode
apm pack --dry-run
```

## Architecture

There are 25 active agents: five primary entry points and 20 supporting agents.
Orchestrators delegate using the host's native subagent mechanism (`Agent` in
Claude Code, `Task` in OpenCode).

### Primary agents

| Agent | Purpose |
|---|---|
| `sdlc-plan` | Product intent → business slice → EARS/BDD → design/security → tasks |
| `sdlc-build` | Approved change → QA/TDD briefs → workers/reviewers → evidence |
| `debugger` | Logs/telemetry → root cause → traceable regression fix |
| `security-reviewer` | Threat-model context → parallel scan → remediation changes |
| `tech-storyteller` | Technical narrative and marketing content |

### Planning agents

| Agent | Purpose |
|---|---|
| `discovery` | Users, personas, competitors, journeys, and evidence |
| `strategist` | Strategic options, OKRs, PR/FAQ, and hypothesis |
| `pm-writer` | PRDs, feature specs, and product briefs |
| `change-spec-writer` | Business slices, EARS requirements, BDD, and evidence anchors |
| `system-architect` | Change design and canonical architecture/ADR/domain curation |

### Delivery agents

| Agent | Purpose |
|---|---|
| `spec` | Codebase analysis and implementation planning |
| `spec-tasks` | Mechanical Beads task creation after approval |
| `qa-strategist` | Test strategy, edge cases, and regression coverage |
| `architect` | Enriched Task Briefs with embedded security and quality gates |
| `builder-worker` | Implementation and verification from an approved brief |
| `builder-reviewer` | Independent correctness, security, and spec review |

`architect` is a design-time planner. It writes enriched briefs and exits.
`sdlc-build` is the runtime executor that dispatches worker/reviewer pipelines.
The old `security-pre-reviewer` is deprecated and removed; its checks are
embedded in `architect`.

### Security agents

`security-reviewer` dispatches these four scanners in parallel:

| Agent | Purpose |
|---|---|
| `secrets-scanner` | Credentials, tokens, keys, and suspicious secrets |
| `code-vuln-scanner` | OWASP, authorization, injection, crypto, and logic flaws |
| `deps-scanner` | CVEs, package age, integrity, and supply-chain risk |
| `config-scanner` | Headers, CORS, cookies, TLS, debug, and infrastructure config |

`threat-modeler` performs the separate design-time workflow for assets, flows,
trust boundaries, STRIDE threats, controls, validation, and residual-risk ownership.

### Standalone agents

| Agent | Purpose |
|---|---|
| `spec-archaeologist` | Reconstruct PRDs, designs, ADRs, and contracts from code |
| `spec-drift-detector` | Compare living specifications with current code |
| `tech-writer` | API docs, READMEs, migrations, and changelogs |
| `release-verifier` | Deployment identity, production scenarios, telemetry, rollback, and release evidence |

## Universal behavior

1. **Evidence before claims.** Run the relevant verification and report its
   observed output before declaring completion.
2. **Human-in-the-loop.** Stop at every marked approval gate.
3. **Canonical behavior gate.** Non-trivial changes require an approved
   `docs/changes/<issue-id>.md` with EARS requirements and BDD scenarios.
4. **Self-contained handoffs.** Include the goal, constraints, evidence,
   expected output, and verification in every delegation.
5. **Least privilege.** Respect the active agent's role and file boundaries.
6. **Portable vocabulary.** Say “host subagent delegation tool” and “host
   interactive question tool” in shared bodies when the native tool names differ.
7. **Optional Beads.** Mirror tasks when available; the repository change artifact
   remains canonical. Otherwise continue with Markdown briefs.
8. **Release evidence.** Merge is not verification. Only observed deployment and
   production evidence may advance a change to `verified`.

## Prompt contract

APM prompt frontmatter may use only portable keys such as `description`,
`input`, `allowed-tools`, `model`, and `argument-hint`. This package deliberately
omits `allowed-tools` and `model` for cross-host compatibility. Reference prompt
inputs as `${input:name}`; APM rewrites them for each target.
