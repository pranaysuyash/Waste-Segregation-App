import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

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
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(cancelLabel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(
                  foregroundColor: okColor ??
                      (isDangerous
                          ? Colors.red
                          : Theme.of(context).primaryColor),
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
    unawaited(showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
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
    ));

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
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
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
                    leading: option.icon != null
                        ? Icon(option.icon, color: option.color)
                        : null,
                    title: Text(option.title),
                    subtitle:
                        option.subtitle != null ? Text(option.subtitle!) : null,
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
    String? title,
    String? description,
    String? dismissCta,
    String? upgradeCta,
    VoidCallback? onUpgrade,
  }) async {
    final t = AppLocalizations.of(context)!;

    return (await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title ?? t.upgradeToUse(featureName)),
                ),
              ],
            ),
            content: Text(description ?? t.premiumFeatureBody(featureName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(dismissCta ?? t.notNow),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                  onUpgrade?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.amber,
                ),
                child: Text(upgradeCta ?? t.seePremiumFeatures),
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
