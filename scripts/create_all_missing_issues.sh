#!/bin/bash

# Create ALL missing GitHub issues from consolidated TODO list
# Based on docs/todos_consolidated_2025-06-14.md

echo "🚀 Creating ALL missing GitHub issues from consolidated TODO list..."
echo "📊 Target: 80+ TODOs → GitHub Issues"
echo ""

# Function to create issue with error handling
create_issue_safe() {
    local title="$1"
    local description="$2"
    local labels="$3"
    local priority="$4"
    
    echo "Creating: $title"
    
    # Create the issue
    result=$(gh issue create \
        --title "$title" \
        --body "**Priority**: $priority

**Description**: $description

**Source**: docs/todos_consolidated_2025-06-14.md

**Category**: $(echo $labels | tr ',' ' ')

**Implementation Notes**:
- Review consolidated TODO list for full context
- Check related planning documents
- Coordinate with team for dependencies" \
        --label "todo,priority-$(echo $priority | tr '[:upper:]' '[:lower:]'),$labels" 2>&1)
    
    if [[ $result == *"https://github.com"* ]]; then
        echo "   ✅ Created: $result"
        return 0
    else
        echo "   ⚠️  Issue: $result"
        return 1
    fi
}

# HIGH PRIORITY TODOs
echo "🔥 Creating HIGH PRIORITY issues..."

# AI & Core Features
create_issue_safe "[TODO] AI Classification Re-Analysis" "Add re-analysis option, confidence warnings, and feedback aggregation" "ai-features" "HIGH"
create_issue_safe "[TODO] Image Segmentation Enhancement" "Complete SAM integration, multi-object detection, and user controls" "ai-features" "HIGH"
create_issue_safe "[TODO] Re-Scan Button on Results Screen" "Let users re-run classification on the same image after adjusting framing/lighting" "ui-ux,feature" "HIGH"
create_issue_safe "[TODO] Confidence Threshold Slider" "Allow power users to adjust minimum confidence for auto-classification vs manual review" "ui-ux,feature" "HIGH"
create_issue_safe "[TODO] Batch Classification" "Add gallery multi-select for queuing multiple images for back-to-back classification" "feature" "HIGH"

# UI/UX & Platform
create_issue_safe "[TODO] Camera Permission Retry" "Show friendly walkthrough for re-enabling camera permissions when denied" "ui-ux,error-handling" "HIGH"
create_issue_safe "[TODO] Segmentation Fail States" "Handle cases where no objects detected with manual crop tool fallback" "error-handling" "HIGH"
create_issue_safe "[TODO] Rate-Limit Feedback" "Display 'please wait' indicator for API throttling instead of generic error" "error-handling" "HIGH"

# Technical Debt & Security
create_issue_safe "[TODO] Firebase Security Rules" "Add comprehensive Firestore rules and data access control" "firebase,security" "HIGH"
create_issue_safe "[TODO] Performance & Memory Management" "Optimize analytics, image caching, and memory leak prevention" "performance" "HIGH"
create_issue_safe "[TODO] Error Handling & Resilience" "Add comprehensive error handling and retry mechanisms" "error-handling" "HIGH"
create_issue_safe "[TODO] Security Rules Testing" "Automate Firestore rule tests in CI via Firebase Emulator Suite" "testing,firebase" "HIGH"

# CI/CD & Quality Gates
create_issue_safe "[TODO] Docs-Lint Workflow" "Add GitHub Action to fail build if TODOs remain in markdown/code" "ci-cd" "HIGH"
create_issue_safe "[TODO] Code Quality Checks" "Enforce dart analyze, flutter test coverage, dart_code_metrics on PRs" "ci-cd,quality" "HIGH"

# Family & Social Features
create_issue_safe "[TODO] Family Management Features" "Implement name editing, copy ID, toggle public/share, member activity" "social,family" "HIGH"
create_issue_safe "[TODO] Family Invite System" "Implement share via messages, email, and generic share" "social,family" "HIGH"
create_issue_safe "[TODO] Achievements System" "Implement challenge generation and navigation to completed challenges" "gamification" "HIGH"

# Security & Privacy
create_issue_safe "[TODO] Data Protection & Privacy" "Add granular privacy settings, consent management, analytics opt-out" "security,privacy" "HIGH"
create_issue_safe "[TODO] Security Hardening" "Input validation, SQL injection prevention, rate limiting, audit logging" "security" "HIGH"

# Offline & Sync Behavior
create_issue_safe "[TODO] Offline Queue System" "Cache scans and classification requests while offline, auto-sync on reconnect" "offline,sync" "HIGH"
create_issue_safe "[TODO] Conflict Resolution UX" "Provide in-app merge/conflict dialogs when syncing offline changes" "offline,sync" "HIGH"
create_issue_safe "[TODO] Connectivity Indicator" "Show subtle banner/icon when offline with reconnect call-to-action" "offline,ui-ux" "HIGH"

echo ""
echo "⚡ Creating MEDIUM PRIORITY issues..."

# Location & Community
create_issue_safe "[TODO] User Location & GPS Integration" "Add geolocator, permissions, GPS calculations, location-based sorting" "location,gps" "MEDIUM"
create_issue_safe "[TODO] User-Contributed Disposal Information" "Add facility editing UI, community verification, reputation, moderation tools" "community" "MEDIUM"

# Testing & Quality
create_issue_safe "[TODO] End-to-End Tests for Reset/Delete" "Write Flutter integration tests simulating Reset Account and verify data deletion" "testing" "MEDIUM"
create_issue_safe "[TODO] Restore Flow Tests" "Test archive → delete → restore → assert user data and auth fully restored" "testing" "MEDIUM"
create_issue_safe "[TODO] Inactive-Cleanup Cron Simulator" "Add test harness to fast-forward clock and run cleanup, verify logs" "testing" "MEDIUM"

# Accessibility & Internationalization
create_issue_safe "[TODO] a11y Audit" "Run accessibility scanner against key screens and surface failures as tasks" "accessibility" "MEDIUM"
create_issue_safe "[TODO] Dark-Mode QA" "Add visual regression tests to ensure both light and dark themes render correctly" "accessibility,ui-ux" "MEDIUM"
create_issue_safe "[TODO] Localization Completion" "Validate generated ARB files against translations missing keys" "i18n" "MEDIUM"
create_issue_safe "[TODO] Automate Missing Translations Reports" "Add CI reports for missing translations" "i18n,ci-cd" "MEDIUM"
create_issue_safe "[TODO] Voice-Guided Scan" "For low-vision users, guide through framing via haptic/audio cues" "accessibility" "MEDIUM"
create_issue_safe "[TODO] Large-Text Mode" "Override UI to use extra-large fonts for key screens, respect system settings" "accessibility" "MEDIUM"

# User Feedback & Reporting
create_issue_safe "[TODO] In-App Feedback Widget" "Let users flag misclassification from Results screen, send image + category for review" "feedback" "MEDIUM"
create_issue_safe "[TODO] Usage Survey" "After a few scans, prompt opt-in for 1-minute survey on accuracy and feature requests" "feedback" "MEDIUM"

# Analytics & Telemetry
create_issue_safe "[TODO] Event Instrumentation" "Track key events: scans started/succeeded/failed, re-analysis used, share actions" "analytics" "MEDIUM"
create_issue_safe "[TODO] Funnel Analysis" "Add custom events around onboarding, first scan, sharing to identify drop-off points" "analytics" "MEDIUM"

# Personalization & Settings
create_issue_safe "[TODO] Scan Presets" "Allow users to save common scan contexts that pre-select disposal categories/filters" "personalization" "MEDIUM"
create_issue_safe "[TODO] Custom Categories" "Enable power users to define new waste categories and map to disposal instructions" "personalization" "MEDIUM"

# Social & Sharing
create_issue_safe "[TODO] One-Tap Share" "Build share cards for Instagram/WhatsApp with image + recycling message" "social,sharing" "MEDIUM"
create_issue_safe "[TODO] Group Challenges" "Allow users to invite friends to mini-challenges directly from app" "social,gamification" "MEDIUM"

# Monitoring & Observability
create_issue_safe "[TODO] Crashlytics Verification" "Write sanity check ensuring real crash events are received" "monitoring" "MEDIUM"
create_issue_safe "[TODO] Performance Benchmarks" "Create benchmark script to record image-segmentation latency on mid-range devices" "performance,monitoring" "MEDIUM"

# Dev-Phase Debug Tools
create_issue_safe "[TODO] Hidden Debug UI" "Document and implement /debug panel behind ENABLE_DEBUG_UI flag" "debug,dev-tools" "MEDIUM"
create_issue_safe "[TODO] Feature-Flag Config" "Create feature_flags.md listing all flags and their default settings" "dev-tools,documentation" "MEDIUM"

# Backup & Disaster Recovery
create_issue_safe "[TODO] Firestore Backup Validation" "Write script/Cloud Function to verify daily backups contain expected collections/doc counts" "backup,firebase" "MEDIUM"
create_issue_safe "[TODO] Rollback Drill" "Document and script rollback procedure for failed migrations, test end-to-end in staging" "backup,disaster-recovery" "MEDIUM"

# Documentation Gaps
create_issue_safe "[TODO] Feature-Flag Guide" "Add docs/admin/feature_flags.md explaining how to flip flags, where they live, intended use" "documentation" "MEDIUM"
create_issue_safe "[TODO] Admin Panel Spec" "Write high-level wireframe and API contract for archive/restore screens" "documentation,admin" "MEDIUM"

echo ""
echo "📋 Creating LOW PRIORITY issues..."

# Documentation & Maintenance
create_issue_safe "[TODO] Update API Documentation" "Update API documentation for new features" "documentation" "LOW"
create_issue_safe "[TODO] Create Developer Guides" "Create developer guides for platform-specific UI" "documentation" "LOW"
create_issue_safe "[TODO] Add Code Examples" "Add code examples for community contributions" "documentation" "LOW"
create_issue_safe "[TODO] Update User Guides" "Update user guides with new feedback features" "documentation" "LOW"
create_issue_safe "[TODO] Doc-as-Code Migration" "Move /docs to Docusaurus, auto-publish to GitHub Pages" "documentation" "LOW"
create_issue_safe "[TODO] Design-Token Reference Page" "Create /docs/design/design_tokens.md" "documentation,design" "LOW"

# UI Polish
create_issue_safe "[TODO] App Logo" "Replace Flutter logo with custom logo" "ui-ux,branding" "LOW"
create_issue_safe "[TODO] Loading States" "Add modern loading states and skeletons" "ui-ux" "LOW"
create_issue_safe "[TODO] Chart Accessibility" "Make charts screen-reader friendly" "accessibility" "LOW"

# Quick Wins
create_issue_safe "[TODO] Crashlytics & Sentry Wiring" "Capture uncaught exceptions, verify dashboard reception" "monitoring" "LOW"
create_issue_safe "[TODO] Connectivity Watchdog" "Wrap API calls in NetworkGuard, add offline user toast" "networking" "LOW"
create_issue_safe "[TODO] Firestore Security Rules Audit" "Write unit tests for rules" "firebase,testing" "LOW"
create_issue_safe "[TODO] Feature-Flag System" "Use flutter_dotenv + remote_config for experimental features" "feature-flags" "LOW"
create_issue_safe "[TODO] Storybook Setup" "Add Widgetbook and React Storybook with CI previews" "dev-tools" "LOW"

echo ""
echo "🧩 Creating CODE TODO issues..."

# i18n & Localization Code TODOs
create_issue_safe "[CODE] dialog_helper.dart:2 - Uncomment gen_l10n" "Uncomment when gen_l10n is properly set up" "i18n,code-todo" "MEDIUM"
create_issue_safe "[CODE] dialog_helper.dart:17 - Use AppLocalizations" "Use AppLocalizations when properly set up" "i18n,code-todo" "MEDIUM"
create_issue_safe "[CODE] Settings Localization" "Localize all settings titles, toggles, labels across multiple files" "i18n,code-todo" "MEDIUM"
create_issue_safe "[CODE] Recycling Code Info Localization" "Localize recycling code info labels, names, examples, semantics" "i18n,code-todo" "MEDIUM"

# Ads & Monetization Code TODOs
create_issue_safe "[CODE] AdMob Configuration Required" "Replace placeholder ad unit IDs with actual AdMob console IDs" "ads,code-todo" "HIGH"
create_issue_safe "[CODE] AdMob GDPR Compliance" "Add consent management for GDPR compliance" "ads,privacy,code-todo" "HIGH"
create_issue_safe "[CODE] Ad Error Tracking" "Implement proper error tracking/analytics for ads" "ads,analytics,code-todo" "MEDIUM"
create_issue_safe "[CODE] Reward Ad Functionality" "Implement reward ad functionality" "ads,code-todo" "MEDIUM"

# Feature Implementation Code TODOs
create_issue_safe "[CODE] Family Invite Share Implementation" "Implement share via messages, email, and generic share" "social,code-todo" "HIGH"
create_issue_safe "[CODE] Theme Settings Premium Navigation" "Navigate to premium features screen" "ui-ux,premium,code-todo" "MEDIUM"
create_issue_safe "[CODE] Contribution Photo Upload" "Implement photo upload functionality" "community,code-todo" "MEDIUM"
create_issue_safe "[CODE] User ID from Auth Provider" "Get userId from auth provider" "auth,code-todo" "MEDIUM"
create_issue_safe "[CODE] Service Method Names Check" "Check correct method names for premiumService, storageService, analyticsService" "refactoring,code-todo" "LOW"
create_issue_safe "[CODE] Classification Migration Logic" "Implement classification migration logic" "migration,code-todo" "MEDIUM"
create_issue_safe "[CODE] Support & Bug Reporting" "Implement email support, bug reporting, app rating functionality" "support,code-todo" "MEDIUM"

# UI/UX & Animations Code TODOs
create_issue_safe "[CODE] Dashboard Animation Replacement" "Replace with dashboard-specific animation" "ui-ux,animations,code-todo" "LOW"
create_issue_safe "[CODE] Progress Tracking Animation" "Implement progress tracking animation" "ui-ux,animations,code-todo" "LOW"

echo ""
echo "🎉 Batch issue creation complete!"
echo ""
echo "📊 Summary:"
echo "   🔥 High Priority: ~25 issues"
echo "   ⚡ Medium Priority: ~30 issues" 
echo "   📋 Low Priority: ~15 issues"
echo "   🧩 Code TODOs: ~15 issues"
echo "   📈 Total Target: ~85 issues"
echo ""
echo "🔗 View all issues:"
echo "   https://github.com/pranaysuyash/Waste-Segregation-App/issues?q=is%3Aissue+is%3Aopen+label%3Atodo"
echo ""
echo "📋 Next steps:"
echo "   1. Review created issues on GitHub"
echo "   2. Update mapping table in docs/automation/todo_management_automation_2025-06-14.md"
echo "   3. Assign issues to team members"
echo "   4. Update sprint board with selected issues" 