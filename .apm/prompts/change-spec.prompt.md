---
description: Turn an approved product outcome or investigated fix into a canonical business-slice change artifact with EARS, BDD, design triggers, and evidence anchors.
input:
  - source: "Product artifact, issue ID, approved outcome, or investigated fix context"
argument-hint: "<product-or-issue-context>"
---

Delegate this work to the `change-spec-writer` agent with the host's native
subagent mechanism. Do not draft or write the artifact in the current agent.

Create a canonical AISDLC change artifact from:

`${input:source}`

Follow the full behavior gate:

1. Resolve a real tracker ID or propose a stable `CHG-YYYYMMDD-<slug>` ID.
2. Select one independently valuable business slice.
3. Draft Why, Scope, EARS requirements, BDD scenarios, design triggers, plan,
   traceability, and evidence anchors.
4. Present the complete draft and wait for explicit human approval.
5. Only after approval, invoke persist mode and write
   `docs/changes/<issue-id>.md`.
6. Report the path plus requirement/scenario counts. Do not create tasks or code.
