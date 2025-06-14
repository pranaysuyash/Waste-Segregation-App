#!/bin/bash

# Create remaining high-priority GitHub issues with existing labels only
echo "🚀 Creating remaining high-priority GitHub issues..."

# Function to create issue safely
create_simple_issue() {
    local title="$1"
    local description="$2"
    local priority="$3"
    
    echo "Creating: $title"
    
    result=$(gh issue create \
        --title "$title" \
        --body "**Priority**: $priority

**Description**: $description

**Source**: docs/todos_consolidated_2025-06-14.md

**Implementation Notes**:
- Review consolidated TODO list for full context
- Check related planning documents
- Coordinate with team for dependencies" \
        --label "todo,priority-$(echo $priority | tr '[:upper:]' '[:lower:]')" 2>&1)
    
    if [[ $result == *"https://github.com"* ]]; then
        echo "   ✅ Created: $result"
    else
        echo "   ⚠️  Issue: $result"
    fi
}

# HIGH PRIORITY TODOs (Core Features)
echo "🔥 Creating HIGH PRIORITY core feature issues..."

create_simple_issue "[TODO] AI Classification Re-Analysis" "Add re-analysis option, confidence warnings, and feedback aggregation for improved classification accuracy" "HIGH"

create_simple_issue "[TODO] Image Segmentation Enhancement" "Complete SAM integration, multi-object detection, and user controls for better image processing" "HIGH"

create_simple_issue "[TODO] Re-Scan Button on Results Screen" "Let users re-run classification on the same image after adjusting framing or lighting conditions" "HIGH"

create_simple_issue "[TODO] Confidence Threshold Slider" "Allow power users to adjust minimum confidence threshold for auto-classification vs manual review" "HIGH"

create_simple_issue "[TODO] Batch Classification" "Add gallery multi-select functionality for queuing multiple images for back-to-back classification" "HIGH"

create_simple_issue "[TODO] Camera Permission Retry" "Show friendly in-app walkthrough for re-enabling camera permissions when initially denied" "HIGH"

create_simple_issue "[TODO] Segmentation Fail States" "Handle cases where no objects are detected by offering manual crop tool as fallback option" "HIGH"

create_simple_issue "[TODO] Rate-Limit Feedback" "Display 'please wait' indicator for API throttling instead of showing generic error messages" "HIGH"

create_simple_issue "[TODO] Firebase Security Rules" "Add comprehensive Firestore security rules and data access control mechanisms" "HIGH"

create_simple_issue "[TODO] Performance & Memory Management" "Optimize analytics processing, image caching, and implement memory leak prevention" "HIGH"

create_simple_issue "[TODO] Error Handling & Resilience" "Add comprehensive error handling, retry mechanisms, and data consistency checks" "HIGH"

create_simple_issue "[TODO] Security Rules Testing" "Automate Firestore security rule tests in CI pipeline via Firebase Emulator Suite" "HIGH"

create_simple_issue "[TODO] Docs-Lint Workflow" "Add GitHub Action to fail builds if any TODOs remain in markdown files or code comments" "HIGH"

create_simple_issue "[TODO] Code Quality Checks" "Enforce dart analyze, flutter test coverage, and dart_code_metrics on all PRs" "HIGH"

create_simple_issue "[TODO] Family Management Features" "Implement name editing, copy ID functionality, toggle public/share, and show member activity" "HIGH"

create_simple_issue "[TODO] Family Invite System" "Implement comprehensive sharing via messages, email, and generic share functionality" "HIGH"

create_simple_issue "[TODO] Achievements System" "Implement challenge generation system and navigation to completed challenges" "HIGH"

create_simple_issue "[TODO] Data Protection & Privacy" "Add granular privacy settings, consent management, and analytics opt-out capabilities" "HIGH"

create_simple_issue "[TODO] Security Hardening" "Implement input validation, SQL injection prevention, rate limiting, and audit logging" "HIGH"

create_simple_issue "[TODO] Offline Queue System" "Cache scans and classification requests while offline, then auto-sync when connectivity returns" "HIGH"

create_simple_issue "[TODO] Conflict Resolution UX" "Provide in-app merge/conflict resolution dialogs when syncing offline changes" "HIGH"

create_simple_issue "[TODO] Connectivity Indicator" "Show subtle banner or icon when offline with reconnect call-to-action" "HIGH"

echo ""
echo "⚡ Creating MEDIUM PRIORITY issues..."

create_simple_issue "[TODO] User Location & GPS Integration" "Add geolocator functionality, permissions handling, GPS calculations, and location-based sorting" "MEDIUM"

create_simple_issue "[TODO] User-Contributed Disposal Information" "Add facility editing UI, community verification system, reputation tracking, and moderation tools" "MEDIUM"

create_simple_issue "[TODO] End-to-End Tests for Reset/Delete" "Write Flutter integration tests that simulate Reset Account functionality and verify complete data deletion" "MEDIUM"

create_simple_issue "[TODO] Restore Flow Tests" "Test complete archive → delete → restore flow and assert user data and authentication are fully restored" "MEDIUM"

create_simple_issue "[TODO] Inactive-Cleanup Cron Simulator" "Add test harness to fast-forward system clock and run cleanup processes, verify logs and results" "MEDIUM"

create_simple_issue "[TODO] Accessibility Audit" "Run accessibility scanner (accessibility_test package) against key screens and surface failures as actionable tasks" "MEDIUM"

create_simple_issue "[TODO] Dark-Mode QA" "Add visual regression tests (golden_toolkit) to ensure both light and dark themes render correctly" "MEDIUM"

create_simple_issue "[TODO] Localization Completion" "Validate generated ARB files against translations and identify missing keys for completion" "MEDIUM"

create_simple_issue "[TODO] Automate Missing Translations Reports" "Add CI pipeline reports for missing translations and localization gaps" "MEDIUM"

create_simple_issue "[TODO] Voice-Guided Scan" "For low-vision users, provide guidance through image framing via haptic feedback and audio cues" "MEDIUM"

create_simple_issue "[TODO] Large-Text Mode" "Override UI to use extra-large fonts for key screens while respecting system accessibility settings" "MEDIUM"

create_simple_issue "[TODO] In-App Feedback Widget" "Allow users to flag misclassifications directly from Results screen, sending image and category for review" "MEDIUM"

create_simple_issue "[TODO] Usage Survey" "After several scans, prompt users for opt-in 1-minute survey on accuracy and feature requests" "MEDIUM"

create_simple_issue "[TODO] Event Instrumentation" "Track key user events: scans started/succeeded/failed, re-analysis used, share actions for product insights" "MEDIUM"

create_simple_issue "[TODO] Funnel Analysis" "Add custom analytics events around onboarding, first scan, and sharing to identify user drop-off points" "MEDIUM"

create_simple_issue "[TODO] Scan Presets" "Allow users to save common scan contexts (kitchen vs office) that pre-select disposal categories or filters" "MEDIUM"

create_simple_issue "[TODO] Custom Categories" "Enable power users to define new waste categories (e-waste) and map them to existing disposal instructions" "MEDIUM"

create_simple_issue "[TODO] One-Tap Share" "Build shareable cards (image + recycling message) optimized for Instagram, WhatsApp, and other social platforms" "MEDIUM"

create_simple_issue "[TODO] Group Challenges" "Allow users to invite friends to mini-challenges (Recycle 10 items this week) directly from the app" "MEDIUM"

create_simple_issue "[TODO] Crashlytics Verification" "Write sanity check to ensure real crash events are being received and processed correctly" "MEDIUM"

create_simple_issue "[TODO] Performance Benchmarks" "Create benchmark script to record image-segmentation latency on typical mid-range devices" "MEDIUM"

create_simple_issue "[TODO] Hidden Debug UI" "Document and implement /debug panel behind ENABLE_DEBUG_UI flag with route listings and button stubs" "MEDIUM"

create_simple_issue "[TODO] Feature-Flag Config Documentation" "Create feature_flags.md listing all flags (enable_account_cleanup, enable_restore_ui) and default settings" "MEDIUM"

create_simple_issue "[TODO] Firestore Backup Validation" "Write script or Cloud Function to periodically verify daily backups contain expected collections and document counts" "MEDIUM"

create_simple_issue "[TODO] Rollback Drill Documentation" "Document and script rollback procedure for failed migrations, test end-to-end in staging project" "MEDIUM"

create_simple_issue "[TODO] Admin Panel Specification" "Write high-level wireframe and API contract for archive/restore screens in docs/admin/restore_spec.md" "MEDIUM"

echo ""
echo "🧩 Creating CODE TODO issues..."

create_simple_issue "[CODE] AdMob Configuration Required" "Replace placeholder ad unit IDs in ad_service.dart with actual AdMob console IDs and complete setup" "HIGH"

create_simple_issue "[CODE] AdMob GDPR Compliance" "Add consent management for GDPR compliance in ad service implementation" "HIGH"

create_simple_issue "[CODE] Family Invite Share Implementation" "Implement share via messages, email, and generic share functionality in family_invite_screen.dart" "HIGH"

create_simple_issue "[CODE] Localization Setup" "Uncomment gen_l10n setup in dialog_helper.dart and implement AppLocalizations usage" "MEDIUM"

create_simple_issue "[CODE] Settings Localization" "Localize all settings titles, toggles, labels, and content across settings screen files" "MEDIUM"

create_simple_issue "[CODE] Support & Bug Reporting" "Implement email support, bug reporting, and app rating functionality in settings screens" "MEDIUM"

create_simple_issue "[CODE] Classification Migration Logic" "Implement classification data migration logic in developer settings" "MEDIUM"

create_simple_issue "[CODE] User ID from Auth Provider" "Get userId from authentication provider in contribution submission screen" "MEDIUM"

create_simple_issue "[CODE] Photo Upload Functionality" "Implement photo upload functionality in contribution submission screen" "MEDIUM"

create_simple_issue "[CODE] Premium Navigation" "Navigate to premium features screen from theme settings" "MEDIUM"

echo ""
echo "🎉 Issue creation complete!"
echo ""
echo "📊 Summary: Created 50+ additional GitHub issues"
echo "🔗 View all issues: https://github.com/pranaysuyash/Waste-Segregation-App/issues?q=is%3Aissue+is%3Aopen+label%3Atodo" 