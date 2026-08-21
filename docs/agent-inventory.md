# Agent inventory

This is the maintained inventory for the 25 agents packaged from `.apm/agents/`.
The source frontmatter remains authoritative for host mode and permissions; this
catalog explains where each agent fits in the AISDLC workflow and when to invoke it.

## Summary

| Class | Count | Purpose |
|---|---:|---|
| Primary entry points | 5 | User-facing orchestration, investigation, review, and communication workflows |
| Product and design support | 6 | Discovery through approved behavior, architecture, and threat modeling |
| Delivery and release support | 7 | TDD planning, execution, independent review, and production verification |
| Security scanners | 4 | Evidence-based secret, code, dependency, and configuration analysis |
| Maintenance and documentation | 3 | Baseline reconstruction, drift detection, and developer documentation |
| **Total** | **25** | One portable APM package for Claude Code and OpenCode |

`Primary` and `subagent` below are the portable `mode` values declared in each
agent file. `Visible` agents can be selected directly in a host; `internal`
agents are normally reached through an orchestrator.

## Primary entry points

| Agent | Mode | Stage | Use it when | Main handoff |
|---|---|---|---|---|
| [`sdlc-plan`](../.apm/agents/sdlc-plan.agent.md) | Primary, visible | Plan | A raw idea must become approved product intent, behavior, design, security, and an implementation handoff | Approved product/change artifacts and TDD task plan |
| [`sdlc-build`](../.apm/agents/sdlc-build.agent.md) | Primary, visible | Build | An approved change is ready for QA strategy, TDD task briefs, implementation, and independent review | Verified implementation evidence and release handoff |
| [`debugger`](../.apm/agents/debugger.agent.md) | Primary, visible | Diagnose | A bug report, failed test, log, or telemetry signal needs a proven root cause and regression-safe fix path | Root-cause evidence and a traceable fix change |
| [`security-reviewer`](../.apm/agents/security-reviewer.agent.md) | Primary, visible | Secure | A codebase or change needs a consolidated evidence-based security assessment | Findings, risk disposition, and remediation changes |
| [`tech-storyteller`](../.apm/agents/tech-storyteller.agent.md) | Primary, visible | Communicate | Technical facts need a blog post, explainer, case study, or launch narrative | Source-checked technical narrative |

## Product and design support

| Agent | Mode | Stage | Use it when | Typical caller / output |
|---|---|---|---|---|
| [`discovery`](../.apm/agents/discovery.agent.md) | Subagent, internal | Discover | Personas, journeys, pain points, and competitive context are missing | `sdlc-plan` / discovery evidence |
| [`strategist`](../.apm/agents/strategist.agent.md) | Subagent, internal | Strategize | Discovery must become strategic options, OKRs, a PR/FAQ, and a hypothesis | `sdlc-plan` / approved strategy |
| [`pm-writer`](../.apm/agents/pm-writer.agent.md) | Subagent, internal | Product intent | An approved direction needs a durable PRD or capability brief | `sdlc-plan` / `docs/product/<capability>.md` |
| [`change-spec-writer`](../.apm/agents/change-spec-writer.agent.md) | Subagent, internal | Behavior | A product outcome must be sliced into EARS requirements, BDD scenarios, triggers, and evidence anchors | Planning, debugging, security, or drift workflow / `docs/changes/<issue-id>.md` |
| [`system-architect`](../.apm/agents/system-architect.agent.md) | Subagent, internal | Design | Approved behavior changes architecture, ADRs, domain rules, migrations, or executable contracts | `sdlc-plan` / approved design and canonical design artifacts |
| [`threat-modeler`](../.apm/agents/threat-modeler.agent.md) | Subagent, internal | Threat model | A change touches trust boundaries, identities, sensitive data, public interfaces, or material abuse paths | `sdlc-plan` / `docs/security/threat-model.md` update and risk ownership |

## Delivery and release support

| Agent | Mode | Stage | Use it when | Typical caller / output |
|---|---|---|---|---|
| [`spec`](../.apm/agents/spec.agent.md) | Subagent, internal | Plan implementation | Approved requirements and design must be mapped to codebase-grounded TDD tasks | `sdlc-plan`, `sdlc-build`, or `debugger` / self-contained task plan |
| [`spec-tasks`](../.apm/agents/spec-tasks.agent.md) | Subagent, internal | Mirror tasks | An approved task plan should be mirrored mechanically into Beads | `spec` / verified Beads epic and child task IDs |
| [`qa-strategist`](../.apm/agents/qa-strategist.agent.md) | Subagent, internal | Test design | Requirements need edge cases, error paths, regression coverage, and executable-test mapping | `sdlc-build` / test strategy |
| [`architect`](../.apm/agents/architect.agent.md) | Subagent, internal | Brief work | A planned task needs a traceable TDD Task Brief with security and quality gates | `sdlc-build` / enriched worker brief |
| [`builder-worker`](../.apm/agents/builder-worker.agent.md) | Subagent, internal | Implement | An approved Task Brief is ready for TDD implementation and verification | `sdlc-build` or `debugger` / code, executable artifacts, tests, and Worker Summary |
| [`builder-reviewer`](../.apm/agents/builder-reviewer.agent.md) | Subagent, internal | Review | Worker claims must be checked independently against behavior, design, security, code, tests, and evidence | `sdlc-build` or `debugger` / approve-or-revise verdict |
| [`release-verifier`](../.apm/agents/release-verifier.agent.md) | Subagent, visible | Verify release | An approved implementation must be tied to a deployment and observed production behavior | Build or debugging workflow / deployment, telemetry, rollback, and scenario evidence |

## Security scanners

These four internal scanners are coordinated by `security-reviewer`; they report
evidence and never silently modify the target codebase.

| Agent | Mode | Focus | Main evidence |
|---|---|---|---|
| [`secrets-scanner`](../.apm/agents/secrets-scanner.agent.md) | Subagent, internal | Credentials, tokens, keys, private material, and high-entropy strings | File, line, and matched secret pattern |
| [`code-vuln-scanner`](../.apm/agents/code-vuln-scanner.agent.md) | Subagent, internal | OWASP risks, authorization, injection, SSRF, crypto, and business logic | Vulnerable code path and exploit reasoning |
| [`deps-scanner`](../.apm/agents/deps-scanner.agent.md) | Subagent, internal | CVEs, package freshness, integrity, licensing, and supply chain | Package, installed version, advisory, and fixed version |
| [`config-scanner`](../.apm/agents/config-scanner.agent.md) | Subagent, internal | CORS, headers, cookies, CSRF, uploads, TLS, containers, and runtime settings | Misconfigured setting and file location |

## Maintenance and documentation

| Agent | Mode | Stage | Use it when | Main handoff |
|---|---|---|---|---|
| [`spec-archaeologist`](../.apm/agents/spec-archaeologist.agent.md) | Subagent, visible | Baseline | An existing codebase lacks trustworthy product, architecture, ADR, domain, or contract inventories | Evidence-backed canonical baseline without invented intent |
| [`spec-drift-detector`](../.apm/agents/spec-drift-detector.agent.md) | Subagent, visible | Detect drift | Intent, executable artifacts, code, or delivery evidence may no longer agree | Traceability, freshness, artifact-gap, and evidence-gap report |
| [`tech-writer`](../.apm/agents/tech-writer.agent.md) | Subagent, visible | Document | Developers need precise API docs, READMEs, migration guides, or changelogs | Source-checked reference documentation linked to executable contracts |

## Lifecycle coverage

```text
sdlc-plan
  discovery → strategist → pm-writer → change-spec-writer
  → system-architect + threat-modeler → spec

sdlc-build
  qa-strategist → architect → builder-worker ↔ builder-reviewer
  → human/CI/security gates → release-verifier

maintenance
  debugger → change-spec-writer → build/release path
  spec-archaeologist → canonical baseline
  spec-drift-detector → remediation change
  security-reviewer → four scanners → remediation change
```

Beads is only an optional mirror through `spec-tasks`. The canonical change
control remains `docs/changes/<issue-id>.md`, while native contracts, tests,
schemas, migrations, infrastructure, and code remain executable sources.
