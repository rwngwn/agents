# SDLC agents for Claude Code and OpenCode

An [Agent Package Manager (APM)](https://microsoft.github.io/apm/) package with
22 agents, four slash commands, and an API security skill for planning,
implementation, debugging, documentation, and security review.

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
| `/audit-security [scope]` | Run the four security scanners and consolidate findings |
| `/spec-archaeology [options]` | Reverse-engineer specs from an existing codebase |
| `/spec-drift [scope]` | Compare living specs with the implementation |
| `/strategist <idea>` | Produce strategic bets, OKRs, a PR/FAQ, and a founding hypothesis |

## Architecture

The five primary agents are entry points. They delegate to 17 focused agents
using the host's native subagent mechanism (`Agent` in Claude Code, `Task` in
OpenCode).

| Primary agent | Workflow |
|---|---|
| `sdlc-plan` | Idea → discovery → strategy → PRD → technical design → task handoff |
| `sdlc-build` | Scope → optional QA plan → task briefs → worker/reviewer pipelines |
| `debugger` | Evidence gathering → root cause → approved fix route |
| `security-reviewer` | Four parallel scanners → consolidated report → remediation route |
| `tech-storyteller` | Technical blog posts, explainers, case studies, and launch narratives |

Supporting agents:

| Area | Agents |
|---|---|
| Product planning | `discovery`, `strategist`, `pm-writer`, `system-architect` |
| Delivery | `spec`, `spec-tasks`, `qa-strategist`, `architect`, `builder-worker`, `builder-reviewer` |
| Security | `secrets-scanner`, `code-vuln-scanner`, `deps-scanner`, `config-scanner` |
| Standalone | `spec-archaeologist`, `spec-drift-detector`, `tech-writer` |

The deprecated `security-pre-reviewer` is intentionally not packaged. Its
security and quality gates are embedded in `architect`.

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

Several workflows can persist task briefs with
[Beads](https://github.com/steveyegge/beads). If `bd` is unavailable, agents
must continue with an explicit Markdown handoff and report that the task was not
persisted. Beads is an enhancement, not an installation requirement.

## Package layout

```text
apm.yml
.apm/
  agents/          # 22 flat .agent.md files; logical groups are documented above
  prompts/         # 4 cross-host slash commands
  instructions/    # shared operating principles
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
