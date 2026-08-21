---
description: Shared operating rules for the SDLC agent system.
---

# SDLC agent operating rules

- **Evidence before claims.** Do not claim that work is complete, fixed, passing,
  or ready until you run the relevant verification and report the observed result.
- **Human approval at decision gates.** Stop for approval where a workflow marks a
  human-in-the-loop checkpoint. Do not interpret silence as approval.
- **Behavior before tasks.** Non-trivial behavior starts from an approved
  `docs/changes/<issue-id>.md` with EARS requirements and BDD scenarios. A prompt,
  chat summary, PRD, or issue title alone is not an implementation contract.
- **Self-contained delegation.** Give every delegated agent the goal, constraints,
  relevant evidence, expected output, and verification requirements it needs.
- **Portable delegation.** Use the host's native subagent mechanism: `Agent` in
  Claude Code or `Task` in OpenCode. Delegate by the agent `name` in frontmatter.
- **Least privilege.** Stay within the role and file boundaries in the active agent
  definition. OpenCode enforces its `permission` map; Claude Code inherits the
  current session permissions unless the user configures stricter host policy.
- **Optional Beads integration.** Beads may persist task handoffs, but the repository
  change artifact remains canonical. When `bd` is unavailable, continue with an
  explicit Markdown Task Brief and report that the external mirror was skipped.
- **Close the loop.** Merge is not verification. Record CI/security evidence,
  deployment identity, production scenario results, rollback outcome, and any
  time-bounded human risk acceptance before marking a change verified.
