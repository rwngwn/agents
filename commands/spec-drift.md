---
description: Detect drift between specs (docs/specs/) and the actual codebase. Read-only — produces a Drift Report and optionally creates Beads remediation tasks.
agent: spec-drift-detector
subtask: true
model: github-copilot/claude-sonnet-4.6
---

Run a spec-drift scan over this project.

**Input:**
$ARGUMENTS

If `$ARGUMENTS` is empty, scan the whole repo with no time filter. Otherwise
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
