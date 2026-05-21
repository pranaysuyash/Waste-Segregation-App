#!/usr/bin/env python3
"""
Classification evaluation harness for waste_segregation_app.

Modes
- offline: evaluate recorded fixture outputs (no network calls)
- recorded: alias of offline
- live: adapter interface placeholder (implement provider calls before use)

Usage
python3 scripts/eval/run_classification_eval.py \
  --mode offline \
  --golden eval/classification/golden/golden_cases_v1.jsonl \
  --fixtures eval/classification/fixtures/provider_outputs_v1.jsonl \
  --output eval/classification/reports/eval_report_offline_v1.json
"""

from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean
from typing import Any, Dict, Iterable, List, Optional, Protocol, Tuple

ALL_CATEGORIES = [
    "Wet Waste",
    "Dry Waste",
    "Hazardous Waste",
    "Medical Waste",
    "Non-Waste",
]


@dataclass
class GoldenCase:
    case_id: str
    expected_category: str
    acceptable_categories: List[str]
    must_not_categories: List[str]
    strict_fields: List[str]
    safety_critical: bool
    expected: Dict[str, Any]


@dataclass
class Prediction:
    case_id: str
    provider_key: str
    model: str
    prediction: Dict[str, Any]
    meta: Dict[str, Any]


class ProviderAdapter(Protocol):
    provider_key: str

    def predict(self, case: GoldenCase) -> Prediction:
        ...


class LiveAdapterNotImplemented:
    def __init__(self, provider_key: str):
        self.provider_key = provider_key

    def predict(self, case: GoldenCase) -> Prediction:
        raise NotImplementedError(
            f"live adapter '{self.provider_key}' is not implemented. "
            "Wire this adapter to backend callable/provider API before using --mode live."
        )


def read_jsonl(path: Path) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid JSONL at {path}:{line_no}: {exc}") from exc
    return rows


def percentile(values: List[float], p: float) -> Optional[float]:
    if not values:
        return None
    if p <= 0:
        return min(values)
    if p >= 100:
        return max(values)
    sorted_vals = sorted(values)
    k = (len(sorted_vals) - 1) * (p / 100.0)
    lo = math.floor(k)
    hi = math.ceil(k)
    if lo == hi:
        return sorted_vals[int(k)]
    return sorted_vals[lo] + (sorted_vals[hi] - sorted_vals[lo]) * (k - lo)


def load_golden_cases(path: Path) -> Dict[str, GoldenCase]:
    rows = read_jsonl(path)
    cases: Dict[str, GoldenCase] = {}
    for row in rows:
        case_id = row["case_id"]
        if case_id in cases:
            raise ValueError(f"Duplicate case_id in golden set: {case_id}")
        expected = row["expected"]
        acceptance = row["acceptance"]
        safety = row["safety"]
        category = expected["category"]
        if category not in ALL_CATEGORIES:
            raise ValueError(f"Invalid expected.category '{category}' in {case_id}")
        cases[case_id] = GoldenCase(
            case_id=case_id,
            expected_category=category,
            acceptable_categories=list(acceptance.get("acceptable_categories", [category])),
            must_not_categories=list(acceptance.get("must_not_categories", [])),
            strict_fields=list(acceptance.get("strict_fields", ["category"])),
            safety_critical=bool(safety.get("safety_critical", False)),
            expected=expected,
        )
    return cases


def load_fixture_predictions(path: Path) -> List[Prediction]:
    rows = read_jsonl(path)
    out: List[Prediction] = []
    for row in rows:
        out.append(
            Prediction(
                case_id=row["case_id"],
                provider_key=row["provider_key"],
                model=row["model"],
                prediction=row.get("prediction", {}),
                meta=row.get("meta", {}),
            )
        )
    return out


def evaluate_prediction(case: GoldenCase, pred: Prediction) -> Dict[str, Any]:
    pred_cat = pred.prediction.get("category")
    strict_pass = True
    for field in case.strict_fields:
        if pred.prediction.get(field) != case.expected.get(field):
            strict_pass = False
            break

    acceptable_pass = pred_cat in case.acceptable_categories
    must_not_violation = pred_cat in case.must_not_categories

    safety_failure = case.safety_critical and (
        (pred_cat != case.expected_category) or must_not_violation
    )

    confidence = pred.prediction.get("confidence")
    try:
        confidence = float(confidence) if confidence is not None else None
    except Exception:
        confidence = None

    return {
        "case_id": case.case_id,
        "expected_category": case.expected_category,
        "predicted_category": pred_cat,
        "strict_pass": strict_pass,
        "acceptable_pass": acceptable_pass,
        "must_not_violation": must_not_violation,
        "safety_critical": case.safety_critical,
        "safety_failure": safety_failure,
        "confidence": confidence,
        "latency_ms": pred.meta.get("latency_ms"),
        "estimated_cost_usd": pred.meta.get("estimated_cost_usd"),
    }


def summarize_provider(results: List[Dict[str, Any]], provider_key: str, model: str) -> Dict[str, Any]:
    total = len(results)
    strict_pass = sum(1 for r in results if r["strict_pass"])
    acceptable_pass = sum(1 for r in results if r["acceptable_pass"])
    must_not_violations = sum(1 for r in results if r["must_not_violation"])
    safety_cases = [r for r in results if r["safety_critical"]]
    safety_failures = sum(1 for r in safety_cases if r["safety_failure"])

    confidences = [r["confidence"] for r in results if r["confidence"] is not None]
    high_conf_total = sum(1 for r in results if (r["confidence"] or 0) >= 0.75)
    high_conf_wrong = sum(
        1
        for r in results
        if ((r["confidence"] or 0) >= 0.75) and (not r["strict_pass"])
    )

    latencies = []
    costs = []
    for r in results:
        lat = r.get("latency_ms")
        cost = r.get("estimated_cost_usd")
        if isinstance(lat, (int, float)):
            latencies.append(float(lat))
        if isinstance(cost, (int, float)):
            costs.append(float(cost))

    strict_rate = strict_pass / total if total else 0
    acceptable_rate = acceptable_pass / total if total else 0

    # Composite ranking score (higher is better)
    # heavy penalty for safety failures and must-not violations
    score = (
        strict_rate * 100
        + acceptable_rate * 30
        - safety_failures * 12
        - must_not_violations * 6
        - high_conf_wrong * 3
    )

    p50 = percentile(latencies, 50) if latencies else None
    p90 = percentile(latencies, 90) if latencies else None

    return {
        "provider_key": provider_key,
        "model": model,
        "total_cases": total,
        "strict_pass": strict_pass,
        "strict_pass_rate": round(strict_rate, 4),
        "acceptable_pass": acceptable_pass,
        "acceptable_pass_rate": round(acceptable_rate, 4),
        "must_not_violations": must_not_violations,
        "safety_cases": len(safety_cases),
        "safety_failures": safety_failures,
        "high_confidence_predictions": high_conf_total,
        "high_confidence_wrong": high_conf_wrong,
        "confidence_mean": round(mean(confidences), 4) if confidences else None,
        "latency_ms": {
            "avg": round(mean(latencies), 2) if latencies else None,
            "p50": round(p50, 2) if p50 is not None else None,
            "p90": round(p90, 2) if p90 is not None else None,
        },
        "cost_usd": {
            "total": round(sum(costs), 6) if costs else None,
            "avg": round(mean(costs), 6) if costs else None,
        },
        "composite_score": round(score, 3),
    }


def run_offline(golden: Dict[str, GoldenCase], fixture_predictions: List[Prediction]) -> Dict[str, Any]:
    provider_groups: Dict[Tuple[str, str], List[Prediction]] = {}
    for p in fixture_predictions:
        key = (p.provider_key, p.model)
        provider_groups.setdefault(key, []).append(p)

    per_provider: List[Dict[str, Any]] = []
    errors: List[str] = []

    for (provider_key, model), preds in sorted(provider_groups.items(), key=lambda x: x[0][0]):
        eval_rows: List[Dict[str, Any]] = []
        seen_case_ids = set()

        for pred in preds:
            case = golden.get(pred.case_id)
            if case is None:
                errors.append(f"Fixture references unknown case_id: {pred.case_id}")
                continue
            seen_case_ids.add(pred.case_id)
            eval_rows.append(evaluate_prediction(case, pred))

        missing = sorted(set(golden.keys()) - seen_case_ids)
        if missing:
            errors.append(
                f"Provider {provider_key}/{model} missing {len(missing)} cases: {missing[:6]}"
                + (" ..." if len(missing) > 6 else "")
            )

        summary = summarize_provider(eval_rows, provider_key, model)
        summary["case_results"] = eval_rows
        per_provider.append(summary)

    ranked = sorted(per_provider, key=lambda r: r["composite_score"], reverse=True)

    return {
        "mode": "offline",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "golden_case_count": len(golden),
        "providers_evaluated": len(per_provider),
        "ranking": [
            {
                "rank": idx + 1,
                "provider_key": row["provider_key"],
                "model": row["model"],
                "composite_score": row["composite_score"],
                "strict_pass_rate": row["strict_pass_rate"],
                "safety_failures": row["safety_failures"],
                "must_not_violations": row["must_not_violations"],
            }
            for idx, row in enumerate(ranked)
        ],
        "provider_results": ranked,
        "errors": errors,
    }


def run_live(golden: Dict[str, GoldenCase]) -> Dict[str, Any]:
    adapters: List[ProviderAdapter] = [
        LiveAdapterNotImplemented("openai"),
        LiveAdapterNotImplemented("gemini"),
        LiveAdapterNotImplemented("router_v1"),
        LiveAdapterNotImplemented("local_small"),
    ]

    raise NotImplementedError(
        "Live mode adapter calls are intentionally left as explicit TODOs. "
        "Wire adapters to backend callable/provider APIs and return Prediction rows before using --mode live."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Waste classification eval harness")
    parser.add_argument("--mode", choices=["offline", "recorded", "live"], default="offline")
    parser.add_argument(
        "--golden",
        default="eval/classification/golden/golden_cases_v1.jsonl",
        help="Path to golden cases JSONL",
    )
    parser.add_argument(
        "--fixtures",
        default="eval/classification/fixtures/provider_outputs_v1.jsonl",
        help="Path to provider fixture outputs JSONL (offline/recorded modes)",
    )
    parser.add_argument(
        "--output",
        default="eval/classification/reports/eval_report_offline_v1.json",
        help="Path to output report JSON",
    )
    args = parser.parse_args()

    golden_path = Path(args.golden)
    output_path = Path(args.output)

    if not golden_path.exists():
        raise SystemExit(f"Golden file not found: {golden_path}")

    golden = load_golden_cases(golden_path)

    if args.mode in ("offline", "recorded"):
        fixtures_path = Path(args.fixtures)
        if not fixtures_path.exists():
            raise SystemExit(f"Fixtures file not found: {fixtures_path}")
        fixture_predictions = load_fixture_predictions(fixtures_path)
        report = run_offline(golden, fixture_predictions)
    else:
        report = run_live(golden)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    print(
        json.dumps(
            {
                "mode": args.mode,
                "golden_cases": len(golden),
                "output": str(output_path),
                "top_rank": report.get("ranking", [None])[0],
                "errors": len(report.get("errors", [])),
            },
            indent=2,
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
