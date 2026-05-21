# Responsive Text Widgets Reference

## Status

This note is now a short reference for the responsive text widgets in `lib/widgets/responsive_text.dart`.

The concrete behavior contract, device matrix, and manual verification steps live in:
- [`docs/testing/responsive_text_manual_testing_guide.md`](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/testing/responsive_text_manual_testing_guide.md)
- [`docs/implementation/ui/widgets/modern_ui_components.md`](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/implementation/ui/widgets/modern_ui_components.md)

## What Exists

- `ResponsiveText` provides the shared auto-sizing wrapper and named presets.
- `ResponsiveAppBarTitle` handles short and long AppBar titles with a narrow-screen abbreviation path.
- `GreetingText` handles the home-screen greeting pattern with pre-check overflow logic.
- `ReadMoreText` is the expand/collapse helper used by other result-screen cards.

## Current Usage

- `ResponsiveAppBarTitle` is used in `lib/screens/web_fallback_screen.dart` and `lib/web_standalone.dart`.
- `ResponsiveText` and `GreetingText` are verified in widget and golden tests, and surfaced in Widgetbook.
- `ResponsiveText.cardTitle` is used in `FeatureCard` after the recent production wiring pass.

## Contract Summary

- The implementation relies on `auto_size_text`, `LayoutBuilder`, and `TextPainter`.
- Narrow `ResponsiveAppBarTitle` behavior is triggered below 200px width.
- `GreetingText` uses overflow pre-calculation before deciding whether to auto-size.
- Accessibility support is present on the base `ResponsiveText` wrapper via `semanticsLabel`.

## Notes

- The older detailed narrative from this document was consolidated into the manual testing guide to avoid two overlapping sources of truth.
- If the production usage of these widgets expands later, update the usage section here and keep the behavior matrix in the manual guide current.
