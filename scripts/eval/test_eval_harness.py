"""Tests for the classification eval harness (goal1.txt Part H).

Runs with: pytest scripts/eval/test_eval_harness.py

Covers:
  1. Eval schema validates good cases
  2. Eval schema rejects missing expected category
  3. Must-not violation is counted as failure
  4. Safety-critical failure is scored separately
  5. Acceptable alternative can pass non-strictly
  6. Offline eval mode requires no API keys
  7. Router comparison report can handle fake backend/local/provider outputs
  8. Golden cases file is valid JSONL with >= 30 cases
  9. Fixture file has predictions for all providers
 10. Composite scoring penalises safety failures heavily
 11. Per-category accuracy breakdown
 12. Routing recommendation generation
 13. Comparison matrix structure
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

# Allow importing the eval runner from the project root.
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "scripts" / "eval"))

from run_classification_eval import (
    GoldenCase,
    Prediction,
    _comparison_matrix,
    _per_category_accuracy,
    _routing_recommendation,
    evaluate_prediction,
    load_fixture_predictions,
    load_golden_cases,
    run_offline,
    summarize_provider,
)

FIXTURES = PROJECT_ROOT / "eval" / "classification" / "fixtures" / "provider_outputs_v1.jsonl"
GOLDEN = PROJECT_ROOT / "eval" / "classification" / "golden" / "golden_cases_v1.jsonl"
SCHEMA = PROJECT_ROOT / "eval" / "classification" / "schema" / "golden_case.schema.json"


# ---------------------------------------------------------------------------
# 1. Schema validation
# ---------------------------------------------------------------------------

class TestSchemaValidation:
    def test_schema_file_exists_and_valid_json(self):
        assert SCHEMA.exists(), f"Schema file missing: {SCHEMA}"
        schema = json.loads(SCHEMA.read_text())
        assert "properties" in schema
        assert "required" in schema
        assert "case_id" in schema["properties"]

    def test_golden_cases_validate_against_schema(self):
        import jsonschema

        schema = json.loads(SCHEMA.read_text())
        lines = GOLDEN.read_text().strip().split("\n")
        for line_no, line in enumerate(lines, start=1):
            case = json.loads(line)
            jsonschema.validate(case, schema)

    def test_schema_rejects_missing_expected_category(self):
        import jsonschema

        schema = json.loads(SCHEMA.read_text())
        bad_case = {
            "case_id": "test_missing_cat",
            "version": "v1",
            "source_type": "synthetic_seed",
            "region": "Bangalore, IN",
            "language": "en",
            "input": {"image_ref": "x.jpg", "description": "test"},
            "expected": {},  # missing required "category"
            "acceptance": {
                "acceptable_categories": ["Wet Waste"],
                "must_not_categories": [],
            },
            "safety": {"safety_critical": False, "notes": ""},
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(bad_case, schema)

    def test_schema_rejects_invalid_category(self):
        import jsonschema

        schema = json.loads(SCHEMA.read_text())
        bad_case = {
            "case_id": "test_bad_cat",
            "version": "v1",
            "source_type": "synthetic_seed",
            "region": "Bangalore, IN",
            "language": "en",
            "input": {"image_ref": "x.jpg", "description": "test"},
            "expected": {"category": "Invalid Category"},
            "acceptance": {
                "acceptable_categories": ["Invalid Category"],
                "must_not_categories": [],
            },
            "safety": {"safety_critical": False, "notes": ""},
        }
        with pytest.raises(jsonschema.ValidationError):
            jsonschema.validate(bad_case, schema)


# ---------------------------------------------------------------------------
# 2. Golden cases file integrity
# ---------------------------------------------------------------------------

class TestGoldenCases:
    def test_golden_cases_file_has_at_least_30_cases(self):
        cases = load_golden_cases(GOLDEN)
        assert len(cases) >= 30, f"Expected >= 30 golden cases, got {len(cases)}"

    def test_golden_cases_have_no_duplicate_ids(self):
        # load_golden_cases already raises on duplicates
        cases = load_golden_cases(GOLDEN)
        ids = list(cases.keys())
        assert len(ids) == len(set(ids))

    def test_golden_cases_cover_all_categories(self):
        cases = load_golden_cases(GOLDEN)
        categories = {c.expected_category for c in cases.values()}
        for cat in ["Wet Waste", "Dry Waste", "Hazardous Waste", "Medical Waste", "Non-Waste"]:
            assert cat in categories, f"Golden set missing category: {cat}"

    def test_golden_cases_include_safety_critical(self):
        cases = load_golden_cases(GOLDEN)
        safety_cases = [c for c in cases.values() if c.safety_critical]
        assert len(safety_cases) >= 5, (
            f"Expected >= 5 safety-critical cases, got {len(safety_cases)}"
        )


# ---------------------------------------------------------------------------
# 3. Scoring logic
# ---------------------------------------------------------------------------

class TestScoring:
    def _make_case(self, **overrides) -> GoldenCase:
        defaults = dict(
            case_id="test_001",
            expected_category="Hazardous Waste",
            acceptable_categories=["Hazardous Waste"],
            must_not_categories=["Wet Waste", "Dry Waste"],
            strict_fields=["category"],
            safety_critical=True,
            expected={"category": "Hazardous Waste"},
        )
        defaults.update(overrides)
        return GoldenCase(**defaults)

    def _make_pred(self, category: str, confidence: float = 0.9) -> Prediction:
        return Prediction(
            case_id="test_001",
            provider_key="test_provider",
            model="test_model",
            prediction={"category": category, "confidence": confidence},
            meta={"latency_ms": 100, "estimated_cost_usd": 0.001},
        )

    def test_strict_pass_when_category_matches(self):
        case = self._make_case()
        pred = self._make_pred("Hazardous Waste")
        result = evaluate_prediction(case, pred)
        assert result["strict_pass"] is True
        assert result["must_not_violation"] is False

    def test_must_not_violation_counted_as_failure(self):
        case = self._make_case()
        pred = self._make_pred("Wet Waste")  # in must_not_categories
        result = evaluate_prediction(case, pred)
        assert result["strict_pass"] is False
        assert result["must_not_violation"] is True

    def test_safety_critical_failure_scored_separately(self):
        # Battery classified as Dry Waste = safety_critical=True + wrong category
        case = self._make_case()
        pred = self._make_pred("Dry Waste")
        result = evaluate_prediction(case, pred)
        assert result["safety_critical"] is True
        assert result["safety_failure"] is True
        assert result["must_not_violation"] is True  # Dry Waste is in must_not

    def test_safety_critical_correct_no_failure(self):
        case = self._make_case()
        pred = self._make_pred("Hazardous Waste")
        result = evaluate_prediction(case, pred)
        assert result["safety_critical"] is True
        assert result["safety_failure"] is False

    def test_acceptable_alternative_passes_non_strictly(self):
        case = self._make_case(
            expected_category="Wet Waste",
            acceptable_categories=["Wet Waste", "Dry Waste"],
            must_not_categories=["Hazardous Waste"],
            safety_critical=False,
        )
        pred = self._make_pred("Dry Waste")  # acceptable alternative
        result = evaluate_prediction(case, pred)
        assert result["strict_pass"] is False  # category doesn't exactly match
        assert result["acceptable_pass"] is True

    def test_high_confidence_wrong_flagged(self):
        case = self._make_case(safety_critical=False)
        pred = self._make_pred("Wet Waste", confidence=0.95)
        result = evaluate_prediction(case, pred)
        assert result["strict_pass"] is False
        assert result["confidence"] == 0.95

    def test_composite_scoring_penalises_safety_heavily(self):
        # Two providers: one perfect, one with safety failure
        case = self._make_case()
        good_pred = self._make_pred("Hazardous Waste")
        bad_pred = self._make_pred("Wet Waste")

        good_result = evaluate_prediction(case, good_pred)
        bad_result = evaluate_prediction(case, bad_pred)

        good_summary = summarize_provider([good_result], "good", "m1")
        bad_summary = summarize_provider([bad_result], "bad", "m2")

        assert good_summary["composite_score"] > bad_summary["composite_score"]
        assert bad_summary["safety_failures"] == 1
        assert good_summary["safety_failures"] == 0


# ---------------------------------------------------------------------------
# 4. Offline mode
# ---------------------------------------------------------------------------

class TestOfflineMode:
    def test_offline_mode_produces_report_without_api_keys(self, tmp_path):
        cases = load_golden_cases(GOLDEN)
        fixtures = load_fixture_predictions(FIXTURES)
        report = run_offline(cases, fixtures)

        assert report["mode"] == "offline"
        assert report["golden_case_count"] == len(cases)
        assert report["providers_evaluated"] > 0
        assert len(report["ranking"]) > 0

    def test_offline_report_has_required_fields(self):
        cases = load_golden_cases(GOLDEN)
        fixtures = load_fixture_predictions(FIXTURES)
        report = run_offline(cases, fixtures)

        for field in ["mode", "generated_at", "golden_case_count", "ranking", "provider_results"]:
            assert field in report, f"Missing field: {field}"

        for provider in report["provider_results"]:
            for field in [
                "provider_key", "model", "total_cases", "strict_pass",
                "strict_pass_rate", "safety_failures", "must_not_violations",
                "composite_score",
            ]:
                assert field in provider, f"Provider missing field: {field}"


# ---------------------------------------------------------------------------
# 5. Router comparison with fake providers
# ---------------------------------------------------------------------------

class TestRouterComparison:
    def test_router_comparison_with_fake_outputs(self):
        golden = {
            "bat_001": GoldenCase(
                case_id="bat_001",
                expected_category="Hazardous Waste",
                acceptable_categories=["Hazardous Waste"],
                must_not_categories=["Wet Waste", "Dry Waste"],
                strict_fields=["category"],
                safety_critical=True,
                expected={"category": "Hazardous Waste"},
            ),
            "org_002": GoldenCase(
                case_id="org_002",
                expected_category="Wet Waste",
                acceptable_categories=["Wet Waste"],
                must_not_categories=["Hazardous Waste"],
                strict_fields=["category"],
                safety_critical=False,
                expected={"category": "Wet Waste"},
            ),
        }

        predictions = [
            Prediction("bat_001", "openai", "gpt-4.1-nano",
                       {"category": "Hazardous Waste", "confidence": 0.9},
                       {"latency_ms": 1200, "estimated_cost_usd": 0.0002}),
            Prediction("org_002", "openai", "gpt-4.1-nano",
                       {"category": "Wet Waste", "confidence": 0.85},
                       {"latency_ms": 1100, "estimated_cost_usd": 0.0002}),
            Prediction("bat_001", "local_small", "smolvlm-500m",
                       {"category": "Dry Waste", "confidence": 0.6},
                       {"latency_ms": 200, "estimated_cost_usd": 0.0}),
            Prediction("org_002", "local_small", "smolvlm-500m",
                       {"category": "Wet Waste", "confidence": 0.7},
                       {"latency_ms": 150, "estimated_cost_usd": 0.0}),
        ]

        report = run_offline(golden, predictions)

        assert report["providers_evaluated"] == 2
        assert len(report["ranking"]) == 2

        # OpenAI should rank higher (correct on safety-critical, local fails)
        openai_rank = next(
            r["rank"] for r in report["ranking"] if r["provider_key"] == "openai"
        )
        local_rank = next(
            r["rank"] for r in report["ranking"] if r["provider_key"] == "local_small"
        )
        assert openai_rank < local_rank, "OpenAI should rank above local (safety failure)"

    def test_existing_fixtures_have_all_four_providers(self):
        fixtures = load_fixture_predictions(FIXTURES)
        providers = {p.provider_key for p in fixtures}
        for expected in ["openai", "gemini", "local_small", "router_v1"]:
            assert expected in providers, f"Missing provider in fixtures: {expected}"


# ---------------------------------------------------------------------------
# 6. Per-category accuracy
# ---------------------------------------------------------------------------

class TestPerCategoryAccuracy:
    def test_per_category_breakdown(self):
        rows = [
            {"expected_category": "Wet Waste", "strict_pass": True, "safety_failure": False},
            {"expected_category": "Wet Waste", "strict_pass": False, "safety_failure": False},
            {"expected_category": "Dry Waste", "strict_pass": True, "safety_failure": False},
            {"expected_category": "Hazardous Waste", "strict_pass": False, "safety_failure": True},
        ]
        result = _per_category_accuracy(rows)
        assert "Wet Waste" in result
        assert result["Wet Waste"]["total"] == 2
        assert result["Wet Waste"]["strict_pass"] == 1
        assert result["Wet Waste"]["strict_pass_rate"] == 0.5
        assert result["Hazardous Waste"]["safety_failures"] == 1

    def test_empty_rows_give_empty_dict(self):
        assert _per_category_accuracy([]) == {}


# ---------------------------------------------------------------------------
# 7. Routing recommendation
# ---------------------------------------------------------------------------

class TestRoutingRecommendation:
    def _make_ranked(self, strict_rate=0.95, safety_failures=0):
        return [{
            "provider_key": "test",
            "model": "m1",
            "strict_pass_rate": strict_rate,
            "safety_failures": safety_failures,
        }]

    def test_review_required_when_safety_failures_exist(self):
        rec = _routing_recommendation(self._make_ranked(safety_failures=1))
        assert rec["recommendation"] == "review_required"

    def test_local_first_candidate_at_high_accuracy(self):
        rec = _routing_recommendation(self._make_ranked(strict_rate=0.92))
        assert rec["recommendation"] == "local_first_candidate"

    def test_cloud_required_at_moderate_accuracy(self):
        rec = _routing_recommendation(self._make_ranked(strict_rate=0.75))
        assert rec["recommendation"] == "cloud_required"

    def test_cloud_only_at_low_accuracy(self):
        rec = _routing_recommendation(self._make_ranked(strict_rate=0.5))
        assert rec["recommendation"] == "cloud_only"

    def test_no_data(self):
        rec = _routing_recommendation([])
        assert rec["recommendation"] == "no_data"


# ---------------------------------------------------------------------------
# 8. Comparison matrix in report
# ---------------------------------------------------------------------------

class TestComparisonMatrix:
    def test_offline_report_includes_comparison_matrix(self):
        cases = load_golden_cases(GOLDEN)
        fixtures = load_fixture_predictions(FIXTURES)
        report = run_offline(cases, fixtures)

        assert "comparison_matrix" in report
        assert len(report["comparison_matrix"]) > 0
        first = report["comparison_matrix"][0]
        for field in [
            "provider_key", "model", "strict_pass_rate", "safety_failures",
            "must_not_violations", "composite_score", "latency_avg_ms",
            "cost_total_usd", "per_category",
        ]:
            assert field in first, f"Comparison matrix missing field: {field}"

    def test_offline_report_includes_routing_recommendation(self):
        cases = load_golden_cases(GOLDEN)
        fixtures = load_fixture_predictions(FIXTURES)
        report = run_offline(cases, fixtures)

        assert "routing_recommendation" in report
        rec = report["routing_recommendation"]
        assert "recommendation" in rec
        assert "notes" in rec
