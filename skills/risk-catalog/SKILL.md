---
name: risk-catalog
description: Catalog of typical software project risks grouped by category (integration, scope, tech, team, client, compliance, timeline, data) with probability/impact defaults, mitigations, and CZ-specific risks (eGovernment, GDPR/ÚOOÚ, NIS2, veřejné zakázky). Use when building the risk section of an estimate and want a checklist to avoid missing common failure modes.
---

# Risk Catalog

## When to use

- You are building the risks section of an estimate.
- You want a structured checklist to not miss common project failure modes.
- You need CZ-specific risks (veřejné zakázky, GDPR via ÚOOÚ, kybernetický zákon, NIS2).

## How to use

1. Load `resources/risks.yaml` — it has ~40 risks grouped by category.
2. For each risk, check if its "trigger conditions" match this RFP.
3. If yes, include in your risk analysis with:
   - Specific anchor (which requirement / open question / integration triggered it)
   - P and I from the catalog (adjust if RFP context differs)
   - Mitigation from catalog (adapt wording)

## Categories in catalog

| Kategorie | Typický počet rizik v RFP | Příklad |
|---|---|---|
| `integration` | 1–3 per integraci | Nedostupný sandbox, chybějící dokumentace |
| `scope` | 2–4 | Scope creep, nejasná akceptace, feature-to-WBS mismatch |
| `tech` | 1–3 | Nový stack pro tým, performance NFR nereálné, legacy závislost |
| `team` | 1–2 | Klíčový člověk odchod, nábor zpomaluje, rozptyl seniority |
| `client` | 2–3 | Pomalé odpovědi, multi-stakeholder decisions, změna kontaktu |
| `compliance` | 1–3 (vzroste u VS/finance/zdraví) | GDPR, NIS2, kybernetický zákon, eGovernment interop |
| `timeline` | 1–2 | Nerealistický deadline, fixní datum + fixní scope |
| `data` | 1–2 per data source | Legacy data kvalita, migrace bez mapping, PII v testech |
| `legal` | 0–2 | IP ownership, third-party licence, penalizace SLA |
| `vendor` | 0–2 | Cloud lock-in, third-party pricing change, supplier bankruptcy |

## Scoring defaults

Katalog má default `probability` a `impact` pro každé riziko. Upravuj dolů, pokud RFP konkrétní riziko explicitně adresuje (např. klient dodal sandbox → sniž pravděpodobnost INT-NO-SANDBOX).

## Anti-cargo-cult pravidlo

**Nedávej do risk analýzy riziko, které nemá konkrétní kotvu v TOMTO RFP.** Lepší 6 konkrétních než 15 generických. Pokud ti zbývá volné místo, přidej spíš podrobnější mitigation na top 3 rizika.

## CZ specifika

Pokud klient je:

- **Veřejná správa / státní instituce** → přidej:
  - `COMPL-EGOV` — eGovernment interoperabilita (ISDS, základní registry)
  - `COMPL-ISVS` — povinnost registrace jako ISVS
  - `LEGAL-ZVZ` — přísná pravidla zakázky (nemožnost změny scope bez dodatku)
  - `COMPL-KYBER` — kybernetický zákon / NIS2 (pro významné subjekty)

- **Banka / pojišťovna / finanční instituce** → přidej:
  - `COMPL-CNB` — dohled ČNB, reporting
  - `COMPL-DORA` — DORA (Digital Operational Resilience Act, od 2025)
  - `COMPL-PSD2` — pokud jakákoliv platební funkce

- **Zdravotnictví** → přidej:
  - `COMPL-EZK` — elektronická zdravotní karta, NIX-ZD
  - `COMPL-UZIS` — reporting ÚZIS
  - `DATA-PII-HEALTH` — zvláštní kategorie osobních údajů

- **Retail / e-commerce** → přidej:
  - `COMPL-EET` (deprekované, ale v legacy systémech stále)
  - `COMPL-ACCESSIBILITY` — EAA (od 28.6.2025 povinné)
  - `VENDOR-PAYMENT-GATEWAY` — GoPay/ComGate lock-in

## Resources

- `resources/risks.yaml` — full catalog (~40 položek)
