---
description: Full API security audit — runs all 4 scanners in parallel (secrets, code vulns, deps, config) with the api-security-checklist skill loaded. Covers AuthZ model, IDOR, mass assignment, JWT session, and input validation on top of OWASP Top 10. Creates Beads tasks for every finding.
input:
  - scope: "Optional path to audit; defaults to the full repository"
argument-hint: "[scope]"
---

Delegate this audit to the `security-reviewer` agent with the host's native
subagent mechanism, then present its final consolidated report.

Run a full security audit of this codebase. Scope the scan to
`${input:scope}` when provided; otherwise scan the full repository.

Strictness: MAXIMUM. Use the api-security-checklist skill in code-vuln-scanner.

In addition to the standard OWASP Top 10 scan, explicitly check for all 5 patterns from the api-security-checklist skill:
1. Broken authorization model — handlers that only check authentication, not role/ownership
2. IDOR — endpoints accepting userId/email from request params without session ownership check
3. Mass assignment — PATCH/PUT passing request body directly to DB $set without field whitelist
4. JWT not invalidated on logout — no token revocation store, long maxAge
5. Missing input validation — write endpoints with no schema validation before DB insert

After the scan, present a consolidated report and offer to create Beads remediation tasks.
