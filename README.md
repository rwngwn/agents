# SDLC agents for Claude Code and OpenCode

An [Agent Package Manager (APM)](https://microsoft.github.io/apm/) package with
25 agents, seven slash commands, and an API security skill for a traceable
AI-native lifecycle from product intent through production verification.

The package uses one canonical `.apm/` source tree and installs native files for
both [Claude Code](https://code.claude.com/docs/en/sub-agents) and
[OpenCode](https://opencode.ai/docs/agents/).

## Install

Install [Microsoft APM](https://microsoft.github.io/apm/getting-started/installation/),
then run these commands from the project where you want to use the agents:

```bash
# Only needed when the project does not already have apm.yml
apm init --yes

apm install rwngwn/agents --target claude,opencode
apm compile --target claude,opencode
```

Install for only one host by using `--target claude` or `--target opencode`.
For a user-wide installation:

```bash
apm install rwngwn/agents --global --target claude,opencode
apm compile --global
```

The legacy `./install.sh` entry point remains available and performs the same
global dual-target installation through APM. Restart Claude Code or OpenCode
after the first install so it discovers the new agents and commands.

APM deploys the package to each host's native locations:

| Primitive | Claude Code | OpenCode |
|---|---|---|
| Agents | `.claude/agents/` | `.opencode/agents/` |
| Commands | `.claude/commands/` | `.opencode/commands/` |
| Skills | `.claude/skills/` | `.agents/skills/` |
| Instructions | `.claude/rules/` | `AGENTS.md` after `apm compile` |

## Use

In Claude Code, start directly with a primary agent:

```bash
claude --agent sdlc-plan
```

Inside a Claude Code session, agents can also be selected with names such as
`@agent-sdlc-plan`. In OpenCode, press Tab to cycle through primary agents or
use its agent selector. Slash commands work in both hosts:

| Command | Purpose |
|---|---|
| `/change-spec <context>` | Create an approved business-slice artifact with EARS and BDD |
| `/threat-model <change>` | Model trust boundaries, threats, controls, and residual risk |
| `/audit-security [scope]` | Run the four security scanners and consolidate findings |
| `/release-verify <change>` | Record deployment and observed production verification |
| `/spec-archaeology [options]` | Reverse-engineer specs from an existing codebase |
| `/spec-drift [scope]` | Compare living specs with the implementation |
| `/strategist <idea>` | Produce strategic bets, OKRs, a PR/FAQ, and a founding hypothesis |

## Architecture

The five primary agents are entry points. They delegate to 20 focused agents
using the host's native subagent mechanism (`Agent` in Claude Code, `Task` in
OpenCode).

| Primary agent | Workflow |
|---|---|
| `sdlc-plan` | Idea → product intent → business slice → EARS/BDD → design/security → tasks |
| `sdlc-build` | Approved change → QA/TDD briefs → worker/reviewer → evidence |
| `debugger` | Report/logs/telemetry → root cause → traceable regression fix |
| `security-reviewer` | Threat-model context → four scanners → remediation changes |
| `tech-storyteller` | Technical blog posts, explainers, case studies, and launch narratives |

Supporting agents:

| Area | Agents |
|---|---|
| Product and behavior | `discovery`, `strategist`, `pm-writer`, `change-spec-writer`, `system-architect` |
| Delivery | `spec`, `spec-tasks`, `qa-strategist`, `architect`, `builder-worker`, `builder-reviewer` |
| Security | `threat-modeler`, `secrets-scanner`, `code-vuln-scanner`, `deps-scanner`, `config-scanner` |
| Release and maintenance | `release-verifier`, `spec-archaeologist`, `spec-drift-detector`, `tech-writer` |

The deprecated `security-pre-reviewer` is intentionally not packaged. Its
security and quality gates are embedded in `architect`.

## AISDLC artifact contract

The workflow deliberately separates durable repository intent, executable
artifacts, external evidence, and ephemeral agent handoffs.

```text
docs/
├── product/<product-or-capability>.md
├── changes/<issue-id>.md
├── adr/ADR-NNNN-<slug>.md
├── architecture/model.likec4
├── domain/{glossary.md,invariants.md,model.mmd}
└── security/threat-model.md
```

`docs/changes/<issue-id>.md` is the control artifact for one independently
valuable business slice. It contains Why, Scope, EARS requirements, BDD
scenarios, design triggers, plan, traceability, and evidence anchors.

Tests, native API/event schemas, migrations, infrastructure, and application
code remain executable artifacts. Jira/GitHub/Beads work items, pull requests,
CI/e2e runs, security scans, deployments, production verification, and risk
acceptance remain external records linked from the change artifact. Shared
context, Task Briefs, Worker Summaries, Review Verdicts, and drift reports are
ephemeral handoffs rather than competing sources of truth.

The end-to-end flow is:

```text
Discovery → product intent → business slice → EARS → BDD → triggered design and
threat model → TDD implementation → independent review → CI/security evidence →
deployment → production verification → drift/maintenance
```

Human approval is required at product, behavior, design/security, remediation,
and production-mutation gates. Merge alone never marks a change verified.

## Cross-host compatibility

The source agents declare a portable `name` and `description`, plus OpenCode's
`mode`, `hidden`, and fine-grained `permission` map. Claude Code ignores the
OpenCode-only metadata and uses the same Markdown body.

Model IDs are deliberately not pinned. A GitHub Copilot model slug is not a
valid Claude Code model identifier, and a Claude alias is not guaranteed to be
valid in OpenCode. Each host therefore uses its configured/default model.

The shared source also omits a `tools` field because Claude Code and OpenCode
expect incompatible YAML shapes for tool allow-lists. OpenCode continues to
enforce each agent's `permission` map. Claude Code agents inherit session tools;
apply stricter Claude permissions in the consuming project when required.

## Beads is optional

Several workflows can mirror task briefs with
[Beads](https://github.com/steveyegge/beads). If `bd` is unavailable, agents
must continue with an explicit Markdown handoff and report that the task was not
persisted. The repository change artifact stays canonical either way.

## Package layout

```text
apm.yml
.apm/
  agents/          # 25 flat .agent.md files; logical groups are documented above
  prompts/         # 7 cross-host slash commands
  instructions/    # operating principles and canonical artifact contract
  skills/          # API security checklist
scripts/
  validate-package.sh
```

APM agents use the `.agent.md` convention, prompts use `.prompt.md`, and skills
use the Agent Skills `SKILL.md` convention. See APM's
[package anatomy](https://microsoft.github.io/apm/concepts/package-anatomy/) and
[primitives/targets matrix](https://microsoft.github.io/apm/concepts/primitives-and-targets/).

## Validate changes

```bash
bash scripts/validate-package.sh
apm compile --validate
apm compile --dry-run --target claude,opencode
apm pack --dry-run
```

The same checks run in GitHub Actions.

## License

[MIT](LICENSE)
