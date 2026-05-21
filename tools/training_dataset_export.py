#!/usr/bin/env python3
"""Build a frozen training dataset manifest from exported candidate JSONL.

This tool is intentionally offline-first: export Firestore documents to JSONL,
then run this script locally in dry-run mode before publishing any dataset
version. It does not read Firestore credentials or mutate production data.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


EXCLUDED_REVIEW_STATUSES = {"rejected", "needs_redaction", "deleted"}
ALLOWED_REVIEW_STATUSES = {"approved", "golden", "training_eligible"}
PII_REDACTION_STATUSES = {"passed", "redacted", "not_collected_metadata_only"}


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise FileNotFoundError(path)

    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            stripped = line.strip()
            if not stripped:
                continue
            try:
                rows.append(json.loads(stripped))
            except json.JSONDecodeError as exc:
                raise ValueError(f"{path}:{line_number}: invalid JSON") from exc
    return rows


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")))
            handle.write("\n")


def is_excluded(
    candidate: dict[str, Any],
    *,
    allow_unreviewed: bool,
) -> tuple[bool, str | None]:
    consent = candidate.get("consent") or {}
    review = candidate.get("review") or {}
    deletion = candidate.get("deletion") or {}
    dataset = candidate.get("dataset") or {}
    image = candidate.get("image") or {}

    if consent.get("enabledAtCapture") is not True:
        return True, "no_consent"
    if deletion.get("requested") is True or deletion.get("deletedAt"):
        return True, "deleted_or_revoked"
    if dataset.get("eligible") is False and review.get("status") != "golden":
        return True, "not_dataset_eligible"

    review_status = review.get("status") or "unreviewed"
    if review_status in EXCLUDED_REVIEW_STATUSES:
        return True, f"review_{review_status}"
    if not allow_unreviewed and review_status not in ALLOWED_REVIEW_STATUSES:
        return True, f"review_{review_status}"

    pii_flags = review.get("piiFlags") or []
    quality_flags = review.get("qualityFlags") or []
    redaction_status = image.get("redactionStatus")
    if pii_flags:
        return True, "pii_flagged"
    if redaction_status not in PII_REDACTION_STATUSES:
        return True, f"redaction_{redaction_status}"
    if "unsafe" in quality_flags:
        return True, "unsafe_quality_flag"

    return False, None


def build_rows(
    candidates: list[dict[str, Any]],
    labels_by_candidate: dict[str, dict[str, Any]],
    *,
    dataset_version: str,
    allow_unreviewed: bool,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], Counter[str]]:
    manifest_rows: list[dict[str, Any]] = []
    label_rows: list[dict[str, Any]] = []
    exclusions: Counter[str] = Counter()
    included_at = datetime.now(timezone.utc).isoformat()

    for candidate in candidates:
        excluded, reason = is_excluded(candidate, allow_unreviewed=allow_unreviewed)
        if excluded:
            exclusions[reason or "unknown"] += 1
            continue

        candidate_id = candidate["candidateId"]
        label_doc = labels_by_candidate.get(candidate_id, {})
        reviewer_label = label_doc.get("reviewerVerified") or {}
        user_label = label_doc.get("userCorrection") or {}
        raw_label = label_doc.get("rawPrediction") or candidate.get("modelPrediction") or {}
        label = reviewer_label or user_label or raw_label

        manifest_rows.append({
            "candidateId": candidate_id,
            "datasetVersion": dataset_version,
            "imagePath": (candidate.get("image") or {}).get("storagePath"),
            "label": {
                "category": label.get("category") or label.get("correctedCategory"),
                "subcategory": label.get("subcategory"),
                "itemName": label.get("itemName") or label.get("correctedItemName"),
                "region": raw_label.get("region"),
            },
            "source": "user_contribution",
            "consentPolicyVersion": (candidate.get("consent") or {}).get("policyVersion"),
            "reviewStatus": (candidate.get("review") or {}).get("status"),
            "createdAt": candidate.get("createdAt"),
            "includedAt": included_at,
        })

        label_rows.append({
            "candidateId": candidate_id,
            "labelState": label_doc.get("labelState"),
            "rawPrediction": raw_label,
            "userCorrection": user_label or None,
            "reviewerVerified": reviewer_label or None,
        })

    return manifest_rows, label_rows, exclusions


def write_datasheet(path: Path, *, dataset_version: str, included: int, exclusions: Counter[str]) -> None:
    lines = [
        f"# Dataset Datasheet: {dataset_version}",
        "",
        f"Generated: {datetime.now(timezone.utc).isoformat()}",
        "",
        "## Consent And Rights",
        "",
        "- Includes only candidates with explicit training-data consent at capture.",
        "- Excludes deleted, revoked, rejected, PII-flagged, and unsafe examples.",
        "- User identity is represented only by server-side HMAC in source metadata, not in this manifest.",
        "",
        "## Counts",
        "",
        f"- Included examples: {included}",
        *[f"- Excluded `{reason}`: {count}" for reason, count in sorted(exclusions.items())],
        "",
        "## Use Limits",
        "",
        "- Model predictions are not ground truth.",
        "- Prefer `reviewerVerified` or `golden` labels for evaluation and serious fine-tuning.",
        "- Treat unreviewed rows as weak labels only when `--allow-unreviewed` was explicitly used.",
    ]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidates-jsonl", required=True, type=Path)
    parser.add_argument("--labels-jsonl", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--dataset-version", required=True)
    parser.add_argument("--allow-unreviewed", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    candidates = read_jsonl(args.candidates_jsonl)
    labels = read_jsonl(args.labels_jsonl)
    labels_by_candidate = {row["candidateId"]: row for row in labels}
    manifest_rows, label_rows, exclusions = build_rows(
        candidates,
        labels_by_candidate,
        dataset_version=args.dataset_version,
        allow_unreviewed=args.allow_unreviewed,
    )

    print(f"Candidates read: {len(candidates)}")
    print(f"Included: {len(manifest_rows)}")
    for reason, count in sorted(exclusions.items()):
        print(f"Excluded {reason}: {count}")

    if args.dry_run:
        return 0

    args.out.mkdir(parents=True, exist_ok=True)
    write_jsonl(args.out / "manifest.jsonl", manifest_rows)
    write_jsonl(args.out / "labels.jsonl", label_rows)
    write_datasheet(
        args.out / "datasheet.md",
        dataset_version=args.dataset_version,
        included=len(manifest_rows),
        exclusions=exclusions,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
