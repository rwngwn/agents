---
description: Reconstruct canonical product, architecture, ADR, domain, and contract-inventory artifacts from code and git evidence without touching source.
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
6. Reference existing executable contracts; generate explicitly human-readable
   inventories only when native contracts are absent; recover domain artifacts
7. Present the draft index and wait for explicit approval (Step 7 gate)
8. Write approved files under `docs/product/`, `docs/architecture/`, `docs/adr/`,
   and `docs/domain/` — each with a provenance block,
   `## Code references`, and `## Assumptions (needs human review)` where applicable
9. Emit the final summary with coverage %, gaps, and suggested next steps

Hard rules:
- Only edit canonical archaeology directories and `docs/SDD.md`. Never touch
  source code or executable contracts.
- Every claim grounded in code, tests, or git history. Speculation → assumptions section.
- If a canonical artifact already exists, diff before overwriting and ask.
