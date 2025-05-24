# Changelog

## [0.1.4+96] - 2025-05-24

### Bug Fixes
- **Fixed Analytics Dashboard Display Issues**: 
  - Charts now display in full with proper sizing and responsive design
  - Recent activities section no longer shows blank - improved data loading and error handling
  - Daily streak box properly formatted with better visual layout
  - Enhanced WebView chart reliability with CDN updates and error fallbacks
  - Improved empty state handling with helpful user guidance
- **Fixed Achievement Unlock Timing Issue**: Resolved critical issue where level-locked achievements (like "Waste Apprentice" at Level 2) weren't tracking progress until the level requirement was met. Now achievements accumulate progress regardless of lock status and unlock immediately when both progress and level requirements are satisfied.
- **Fixed Statistics Display Inconsistency**: Resolved issue where "Items Identified" count (1) didn't match individual category counts (e.g., "Wet Waste: 10 items"). The achievements screen now correctly converts points to item counts for consistent display across all statistics.
- **Fixed Educational Content Navigation Issue**: Resolved issue where educational content (quizzes, articles, videos, infographics, tutorials) showed limited or no content when accessed via "Learn More" from classification results. Updated all content categories and added new category-specific educational materials to ensure comprehensive content availability for all waste types.
- Count multiplication bug fixes
- Tab visibility improvements  
- About page overflow fixes

### Technical Improvements
- Enhanced data consistency validation in gamification system
- Improved code documentation for points-to-items conversion logic
- Added comprehensive test coverage for statistics calculation to prevent regression
- **Documentation Reorganization**: Cleaned up and reorganized docs folder structure for better navigation and maintenance


## [0.9.1] - 2025-05-20

### Improvements & Fixes
- Points popup and reward animations now only show for new classifications, not when viewing history
- UI fixes: result screen text overflow, recycling code info widget improvements, material info display
- Settings: offline mode settings, data export functionality
- Gamification: enhanced feedback connection, challenge progress visualization
- AI: improved classification consistency, feedback loop implementation
- Documentation: updated for new features, ad-unlocked premium ideas, and bug fixes

## [Unreleased]

### Added
- Google Play Store submission (May 2025)
  - Created Google Play Developer account
  - Uploaded initial app bundle (version 0.9.0+90)
  - Submitted for review
  - Documentation updated for tracking submission status

### Planned for v0.9.2
- (Planned features and fixes)

## [1.1.0] - 2025-05-16

### Added
- Enhanced Gamification System
  - Immediate visual feedback after waste classification
  - Animated achievement notifications with confetti effects
  - Challenge completion celebrations
  - Points earned popup notifications
  - Enhanced streak indicator with flame animations
  - Improved visual representation of progress

- Waste Analytics Dashboard
  - New dashboard screen accessible from multiple points in the app
  - Overview tab with waste composition visualization
  - Trends tab with time series analysis
  - Insights tab with personalized recommendations
  - Time filtering options (week, month, all time)
  - Environmental impact statistics
  - Goal tracking and progress visualization

- Animation System
  - New animation utilities for consistent visual feedback
  - Particle effects for celebrations
  - Progress animations for challenges and achievements
  - Transition effects for smoother UI experience

### Changed
- Gamification Service updated to provide better feedback loop
- Home screen UI enhanced with more engaging gamification elements
- Result screen now shows immediate classification feedback
- Improved challenge progress tracking and visualization

### Dependencies
- Added fl_chart package for data visualization
- Added intl package for date formatting

### Documentation
- Created user guide for new features
- Added developer documentation for animation and dashboard systems
- Updated project features roadmap
- Enhanced code comments for better maintainability

## [1.0.0] - 2025-04-15

### Initial Release
- Core waste classification functionality using AI
- Basic gamification system (points, achievements, challenges)
- Educational content framework
- Local storage with Hive
- Google Sign-In integration
- History of classified items
- Basic reporting features

## [0.1.0+92] - 2025-05-19
### Changed
- Versioning reset: Restarted public versioning at 0.1.0 for clarity, after internal 0.9.x builds.
- Updated Android package name and all references to `com.pranaysuyash.wastewise` for Play Store compliance.
- Fixed MainActivity class/package mismatch that caused Play Store runtime crash.
- Ensured versionCode is incremented to 92 for Play Console compatibility.
- Updated documentation to reflect new versioning and Play Store issues.

## [0.1.2+94] - 2025-05-19
### Fixed
- Improved color contrast and text visibility across all screens for better accessibility in both light and dark themes.
- All legal/consent, onboarding, and educational screens now meet accessibility standards for color contrast.

## [0.1.3+95] - 2025-05-19
### Changed
- Minor accessibility and color contrast polish based on user feedback.
- Version bump to 0.1.3 (build 95) for Play Store/internal test release.
