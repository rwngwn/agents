---
name: estimation-pert
description: Computes PERT three-point estimates with aggregate statistics (TE total, sigma via sqrt-sum-of-variances, 90%/95% confidence intervals) and role breakdown. Use when you have a WBS with O/M/P values per leaf item and need aggregated numbers, scenario totals (MVP/Standard/Full), and role-level MD sums. Runs via `uv run --script` — no manual setup.
---

# Estimation PERT

## When to use

- You have a WBS JSON with per-leaf `{O, M, P, role, moscow}` values.
- You need: TE per item, σ per item, aggregate TE/σ, 90%/95% CI, role breakdown, MVP/Standard/Full scenarios.

## The math (for audit)

Per item:
```
TE       = (O + 4M + P) / 6
σ (std)  = (P − O) / 6
variance = σ²
```

Aggregate across N independent items (Central Limit Theorem):
```
TE_total = Σ TE_i
var_total = Σ variance_i
σ_total   = √var_total     # NOT Σ σ_i
```

Confidence intervals (normal approximation):
```
90% CI = TE_total ± 1.645 · σ_total
95% CI = TE_total ± 1.96  · σ_total
```

## How to run

```bash
uv run --script resources/pert.py \
  --input estimates/<slug>/.wbs.json \
  --output estimates/<slug>/.wbs.json \
  --contingency-percent 20 \
  --reserve-percent 10
```

Input WBS JSON schema (minimum):
```json
{
  "wbs": [
    {
      "id": "1.1",
      "title": "...",
      "role": "Backend",
      "moscow": "Must",        // inherited from requirement_ids
      "requirement_ids": ["R-001"],
      "pert": {"O": 2, "M": 4, "P": 8}
    }
  ]
}
```

The script walks the tree (children arrays), computes per-leaf TE/σ/variance,
then aggregates into:

```json
{
  "role_breakdown": {"Backend": {"md": 58.0, "percent": 38.7}, ...},
  "aggregate_pert": {"te_total": ..., "sigma_total": ..., "ci_90_low": ..., "ci_90_high": ...},
  "scenarios": {
    "mvp":      {"includes": "Must",                  "te": ..., "ci_90": [..., ...]},
    "standard": {"includes": "Must + Should",         "te": ..., "ci_90": [..., ...]},
    "full":     {"includes": "Must + Should + Could", "te": ..., "ci_90": [..., ...]}
  },
  "buffers": {
    "contingency_md": ...,  "contingency_percent": 20,
    "reserve_md": ...,      "reserve_percent": 10
  }
}
```

## Rounding convention

- Intermediate computations: full float precision
- Output: 2 decimals for MD values, 1 decimal for σ, nearest integer for CI bounds
- Role percentages: 1 decimal, normalized to sum to 100

## Scenario filtering

- **MVP**: items whose `moscow == "Must"` (direct + any ancestor `cross_cutting` items scaled by Must-share).
- **Standard**: `moscow in {"Must", "Should"}`.
- **Full**: all except `"Won't"`.

For `cross_cutting: true` items (e.g. PM, DevOps setup) that don't map to a MoSCoW, they're scaled proportionally to the scenario's leaf-level MD ratio.

## Sanity checks

Script will warn (non-fatal) on:
- `P − O < 0.3 * M` on any leaf (too-narrow interval)
- Any leaf > 80 MD (violates 80-hour rule at 8h/day = 10 MD; warn above 10)
- Role % outside `[0, 100]` after normalization
- `sigma_total / te_total > 0.20` (high relative variance, flag as low confidence)

## Resources

- `resources/pert.py` — the calculator
