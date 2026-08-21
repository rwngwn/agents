---
description: Canonical AISDLC artifact locations, ownership, traceability, and lifecycle gates.
---

# AISDLC artifact contract

Use this contract in every planning, build, review, security, debugging,
release, archaeology, and drift workflow. The repository is the durable source
of truth for intent and verification anchors. Issue trackers, Beads, pull
requests, CI systems, security scanners, and deployment platforms are external
systems of record linked from repository artifacts; they do not replace them.

## Canonical repository layout

```text
docs/
├── product/
│   └── <product-or-capability>.md
├── changes/
│   └── <issue-id>.md
├── adr/
│   └── ADR-NNNN-<slug>.md
├── architecture/
│   ├── model.likec4
│   └── contracts/                 # human-readable legacy inventories only
├── domain/
│   ├── glossary.md
│   ├── invariants.md
│   └── model.mmd
└── security/
    └── threat-model.md
```

Executable contracts belong in the format and directory used by the codebase:
OpenAPI, AsyncAPI, JSON Schema, Protobuf, GraphQL schema, Avro, SQL migrations,
or equivalent. Tests, schemas, migrations, infrastructure, and application code
are executable artifacts. Do not duplicate an executable contract in Markdown;
link to it from the relevant product or change artifact.

## Artifact classes

### Durable intent

- `docs/product/<capability>.md`: product problem, users, outcomes, scope, and
  long-lived behavior. A PRD belongs here.
- `docs/changes/<issue-id>.md`: the control artifact for one business slice.
  It links requirements to scenarios, implementation, and observed evidence.
- `docs/adr/ADR-NNNN-<slug>.md`: a consequential, long-lived decision and its
  alternatives. Do not create an ADR for routine implementation detail.
- Architecture, domain, and threat-model files describe living system context.

### External records

- Jira/GitHub/Beads work item
- pull or merge request
- CI and end-to-end test run
- security scan and risk acceptance
- deployment record, rollback record, and production verification

Link these from `docs/changes/<issue-id>.md` using stable URLs or identifiers.

### Ephemeral handoffs

Discovery drafts, strategy options, Shared Codebase Context, implementation
plans, Task Briefs, Continuation Briefs, Worker Summaries, Review Verdicts, and
drift reports are working material. Keep them in the conversation, Beads, the
issue, the pull request, or CI artifacts. Promote only durable intent, decisions,
and evidence anchors into the repository.

## Change artifact template

Every non-trivial change must have `docs/changes/<issue-id>.md`. Use the real
tracker ID when available. If there is no tracker, use
`CHG-YYYYMMDD-<short-slug>` and keep that identifier stable.

````markdown
---
id: <issue-id>
status: draft | approved | implementing | deployed | verified | rolled_back | rejected
product: <relative product artifact path>
owners:
  product: <person or role>
  technical: <person or role>
  security: <person or role, when applicable>
---

# <issue-id>: <business slice title>

## Why
<problem, user/business outcome, and measurable success signal>

## Scope
### In scope
### Out of scope

## Behavior
### EARS requirements
- REQ-001 — The <system> shall <response>.
- REQ-002 — When <trigger>, the <system> shall <response>.
- REQ-003 — While <state>, the <system> shall <response>.
- REQ-004 — If <unwanted condition>, then the <system> shall <response>.

### BDD scenarios
```gherkin
Scenario: SCN-001 — <observable business behavior>
  Given <precondition>
  When <business event>
  Then <observable result>
```

## Design impact
- Architecture model: <link or N/A with reason>
- ADRs: <links or N/A with reason>
- Domain model/invariants: <links or N/A with reason>
- Threat model: <link or N/A with reason>
- Executable contracts: <links or N/A>

## Plan
<ordered implementation slices, migrations, rollout, rollback, and verification>

## Traceability
| Requirement | Scenario | Executable test | Implementation | Evidence |
|---|---|---|---|---|
| REQ-001 | SCN-001 | pending | pending | pending |

## Evidence
- Work item: <URL or ID>
- Pull/merge request: pending
- CI and end-to-end tests: pending
- Security scan: pending or N/A with reason
- Deployment: pending
- Production verification: pending
- Risk acceptance: N/A or owner + expiry + reference
````

Requirements describe externally observable behavior, not implementation steps.
Use stable `REQ-NNN` and `SCN-NNN` identifiers. Scenarios must be automatable or
state explicitly why manual verification is necessary.

## Lifecycle gates

1. **Product gate** — a human product owner approves the outcome and scope.
2. **Behavior gate** — EARS requirements and BDD scenarios are specific,
   testable, and approved before implementation planning.
3. **Design gate** — update architecture, domain artifacts, executable
   contracts, ADRs, and threat model only when the slice triggers them.
4. **Build gate** — tests are written first; code, tests, schemas, migrations,
   and infrastructure implement the approved behavior.
5. **Review gate** — independently verify requirements, architecture, security,
   contracts, tests including end-to-end coverage, and evidence links; then have
   the accountable human author review the resulting diff and exceptions.
6. **Release gate** — record deployment, execute production verification, and
   capture rollback or time-bounded risk acceptance before marking verified.

Do not advance a status based on an agent summary alone. Record observed command
results, URLs, commit SHAs, deployment IDs, or telemetry queries as evidence.

## Trigger rules

- Update `model.likec4` when components, responsibilities, trust boundaries, or
  important relationships change.
- Create an ADR for a consequential choice with meaningful alternatives and
  long-term cost or reversibility impact.
- Update domain artifacts when terminology, entities, states, or invariants change.
- Update the threat model when the change touches authentication, authorization,
  sensitive data, trust boundaries, file operations, external services, or a
  new public interface.
- Update executable contracts in the same change as their implementation.
- If specifications and code conflict, stop and obtain human clarification;
  never silently choose one.

## Optional Beads integration

Beads may mirror the change as an epic and persist Task Briefs. Every Beads task
must reference the change artifact and relevant requirement IDs. When Beads is
unavailable, continue with explicit Markdown briefs. The workflow and durable
traceability must remain complete without Beads.
