#!/usr/bin/env python3
"""
Export classification feedback into privacy-scrubbed review queue and approved candidates.

Input formats supported:
- JSON array of feedback objects
- JSON object with key `documents` containing array
- JSONL (one feedback JSON object per line)

Example:
python3 scripts/eval/export_feedback_candidates.py \
  --input data/classification_feedback_export.json \
  --output-dir eval/classification/feedback_exports
"""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List

APPROVED_STATUSES = {
    "approved",
    "reviewed_accepted_impacted_ai",
    "reviewed_accepted_informational",
}


def _sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def load_input(path: Path) -> List[Dict[str, Any]]:
    raw = path.read_text(encoding="utf-8").strip()
    if not raw:
        return []

    # Try JSON first
    try:
        parsed = json.loads(raw)
        if isinstance(parsed, list):
            return [x for x in parsed if isinstance(x, dict)]
        if isinstance(parsed, dict):
            docs = parsed.get("documents", [])
            if isinstance(docs, list):
                return [x for x in docs if isinstance(x, dict)]
    except json.JSONDecodeError:
        pass

    # Fallback: JSONL
    rows: List[Dict[str, Any]] = []
    for line_no, line in enumerate(raw.splitlines(), start=1):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            if isinstance(obj, dict):
                rows.append(obj)
        except json.JSONDecodeError as exc:
            raise ValueError(f"Invalid JSON at line {line_no}: {exc}") from exc
    return rows


def normalize_row(row: Dict[str, Any]) -> Dict[str, Any]:
    user_id = str(row.get("userId", ""))
    original_id = str(row.get("originalClassificationId", ""))
    review_status = str(row.get("reviewStatus", "pending_review"))
    suggested_category = str(row.get("userSuggestedCategory", "")).strip()
    suggested_item = str(row.get("userSuggestedItemName", "")).strip()
    suggested_material = str(row.get("userSuggestedMaterial", "")).strip()

    candidate_id_seed = f"{original_id}|{suggested_category}|{suggested_item}|{suggested_material}"

    return {
        "candidate_id": _sha(candidate_id_seed)[:24],
        "source_type": "user_correction",
        "review_status": review_status,
        "user_id_hash": _sha(user_id)[:16] if user_id else None,
        "original": {
            "classification_id": original_id,
            "item_name": row.get("originalAIItemName"),
            "category": row.get("originalAICategory"),
            "material": row.get("originalAIMaterial"),
            "confidence": row.get("originalAIConfidence"),
        },
        "suggested": {
            "item_name": row.get("userSuggestedItemName"),
            "category": row.get("userSuggestedCategory"),
            "material": row.get("userSuggestedMaterial"),
        },
        "review_meta": {
            "admin_reviewer_id": row.get("adminReviewerId"),
            "admin_review_timestamp": row.get("adminReviewTimestamp"),
            "admin_notes": row.get("adminNotes"),
            "feedback_timestamp": row.get("feedbackTimestamp"),
            "app_version": row.get("appVersion"),
        },
        "privacy": {
            "user_notes_dropped": row.get("userNotes") is not None,
            "barcode_dropped": row.get("barcode") is not None,
            "device_info_dropped": row.get("deviceInfo") is not None,
        },
    }


def to_jsonl(rows: Iterable[Dict[str, Any]]) -> str:
    return "\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Export feedback candidates for eval/training review")
    parser.add_argument("--input", required=True, help="Input JSON/JSONL feedback export path")
    parser.add_argument("--output-dir", default="eval/classification/feedback_exports", help="Output directory")
    args = parser.parse_args()

    in_path = Path(args.input)
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    rows = load_input(in_path)
    normalized = [normalize_row(r) for r in rows]

    review_queue = normalized
    approved = [r for r in normalized if r["review_status"] in APPROVED_STATUSES]

    now_tag = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    queue_path = out_dir / f"classification_feedback_review_queue_{now_tag}.jsonl"
    approved_path = out_dir / f"classification_feedback_approved_candidates_{now_tag}.jsonl"
    summary_path = out_dir / f"classification_feedback_export_summary_{now_tag}.json"

    queue_path.write_text(to_jsonl(review_queue), encoding="utf-8")
    approved_path.write_text(to_jsonl(approved), encoding="utf-8")

    summary = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "input_path": str(in_path),
        "total_input_rows": len(rows),
        "review_queue_rows": len(review_queue),
        "approved_rows": len(approved),
        "approved_statuses": sorted(APPROVED_STATUSES),
        "output_files": {
            "review_queue": str(queue_path),
            "approved_candidates": str(approved_path),
            "summary": str(summary_path),
        },
    }
    summary_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")

    print(json.dumps(summary, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
