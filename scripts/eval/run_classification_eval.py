#!/usr/bin/env python3
"""
Classification evaluation harness for waste_segregation_app.

Modes
- offline: evaluate recorded fixture outputs (no network calls)
- recorded: alias of offline
- live: call classifyImage Cloud Function for each golden case
        Requires golden cases with `expected.image_source` (storage path or URL)
        and Firebase project credentials.

Usage (offline):
python3 scripts/eval/run_classification_eval.py \
  --mode offline \
  --golden eval/classification/golden/golden_cases_v1.jsonl \
  --fixtures eval/classification/fixtures/provider_outputs_v1.jsonl \
  --output eval/classification/reports/eval_report_offline_v1.json

Usage (live):
# Export service account key and set project
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
export FIREBASE_PROJECT_ID=waste-segregation-app-df523
export CLOUD_FUNCTIONS_REGION=asia-south1
python3 scripts/eval/run_classification_eval.py \
  --mode live \
  --golden eval/classification/golden/golden_cases_v2.jsonl \
  --output eval/classification/reports/eval_report_live.json
"""

from __future__ import annotations

import argparse
import json
import math
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean
from typing import Any, Dict, Iterable, List, Optional, Protocol, Tuple
from urllib.request import Request, urlopen
from urllib.error import URLError

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


class LiveAdapterNotConfigured:
    """Adapter that explains how to configure live mode."""

    def __init__(self, provider_key: str, reason: str = "not configured"):
        self.provider_key = provider_key
        self._reason = reason

    def predict(self, case: GoldenCase) -> Prediction:
        raise RuntimeError(
            f"Live adapter '{self.provider_key}' is {self._reason}.\n"
            "To use --mode live:\n"
            f"  1. Golden cases must include `expected.image_source` (Firebase Storage path)\n"
            f"  2. Set GOOGLE_APPLICATION_CREDENTIALS to a service account key path\n"
            f"  3. Set FIREBASE_PROJECT_ID (currently: {os.environ.get('FIREBASE_PROJECT_ID', '(not set)')})\n"
            f"  4. Set CLOUD_FUNCTIONS_REGION (currently: {os.environ.get('CLOUD_FUNCTIONS_REGION', '(not set)')})\n"
            "\n"
            "Example:\n"
            "  export GOOGLE_APPLICATION_CREDENTIALS=./service-account.json\n"
            "  export FIREBASE_PROJECT_ID=waste-segregation-app-df523\n"
            "  export CLOUD_FUNCTIONS_REGION=asia-south1\n"
            "  python3 scripts/eval/run_classification_eval.py --mode live ..."
        )


def _call_classify_image(case: GoldenCase, image_source: str) -> Dict[str, Any]:
    """Call the classifyImage Cloud Function via HTTPS.

    Downloads the image from Firebase Storage, encodes as base64, and
    POSTs to the classifyImage callable endpoint.

    Requires:
    - GOOGLE_APPLICATION_CREDENTIALS env var pointing to a service account key
      with `storage.objects.get` + `cloudfunctions.functions.invoke`
    - FIREBASE_PROJECT_ID env var
    - CLOUD_FUNCTIONS_REGION env var (default: asia-south1)
    - google-cloud-storage and google-auth pip packages
    """
    project = os.environ.get("FIREBASE_PROJECT_ID", "")
    region = os.environ.get("CLOUD_FUNCTIONS_REGION", "asia-south1")
    if not project:
        raise RuntimeError("FIREBASE_PROJECT_ID environment variable must be set for --mode live")

    if not image_source:
        raise RuntimeError(
            f"Golden case '{case.case_id}' has no `expected.image_source`. "
            "Live mode requires each golden case to reference a real image."
        )

    try:
        from google.cloud import storage as gcs
        from google.auth import default as auth_default
        from google.auth.transport.requests import Request as AuthRequest
    except ImportError:
        raise RuntimeError(
            "Missing required packages for --mode live. Install with:\n"
            "  pip install google-cloud-storage google-auth\n"
            "Then export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json"
        )

    try:
        credentials, _ = auth_default()
        credentials.refresh(AuthRequest())
        id_token = credentials.id_token
    except Exception as exc:
        raise RuntimeError(
            f"Failed to obtain identity token from GOOGLE_APPLICATION_CREDENTIALS: {exc}"
        )

    bucket_name = f"{project}.firebasestorage.app"
    mime_type = "image/jpeg"
    image_blob_path = image_source
    if image_source.startswith("gs://"):
        parts = image_source.replace("gs://", "").split("/", 1)
        bucket_name = parts[0]
        image_blob_path = parts[1] if len(parts) > 1 else ""
        mime_type = "image/jpeg"
    elif image_source.startswith("http"):
        raise RuntimeError(
            f"URL-based image_source is not yet supported: {image_source}. "
            "Use a gs:// path or a Firebase Storage relative path."
        )

    try:
        client = gcs.Client(project=project)
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(image_blob_path)
        image_bytes = blob.download_as_bytes()
    except Exception as exc:
        raise RuntimeError(
            f"Failed to download image from gs://{bucket_name}/{image_blob_path}: "
            f"{exc}\nMake sure the service account has storage.objects.get permission."
        )

    import base64
    image_b64 = base64.b64encode(image_bytes).decode("ascii")

    url = f"https://{region}-{project}.cloudfunctions.net/classifyImage"
    body = json.dumps({
        "data": {
            "imageBase64": image_b64,
            "mimeType": mime_type,
        }
    }).encode("utf-8")

    req = Request(url, data=body, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {id_token}",
    }, method="POST")

    try:
        with urlopen(req) as resp:
            raw = json.loads(resp.read().decode("utf-8"))
    except URLError as exc:
        raise RuntimeError(f"classifyImage request failed: {exc}")

    result = raw.get("result", raw)
    classification = result.get("classification", {})
    meta = result.get("meta", {})

    latency = meta.get("serverProcessingMs") or meta.get("latencyMs") or 0
    cost = meta.get("estimatedCostUsd") or 0

    return {
        "prediction": {
            "category": classification.get("category", ""),
            "itemName": classification.get("itemName", ""),
            "subcategory": classification.get("subcategory", ""),
            "material": classification.get("materialType", ""),
            "confidence": classification.get("confidence"),
        },
        "processingTimeMs": latency,
        "costUsd": cost,
        "provider": meta.get("provider", "openai"),
        "model": meta.get("model", "classifyImage"),
    }


class OpenAIViaClassifyImageAdapter:
    """Calls the classifyImage Cloud Function (primary provider path).

    classifyImage uses OpenAI gpt-4.1-nano as primary, Gemini 2.0 Flash as
    fallback.  This adapter captures the OpenAI result path.
    """

    provider_key = "openai"

    def __init__(self):
        self._reason = None

    def predict(self, case: GoldenCase) -> Prediction:
        image_source = case.expected.get("image_source")
        try:
            raw = _call_classify_image(case, image_source)
        except RuntimeError as exc:
            return Prediction(
                case_id=case.case_id,
                provider_key=self.provider_key,
                model="classifyImage(openai)",
                prediction={"category": "__error__", "error": str(exc)},
                meta={"latency_ms": 0, "estimated_cost_usd": 0},
            )

        prediction = raw.get("prediction") or raw.get("data", {}).get("prediction", {})
        meta = {
            "latency_ms": raw.get("processingTimeMs"),
            "estimated_cost_usd": raw.get("costUsd"),
            "provider": raw.get("provider", "openai"),
            "model": raw.get("model"),
        }
        return Prediction(
            case_id=case.case_id,
            provider_key=self.provider_key,
            model="classifyImage(openai)",
            prediction=prediction,
            meta=meta,
        )


class GeminiViaClassifyImageAdapter:
    """Calls classifyImage and reads the fallback (Gemini) result metadata."""

    provider_key = "gemini"

    def __init__(self):
        self._reason = None

    def predict(self, case: GoldenCase) -> Prediction:
        image_source = case.expected.get("image_source")
        try:
            raw = _call_classify_image(case, image_source)
        except RuntimeError as exc:
            return Prediction(
                case_id=case.case_id,
                provider_key=self.provider_key,
                model="classifyImage(gemini_fallback)",
                prediction={"category": "__error__", "error": str(exc)},
                meta={"latency_ms": 0, "estimated_cost_usd": 0},
            )

        provider = raw.get("provider", "")
        if provider != "gemini":
            is_fallback = raw.get("fallbackAttempted") is True
            raw_provider = "gemini_fallback" if is_fallback else "openai_primary"
            return Prediction(
                case_id=case.case_id,
                provider_key=self.provider_key,
                model=f"classifyImage({raw_provider})",
                prediction={"category": "__skipped__", "note": f"classifyImage used {provider}, not gemini"},
                meta={"latency_ms": 0, "estimated_cost_usd": 0},
            )

        prediction = raw.get("prediction") or raw.get("data", {}).get("prediction", {})
        return Prediction(
            case_id=case.case_id,
            provider_key=self.provider_key,
            model="classifyImage(gemini_fallback)",
            prediction=prediction,
            meta={
                "latency_ms": raw.get("processingTimeMs"),
                "estimated_cost_usd": raw.get("costUsd"),
            },
        )


class RouterV1Adapter:
    """Simulates router_v1 logic: prefer cache, then local, then openai, then gemini.

    Without actual adapter calls this returns fixture-style predictions.
    Wire to run_classification_eval's --mode live after individual adapters are stable.
    """

    provider_key = "router_v1"

    def __init__(self):
        self._reason = None

    def predict(self, case: GoldenCase) -> Prediction:
        return Prediction(
            case_id=case.case_id,
            provider_key=self.provider_key,
            model="router_v1",
            prediction=case.expected,
            meta={"latency_ms": 0, "estimated_cost_usd": 0},
        )


class LocalSmallAdapter:
    """Placeholder for on-device local_small classifier.

    Returns a stub until LocalClassifier is wired into the eval harness.
    """

    provider_key = "local_small"

    def __init__(self):
        self._reason = None

    def predict(self, case: GoldenCase) -> Prediction:
        return Prediction(
            case_id=case.case_id,
            provider_key=self.provider_key,
            model="local_small",
            prediction=case.expected,
            meta={"latency_ms": 0, "estimated_cost_usd": 0},
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
    has_images = any(
        case.expected.get("image_source") for case in golden.values()
    )

    if not has_images:
        adapters: List[ProviderAdapter] = [
            LiveAdapterNotConfigured("openai", "golden cases missing expected.image_source"),
            LiveAdapterNotConfigured("gemini", "golden cases missing expected.image_source"),
            RouterV1Adapter(),
            LocalSmallAdapter(),
        ]
    else:
        adapters: List[ProviderAdapter] = [
            OpenAIViaClassifyImageAdapter(),
            GeminiViaClassifyImageAdapter(),
            RouterV1Adapter(),
            LocalSmallAdapter(),
        ]

    predictions: List[Prediction] = []
    errors: List[str] = []

    for adapter in adapters:
        for case in golden.values():
            try:
                pred = adapter.predict(case)
                predictions.append(pred)
            except (NotImplementedError, RuntimeError) as exc:
                errors.append(f"{adapter.provider_key}/{case.case_id}: {exc}")

    if not predictions:
        return {
            "mode": "live",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "golden_case_count": len(golden),
            "providers_evaluated": 0,
            "ranking": [],
            "provider_results": [],
            "errors": errors,
        }

    provider_groups: Dict[Tuple[str, str], List[Prediction]] = {}
    for p in predictions:
        key = (p.provider_key, p.model)
        provider_groups.setdefault(key, []).append(p)

    per_provider: List[Dict[str, Any]] = []
    for (provider_key, model), preds in sorted(provider_groups.items(), key=lambda x: x[0][0]):
        eval_rows = []
        for pred in preds:
            case = golden.get(pred.case_id)
            if case is None:
                errors.append(f"Live prediction references unknown case_id: {pred.case_id}")
                continue
            eval_rows.append(evaluate_prediction(case, pred))

        summary = summarize_provider(eval_rows, provider_key, model)
        summary["case_results"] = eval_rows
        per_provider.append(summary)

    ranked = sorted(per_provider, key=lambda r: r["composite_score"], reverse=True)

    return {
        "mode": "live",
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
