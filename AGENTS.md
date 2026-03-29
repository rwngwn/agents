# SDLC Agent System for OpenCode

Complete set of AI agents covering the Software Development Lifecycle -- from
raw idea to security audit.

## Architecture

The system consists of 21 custom agents organized into 5 primary agents and 16
subagents. Users press **Tab** to cycle through the 5 primary agents.
Subagents are invoked automatically by orchestrators via the Task tool, or manually
via `@mention`.

**Note:** OpenCode's built-in `plan` (read-only) and `build` (full access) agents
are preserved -- the custom agents use `sdlc-plan` and `sdlc-build` to avoid
overriding them.

Agents communicate via Beads (`bd`) -- a local AI-optimized issue tracker serving
as shared memory for the entire system.

### Universal Principle

**Evidence before claims.** No agent may claim work is complete, fixed, passing,
or ready without running the relevant verification command and confirming output
in the same message. "Should work" is not verification.

---

## Primary Agents (Tab-cycleable)

| File | Agent | Purpose |
|------|-------|---------|
| `sdlc-plan.md` | **sdlc-plan** | Idea -> discovery -> strategy -> PRD -> tech design -> Beads tasks -> handoff to sdlc-build |
| `sdlc-build.md` | **sdlc-build** | Takes Beads epic or plan -> optional QA -> spec -> architect -> parallel workers/reviewers |
| `debugger.md` | **debugger** | Bug investigation -> root cause analysis -> spec (fix mode) -> sdlc-build |
| `security-reviewer.md` | **security-reviewer** | 4 parallel scanners -> consolidated report -> remediation tasks |
| `tech-storyteller.md` | **tech-storyteller** | Blog posts, explainers, case studies, launch narratives |

## Subagents

### sdlc-plan subagents (hidden)

| File | Agent | Invoked by | Purpose |
|------|-------|-----------|---------|
| `discovery.md` | discovery | sdlc-plan | Market research, user research, personas, competitive analysis |
| `strategist.md` | strategist | sdlc-plan | Product strategy, OKRs, PR/FAQ, founding hypothesis |
| `pm-writer.md` | pm-writer | sdlc-plan | PRDs, feature specs, product briefs. Calls spec for codebase analysis |
| `system-architect.md` | system-architect | sdlc-plan | Tech design, DB schema, API design, application architecture |

### sdlc-build subagents (hidden)

| File | Agent | Invoked by | Purpose |
|------|-------|-----------|---------|
| `spec.md` | spec | sdlc-plan, sdlc-build, debugger | Codebase analysis, Shared Context, implementation plan (feature or fix mode) |
| `spec-tasks.md` | spec-tasks | sdlc-plan, spec | Mechanical Beads task creation from approved plan |
| `qa-strategist.md` | qa-strategist | sdlc-build | Test strategy, edge case matrices, regression suites |
| `architect.md` | architect | sdlc-build | Task Briefs, parallel worker/reviewer pipelines |
| `builder-worker.md` | builder-worker | architect | Code implementation per Task Brief |
| `builder-reviewer.md` | builder-reviewer | architect | Independent code review of implementation |

### security subagents (hidden)

| File | Agent | Invoked by | Purpose |
|------|-------|-----------|---------|
| `security-pre-reviewer.md` | security-pre-reviewer | architect | Shift-left security gate (reviews Task Briefs before implementation) |
| `secrets-scanner.md` | secrets-scanner | security-reviewer | Hardcoded secrets, API keys, tokens, credentials |
| `code-vuln-scanner.md` | code-vuln-scanner | security-reviewer | OWASP Top 10, injection, auth flaws, crypto misuse |
| `deps-scanner.md` | deps-scanner | security-reviewer | CVEs, outdated packages, supply chain risks |
| `config-scanner.md` | config-scanner | security-reviewer | CORS, CSP, headers, debug mode, TLS config |

### Standalone subagents (visible via @mention)

| File | Agent | Purpose |
|------|-------|---------|
| `tech-writer.md` | tech-writer | API docs, README, migration guides, changelogs |

---

## Visual Flow

```
  User (Tab to switch primary agents)
    |
    +---> [sdlc-plan] -+-> discovery (personas, journey maps, competitive analysis)
    |                   |   HIL: approve personas and analysis
    |                   +-> strategist (strategy, OKRs, PR/FAQ)
    |                   |   HIL: approve strategy
    |                   +-> pm-writer -> spec (codebase analysis, implementation plan)
    |                   |   HIL: approve PRD + plan
    |                   +-> system-architect (tech design, DB, API)
    |                   |   HIL: approve tech design
    |                   +-> spec + spec-tasks (create Beads epic with tasks)
    |                   +-> handoff: "Switch to sdlc-build, implement epic bd-XX"
    |
    +---> [sdlc-build] -+-> (optional) qa-strategist (test strategy, edge cases)
    |                    +-> spec (codebase analysis, Shared Context, plan)
    |                    |   HIL: approve implementation plan
    |                    +-> spec-tasks (create Beads tasks)
    |                    +-> architect -+-> security-pre-reviewer (shift-left gate)
    |                                   +-> builder-worker (implementation)
    |                                   +-> builder-reviewer (review)
    |                                   +-> builder-worker (fix, max 2x)
    |                                   +-> builder-reviewer (re-review)
    |
    +---> [debugger] -> spec (fix mode) -> sdlc-build (implementation)
    |
    +---> [security-reviewer] -+-> secrets-scanner
    |                          +-> code-vuln-scanner    (all 4 in parallel)
    |                          +-> deps-scanner
    |                          +-> config-scanner
    |                          +-> remediation -> architect or debugger
    |
    +---> @tech-writer (standalone -- docs, README, changelog)
    |
    +---> [tech-storyteller] (primary -- blog posts, case studies)
```

## Typical Workflows

### A) From idea to shipped product

1. User switches to `sdlc-plan` (Tab) -- "I want to build X"
   - sdlc-plan orchestrator invokes: discovery -> strategist -> pm-writer -> system-architect
   - HIL checkpoint after each phase
   - Creates Beads epic with tasks
   - Tells user to switch to sdlc-build with epic ID
2. User switches to `sdlc-build` (Tab) -- "Implement epic bd-XX"
   - sdlc-build orchestrator invokes: (optional) qa-strategist -> architect -> workers/reviewers
3. User switches to `security-reviewer` (Tab) -- "Security audit before merge"
   - security orchestrator invokes: 4 parallel scanners -> consolidated report -> remediation tasks

### B) Bug fix workflow

1. User switches to `debugger` (Tab) -- "Investigate this bug"
   - debugger investigates root cause -> calls spec (fix mode) -> sdlc-build implements fix
   - Optional: qa-strategist for regression suite

### C) Small task (skip planning)

1. User switches to `sdlc-build` (Tab) -- "Add a health check endpoint"
   - sdlc-build routes directly to architect (skips spec for small tasks)
   - architect creates mini Task Brief -> worker -> reviewer -> done

### D) Documentation

1. User types `@tech-writer` -- "Document the API"
   - tech-writer explores codebase -> produces docs
2. User types `@tech-storyteller` -- "Write a blog post about the new feature"
   - tech-storyteller explores codebase -> produces narrative content

## Installation

Run the install script:

```bash
./install.sh
```

Or manually copy all agent `.md` files to `~/.config/opencode/agents/`:

```bash
# From the root of this repo
cp *.md ~/.config/opencode/agents/   # copies agent files (README.md is harmless)
cp AGENTS.md ~/.config/opencode/AGENTS.md
```

## Beads (optional)

Agents spec, spec-tasks, and architect use [Beads](https://github.com/steveyegge/beads)
for reliable task handoff. If you don't use Beads, you can skip these three agents
and work directly with the others.

```bash
brew install beads
cd your-project && bd init
```

## Design Principles

1. **Subagent verification** -- orchestrators automatically invoke domain agents;
   the user cannot forget a step
2. **Least privilege** -- each agent has only the permissions it needs
3. **Self-contained handoff** -- subagents start with clean context; everything
   they need is in the prompt
4. **Human-in-the-Loop** -- key decisions are approved by the human (HIL checkpoints
   between phases)
5. **Explicit formats** -- every agent has defined input and output formats
6. **Consistency** -- all agents use the same structures (P0-P4 priority,
   severity levels, risk matrices)
7. **5 primary + 16 subagents** -- users Tab through 5 agents; the rest are
   invoked automatically or via `@mention`
8. **No built-in overrides** -- `plan` and `build` are OpenCode defaults; we use
   `sdlc-plan` and `sdlc-build` to avoid collision
9. **Separation of concerns** -- each orchestrator has a clear area of responsibility
10. **Evidence before claims** -- universal verification principle across all agents
11. **Behaviors embedded, not referenced** -- skill-derived behaviors are baked directly
    into agent descriptions, not loaded as external dependencies
