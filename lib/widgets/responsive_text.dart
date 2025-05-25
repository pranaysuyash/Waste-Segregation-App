import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// A responsive text widget that automatically handles text overflow
/// by adjusting font size or wrapping text based on available space
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final double? minFontSize;
  final double? maxFontSize;
  final bool enableAutoSizing;
  final bool enableWrapping;
  final String? semanticsLabel;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.minFontSize = 12.0,
    this.maxFontSize,
    this.enableAutoSizing = true,
    this.enableWrapping = true,
    this.semanticsLabel,
  });

  /// Creates a responsive text widget optimized for app bar titles
  const ResponsiveText.appBarTitle(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
    this.semanticsLabel,
  })  : maxLines = 1,
        overflow = TextOverflow.ellipsis,
        minFontSize = 14.0,
        maxFontSize = 20.0,
        enableAutoSizing = true,
        enableWrapping = false;

  /// Creates a responsive text widget optimized for greeting cards
  const ResponsiveText.greeting(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.semanticsLabel,
  })  : maxLines = 2,
        overflow = TextOverflow.ellipsis,
        minFontSize = 16.0,
        maxFontSize = 28.0,
        enableAutoSizing = true,
        enableWrapping = true;

  /// Creates a responsive text widget optimized for card titles
  const ResponsiveText.cardTitle(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.semanticsLabel,
  })  : maxLines = 2,
        overflow = TextOverflow.ellipsis,
        minFontSize = 14.0,
        maxFontSize = 18.0,
        enableAutoSizing = true,
        enableWrapping = true;

  @override
  Widget build(BuildContext context) {
    if (enableAutoSizing) {
      return AutoSizeText(
        text,
        style: style,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: overflow ?? TextOverflow.ellipsis,
        minFontSize: minFontSize ?? 12.0,
        maxFontSize: maxFontSize ?? (style?.fontSize ?? 16.0),
        semanticsLabel: semanticsLabel,
        wrapWords: enableWrapping,
      );
    } else {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: overflow,
        semanticsLabel: semanticsLabel,
      );
    }
  }
}

/// A responsive text widget specifically designed for dynamic greetings
/// that adapts to different screen sizes and user name lengths
class GreetingText extends StatelessWidget {
  final String greeting;
  final String userName;
  final TextStyle? style;
  final Color? color;
  final int maxLines;

  const GreetingText({
    super.key,
    required this.greeting,
    required this.userName,
    this.style,
    this.color,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.headlineMedium?.copyWith(
      color: color ?? Colors.white,
      fontWeight: FontWeight.bold,
    );

    final effectiveStyle = style ?? defaultStyle;
    final greetingText = '$greeting, $userName!';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate if text will overflow
        final textPainter = TextPainter(
          text: TextSpan(text: greetingText, style: effectiveStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        // If text overflows, use responsive text with auto-sizing
        if (textPainter.didExceedMaxLines || textPainter.width > constraints.maxWidth) {
          return AutoSizeText(
            greetingText,
            style: effectiveStyle,
            maxLines: maxLines,
            minFontSize: 16.0,
            maxFontSize: effectiveStyle?.fontSize ?? 28.0,
            overflow: TextOverflow.ellipsis,
            wrapWords: true,
          );
        }

        // If text fits, use regular text
        return Text(
          greetingText,
          style: effectiveStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// A responsive app bar title that handles long app names gracefully
class ResponsiveAppBarTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const ResponsiveAppBarTitle({
    super.key,
    required this.title,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // For very narrow screens, show abbreviated title
        if (constraints.maxWidth < 200) {
          return AutoSizeText(
            _getAbbreviatedTitle(title),
            style: style,
            maxLines: 1,
            minFontSize: 14.0,
            maxFontSize: 20.0,
            overflow: TextOverflow.ellipsis,
          );
        }

        // For normal screens, use responsive text
        return AutoSizeText(
          title,
          style: style,
          maxLines: 1,
          minFontSize: 14.0,
          maxFontSize: 20.0,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  String _getAbbreviatedTitle(String fullTitle) {
    // Create abbreviation for long titles
    final words = fullTitle.split(' ');
    if (words.length > 1) {
      return words.map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join('');
    }
    return fullTitle.length > 10 ? '${fullTitle.substring(0, 10)}...' : fullTitle;
  }
} 