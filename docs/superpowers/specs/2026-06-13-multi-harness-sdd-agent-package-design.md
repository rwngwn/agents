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
- Every harness gets equivalent workflows.
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
claude/agents/           # Claude Code subagents where useful
install.sh               # parameterized multi-harness installer
```

The core defines intent, artifacts, quality gates, and anchor semantics. Adapters
translate that intent into each harness's native mechanics:

- OpenCode: primary agents, subagents, permissions, optional commands.
- Codex: `SKILL.md` workflow skills and `AGENTS-sdlc.md`.
- Claude Code: `SKILL.md` workflow skills, optional subagents, and a
  `CLAUDE-sdlc.md` instruction file or snippet.

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

Install Plannotator review hooks? [y/N]
Install spec-driven templates? [Y/n]
Overwrite existing SDLC files? [y/N]
```

Non-interactive:

```bash
./install.sh --harness opencode
./install.sh --harness codex,claude
./install.sh --harness all --with-plannotator --with-spec-templates
./install.sh --harness all --dry-run
```

The script should also support:

- `--force` to overwrite existing SDLC-managed files.
- `--no-plannotator` to skip hooks explicitly.
- `--no-spec-templates` to install agents only.
- `--print-targets` to show resolved install paths.

## Installed Outputs

OpenCode:

```text
~/.config/opencode/agents/*.md
~/.config/opencode/skills/*
~/.config/opencode/commands/*        # optional adapter commands only
~/.config/opencode/AGENTS.md
```

Codex:

```text
~/.codex/skills/sdlc-*/SKILL.md
~/.codex/skills/spec-*/SKILL.md
~/.codex/AGENTS-sdlc.md
```

Claude Code:

```text
~/.claude/skills/sdlc-*/SKILL.md
~/.claude/skills/spec-*/SKILL.md
~/.claude/agents/*.md                # only for workflows that need subagents
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
    REQ-*.md

  acceptance/
    AC-*.feature
    AC-*.test.ts

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

  tasks/
    TASK-*.yaml

  evidence/
    TEST-*.yaml
```

`architecture/` replaces the vague `system/` name. It contains C4/Structurizr
models, component boundaries, runtime/data flow, deployment shape, NFRs,
security/privacy constraints, and ADRs. It does not contain API schemas, event
schemas, or database contracts.

## Anchor Registry

`docs/specs/index.yaml` is the token-efficient entry point. Agents read it first,
then load only referenced anchors.

Example:

```yaml
anchors:
  REQ-001:
    title: Login with email
    file: product/auth.md
    acceptance: [AC-001]
    contracts: [API-001]
    decisions: [ADR-0001]
    status: approved

  API-001:
    title: POST /auth/login
    file: contracts/openapi.yaml
    pointer: /paths/~1auth~1login/post
    status: approved

  AC-001:
    title: Successful email login
    file: acceptance/auth-login.feature
    status: approved
```

Anchor types:

- `REQ-*`: product requirement.
- `AC-*`: acceptance criterion or executable acceptance test.
- `API-*`: OpenAPI pointer.
- `EVT-*`: AsyncAPI or event schema pointer.
- `GQL-*`: GraphQL schema field or operation.
- `PROTO-*`: protobuf service/message.
- `DB-*`: database schema or migration anchor.
- `ADR-*`: architecture decision.
- `TASK-*`: implementation task.
- `TEST-*`: verification evidence.

## Token Efficiency Design

Agents must not load whole PRDs, whole OpenAPI files, or broad architecture docs
unless required.

Context pack rule:

1. Load `docs/specs/index.yaml`.
2. Resolve only anchors referenced by the current task or request.
3. For machine contracts, load only the referenced pointer or schema object.
4. Load only linked ADRs, not every ADR.
5. Load only relevant acceptance files/tests.
6. Summarize the context pack before planning or implementation.

Generated task briefs should include:

```yaml
id: TASK-001
title: Implement email login endpoint
anchors:
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
2. Product requirement anchors.
3. Acceptance criteria.
4. Optional Product Lab/prototype for user-facing work.
5. Architecture notes and ADRs.
6. Machine-readable contracts.
7. Tasks.
8. Evidence.

Minimal artifacts:

- `product/REQ-*.md`
- `acceptance/AC-*.feature`
- `architecture/architecture.dsl`
- `architecture/decisions/ADR-*.md`
- relevant files under `contracts/`
- `tasks/TASK-*.yaml`

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

It is not the primary user interface. The installer can configure hooks, but the
agents must still work without Plannotator.

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
- "Install Plannotator review hooks? You can still use the agents without it."
- "Install SDD templates into this repo?"
- "Existing SDLC files found. Overwrite managed files only?"
- "Dry run complete. No files changed."

Agent checkpoint copy:

- "Review these anchors before implementation."
- "This task references no acceptance criteria yet. Add one or continue with lower confidence?"
- "The OpenAPI contract changed. Should I update generated tests now?"
- "Beads is unavailable, so I created inline task artifacts instead."

Error copy:

- "I cannot find a spec index at `docs/specs/index.yaml`. I can create the template or continue with a one-off plan."
- "This contract is Markdown, not a machine-readable schema. I need OpenAPI, AsyncAPI, GraphQL, protobuf, JSON Schema, or SQL to treat it as a contract."
- "The requested anchor exists in the index but the target file is missing."

## Accessibility And Inclusivity

- Installer works interactively and non-interactively.
- Prompts use plain language and defaults.
- Generated artifacts are text-first and diffable.
- Plannotator is optional; review must remain possible in terminal/editor.
- Use stable IDs and file paths so users with different tools can inspect the
  same artifacts.

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

## Prioritized Changes

1. Reconcile current branch with latest `origin/main` refactor.
2. Replace split installers with one parameterized `install.sh`.
3. Add Claude Code adapter tree.
4. Add shared `workflows/core/` source files.
5. Add SDD template structure under `docs/specs/`.
6. Update OpenCode and Codex adapters to reference shared SDD anchors.
7. Add token-efficient context-pack rules to `spec`, `sdlc-build`, and debugger
   workflows.
8. Keep Plannotator integration optional and documented.
9. Add installer tests and syntax checks.
10. Add README quick start for all three harnesses.

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
  `index.yaml`, and creates tasks that point to exact OpenAPI pointers.

Task 5: Debug a bug.

- Success: agent reproduces, records root cause evidence, adds a regression
  acceptance/test anchor, and avoids the full product pipeline.

## Open Questions

- Should Claude Code receive only skills, or also dedicated subagents for
  builder/reviewer/scanner roles?
- Should `docs/specs/index.yaml` be created in this repo by default, or only when
  `--with-spec-templates` is selected?
- Should Plannotator hook setup be delegated to the official installer, with this
  repo only documenting how to enable it?

## Design Decision

Proceed with one parameterized installer and shared SDD core. Runtime workflows
remain native to OpenCode, Codex, and Claude Code. Contracts are machine-readable
formats. Markdown remains for requirements, ADRs, architecture notes, tasks, and
evidence summaries.
