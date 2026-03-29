# SDLC Agent System for OpenCode

21 custom AI agents covering the full software development lifecycle — from raw idea to security audit. Built for [OpenCode](https://opencode.ai), powered by [Superpowers](https://github.com/obra/superpowers) skills.

## Quick Start

```bash
git clone https://github.com/rwngwn/agents.git
cd agents
./install.sh
```

Or manually:

```bash
cp *.md ~/.config/opencode/agents/
cp AGENTS.md ~/.config/opencode/AGENTS.md
```

Then restart OpenCode. Press **Tab** to cycle through the 5 primary agents.

## Architecture

```
  You (Tab to switch)
    │
    ├──▶ [sdlc-plan]  ──▶ discovery ──▶ strategist ──▶ pm-writer ──▶ system-architect
    │                      ↳ HIL checkpoints between each phase
    │                      ↳ creates Beads tasks → hands off to sdlc-build
    │
    ├──▶ [sdlc-build] ──▶ (optional) qa-strategist
    │                  ──▶ architect ──▶ security-pre-reviewer (shift-left gate)
    │                               ──▶ builder-worker  ──▶ builder-reviewer
    │                               ──▶ builder-worker  ──▶ builder-reviewer  (repeat)
    │
    ├──▶ [debugger]   ──▶ root cause investigation ──▶ spec (fix mode) ──▶ sdlc-build
    │
    ├──▶ [security-reviewer] ──▶ secrets-scanner    ╮
    │                         ──▶ code-vuln-scanner  ├── all 4 in parallel
    │                         ──▶ deps-scanner       │
    │                         ──▶ config-scanner     ╯
    │
    ├──▶ [tech-storyteller]  blog posts, case studies, launch narratives
    │
    └──▶ @tech-writer         API docs, README, migration guides, changelogs
```

## Primary Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| **sdlc-plan** | claude-opus-4.6 | Idea → discovery → strategy → PRD → tech design → Beads tasks |
| **sdlc-build** | claude-sonnet-4.6 | Beads epic or plan → QA → architect → parallel workers/reviewers |
| **debugger** | claude-opus-4.6 | Bug investigation → root cause → spec (fix mode) → sdlc-build |
| **security-reviewer** | claude-opus-4.6 | 4 parallel scanners → consolidated report → remediation tasks |
| **tech-storyteller** | claude-sonnet-4.6 | Blog posts, explainers, case studies, launch narratives |

## Subagents

Subagents are invoked automatically by orchestrators via the Task tool. Hidden subagents don't appear in `@` autocomplete but are dispatched behind the scenes.

### sdlc-plan pipeline

| Subagent | Model | Role |
|----------|-------|------|
| discovery | claude-sonnet-4.6 | Market research, personas, competitive analysis, journey mapping |
| strategist | claude-sonnet-4.6 | Product strategy, OKRs, PR/FAQ, founding hypothesis |
| pm-writer | claude-opus-4.6 | PRDs, feature specs, product briefs |
| system-architect | claude-opus-4.6 | Tech design, DB schema, API design, application architecture |

### sdlc-build pipeline

| Subagent | Model | Role |
|----------|-------|------|
| spec | claude-opus-4.6 | Codebase analysis, shared context, implementation plan |
| spec-tasks | claude-haiku-4.5 | Mechanical Beads task creation from approved plan |
| qa-strategist | claude-sonnet-4.6 | Test strategy, edge case matrices, regression suites |
| architect | claude-sonnet-4.6 | Task Briefs, parallel worker/reviewer pipelines |
| builder-worker | claude-sonnet-4.6 | Code implementation per Task Brief (TDD, YAGNI) |
| builder-reviewer | gpt-5.3-codex | Independent two-stage code review |

### Security pipeline (all run in parallel)

| Subagent | Model | Role |
|----------|-------|------|
| security-pre-reviewer | claude-sonnet-4.6 | Shift-left gate — reviews Task Briefs before implementation |
| secrets-scanner | claude-sonnet-4.6 | Hardcoded secrets, API keys, tokens, credentials |
| code-vuln-scanner | claude-sonnet-4.6 | OWASP Top 10, injection, auth flaws, crypto misuse |
| deps-scanner | claude-sonnet-4.6 | CVEs, outdated packages, supply chain risks |
| config-scanner | claude-sonnet-4.6 | CORS, CSP, headers, debug mode, TLS configuration |

### Standalone (call via `@mention`)

| Subagent | Model | Role |
|----------|-------|------|
| tech-writer | claude-sonnet-4.6 | API docs, README, migration guides, changelogs |

## Model Strategy

| Model | Role | Agents |
|-------|------|--------|
| **claude-opus-4.6** | Heavy reasoning | sdlc-plan, pm-writer, system-architect, spec, debugger, security-reviewer |
| **claude-sonnet-4.6** | Implementation & structured output | sdlc-build, architect, builder-worker, discovery, strategist, qa-strategist, all security scanners, tech-writer, tech-storyteller |
| **gpt-5.3-codex** | Code review | builder-reviewer |
| **claude-haiku-4.5** | Mechanical tasks | spec-tasks |

## Typical Workflows

### A) From idea to shipped feature

1. Tab to `sdlc-plan` → "I want to build X"
   - Runs: discovery → strategist → pm-writer → system-architect
   - HIL checkpoint after each phase — you approve before it proceeds
   - Creates a Beads epic with tasks, tells you to switch to sdlc-build
2. Tab to `sdlc-build` → "Implement epic bd-XX"
   - Runs: qa-strategist (optional) → architect → parallel workers/reviewers
3. Tab to `security-reviewer` → "Audit before merge"
   - Runs: 4 parallel scanners → consolidated report → remediation tasks

### B) Bug fix

1. Tab to `debugger` → "Investigate this bug"
   - Runs systematic root-cause investigation, then calls spec (fix mode), then sdlc-build implements the fix

### C) Small task (skip planning)

1. Tab to `sdlc-build` → "Add a health check endpoint"
   - Routes directly to architect — no spec needed for small, well-defined tasks

### D) Documentation

- `@tech-writer` → "Document the authentication API"
- Tab to `tech-storyteller` → "Write a blog post about this release"

## Prerequisites

- [OpenCode](https://opencode.ai)
- [Superpowers](https://github.com/obra/superpowers) skills installed for OpenCode

### Optional

- [Beads](https://github.com/steveyegge/beads) — AI-optimized local issue tracker for task handoff between agents

```bash
brew install beads
cd your-project && bd init
```

Agents that use Beads: spec, spec-tasks, architect. If you don't use Beads, these agents still work but skip task persistence.

## Design Principles

1. **Evidence before claims** — no agent claims work is complete without running verification and confirming output. "Should work" is not verification.
2. **Least privilege** — each agent has only the permissions its role requires.
3. **Self-contained handoff** — subagents start with clean context; everything they need is in the prompt.
4. **Human-in-the-Loop** — key decisions require your approval before the pipeline proceeds.
5. **No built-in overrides** — uses `sdlc-plan`/`sdlc-build` to preserve OpenCode's built-in `plan`/`build` agents.
6. **Behaviors embedded, not referenced** — skill-derived behaviors are baked directly into agent descriptions, not loaded as external dependencies at runtime.

## Relationship to Superpowers

This agent system was designed to work with [Superpowers](https://github.com/obra/superpowers) skills. Key behaviors from 14 Superpowers skills (brainstorming, TDD, systematic debugging, verification-before-completion, etc.) are embedded directly into the agent descriptions — agents carry their workflows with them rather than loading skills at runtime.

The agents repo is standalone: you can install it without Superpowers if you want just the agent pipeline. But the full workflow (skills + agents) is the intended experience.

## File Structure

```
AGENTS.md                  # Master architecture doc (copied to ~/.config/opencode/)
README.md                  # This file
install.sh                 # Install script
sdlc-plan.md              # Primary: planning orchestrator
sdlc-build.md             # Primary: build orchestrator
debugger.md               # Primary: bug investigation
security-reviewer.md      # Primary: security audit orchestrator
tech-storyteller.md        # Primary: technical content
discovery.md              # Subagent: market/user research
strategist.md             # Subagent: product strategy
pm-writer.md              # Subagent: PRD writing
system-architect.md       # Subagent: technical design
spec.md                   # Subagent: codebase analysis & planning
spec-tasks.md             # Subagent: Beads task creation
qa-strategist.md          # Subagent: test strategy
architect.md              # Subagent: task briefs & dispatch
builder-worker.md         # Subagent: code implementation
builder-reviewer.md       # Subagent: code review
security-pre-reviewer.md  # Subagent: shift-left security gate
secrets-scanner.md        # Subagent: secrets detection
code-vuln-scanner.md      # Subagent: vulnerability scanning
deps-scanner.md           # Subagent: dependency scanning
config-scanner.md         # Subagent: configuration scanning
tech-writer.md            # Subagent: documentation
```

## License

MIT
