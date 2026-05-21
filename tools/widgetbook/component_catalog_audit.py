#!/usr/bin/env python3
"""
Generate a coverage snapshot between lib/widgets components and widgetbook catalog.
"""

from __future__ import annotations

import argparse
import pathlib
import re
from dataclasses import dataclass


WIDGET_CLASS_RE = re.compile(
    r"class\s+([A-Z][A-Za-z0-9_]*)\s+extends\s+(StatelessWidget|StatefulWidget)\b"
)
WIDGETBOOK_USAGE_RE = re.compile(
    r"\b(?:const\s+)?([A-Z][A-Za-z0-9_]*)(?:\.[A-Za-z0-9_]+)?\s*\("
)


@dataclass(frozen=True)
class AuditResult:
    total: int
    covered: int
    uncovered: list[str]


def collect_widget_classes(widgets_root: pathlib.Path) -> list[str]:
    classes: set[str] = set()
    for path in widgets_root.rglob("*.dart"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in WIDGET_CLASS_RE.finditer(text):
            classes.add(match.group(1))
    return sorted(classes)


def collect_widgetbook_references(widgetbook_file: pathlib.Path) -> set[str]:
    text = widgetbook_file.read_text(encoding="utf-8", errors="ignore")
    refs = set()
    for match in WIDGETBOOK_USAGE_RE.finditer(text):
        refs.add(match.group(1))
    return refs


def audit(widgets_root: pathlib.Path, widgetbook_file: pathlib.Path) -> AuditResult:
    widget_classes = collect_widget_classes(widgets_root)
    refs = collect_widgetbook_references(widgetbook_file)
    uncovered = [name for name in widget_classes if name not in refs]
    return AuditResult(
        total=len(widget_classes),
        covered=len(widget_classes) - len(uncovered),
        uncovered=uncovered,
    )


def markdown_report(result: AuditResult) -> str:
    pct = 0.0 if result.total == 0 else (result.covered / result.total) * 100
    lines = [
        "# Widgetbook Component Coverage",
        "",
        f"- Total widget classes: **{result.total}**",
        f"- Referenced in Widgetbook: **{result.covered}**",
        f"- Coverage: **{pct:.2f}%**",
        "",
        "## Uncovered Widget Classes",
        "",
    ]
    if not result.uncovered:
        lines.append("- None")
    else:
        lines.extend([f"- `{name}`" for name in result.uncovered])
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--widgets-root",
        default="lib/widgets",
        help="Widgets root directory",
    )
    parser.add_argument(
        "--widgetbook-file",
        default="widgetbook/main.dart",
        help="Widgetbook entry file",
    )
    parser.add_argument(
        "--output",
        default="docs/testing/WIDGETBOOK_COMPONENT_COVERAGE.md",
        help="Output markdown path",
    )
    args = parser.parse_args()

    widgets_root = pathlib.Path(args.widgets_root)
    widgetbook_file = pathlib.Path(args.widgetbook_file)
    output_path = pathlib.Path(args.output)

    result = audit(widgets_root, widgetbook_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(markdown_report(result), encoding="utf-8")
    print(
        f"Wrote {output_path} | covered {result.covered}/{result.total} "
        f"({(0 if result.total == 0 else (result.covered/result.total)*100):.2f}%)"
    )


if __name__ == "__main__":
    main()
