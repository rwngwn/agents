---
description: Reverse-engineer specs (PRDs, tech designs, ADRs, contracts) from the current codebase. Writes to docs/specs/ only — no code is touched. Use to seed SDD on a legacy project or backfill after un-spec'd sprints.
input:
  - options: "Optional --scope, --depth, --style, and --dry-run flags"
argument-hint: "[options]"
---

Delegate this work to the `spec-archaeologist` agent with the host's native
subagent mechanism. Do not perform the archaeology in the current agent.

Reverse-engineer specs for this project.

**Input:**
`${input:options}`

Recognized options in `${input:options}`:
- `--scope=<path or module>` — restrict analysis to a subdirectory or KMP source set
- `--depth=<minimal|standard|deep>` — how thorough (default: standard)
- `--style=<sdd|arc42|c4>` — output style (default: sdd)
- `--dry-run` — present the draft index only, write nothing

Follow the spec-archaeologist workflow exactly:

1. Detect project type (stack, build system, modules, KMP targets if any)
2. Inventory the public surface (routes, screens, deeplinks, public APIs, schema)
3. Cluster into feature areas → PRDs
4. Cluster into architectural concerns → tech designs
5. Mine git history for decisions → ADRs (one per substantive choice)
6. Extract or generate machine-readable contracts
7. Present the draft index and wait for explicit approval (Step 7 gate)
8. Write the approved files under docs/specs/ — each with a provenance block,
   `## Code references`, and `## Assumptions (needs human review)` where applicable
9. Emit the final summary with coverage %, gaps, and suggested next steps

Hard rules:
- Only edit under `docs/specs/` and `docs/SDD.md`. Never touch source code.
- Every claim grounded in code, tests, or git history. Speculation → assumptions section.
- If `docs/specs/` already has content, diff before overwriting and ask.
