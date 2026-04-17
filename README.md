# SDLC Agent System for OpenCode

21 custom AI agents covering the full software development lifecycle — from raw idea to security audit. Built for [OpenCode](https://opencode.ai).

## Quick Start

```bash
git clone https://github.com/rwngwn/agents.git
cd agents
./install.sh
```

Or manually:

```bash
find agents/ -name "*.md" | xargs -I{} cp {} ~/.config/opencode/agents/
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
| **sdlc-plan** | claude-opus-4.7 | Idea → discovery → strategy → PRD → tech design → Beads tasks |
| **sdlc-build** | claude-sonnet-4.6 | Beads epic or plan → QA → architect → parallel workers/reviewers |
| **debugger** | claude-opus-4.7 | Bug investigation → root cause → spec (fix mode) → sdlc-build |
| **security-reviewer** | claude-opus-4.7 | 4 parallel scanners → consolidated report → remediation tasks |
| **tech-storyteller** | claude-sonnet-4.6 | Blog posts, explainers, case studies, launch narratives |

## Subagents

Subagents are invoked automatically by orchestrators via the Task tool. Hidden subagents don't appear in `@` autocomplete but are dispatched behind the scenes.

### sdlc-plan pipeline

| Subagent | Model | Role |
|----------|-------|------|
| discovery | claude-sonnet-4.6 | Market research, personas, competitive analysis, journey mapping |
| strategist | claude-sonnet-4.6 | Product strategy, OKRs, PR/FAQ, founding hypothesis |
| pm-writer | claude-opus-4.7 | PRDs, feature specs, product briefs |
| system-architect | claude-opus-4.7 | Tech design, DB schema, API design, application architecture |

### sdlc-build pipeline

| Subagent | Model | Role |
|----------|-------|------|
| spec | claude-opus-4.7 | Codebase analysis, shared context, implementation plan |
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
| **claude-opus-4.7** | Heavy reasoning | sdlc-plan, pm-writer, system-architect, spec, debugger, security-reviewer |
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

## File Structure

```
AGENTS.md                        # Master architecture doc (copied to ~/.config/opencode/)
README.md                        # This file
install.sh                       # Install script — flattens agents/**/ into ~/.config/opencode/agents/

agents/
  primary/
    sdlc-plan.md                 # Idea → discovery → strategy → PRD → tech design → tasks
    sdlc-build.md                # Epic or plan → QA → architect → parallel workers
    debugger.md                  # Bug investigation → root cause → fix
    security-reviewer.md         # 4 parallel scanners → consolidated report
    tech-storyteller.md          # Blog posts, case studies, launch narratives

  plan/                          # sdlc-plan subagents
    discovery.md                 # Market research, personas, competitive analysis
    strategist.md                # Product strategy, OKRs, PR/FAQ
    pm-writer.md                 # PRDs, feature specs, product briefs
    system-architect.md          # Tech design, DB schema, API design

  build/                         # sdlc-build subagents
    spec.md                      # Codebase analysis, shared context, implementation plan
    spec-tasks.md                # Mechanical Beads task creation
    qa-strategist.md             # Test strategy, edge case matrices
    architect.md                 # Task briefs, parallel worker/reviewer dispatch
    builder-worker.md            # Code implementation per Task Brief
    builder-reviewer.md          # Independent code review

  security/                      # Security subagents (all run in parallel)
    security-pre-reviewer.md     # Shift-left gate — reviews briefs before implementation
    secrets-scanner.md           # Hardcoded secrets, API keys, credentials
    code-vuln-scanner.md         # OWASP Top 10, injection, auth flaws
    deps-scanner.md              # CVEs, outdated packages, supply chain risks
    config-scanner.md            # CORS, CSP, headers, debug mode, TLS

  standalone/
    tech-writer.md               # API docs, README, migration guides, changelogs
```

## License

MIT
