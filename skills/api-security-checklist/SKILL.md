---
name: api-security-checklist
description: Extended API security checklist derived from real-world pen-test findings. Adds 5 specific check patterns on top of OWASP Top 10 -- broken AuthZ model, IDOR, mass assignment, JWT non-invalidation, and missing input validation. Load this when scanning Node.js/Next.js/Express APIs.
license: MIT
compatibility: opencode
metadata:
  source: CTOO-434 pen-test findings
  domain: api-security
  frameworks: nextjs, express, node
---

# API Security Checklist

This skill extends `code-vuln-scanner` with 5 specific high-signal check patterns
derived from real pen-test findings. Run these in addition to the standard OWASP Top 10 steps.

---

## Check 1 — Broken Authorization Model (CWE-284, CWE-285)

**Finding origin:** CTOO-437 — 13 of 22 API handlers had no in-handler authorization,
relying only on middleware that checked authentication (session exists), not authorization (role/ownership).

### What to look for

Middleware that only checks session existence, not role:

```bash
# Find auth middleware — check what it actually validates
rg -n "middleware\|withAuth\|requireAuth\|isAuthenticated" --type ts --type js
rg -n "getServerSession\|getSession\|auth()" --type ts --type js | head -40

# Find route handlers — check each one for in-handler role verification
rg -n "export.*async function (GET|POST|PUT|PATCH|DELETE)" --type ts
rg -n "router\.(get|post|put|patch|delete)\s*\(" --type js
```

For every handler found, check:
1. Does it call `getServerSession()` / `getSession()` at the top?
2. Does it check `session.user.role` against an allowed role list?
3. Is there a `withRole(...)` wrapper or equivalent?

Flag any handler where the answer to (2) or (3) is NO, especially:
- POST/PUT/DELETE handlers (write operations)
- Any handler that creates, modifies, or deletes resources owned by specific users/roles
- Admin-only operations (user management, content governance, AI generation triggers)

**Severity:** HIGH to CRITICAL depending on the operation exposed.

### Pattern: missing role check

```bash
# Handlers that get session but never check role
rg -n -A 20 "export async function (POST|PUT|PATCH|DELETE)" --type ts | \
  grep -L "role\|withRole\|isAdmin\|hasPermission"
```

---

## Check 2 — IDOR: Insecure Direct Object Reference (CWE-639)

**Finding origin:** CTOO-440 — endpoints accepted `userId` from query params/body and
passed it directly to DB queries without comparing to the authenticated session user.

### What to look for

```bash
# userId / email / ID accepted from request without ownership check
rg -n "userId.*req\.\|userId.*query\.\|userId.*params\.\|userId.*body\." --type ts --type js
rg -n "email.*req\.\|email.*query\.\|email.*searchParams" --type ts --type js
rg -n "searchParams\.get\(['\"]userId\|query\?\.userId\|params\.userId" --type ts --type js

# Check for ownership validation pattern (absence = IDOR)
rg -n "session\.user\.id.*===\|session\.user\.email.*===" --type ts --type js
```

For each endpoint accepting a user identifier from the request:
1. Is the incoming `userId` compared to `session.user.id`?
2. Is there a role check allowing admins to access other users' data?
3. If neither — flag as IDOR.

**High-risk endpoint patterns:**
- `GET /api/[resource]?userId=X` — returns data scoped to userId from query param
- `POST /api/[resource]` with `userId` in body — creates resource for another user
- `GET /api/user?email=X` — profile lookup by email without ownership check

**Severity:** HIGH — authenticated attacker can access any user's data.

---

## Check 3 — Mass Assignment / Missing Field Whitelist (CWE-915)

**Finding origin:** CTOO-436 — PATCH/PUT handlers passed `request.json()` directly
into MongoDB `$set` without filtering, allowing internal fields (`role`, `createdAt`,
`createdBy`, `status`) to be overwritten.

### What to look for

```bash
# Direct body passthrough to DB update
rg -n "const body = await request\.json\(\)" --type ts --type js -A 5
rg -n "\$set.*body\|\$set.*updates\b" --type ts --type js
rg -n "updateOne\|updateMany\|findOneAndUpdate" --type ts --type js -B 3

# ORM equivalents
rg -n "\.update\(.*body\)\|\.save\(.*body\)\|\.create\(.*body\)" --type ts --type js
rg -n "Object\.assign.*body\|spread.*body.*update" --type ts --type js

# Check for whitelist/pick pattern (absence = mass assignment)
rg -n "pick\(\|allowedFields\|whitelist\|omit\(" --type ts --type js
```

For each mutation handler (`PATCH`, `PUT`, `POST`):
1. Is the body passed through a schema validator (Zod, Joi, class-validator)?
2. Is there an explicit field whitelist (`pick`, `allowedFields`, destructuring only specific keys)?
3. If neither — flag as mass assignment.

**Sensitive fields to highlight if writable:** `role`, `createdAt`, `createdBy`, `updatedAt`, `_id`, `id`, `status`, `keycloakId`, `lastLogin`, `isAdmin`, `permissions`.

**Severity:** CRITICAL if `role` or admin fields are writable. HIGH otherwise.

### Pattern: privilege escalation via mass assignment

```bash
# The specific worst case — role field writable via PATCH /api/users/:id
rg -n "PATCH\|patch" --type ts -l | xargs rg -n "role" 2>/dev/null | head -20
```

---

## Check 4 — JWT Session Not Invalidated on Logout (CWE-613)

**Finding origin:** CTOO-439 — Auth.js JWT strategy; logout only cleared the cookie,
JWT remained valid for up to 30 days. No token blacklist implemented.

### What to look for

```bash
# Identify auth strategy
rg -n "strategy.*jwt\|jwt.*strategy\|session.*strategy" --type ts --type js
rg -n "maxAge\|updateAge\|sessionToken\|JWT_SECRET" --type ts --type js

# Find signout handler
rg -n "signout\|sign-out\|logout\|destroySession" --type ts --type js -A 10

# Check for token blacklist / revocation store
rg -n "blacklist\|revoke\|invalidat.*token\|tokenStore\|redis.*token" --type ts --type js
```

Flag if ALL of the following are true:
1. Auth strategy is `jwt` (not database sessions)
2. Logout handler only clears a cookie, does not invalidate server-side
3. No token revocation mechanism exists (Redis set, DB table, in-memory store)
4. `maxAge` is > 3600 (1 hour) — long-lived tokens amplify the risk

**Also check session config:**
- No absolute timeout (only sliding window) — sessions that never expire if used regularly
- `maxAge` > 86400 (1 day) — flag as HIGH
- `maxAge` > 604800 (7 days) — escalate to CRITICAL

**Severity:** MEDIUM baseline, HIGH if maxAge > 7 days, CRITICAL if stolen token allows persistent access with no revocation path.

---

## Check 5 — Missing Input Validation on Write Endpoints (CWE-20)

**Finding origin:** CTOO-442 — `POST /api/adrs` accepted empty JSON `{}` and returned
`HTTP 201`, creating incomplete DB records that later caused `TypeError` crashes in the
frontend when accessing null properties.

### What to look for

```bash
# POST/PUT handlers — check for schema validation at entry
rg -n "export async function POST\|export async function PUT" --type ts -A 30 | \
  grep -v "safeParse\|parse\|validate\|schema\|Zod\|joi\|yup"

# Absence of validation libraries
rg -rn "safeParse\|\.parse\(\|validate\(\|z\.object\|Joi\.\|yup\." --type ts --type js | wc -l

# Direct DB insert without validation
rg -n "insertOne\|create\(\|insertMany" --type ts --type js -B 5 | \
  grep -v "safeParse\|validate\|schema"

# Null access on potentially-null fields (frontend crash pattern)
rg -n "\.toUpperCase\(\)\|\.toLowerCase\(\)\|\.trim\(\)" --type tsx --type ts | \
  grep -v "\?\." | head -30
```

Flag if:
1. A write endpoint has no schema validation before DB insert
2. Required fields are not enforced server-side (check API docs / DB schema vs handler)
3. Frontend accesses properties without null guards that could be null if record is incomplete

**Severity:** MEDIUM for data integrity. HIGH if incomplete records cause DoS (frontend crashes for any user who views the record).

---

## Reporting additions

When using this skill, add to each finding's remediation section:

- **For AuthZ issues:** "Add `withRole(['required_role'])` wrapper or inline session role check at handler entry. Do not rely solely on middleware for authorization."
- **For IDOR:** "Extract user identity from session only: `const userId = session.user.id`. Never trust userId from request params/body unless role check confirms admin access."
- **For mass assignment:** "Destructure only allowed fields from body, or use `pick(body, ALLOWED_FIELDS)`. Define `ALLOWED_FIELDS` as a const adjacent to the handler."
- **For JWT session:** "Implement token revocation store (Redis SET with TTL matching maxAge). On logout, add token jti to revocation set. Check revocation set in JWT callback."
- **For missing validation:** "Add Zod schema at handler entry: `const result = schema.safeParse(await request.json()); if (!result.success) return Response.json({ error: result.error }, { status: 400 })`."
