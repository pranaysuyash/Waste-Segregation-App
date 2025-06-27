import 'package:flutter/material.dart';
// TODO: Uncomment when gen_l10n is properly set up
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Helper class for consistent dialog management throughout the app
class DialogHelper {
  /// Shows a simple confirm/cancel dialog. Returns true if user pressed "OK".
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String body,
    String? okLabel,
    String? cancelLabel,
    Color? okColor,
    bool isDangerous = false,
  }) async {
    // TODO: Use AppLocalizations when properly set up
    // final t = AppLocalizations.of(context)!;

    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(_, false),
                child: Text(cancelLabel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(_, true),
                style: TextButton.styleFrom(
                  foregroundColor: okColor ?? (isDangerous ? Colors.red : Theme.of(context).primaryColor),
                ),
                child: Text(okLabel ?? 'OK'),
              ),
            ],
          ),
        )) ??
        false;
  }

  /// Displays a loading dialog while [task] is running.
  /// Returns the result of the task.
  static Future<T> loading<T>(
    BuildContext context,
    Future<T> Function() task, {
    String? message,
    bool barrierDismissible = false,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message ?? 'Please wait...'),
            ),
          ],
        ),
      ),
    );

    try {
      return await task();
    } finally {
      // Always dismiss the loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Shows an error dialog with the given message
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: Text(buttonText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Shows an info dialog with the given message
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    IconData? icon,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: Text(buttonText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet with options
  static Future<T?> showOptions<T>(
    BuildContext context, {
    required String title,
    required List<DialogOption<T>> options,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...options.map((option) => ListTile(
                    leading: option.icon != null ? Icon(option.icon, color: option.color) : null,
                    title: Text(option.title),
                    subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                    onTap: () {
                      Navigator.pop(context, option.value);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Shows a premium feature prompt dialog
  static Future<bool> showPremiumPrompt(
    BuildContext context, {
    required String featureName,
    VoidCallback? onUpgrade,
  }) async {
    // TODO: Use AppLocalizations when properly set up
    // final t = AppLocalizations.of(context)!;

    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('$featureName - Premium Feature'),
            content: Text('$featureName is a premium feature. Upgrade to unlock this and other advanced features.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(_, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(_, true);
                  onUpgrade?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.amber,
                ),
                child: const Text('Upgrade'),
              ),
            ],
          ),
        )) ??
        false;
  }
}

/// Represents an option in a dialog or bottom sheet
class DialogOption<T> {
  const DialogOption({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final T value;
}
