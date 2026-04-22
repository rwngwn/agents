# SDLC Agent System for OpenCode

Complete set of AI agents covering the Software Development Lifecycle -- from
raw idea to security audit.

## Architecture

The system consists of 26 custom agents organized into 6 primary agents and 20
subagents, plus 4 reusable skills. Users press **Tab** to cycle through the 6 primary agents.
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

### Key Architecture Decision: Architect as Planner, sdlc-build as Executor

The architect agent is a **design-time planner** -- it prepares enriched Task Briefs
(with embedded security and quality constraints) and writes them to Beads, then exits.

The `sdlc-build` agent is the **runtime executor** -- it reads Task Briefs from Beads
and directly orchestrates parallel builder-worker/reviewer pipelines. This separation
eliminates the bottleneck of having architect manage worker/reviewer orchestration,
enabling better parallelism and reducing stalling.

The `security-pre-reviewer` subagent has been **deprecated** -- its CWE checklist
logic is now embedded directly in the architect as a Security Skill, eliminating
one round-trip per Task Brief.

---

## Primary Agents (Tab-cycleable)

| File | Agent | Purpose |
|------|-------|---------|
| `sdlc-plan.md` | **sdlc-plan** | Idea -> discovery -> strategy -> PRD -> tech design -> Beads tasks -> handoff to sdlc-build |
| `sdlc-build.md` | **sdlc-build** | Takes Beads epic or plan -> optional QA -> architect (brief prep) -> parallel workers/reviewers |
| `debugger.md` | **debugger** | Bug investigation -> root cause analysis -> direct fix via builder-worker/reviewer (small) or spec (fix mode) -> sdlc-build (large) |
| `security-reviewer.md` | **security-reviewer** | 4 parallel scanners -> consolidated report -> remediation tasks |
| `tech-storyteller.md` | **tech-storyteller** | Blog posts, explainers, case studies, launch narratives |
| `estimator.md` | **estimator** | RFP/poptávka (PDF/DOCX/URL) -> requirements extraction -> WBS + PERT estimation -> risks -> client proposal |

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
| `architect.md` | architect | sdlc-build | Task Brief design with embedded Security + Quality skills, writes enriched briefs to Beads |
| `builder-worker.md` | builder-worker | sdlc-build | Code implementation per Task Brief |
| `builder-reviewer.md` | builder-reviewer | sdlc-build | Independent code review of implementation |

### security subagents (hidden)

| File | Agent | Invoked by | Purpose |
|------|-------|-----------|---------|
| `security-pre-reviewer.md` | ~~security-pre-reviewer~~ | ~~architect~~ | **DEPRECATED** -- logic merged into architect's Security Skill |
| `secrets-scanner.md` | secrets-scanner | security-reviewer | Hardcoded secrets, API keys, tokens, credentials |
| `code-vuln-scanner.md` | code-vuln-scanner | security-reviewer | OWASP Top 10, injection, auth flaws, crypto misuse |
| `deps-scanner.md` | deps-scanner | security-reviewer | CVEs, outdated packages, supply chain risks |
| `config-scanner.md` | config-scanner | security-reviewer | CORS, CSP, headers, debug mode, TLS config |

### Standalone subagents (visible via @mention)

| File | Agent | Purpose |
|------|-------|---------|
| `tech-writer.md` | tech-writer | API docs, README, migration guides, changelogs |

### estimator subagents (hidden)

| File | Agent | Invoked by | Purpose |
|------|-------|-----------|---------|
| `requirements-extractor.md` | requirements-extractor | estimator | RFP parsing (PDF/DOCX/URL), use cases, integrations, NFR, constraints (JSON schema) |
| `wbs-planner.md` | wbs-planner | estimator | WBS + PERT estimation (O/M/P), role breakdown (BE/FE/QA/DevOps/PM/Analýza/Design), 3 scenarios, Wideband Delphi simulation |
| `risk-analyst.md` | risk-analyst | estimator | Risk catalog + P/I scoring, mitigation strategies, CZ-specific risks (eGov, GDPR, NIS2, DORA, ČNB, ÚZIS, EAA, ZZVZ) |
| `proposal-writer.md` | proposal-writer | estimator | Client-ready proposal (12 sections) in Czech |

## Skills (reusable, loaded by agents)

| Skill | Purpose |
|-------|---------|
| `rfp-pdf-extraction` | PDF/DOCX text + table extraction via `uv` + pdfplumber (fallback pdftotext, OCR tesseract `-l ces`) |
| `estimation-pert` | PERT calculator: TE=(O+4M+P)/6, σ=(P−O)/6, agregace σ_total=√Σσ², scenarios, sanity checks |
| `wbs-templates` | 6 WBS templates (web-app-saas, mobile-app, integration, data-pipeline, migration, microservices) |
| `risk-catalog` | ~30 risks in 9 categories with CZ-specific compliance items |

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
    |                    +-> spec (codebase analysis, Shared Context, plan) [if needed]
    |                    |   HIL: approve implementation plan
    |                    +-> architect (designs enriched Task Briefs → Beads)
    |                    |     • Security Skill (embedded CWE checklist)
    |                    |     • Quality Skill (embedded quality gates)
    |                    |     • writes briefs to Beads, then EXITS
    |                    +-> sdlc-build reads briefs from Beads
    |                    +-> parallel pipelines (sdlc-build orchestrates directly):
    |                         +-> builder-worker (implementation)
    |                         +-> builder-reviewer (review)
    |                         +-> builder-worker (fix, max 2x)
    |                         +-> builder-reviewer (re-review)
    |
    +---> [debugger] -> spec (fix mode) -> sdlc-build (implementation)
    |
    +---> [security-reviewer] -+-> secrets-scanner
    |                          +-> code-vuln-scanner    (all 4 in parallel)
    |                          +-> deps-scanner
    |                          +-> config-scanner
    |                          +-> remediation -> sdlc-build
    |
    +---> @tech-writer (standalone -- docs, README, changelog)
    |
    +---> [tech-storyteller] (primary -- blog posts, case studies)
    |
    +---> [estimator] -+-> requirements-extractor (PDF/DOCX/URL -> requirements JSON)
                       |   HIL: approve brief
                       +-> wbs-planner ∥ risk-analyst (parallel)
                       |   HIL: approve estimate
                       +-> proposal-writer (client proposal in Czech)
                       |   Output: ./estimates/<slug>/{brief,estimate,questions,architecture}.md + architecture.dsl (+ proposal.md)
```

## Typical Workflows

### A) From idea to shipped product

1. User switches to `sdlc-plan` (Tab) -- "I want to build X"
   - sdlc-plan orchestrator invokes: discovery -> strategist -> pm-writer -> system-architect
   - HIL checkpoint after each phase
   - Creates Beads epic with tasks
   - Tells user to switch to sdlc-build with epic ID
2. User switches to `sdlc-build` (Tab) -- "Implement epic bd-XX"
   - sdlc-build invokes architect (designs briefs with security + quality gates → Beads)
   - sdlc-build reads enriched briefs from Beads
   - sdlc-build dispatches parallel worker/reviewer pipelines directly
3. User switches to `security-reviewer` (Tab) -- "Security audit before merge"
   - security orchestrator invokes: 4 parallel scanners -> consolidated report -> remediation tasks

### B) Bug fix workflow

1. User switches to `debugger` (Tab) -- "Investigate this bug"
   - debugger investigates root cause -> calls spec (fix mode) -> sdlc-build implements fix
   - Optional: qa-strategist for regression suite

### C) Small task (skip planning)

1. User switches to `sdlc-build` (Tab) -- "Add a health check endpoint"
   - sdlc-build routes to architect (designs mini Task Brief → Beads)
   - sdlc-build reads brief, dispatches worker -> reviewer -> done

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
cp agents/**/*.md ~/.config/opencode/agents/
cp AGENTS.md ~/.config/opencode/AGENTS.md
```

## Beads (optional)

Agents spec, spec-tasks, architect, and sdlc-build use
[Beads](https://github.com/steveyegge/beads) for reliable task handoff. Beads serves
as the shared memory between architect (writes enriched briefs) and sdlc-build
(reads briefs and orchestrates execution).

```bash
brew install beads
cd your-project && bd init
```

## Design Principles

1. **Architect plans, sdlc-build executes** -- architect prepares enriched Task Briefs
   and writes them to Beads; sdlc-build reads them and orchestrates worker/reviewer
   pipelines. Clean separation of design-time and run-time.
2. **Embedded security and quality** -- architect runs CWE and quality checklists
   internally (no separate security-pre-reviewer subagent), injecting constraints
   directly into Task Briefs before writing to Beads.
3. **Subagent verification** -- orchestrators automatically invoke domain agents;
   the user cannot forget a step
4. **Least privilege** -- each agent has only the permissions it needs
5. **Self-contained handoff** -- subagents start with clean context; everything
   they need is in the prompt
6. **Human-in-the-Loop** -- key decisions are approved by the human (HIL checkpoints
   between phases)
7. **Explicit formats** -- every agent has defined input and output formats
8. **Consistency** -- all agents use the same structures (P0-P4 priority,
   severity levels, risk matrices)
9. **5 primary + 16 subagents** -- users Tab through 5 agents; the rest are
   invoked automatically or via `@mention`
10. **No built-in overrides** -- `plan` and `build` are OpenCode defaults; we use
    `sdlc-plan` and `sdlc-build` to avoid collision
11. **Separation of concerns** -- each orchestrator has a clear area of responsibility
12. **Evidence before claims** -- universal verification principle across all agents
13. **Behaviors embedded, not referenced** -- skill-derived behaviors are baked directly
    into agent descriptions, not loaded as external dependencies
