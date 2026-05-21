import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';

/// Responsive layout for settings that adapts to different screen sizes
class ResponsiveSettingsLayout extends StatelessWidget {
  const ResponsiveSettingsLayout({
    super.key,
    required this.sections,
    this.maxWidth = 1200,
    this.tabletBreakpoint = 600,
    this.desktopBreakpoint = 1024,
  });

  final List<Widget> sections;
  final double maxWidth;
  final double tabletBreakpoint;
  final double desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (screenWidth >= desktopBreakpoint) {
          return _buildDesktopLayout(context);
        } else if (screenWidth >= tabletBreakpoint) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  /// Desktop layout with sidebar navigation and content area
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar navigation
        SizedBox(
          width: 280,
          child: _buildSidebarNavigation(context),
        ),

        // Vertical divider
        const VerticalDivider(width: 1),

        // Main content area
        Expanded(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth - 280),
            child: _buildContentArea(),
          ),
        ),
      ],
    );
  }

  /// Tablet layout with two-column grid
  Widget _buildTabletLayout() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < sections.length) {
                  return _wrapSectionForGrid(sections[index]);
                }
                return null;
              },
              childCount: sections.length,
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile layout with single column
  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sectionIndex = index ~/ 2;
                final isSection = index % 2 == 0;

                if (isSection && sectionIndex < sections.length) {
                  return sections[sectionIndex];
                } else if (!isSection && sectionIndex < sections.length - 1) {
                  return const SizedBox(height: 16);
                }
                return null;
              },
              childCount: sections.length * 2 - 1,
            ),
          ),
        ),
      ],
    );
  }

  /// Sidebar navigation for desktop layout
  Widget _buildSidebarNavigation(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        border: Border(
          right: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              t.settingsTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavItem(Icons.account_circle, t.accountSection, true),
                _buildNavItem(Icons.star, t.premiumSection, false),
                _buildNavItem(Icons.settings, t.appSettingsSection, false),
                _buildNavItem(Icons.navigation, t.navigationSection, false),
                _buildNavItem(Icons.extension, t.featuresSection, false),
                _buildNavItem(Icons.help, t.legalSupportSection, false),
                _buildNavItem(Icons.developer_mode, t.developerOptions, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  /// Main content area for desktop layout
  Widget _buildContentArea() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sectionIndex = index ~/ 2;
                final isSection = index % 2 == 0;

                if (isSection && sectionIndex < sections.length) {
                  return sections[sectionIndex];
                } else if (!isSection && sectionIndex < sections.length - 1) {
                  return const SizedBox(height: 24);
                }
                return null;
              },
              childCount: sections.length * 2 - 1,
            ),
          ),
        ),
      ],
    );
  }

  /// Wrap section for grid layout
  Widget _wrapSectionForGrid(Widget section) {
    return Material(
      elevation: AppTheme.elevationMd,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: section,
      ),
    );
  }
}

/// Breakpoint utilities for responsive design
class SettingsBreakpoints {
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktop;
  }
}

/// Responsive padding utility
class ResponsivePadding {
  static EdgeInsets of(BuildContext context) {
    if (SettingsBreakpoints.isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (SettingsBreakpoints.isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  static EdgeInsets horizontal(BuildContext context) {
    if (SettingsBreakpoints.isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (SettingsBreakpoints.isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
  }
}

/// Responsive text scaling
class ResponsiveText {
  static double titleScale(BuildContext context) {
    if (SettingsBreakpoints.isMobile(context)) {
      return 1.0;
    } else if (SettingsBreakpoints.isTablet(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  static double bodyScale(BuildContext context) {
    if (SettingsBreakpoints.isMobile(context)) {
      return 1.0;
    } else if (SettingsBreakpoints.isTablet(context)) {
      return 1.05;
    } else {
      return 1.1;
    }
  }
}
