import 'package:flutter/material.dart';
import '../../utils/color_extensions.dart';

/// A standardized tile component for settings screens that provides
/// consistent styling and behavior across all settings items.
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveTitleColor = titleColor ?? (enabled ? theme.colorScheme.onSurface : theme.disabledColor);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Semantics(
        button: true,
        label: title,
        hint: subtitle,
        enabled: enabled,
        child: Focus(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                enabled: enabled,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withAlphaFraction(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveIconColor,
                  ),
                ),
                title: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: effectiveTitleColor,
                  ),
                ),
                subtitle: subtitle != null
                    ? Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: enabled ? theme.colorScheme.onSurfaceVariant : theme.disabledColor,
                        ),
                      )
                    : null,
                trailing: trailing ?? const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A specialized setting tile for toggles/switches
class SettingToggleTile extends StatelessWidget {
  const SettingToggleTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveIconColor.withAlphaFraction(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: effectiveIconColor,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled ? theme.colorScheme.onSurfaceVariant : theme.disabledColor,
                ),
              )
            : null,
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
