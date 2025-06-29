import 'package:flutter/material.dart';
import '../utils/share_service.dart';
import '../utils/waste_app_logger.dart';

/// A reusable share button widget that can be added to any screen
class ShareButton extends StatelessWidget {
  const ShareButton({
    super.key,
    required this.text,
    this.subject,
    this.files,
    this.tooltip = 'Share',
    this.icon = Icons.share,
    this.color,
    this.size = 24.0,
    this.showSnackBar = true,
  });

  /// The text content to share
  final String text;

  /// Optional subject for the share
  final String? subject;

  /// Optional list of file paths to share (currently not supported in our implementation)
  final List<String>? files;

  /// Optional tooltip to show when long-pressing the button
  final String? tooltip;

  /// Optional custom icon
  final IconData icon;

  /// Optional custom color
  final Color? color;

  /// Optional custom size
  final double size;

  /// Whether to show a SnackBar notification
  final bool showSnackBar;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: size, color: color),
      onPressed: () {
        if (showSnackBar) {
          // Use context for SnackBar notification
          try {
            ShareService.share(
              text: text,
              subject: subject,
              files: files,
              context: context,
            );
          } catch (e) {
            WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'share_button'});
          }
        } else {
          // Use callback for custom notification
          ShareService.onShareComplete = (message) {
            WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'share_button'});
            // No visual notification
          };

          ShareService.share(
            text: text,
            subject: subject,
            files: files,
          );
        }
      },
    );
  }
}

/// A floating action button for sharing
class ShareFloatingActionButton extends StatelessWidget {
  const ShareFloatingActionButton({
    super.key,
    required this.text,
    this.subject,
    this.files,
    this.tooltip = 'Share',
    this.backgroundColor,
    this.foregroundColor,
    this.showSnackBar = true,
  });

  /// The text content to share
  final String text;

  /// Optional subject for the share
  final String? subject;

  /// Optional list of file paths to share (currently not supported in our implementation)
  final List<String>? files;

  /// Optional tooltip to show when long-pressing the button
  final String? tooltip;

  /// Optional custom color
  final Color? backgroundColor;

  /// Optional custom foreground color
  final Color? foregroundColor;

  /// Whether to show a SnackBar notification
  final bool showSnackBar;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: const Icon(Icons.share),
      onPressed: () {
        if (showSnackBar) {
          // Use context for SnackBar notification
          try {
            ShareService.share(
              text: text,
              subject: subject,
              files: files,
              context: context,
            );
          } catch (e) {
            WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'share_button'});
          }
        } else {
          // Use callback for custom notification
          ShareService.onShareComplete = (message) {
            WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'share_button'});
            // No visual notification
          };

          ShareService.share(
            text: text,
            subject: subject,
            files: files,
          );
        }
      },
    );
  }
}
