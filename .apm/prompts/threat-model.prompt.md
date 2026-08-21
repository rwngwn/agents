---
description: Run design-time threat modeling for a canonical change and update the living threat model after human approval.
input:
  - change: "Path to docs/changes/<issue-id>.md and optional scope"
argument-hint: "<change-path> [scope]"
---

Delegate this work to the `threat-modeler` agent with the host's native subagent
mechanism. Do not perform the threat model in the current agent.

Threat-model this approved change:

`${input:change}`

Load product intent, LikeC4 architecture, domain invariants, executable
contracts, existing threat model, and relevant code. Produce assets, actors,
entry points, trust boundaries, data flows, stable STRIDE threats, controls,
validation methods, residual-risk ownership/expiry, and returned security
requirements. Present the complete draft and wait for explicit approval before
updating `docs/security/threat-model.md`.
