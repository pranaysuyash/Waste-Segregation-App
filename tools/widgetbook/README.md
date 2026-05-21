# Widgetbook Tools

## `component_catalog_audit.py`

Audits how many `lib/widgets` classes are referenced by `widgetbook/main.dart`.

### Usage

```bash
python3 tools/widgetbook/component_catalog_audit.py
```

Optional flags:

- `--widgets-root` (default: `lib/widgets`)
- `--widgetbook-file` (default: `widgetbook/main.dart`)
- `--output` (default: `docs/testing/WIDGETBOOK_COMPONENT_COVERAGE.md`)
