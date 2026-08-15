---
description: Detect drift between specs (docs/specs/) and the actual codebase. Read-only — produces a Drift Report and optionally creates Beads remediation tasks.
input:
  - scope: "Optional scope path, since=YYYY-MM-DD, or spec file paths"
argument-hint: "[scope]"
---

Delegate this work to the `spec-drift-detector` agent with the host's native
subagent mechanism. Do not perform the drift scan in the current agent.

Run a spec-drift scan over this project.

**Input:**
`${input:scope}`

If `${input:scope}` is empty, scan the whole repo with no time filter. Otherwise
respect any of: scope path, `since=YYYY-MM-DD`, specific spec file paths.

Follow the spec-drift-detector workflow exactly:

1. Discover the spec corpus under docs/specs/ (or fall back paths)
2. Build the code inventory of public surface, KMP source sets, expect/actual
3. Cross-reference spec → code (Pass A) and code → spec (Pass B)
4. Classify into the 5 drift categories and score severity
5. Self-check (every finding has both citations)
6. Emit the Drift Report
7. Offer Beads task creation (do not auto-create — wait for user choice)

If no specs are found, recommend `/spec-archaeology` and exit.
