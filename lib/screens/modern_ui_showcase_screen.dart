import 'package:flutter/material.dart';
import '../widgets/modern_ui/modern_cards.dart';
import '../widgets/modern_ui/modern_buttons.dart';
import '../widgets/modern_ui/modern_badges.dart';
import '../utils/constants.dart';

/// Demo screen to showcase all modern UI components
class ModernUIShowcaseScreen extends StatefulWidget {
  const ModernUIShowcaseScreen({super.key});

  @override
  State<ModernUIShowcaseScreen> createState() => _ModernUIShowcaseScreenState();
}

class _ModernUIShowcaseScreenState extends State<ModernUIShowcaseScreen> {
  int _selectedChipIndex = 0;
  bool _isLoading = false;

  final List<String> _chipOptions = [
    'All',
    'Wet Waste',
    'Dry Waste',
    'Hazardous',
    'Medical',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern UI Showcase'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Modern Cards'),
            const SizedBox(height: AppTheme.spacingMd),
            
            // Card examples
            _buildCardExamples(),
            
            const SizedBox(height: AppTheme.spacingXl),
            _buildSectionTitle('Modern Buttons'),
            const SizedBox(height: AppTheme.spacingMd),
            
            // Button examples
            _buildButtonExamples(),
            
            const SizedBox(height: AppTheme.spacingXl),
            _buildSectionTitle('Modern Badges & Chips'),
            const SizedBox(height: AppTheme.spacingMd),
            
            // Badge and chip examples
            _buildBadgeExamples(),
            
            const SizedBox(height: AppTheme.spacingXl),
            _buildSectionTitle('Interactive Components'),
            const SizedBox(height: AppTheme.spacingMd),
            
            // Interactive examples
            _buildInteractiveExamples(),
            
            const SizedBox(height: AppTheme.spacingXxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCardExamples() {
    return Column(
      children: [
        // Feature Card Example
        FeatureCard(
          icon: Icons.analytics,
          title: 'Analytics Dashboard',
          subtitle: 'View detailed insights and statistics',
          iconColor: AppTheme.infoColor,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Analytics Dashboard tapped!')),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingMd),
        
        // Stats Card Row
        const Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Total Items',
                value: '1,234',
                icon: Icons.inventory,
                color: AppTheme.primaryColor,
                trend: '+15%',
                subtitle: 'This month',
              ),
            ),
            SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: StatsCard(
                title: 'Recycled',
                value: '987',
                icon: Icons.recycling,
                color: AppTheme.successColor,
                trend: '+8%',
                subtitle: 'This month',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingMd),
        
        // Glassmorphism Card
        GlassmorphismCard(
          child: Column(
            children: [
              const Icon(
                Icons.eco,
                size: AppTheme.iconSizeXl,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Glassmorphism Effect',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Modern translucent design with blur effect',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingMd),
        
        // Action Cards Row
        Row(
          children: [
            Expanded(
              child: ActionCard(
                title: 'Scan Item',
                subtitle: 'Camera analysis',
                icon: Icons.camera_alt,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scan Item tapped!')),
                  );
                },
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: ActionCard(
                title: 'Upload Image',
                subtitle: 'From gallery',
                icon: Icons.photo_library,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upload Image tapped!')),
                  );
                },
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonExamples() {
    return Column(
      children: [
        // Filled buttons row
        Row(
          children: [
            Expanded(
              child: ModernButton(
                text: 'Primary Action',
                icon: Icons.check,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Primary action pressed!')),
                  );
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: ModernButton(
                text: 'Secondary',
                icon: Icons.info,
                onPressed: () {},
                style: ModernButtonStyle.outlined,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingMd),
        
        // Loading button
        ModernButton(
          text: 'Processing...',
          isLoading: _isLoading,
          isExpanded: true,
          onPressed: _isLoading 
              ? null 
              : () {
                  setState(() {
                    _isLoading = true;
                  });
                  
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  });
                },
        ),
        
        const SizedBox(height: AppTheme.spacingMd),
        
        // Button sizes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ModernButton(
              text: 'Small',
              size: ModernButtonSize.small,
              onPressed: () {},
            ),
            ModernButton(
              text: 'Medium',
              onPressed: () {},
            ),
            ModernButton(
              text: 'Large',
              size: ModernButtonSize.large,
              onPressed: () {},
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingMd),
        
        // Glassmorphism button
        ModernButton(
          text: 'Glassmorphism Style',
          icon: Icons.blur_on,
          style: ModernButtonStyle.glassmorphism,
          isExpanded: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Glassmorphism button pressed!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBadgeExamples() {
    return Column(
      children: [
        // Category badges
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: [
            WasteCategoryBadge(
              category: 'Wet Waste',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wet Waste category tapped!')),
                );
              },
            ),
            const WasteCategoryBadge(
              category: 'Dry Waste',
              style: ModernBadgeStyle.soft,
            ),
            const WasteCategoryBadge(
              category: 'Hazardous Waste',
              style: ModernBadgeStyle.outlined,
            ),
            const WasteCategoryBadge(
              category: 'Medical Waste',
              style: ModernBadgeStyle.glassmorphism,
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        // Status badges
        const Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: [
            StatusBadge(status: 'Completed'),
            StatusBadge(status: 'Pending'),
            StatusBadge(status: 'Failed'),
            StatusBadge(status: 'New'),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        // Modern badges with different styles
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ModernBadge(
              text: 'Premium',
              icon: Icons.star,
              backgroundColor: Colors.amber,
            ),
            ModernBadge(
              text: 'Live',
              backgroundColor: Colors.red,
              style: ModernBadgeStyle.soft,
              showPulse: true,
            ),
            ModernBadge(
              text: '42',
              icon: Icons.notifications,
              backgroundColor: AppTheme.infoColor,
              style: ModernBadgeStyle.outlined,
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        // Progress badge
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ProgressBadge(
              progress: 0.25,
              text: '25%',
              size: 40,
            ),
            ProgressBadge(
              progress: 0.65,
              text: '65%',
              size: 40,
              progressColor: AppTheme.warningColor,
            ),
            ProgressBadge(
              progress: 0.90,
              text: '90%',
              size: 40,
              progressColor: AppTheme.successColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractiveExamples() {
    return Column(
      children: [
        // Chip group
        ModernChipGroup(
          options: _chipOptions,
          selectedOptions: [_chipOptions[_selectedChipIndex]],
          multiSelect: false,
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) {
              setState(() {
                _selectedChipIndex = _chipOptions.indexOf(selected.first);
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected: ${selected.first}')),
              );
            }
          },
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        // Search bar
        ModernSearchBar(
          hint: 'Search waste items...',
          onChanged: (value) {
            // Handle search
          },
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        // Modern FAB
        Center(
          child: ModernFAB(
            icon: Icons.camera_alt,
            label: 'Scan Item',
            isExtended: true,
            showBadge: true,
            badgeText: '3',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FAB pressed!')),
              );
            },
          ),
        ),
      ],
    );
  }
}


