# Multi-Harness SDD Agent Package Design

Date: 2026-06-13
Status: Approved direction, pending implementation plan

## Goal

Create one shared spec-driven development agent package that installs into
OpenCode, Codex, and Claude Code. The installer is parameterized and asks which
harnesses to configure. Runtime workflow UX stays native to each harness; there
is no new workflow CLI.

## Current UX Diagnosis

The repo has strong agent workflows, but the user-facing model is fragmented:

- OpenCode agents are the most complete surface.
- Codex skills exist as a parallel distribution.
- Claude Code is not yet a first-class install target.
- Installer behavior is split across scripts.
- The system exposes too many workflow commands and internal concepts.
- Spec-driven development artifacts are implied, but not yet a clear canonical
  source of truth.

This creates unnecessary cognitive load. Users should choose the harnesses they
use, install once, and then use native agent workflows inside each tool. Agents
should share the same durable SDD structure so plans, tasks, contracts, ADRs,
tests, and evidence do not drift between harnesses.

## Users And Goals

Primary users:

- Product-minded builder: turns new ideas or customer requests into buildable
  specs.
- Engineering lead: wants traceable requirements, contracts, ADRs, tasks, and
  verification evidence.
- Agent power user: works across OpenCode, Codex, and Claude Code and expects
  consistent behavior.

Success looks like:

- One install command configures selected harnesses.
- Every harness gets equivalent primary workflows and subagent roles, using the
  closest native mechanism each harness supports.
- Agents produce and consume the same spec anchors.
- Contracts use machine-readable formats, not prose.
- Context packs stay small and precise.
- Plannotator is optional review infrastructure, not the main UX.

Likely emotional state:

- The user is trying to reduce workflow sprawl and wants fewer choices at the
  surface.
- They need confidence that multi-agent work will not become unmaintainable.

## Mental Model

Expected model:

1. Install agent workflows into selected tools.
2. Use the native workflow inside that tool.
3. Artifacts land in one repo-local SDD structure.
4. Future agents read the anchors they need, not entire documents.

Avoid this model:

- A new `./sdlc` runtime command for every workflow.
- User-facing commands that require remembering anchor IDs.
- Markdown-only contracts.
- Three unrelated agent implementations.

## Recommended Approach

Use a canonical workflow core plus thin harness adapters.

```text
workflows/
  core/
    principles.md
    artifacts.md
    use-cases/
      new-idea.md
      customer-jira-requirement.md
      debugging-issue.md
      technical-spec-issue.md

agents/                 # OpenCode adapter
codex/skills/            # Codex adapter
claude/skills/           # Claude Code adapter
claude/agents/           # Claude Code subagents for parity
install.sh               # parameterized multi-harness installer
```

The core defines intent, artifacts, quality gates, and anchor semantics. Adapters
translate that intent into each harness's native mechanics:

- OpenCode: primary agents, subagents, permissions, optional commands.
- Codex: `SKILL.md` workflow skills, phase/subagent-equivalent skills for every
  shared role, and `AGENTS-sdlc.md`.
- Claude Code: `SKILL.md` workflow skills, subagents, and a `CLAUDE-sdlc.md`
  instruction file or snippet.

## Harness Parity

The experience should be as similar as each harness allows:

| Role | OpenCode | Codex | Claude Code |
| --- | --- | --- | --- |
| Primary workflows | primary agents | workflow skills | workflow skills |
| Subagents / phases | subagents | phase skills or focused task prompts for every shared role | subagents |
| Shared repo guidance | `AGENTS.md` | `AGENTS-sdlc.md` | `CLAUDE-sdlc.md` |
| Task memory | Beads preferred, fallback inline | Beads preferred, fallback inline | Beads preferred, fallback inline |
| Review gates | native questions + optional Plannotator | native prompts + optional Plannotator | plan mode + optional Plannotator |

Parity means the same role names, artifact anchors, approval gates, and evidence
rules everywhere. It does not require identical tool mechanics.

## Installer UX

Primary UX:

```bash
./install.sh
```

Interactive prompt:

```text
Which harnesses should be installed?

1. OpenCode
2. Codex
3. Claude Code
4. All

Offer Plannotator setup through its official installer/plugin? [y/N]
Install spec-driven templates into this repo? [y/N]
Initialize Beads task memory in this repo? [y/N]
Overwrite existing SDLC files? [y/N]
```

Non-interactive:

```bash
./install.sh --harness opencode
./install.sh --harness codex,claude
./install.sh --harness all --with-plannotator --with-spec-templates
./install.sh --harness all --with-spec-templates --init-beads
./install.sh --harness all --dry-run
```

The script should also support:

- `--force` to overwrite existing SDLC-managed files.
- `--with-plannotator` to delegate setup to the official Plannotator installer
  or plugin instructions.
- `--no-plannotator` to skip Plannotator setup guidance explicitly.
- `--no-spec-templates` to install agents only.
- `--init-beads` to run `bd init` for the current repo when templates are
  installed.
- `--print-targets` to show resolved install paths.

## Installed Outputs

OpenCode:

```text
~/.config/opencode/agents/*.md       # primary agents and subagents
~/.config/opencode/skills/*
~/.config/opencode/commands/*        # optional adapter commands only
~/.config/opencode/AGENTS.md
```

Codex:

```text
~/.codex/skills/sdlc-*/SKILL.md
~/.codex/skills/spec-*/SKILL.md
~/.codex/skills/*/SKILL.md           # phase/subagent-equivalent skills
~/.codex/AGENTS-sdlc.md
```

Claude Code:

```text
~/.claude/skills/sdlc-*/SKILL.md
~/.claude/skills/spec-*/SKILL.md
~/.claude/agents/*.md                # subagents matching OpenCode roles
~/.claude/CLAUDE-sdlc.md             # installable instruction snippet
```

The installer should never silently modify a user's global project memory. If a
harness requires adding a line to `AGENTS.md`, `CLAUDE.md`, or equivalent, print
the snippet and ask before applying it.

## Spec-Driven Artifact Structure

Contracts use native machine-readable formats. Markdown is reserved for product
requirements, ADRs, and explanatory architecture notes.

```text
docs/specs/
  index.yaml

  product/
    PRD-*.md
    REQ-*.md

  acceptance/
    AC-*.feature

  architecture/
    architecture.dsl
    notes.md
    decisions/
      ADR-0001-*.md

  contracts/
    openapi.yaml
    asyncapi.yaml
    schema.graphql
    proto/
    json-schema/
    db/
      schema.sql
      migrations/

  evidence/
    TEST-*.yaml
```

`architecture/` replaces the vague `system/` name. It contains C4/Structurizr
models, component boundaries, runtime/data flow, deployment shape, NFRs,
security/privacy constraints, and ADRs. It does not contain API schemas, event
schemas, or database contracts.

Tests live in the product codebase, not in `docs/specs/`. Acceptance artifacts
under `docs/specs/acceptance/` describe behavior in a reviewable form such as
Gherkin. The anchor registry points to executable test files in their native
project locations, for example `apps/api/tests/auth-login.test.ts`.

PRDs are first-class product artifacts. `PRD-*.md` files hold the narrative
product decision context, while `REQ-*` anchors are the granular requirements
that tasks, contracts, acceptance criteria, and ADRs reference.

Implementation tasks are stored in Beads when Beads is available. YAML task
artifacts are only a fallback/export format for environments where Beads is not
initialized.

## Anchor Registry

`docs/specs/index.yaml` is the token-efficient entry point. Agents read it first,
then load only referenced anchors.

Example:

```yaml
anchors:
  REQ-001:
    title: Login with email
    file: product/auth.md
    prd: PRD-001
    acceptance: [AC-001]
    contracts: [API-001]
    decisions: [ADR-0001]
    tasks: [bd-123]
    status: approved

  PRD-001:
    title: Authentication MVP
    file: product/PRD-authentication.md
    status: approved

  API-001:
    title: POST /auth/login
    file: contracts/openapi.yaml
    pointer: /paths/~1auth~1login/post
    status: approved

  AC-001:
    title: Successful email login
    file: acceptance/auth-login.feature
    test_refs:
      - apps/api/tests/auth-login.test.ts
    status: approved
```

Anchor types:

- `PRD-*`: product requirements document.
- `REQ-*`: granular product requirement.
- `AC-*`: acceptance criterion with optional references to executable tests in
  the codebase.
- `API-*`: OpenAPI pointer.
- `EVT-*`: AsyncAPI or event schema pointer.
- `GQL-*`: GraphQL schema field or operation.
- `PROTO-*`: protobuf service/message.
- `DB-*`: database schema or migration anchor.
- `ADR-*`: architecture decision.
- `TASK-*`: fallback/exported task artifact when Beads is unavailable.
- `TEST-*`: verification evidence.

When Beads is available, task anchors should point to Beads IDs such as `bd-123`
instead of `TASK-*.yaml` files.

## Token Efficiency Design

Agents must not load whole PRDs, whole OpenAPI files, or broad architecture docs
unless required.

Context pack rule:

1. Load `docs/specs/index.yaml`.
2. Resolve only anchors referenced by the current task or request.
3. For machine contracts, load only the referenced pointer or schema object.
4. Load only linked ADRs, not every ADR.
5. Load only relevant acceptance files and referenced code test files.
6. Summarize the context pack before planning or implementation.

Generated task briefs should include:

```yaml
id: bd-123
title: Implement email login endpoint
task_backend: beads
beads_id: bd-123
anchors:
  prd: [PRD-001]
  requirements: [REQ-001]
  acceptance: [AC-001]
  contracts: [API-001, DB-001]
  decisions: [ADR-0001]
context_pack:
  max_tokens_target: 6000
verification:
  commands:
    - npm test -- auth-login
```

## Use Case Flows

### New Product Idea

Flow:

1. Discovery.
2. PRD.
3. Product requirement anchors.
4. Acceptance criteria.
5. Optional Product Lab/prototype for user-facing work.
6. Architecture notes and ADRs.
7. Machine-readable contracts.
8. Beads tasks or fallback task exports.
9. Evidence.

Minimal artifacts:

- `product/REQ-*.md`
- `product/PRD-*.md`
- `acceptance/AC-*.feature`
- `architecture/architecture.dsl`
- `architecture/decisions/ADR-*.md`
- relevant files under `contracts/`
- Beads tasks, or `TASK-*.yaml` fallback exports when Beads is unavailable

### Customer Or Jira Requirement

Flow:

1. Normalize the ticket into product anchors.
2. Challenge ambiguity and missing acceptance criteria.
3. Add or update contract pointers.
4. Create task anchors.

Skip broad discovery and strategy unless the ticket reveals product uncertainty.

### Debugging Issue

Flow:

1. Reproduce.
2. Identify root cause with evidence.
3. Add regression acceptance criterion or test.
4. Create focused fix task or direct implementation brief.
5. Store verification evidence.

This path must not run the full product pipeline.

### Technical Spec Or Architecture Issue

Flow:

1. Use spec archaeology or drift detection as needed.
2. Update architecture model, ADR, and contracts.
3. Generate implementation tasks only after specs are coherent.

## Plannotator Integration

Plannotator is optional and gate-based:

- Plan review before implementation.
- Product Lab artifact review when generated.
- Code diff review before completion.

It is not the primary user interface. Hook setup should be delegated to the
official Plannotator installer or plugin instructions. This installer may detect
and report Plannotator status, but it should not reimplement Plannotator setup.
The agents must work without Plannotator.

## Information Architecture

Top-level repo IA after implementation:

```text
agents/                 # OpenCode
codex/                  # Codex
claude/                 # Claude Code
workflows/core/          # shared workflow source of truth
skills/                 # reusable cross-harness skills/resources
docs/specs/             # project SDD artifacts/templates
install.sh              # all harness installation
README.md               # concise install/use docs
AGENTS.md               # OpenCode/root guidance
```

## Microcopy

Installer prompts:

- "Which harnesses should be installed?"
- "Offer Plannotator setup through its official installer/plugin? You can still use the agents without it."
- "Install SDD templates into this repo?"
- "Initialize Beads task memory in this repo?"
- "Existing SDLC files found. Overwrite managed files only?"
- "Dry run complete. No files changed."

Agent checkpoint copy:

- "Review these anchors before implementation."
- "This task references no acceptance criteria yet. Add one or continue with lower confidence?"
- "The OpenAPI contract changed. Should I update generated tests now?"
- "Beads is unavailable, so I created fallback task artifacts instead."

Error copy:

- "I cannot find a spec index at `docs/specs/index.yaml`. I can create the template or continue with a one-off plan."
- "This contract is Markdown, not a machine-readable schema. I need OpenAPI, AsyncAPI, GraphQL, protobuf, JSON Schema, or SQL to treat it as a contract."
- "The requested anchor exists in the index but the target file is missing."
- "This acceptance criterion references a test file that does not exist in the codebase."

## Accessibility And Inclusivity

- Installer works interactively and non-interactively.
- Prompts use plain language and defaults.
- Generated artifacts are text-first and diffable.
- Plannotator is optional; review must remain possible in terminal/editor.
- Use stable IDs and file paths so users with different tools can inspect the
  same artifacts.
- Subagent role names and handoff summaries should stay consistent across
  OpenCode, Codex, and Claude Code.

## Empty, Loading, And Success States

Installer empty states:

- No harness selected: show harness list again, default to "All" only with user
  confirmation.
- Harness missing on disk: explain target path and offer to create directories.
- No spec templates requested: install agents only and skip repo files.

Working states:

- Print current harness being installed.
- Print files copied, skipped, and overwritten.
- In dry-run mode, print planned changes only.

Success states:

- "Installed OpenCode, Codex, and Claude Code adapters."
- "Spec templates created under `docs/specs/`."
- "Beads initialized for task memory."
- "Plannotator hook setup skipped."
- "Next: open your harness and invoke the native SDLC workflow."

## Error Prevention

- Default to no overwrite.
- Dry-run before destructive copy.
- Copy whole skill directories so resource files are preserved.
- Preserve existing user config; print snippets instead of blindly editing global
  memory files.
- Validate every generated YAML/JSON file.
- Validate shell syntax for installer.
- Detect missing machine-readable contract files before task generation.
- Detect whether Beads is available before creating implementation tasks.
- Validate that acceptance criteria point to real code test files before claiming
  executable coverage.

## Prioritized Changes

1. Reconcile current branch with latest `origin/main` refactor.
2. Replace split installers with one parameterized `install.sh`.
3. Add Claude Code adapter tree.
4. Add shared `workflows/core/` source files.
5. Add SDD template structure under `docs/specs/`, gated behind
   `--with-spec-templates`.
6. Update OpenCode and Codex adapters to reference shared SDD anchors.
7. Add token-efficient context-pack rules to `spec`, `sdlc-build`, and debugger
   workflows.
8. Add Claude Code subagents and Codex phase skills so role names are consistent
   across harnesses.
9. Make Beads the preferred task backend with YAML fallback/export only.
10. Delegate Plannotator hook setup to official Plannotator instructions.
11. Add installer tests and syntax checks.
12. Add README quick start for all three harnesses.

## Usability Test Plan

Task 1: Install all harnesses.

- Command: `./install.sh --harness all --dry-run`
- Success: user can predict target files before writing.
- Metric: no more than one clarification needed.

Task 2: Install only Claude Code.

- Command: `./install.sh --harness claude`
- Success: skills and instruction snippet are installed or printed without
  touching OpenCode/Codex paths.

Task 3: Start a Jira/customer requirement workflow in each harness.

- Success: each harness asks for requirement context and produces the same anchor
  types.

Task 4: Update an API contract.

- Success: agent writes or references `contracts/openapi.yaml`, updates
  `index.yaml`, and creates Beads tasks that point to exact OpenAPI pointers.

Task 5: Debug a bug.

- Success: agent reproduces, records root cause evidence, adds a regression
  acceptance anchor, links it to a code test file, and avoids the full product
  pipeline.

## Resolved Review Decisions

- Product planning keeps PRDs. PRDs carry narrative product context; REQ anchors
  carry granular traceability.
- Tests live in code. `docs/specs/acceptance/` stores acceptance descriptions and
  points to executable tests in project test directories.
- Beads is the preferred task backend. YAML task artifacts exist only as fallback
  or export when Beads is unavailable.
- Claude Code should receive subagents matching OpenCode roles where the harness
  supports them. Codex should receive phase/subagent-equivalent skills.
- `docs/specs/index.yaml` and templates are created only with
  `--with-spec-templates`.
- Plannotator setup is delegated to the official Plannotator installer or plugin
  instructions.

## Design Decision

Proceed with one parameterized installer and shared SDD core. Runtime workflows
remain native to OpenCode, Codex, and Claude Code. Contracts are machine-readable
formats. Markdown remains for PRDs, requirements, ADRs, architecture notes,
acceptance descriptions, and evidence summaries.
