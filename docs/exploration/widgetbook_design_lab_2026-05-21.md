# Widgetbook Design Lab

Date: 2026-05-21

This pass turned Widgetbook from a pure catalog into an exploration surface.

What was added in `widgetbook/main.dart`:

- `Design Lab`
- `Token Playground`
- `Button Studio`
- `Prototype Lab`
- `Theme Matrix`

What those areas are for:

- live color, radius, elevation, and text exploration
- theme palette swaps with brightness switching
- button state and width exploration
- concept sketches for future components before they land in `lib/widgets`

Verification:

- `flutter test test/widgetbook/widgetbook_smoke_test.dart`
- `python3 tools/widgetbook/component_catalog_audit.py`
- local static Widgetbook served at `http://localhost:7360`

Current exploratory route:

- `http://localhost:7360/#/?path=waste-segregation-components/polished/shimmerbox/default`
