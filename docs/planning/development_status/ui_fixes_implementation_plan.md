# Implementation Plan: UI Fixes for v0.9.1

This document provides specific code implementation examples for the highest priority UI fixes identified for version 0.9.1.

## 1. Result Screen Text Overflow Fix

### Issue Summary
The Result Screen has multiple instances of potential text overflow:
- Material type information can overflow with long material names
- Educational facts have no length constraints
- Property tables may have alignment issues with long text

### Implementation Guide

#### a. Fix Material Type Display

```dart
// In result_screen.dart
// Replace existing Material Type row with this implementation:

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'Material Type: ',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    Expanded(
      child: Text(
        widget.classification.materialType!,
        overflow: TextOverflow.ellipsis,
        maxLines: 3, // Allow up to 3 lines
      ),
    ),
  ],
),
```

#### b. Improve Educational Fact Section

```dart
// In result_screen.dart
// Replace the educational fact section with:

Container(
  padding: const EdgeInsets.all(AppTheme.paddingRegular),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.05),
    borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.school, color: AppTheme.secondaryColor),
          SizedBox(width: 8),
          Text(
            'Did You Know?',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppTheme.paddingRegular),
      
      // Educational fact with read more option if long
      _buildEducationalFact(
        widget.classification.category,
        widget.classification.subcategory,
      ),

      const SizedBox(height: AppTheme.paddingRegular),
      const Text(
        'Proper waste segregation can reduce landfill waste by up to 80% and significantly decrease greenhouse gas emissions.',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: AppTheme.textSecondaryColor,
        ),
      ),
    ],
  ),
),

// Add this new method to the _ResultScreenState class:
Widget _buildEducationalFact(String category, String? subcategory) {
  final String fact = _getEducationalFact(category, subcategory);
  
  // If fact is short, display it directly
  if (fact.length < 150) {
    return Text(fact);
  }
  
  // For longer facts, show a preview with "Read More" option
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        fact,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      TextButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('About ${subcategory ?? category}'),
              content: SingleChildScrollView(
                child: Text(fact),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(50, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Read More'),
      ),
    ],
  );
}
```

## 2. Recycling Code Info Widget Improvement

### Issue Summary
The RecyclingCodeInfoCard widget has several issues:
- No proper handling of null or missing codes
- Doesn't separate plastic type name from examples
- No handling for long descriptions

### Implementation Guide

#### Create an Enhanced Recycling Code Info Widget

```dart
// In recycling_code_info.dart
// Replace the entire widget with this implementation:

/// Displays information about a recycling code (1-7) with description.
class RecyclingCodeInfoCard extends StatelessWidget {
  final String code;
  const RecyclingCodeInfoCard({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    // Safe access to recycling code information
    final String codeDescription = 
        WasteInfo.recyclingCodes[code] ?? 'Unknown plastic type';
    
    // Parse the description to separate plastic name from examples
    String plasticName = '';
    String examples = codeDescription;
    
    if (codeDescription.contains('-')) {
      final parts = codeDescription.split('-');
      plasticName = parts[0].trim();
      // Join the rest in case there are multiple dashes
      examples = parts.sublist(1).join('-').trim();
    }
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with code symbol and plastic name
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Code symbol
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.secondaryColor),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Title and plastic name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recycling Code',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSizeMedium,
                      ),
                    ),
                    if (plasticName.isNotEmpty)
                      Text(
                        plasticName,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Examples section
          const Text(
            'Common Examples:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.fontSizeRegular,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            examples,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Add "View Details" button for additional information
          if (examples.length > 50)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _showRecyclingCodeDetails(context, code, plasticName, examples);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, 
                    vertical: 4,
                  ),
                  minimumSize: const Size(40, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Details'),
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper method to show detailed information
  void _showRecyclingCodeDetails(
    BuildContext context, 
    String code, 
    String plasticName, 
    String examples
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.secondaryColor),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recycling Code $code',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (plasticName.isNotEmpty) ...[
                const Text(
                  'Plastic Type:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(plasticName),
                const SizedBox(height: 16),
              ],
              const Text(
                'Common Examples:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(examples),
              const SizedBox(height: 16),
              const Text(
                'Recycling Tips:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(_getRecyclingTips(code)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get recycling tips based on code
  String _getRecyclingTips(String code) {
    switch (code) {
      case '1':
        return 'PET bottles should be emptied, rinsed, and crushed before recycling. Remove caps and place them separately in recycling.';
      case '2':
        return 'HDPE is widely accepted by recycling programs. Ensure containers are clean and free of product residue.';
      case '3':
        return 'PVC is difficult to recycle. Check with your local recycling program as many do not accept it. Consider alternatives when possible.';
      case '4':
        return 'LDPE film (bags) are not accepted in most curbside programs but can be recycled at many grocery stores. Rigid LDPE may be accepted in your local program.';
      case '5':
        return 'PP is increasingly accepted in recycling programs. Make sure containers are clean and free of food residue.';
      case '6':
        return 'PS, especially foam (Styrofoam), is rarely accepted in curbside recycling. Look for special drop-off locations or consider alternatives.';
      case '7':
        return 'This is a catch-all category for plastics not in categories 1-6. Recycling options vary widely; check local guidelines.';
      default:
        return 'Check with your local recycling program for specific guidelines on how to properly recycle this material.';
    }
  }
}
```

## Testing Plan

### For Result Screen Fixes:
1. Test with extra-long material type names (20+ words)
2. Test with all educational facts to ensure proper display
3. Verify "Read More" functionality works correctly
4. Test on different screen sizes (small phone to large tablet)

### For Recycling Code Widget:
1. Test with each recycling code (1-7)
2. Test with invalid codes to verify error handling
3. Verify dialog display and content
4. Check responsiveness on different screen sizes

## Next Steps

After implementing these high-priority UI fixes:
1. Update the version number in pubspec.yaml
2. Update CHANGELOG.md with the specific fixes
3. Document the changes in the project documentation
4. Create a test plan for the next set of fixes

These implementation examples should provide a clear path forward for addressing the most critical UI issues identified in the app.
