---
description: Verify a specific deployed change in production and record deployment, telemetry, rollback, risk, and scenario evidence.
input:
  - change: "Path to docs/changes/<issue-id>.md plus environment or deployment ID"
argument-hint: "<change-path> [environment-or-deployment]"
---

Delegate this work to the `release-verifier` agent with the host's native
subagent mechanism. Do not execute deployment or production commands in the
current agent.

Verify the release described by:

`${input:change}`

Confirm the intended commit, environment, approvals, CI/e2e/security evidence,
runbook, rollback, and safe production probes. Before any production mutation,
present the exact action and obtain explicit human approval. Mark the change
`verified` only when every in-scope BDD scenario has observed production evidence.
