---
description: "DEPRECATED — Security pre-review logic has been merged into the architect agent as an embedded Security Skill. This agent is kept for backward compatibility but is no longer invoked by any orchestrator."
mode: subagent
model: github-copilot/claude-haiku-4.5
hidden: true
temperature: 0.1
permission:
  edit:
    "*": deny
  bash:
    "*": deny
---

# DEPRECATED

**This agent has been deprecated.** Its functionality (CWE checklist, security
constraint injection into Task Briefs) has been merged directly into the
**architect** agent as an embedded **Security Skill**.

## Why deprecated

The separate security-pre-reviewer subagent introduced an extra round-trip per
Task Brief during the architect's planning phase. This caused stalling and
increased latency, especially when processing multiple briefs.

By embedding the security checklist directly into the architect, we:
- Eliminate one subagent invocation per Task Brief
- Reduce overall pipeline latency
- Keep the same security coverage (full CWE checklist is preserved in architect.md)
- Allow the architect to batch-process all briefs without waiting for external calls

## Where to find this logic now

See `architect.md` → **Step 5 — Security Skill (embedded)**.

The full checklist covers:
1. Input handling (CWE-20)
2. SQL / Database (CWE-89)
3. Auth & authz (CWE-287, CWE-284)
4. Output encoding (CWE-79)
5. File operations (CWE-22, CWE-434)
6. External requests (CWE-918)
7. Cryptography (CWE-327, CWE-338)
8. Error handling (CWE-209, CWE-532)
9. Cookies/sessions (CWE-614, CWE-1004)
10. Rate limiting (CWE-770)

## If invoked directly

If you are reading this because someone invoked this agent directly, redirect them
to the architect agent. The architect now handles security pre-review as part of
its Task Brief design workflow.
