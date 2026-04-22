# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
PERT aggregator — reads WBS JSON with per-leaf O/M/P, computes TE, sigma, and
aggregates (total TE, sigma_total, 90%/95% CI), role breakdown, scenarios
(MVP/Standard/Full), and buffer recommendations.

Run: uv run --script pert.py --input wbs.json --output wbs.json
"""
from __future__ import annotations
import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any


Z_90 = 1.645
Z_95 = 1.96


def compute_pert(o: float, m: float, p: float) -> dict:
    te = (o + 4 * m + p) / 6.0
    sigma = (p - o) / 6.0
    variance = sigma ** 2
    return {
        "O": round(o, 2),
        "M": round(m, 2),
        "P": round(p, 2),
        "te": round(te, 2),
        "sigma": round(sigma, 2),
        "variance": round(variance, 4),
    }


def walk_leaves(items: list[dict], parent_moscow: str | None = None, parent_cc: bool = False):
    """Yield (leaf_item, inherited_moscow, cross_cutting) tuples."""
    for it in items or []:
        moscow = it.get("moscow") or parent_moscow
        cc = it.get("cross_cutting", False) or parent_cc
        children = it.get("children")
        if children:
            yield from walk_leaves(children, moscow, cc)
        else:
            yield it, moscow, cc


def ensure_pert(leaf: dict) -> dict:
    p = leaf.get("pert") or {}
    if "te" not in p or "sigma" not in p:
        O, M, P = float(p["O"]), float(p["M"]), float(p["P"])
        computed = compute_pert(O, M, P)
        # Preserve any personas already there
        computed.update({k: v for k, v in p.items() if k not in computed})
        leaf["pert"] = computed
    return leaf["pert"]


def aggregate(leaves: list[tuple[dict, str | None, bool]]) -> dict:
    te_total = 0.0
    var_total = 0.0
    role_md: dict[str, float] = {}
    for leaf, _mosc, _cc in leaves:
        pert = ensure_pert(leaf)
        te = pert["te"]
        var = pert["variance"]
        te_total += te
        var_total += var
        role = leaf.get("role", "Other")
        role_md[role] = role_md.get(role, 0) + te
    sigma = math.sqrt(var_total) if var_total > 0 else 0.0
    return {
        "te_total": round(te_total, 2),
        "sigma_total": round(sigma, 2),
        "variance_total": round(var_total, 4),
        "ci_90_low": round(te_total - Z_90 * sigma),
        "ci_90_high": round(te_total + Z_90 * sigma),
        "ci_95_low": round(te_total - Z_95 * sigma),
        "ci_95_high": round(te_total + Z_95 * sigma),
        "_role_md_raw": role_md,
    }


def role_breakdown(role_md: dict[str, float]) -> dict:
    total = sum(role_md.values())
    if total <= 0:
        return {}
    raw = {r: (md / total) * 100 for r, md in role_md.items()}
    # Normalize to exactly 100 after rounding (largest-remainder method)
    rounded = {r: round(p, 1) for r, p in raw.items()}
    diff = round(100 - sum(rounded.values()), 1)
    if diff != 0 and rounded:
        top = max(rounded, key=rounded.get)
        rounded[top] = round(rounded[top] + diff, 1)
    return {r: {"md": round(role_md[r], 2), "percent": rounded[r]} for r in role_md}


def scenario(leaves, include_moscow: set[str]) -> dict:
    subset = []
    all_leaves_te = 0.0
    included_leaves_te = 0.0
    for leaf, mosc, cc in leaves:
        pert = ensure_pert(leaf)
        all_leaves_te += pert["te"]
        if not cc and mosc in include_moscow:
            subset.append((leaf, mosc, cc))
            included_leaves_te += pert["te"]
    # Scale cross-cutting items proportionally
    ratio = (included_leaves_te / all_leaves_te) if all_leaves_te > 0 else 0.0
    cc_te = 0.0
    cc_var = 0.0
    for leaf, mosc, cc in leaves:
        if cc:
            pert = ensure_pert(leaf)
            cc_te += pert["te"] * ratio
            cc_var += pert["variance"] * (ratio ** 2)
    agg = aggregate(subset)
    te = agg["te_total"] + cc_te
    var = agg["variance_total"] + cc_var
    sigma = math.sqrt(var) if var > 0 else 0.0
    return {
        "includes": " + ".join(sorted(include_moscow)),
        "te": round(te, 2),
        "sigma": round(sigma, 2),
        "ci_90": [round(te - Z_90 * sigma), round(te + Z_90 * sigma)],
        "ci_95": [round(te - Z_95 * sigma), round(te + Z_95 * sigma)],
        "leaf_count": len(subset),
    }


def sanity_checks(leaves) -> list[str]:
    warnings = []
    for leaf, _m, _cc in leaves:
        p = leaf["pert"]
        O, M, P = p["O"], p["M"], p["P"]
        title = leaf.get("title", leaf.get("id", "?"))
        if P - O < 0.3 * M:
            warnings.append(f"[narrow-interval] {title}: P-O={P-O:.1f} < 0.3*M={0.3*M:.1f}")
        if p["te"] > 10:
            warnings.append(f"[>80h rule] {title}: TE={p['te']} MD (> 10 MD / 80 h)")
        if M < O or P < M:
            warnings.append(f"[ordering] {title}: expected O <= M <= P, got {O}/{M}/{P}")
    return warnings


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, type=Path)
    ap.add_argument("--output", required=True, type=Path)
    ap.add_argument("--contingency-percent", type=float, default=20.0)
    ap.add_argument("--reserve-percent", type=float, default=10.0)
    args = ap.parse_args()

    data: dict[str, Any] = json.loads(args.input.read_text(encoding="utf-8"))
    wbs = data.get("wbs") or []
    leaves = list(walk_leaves(wbs))
    if not leaves:
        print("[pert] No leaves in WBS", file=sys.stderr)
        return 2

    agg = aggregate(leaves)
    role_md = agg.pop("_role_md_raw")
    rb = role_breakdown(role_md)

    scenarios = {
        "mvp": scenario(leaves, {"Must"}),
        "standard": scenario(leaves, {"Must", "Should"}),
        "full": scenario(leaves, {"Must", "Should", "Could"}),
    }

    te_std = scenarios["standard"]["te"]
    buffers = {
        "contingency_percent": args.contingency_percent,
        "contingency_md": round(te_std * args.contingency_percent / 100.0, 2),
        "reserve_percent": args.reserve_percent,
        "reserve_md": round(te_std * args.reserve_percent / 100.0, 2),
    }

    warnings = sanity_checks(leaves)
    if agg["te_total"] and agg["sigma_total"] / agg["te_total"] > 0.20:
        warnings.append(
            f"[high-variance] sigma/TE = {agg['sigma_total']/agg['te_total']:.2%} (> 20%, low confidence)"
        )

    data["aggregate_pert"] = agg
    data["role_breakdown"] = rb
    data["scenarios"] = scenarios
    data["buffers"] = buffers
    if warnings:
        data.setdefault("meta", {})["pert_warnings"] = warnings

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

    print(
        f"[pert] OK — leaves: {len(leaves)}, TE={agg['te_total']}, "
        f"σ={agg['sigma_total']}, 90%CI=[{agg['ci_90_low']}, {agg['ci_90_high']}]"
    )
    for w in warnings:
        print(f"[pert] warn: {w}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
