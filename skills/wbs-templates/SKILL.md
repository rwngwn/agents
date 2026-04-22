---
name: wbs-templates
description: Library of Work Breakdown Structure templates for typical software projects — web SaaS, mobile app, integration/middleware, data pipeline, legacy migration, microservices. Use when starting a WBS for an RFP and need a proven top-level skeleton with role breakdown and typical items to not forget (DevOps, QA infra, UAT, hypercare).
---

# WBS Templates

## When to use

- You are about to build a WBS for an RFP and want a proven skeleton.
- You want to avoid forgetting cross-cutting work (DevOps, QA infra, PM overhead, UAT, handover).
- The RFP does NOT prescribe a client structure (if it does, follow the client and use these templates only as reference for completeness).

## How to use in wbs-planner

1. Pick the closest template from `resources/templates.yaml`.
2. Use the top 2 levels as your starting WBS skeleton.
3. Fill leaves from the RFP's requirements (requirement_ids per leaf).
4. Cross-cutting items (PM, DevOps setup, QA infrastructure) marked `cross_cutting: true` — they don't need requirement_ids.
5. Add/remove items based on THIS RFP's specifics.

## Templates available

| ID | Typ | Default TE range | Kdy použít |
|---|---|---|---|
| `web-app-saas` | Multi-tenant webová aplikace | 80–300 MD | Klasická SaaS, admin + end-user |
| `mobile-app` | Native/RN mobilní aplikace | 100–400 MD | iOS/Android, jednoplatformní nebo cross |
| `integration` | ESB / middleware / connector | 40–150 MD | Propojení 2+ systémů, transformace dat |
| `data-pipeline` | ETL, DWH, analytics | 60–250 MD | Data processing, reportingové řešení |
| `migration` | Legacy → nový systém | 100–500 MD | Data + funkcionalita, postupný cut-over |
| `microservices` | Multi-service ekosystém | 200+ MD | 3+ samostatných služeb |

## Universal cross-cutting items (do every WBS)

Bez těchto leafů nevydávej WBS. Každý má `cross_cutting: true`.

```yaml
- id: PM.1
  title: Projektové řízení (status, schůzky, reporting)
  role: PM
  cross_cutting: true
  effort_rule: "~10% aggregate TE (min 5 MD)"

- id: PM.2
  title: Kickoff + handover workshop
  role: PM
  cross_cutting: true

- id: DEVOPS.1
  title: CI/CD pipeline setup
  role: DevOps
  cross_cutting: true

- id: DEVOPS.2
  title: Infra provisioning (IaC)
  role: DevOps
  cross_cutting: true

- id: DEVOPS.3
  title: Monitoring, alerting, log aggregation
  role: DevOps
  cross_cutting: true

- id: QA.1
  title: Test plan + test infrastructure
  role: QA
  cross_cutting: true

- id: QA.2
  title: UAT koordinace
  role: QA
  cross_cutting: true

- id: UAT.1
  title: Hypercare (4 týdny po go-live)
  role: BE+FE+QA
  cross_cutting: true
  effort_rule: "~5% aggregate TE"

- id: DOC.1
  title: Dokumentace (technická + uživatelská)
  role: Backend
  cross_cutting: true
```

## Anti-forgetting checklist

Když dáváš WBS dohromady, zkontroluj, zda máš položky na:

- [ ] Authentication / autorizace (pokud je to user-facing systém)
- [ ] Data migration (pokud existuje cokoliv, co přebíráte)
- [ ] Logging + audit trail
- [ ] Error handling + retry mechanisms (pro integrace)
- [ ] Rate limiting / abuse protection (pokud je public API)
- [ ] Privacy / GDPR compliance (data retention, export, delete)
- [ ] Backup & disaster recovery (pokud SLA vyžaduje)
- [ ] i18n / l10n (pokud cs + en)
- [ ] Accessibility (WCAG pokud veřejný sektor)
- [ ] Performance testing (pokud jsou NFR na výkon)
- [ ] Security testing (pentest, SAST, dependency scan)
- [ ] Školení klienta / admin training
- [ ] Dokumentace zdrojového kódu + README
- [ ] Předávací protokol + příručka provozu

## Resources

- `resources/templates.yaml` — full per-template skeleton with 2-level structure and typical percentage allocation
