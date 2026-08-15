---
description: Shared operating rules for the SDLC agent system.
---

# SDLC agent operating rules

- **Evidence before claims.** Do not claim that work is complete, fixed, passing,
  or ready until you run the relevant verification and report the observed result.
- **Human approval at decision gates.** Stop for approval where a workflow marks a
  human-in-the-loop checkpoint. Do not interpret silence as approval.
- **Self-contained delegation.** Give every delegated agent the goal, constraints,
  relevant evidence, expected output, and verification requirements it needs.
- **Portable delegation.** Use the host's native subagent mechanism: `Agent` in
  Claude Code or `Task` in OpenCode. Delegate by the agent `name` in frontmatter.
- **Least privilege.** Stay within the role and file boundaries in the active agent
  definition. OpenCode enforces its `permission` map; Claude Code inherits the
  current session permissions unless the user configures stricter host policy.
- **Optional Beads integration.** When `bd` is available, use it for durable task
  handoffs. When it is unavailable, continue with an explicit Markdown task brief
  and tell the user that the handoff was not persisted in Beads.
