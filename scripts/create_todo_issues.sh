#!/bin/bash

# Batch create GitHub issues for high-priority TODOs
# Based on docs/todos_consolidated_2025-06-14.md

echo "🚀 Creating GitHub issues for high-priority TODOs..."

# Array of high-priority TODOs
declare -a HIGH_PRIORITY_TODOS=(
    "[TODO] Firebase Integration & Migration|Complete data migration, analytics, and backup/rollback|firebase,backend"
    "[TODO] AI Classification Re-Analysis|Add re-analysis option, confidence warnings, and feedback aggregation|ai-features"
    "[TODO] Image Segmentation Enhancement|Complete SAM integration, multi-object detection, and user controls|ai-features"
    "[TODO] Re-Scan Button on Results Screen|Let users re-run classification on the same image|ui-ux,feature"
    "[TODO] Confidence Threshold Slider|Allow power users to adjust minimum confidence for auto-classification|ui-ux,feature"
    "[TODO] Batch Classification|Add gallery multi-select for queuing multiple images|feature"
    "[TODO] Android vs iOS Native Design|Implement platform-specific UI, navigation, and animations|ui-ux"
    "[TODO] Modern Design System Overhaul|Add dark mode, glassmorphism, micro-interactions, dynamic theming|ui-ux"
    "[TODO] Camera Permission Retry|Show friendly walkthrough for re-enabling camera permissions|ui-ux,error-handling"
    "[TODO] Segmentation Fail States|Handle cases where no objects detected with manual crop fallback|error-handling"
    "[TODO] Rate-Limit Feedback|Display 'please wait' indicator for API throttling|error-handling"
    "[TODO] Firebase Security Rules|Add comprehensive Firestore rules and data access control|firebase,security"
    "[TODO] Performance & Memory Management|Optimize analytics, image caching, memory leak prevention|performance"
    "[TODO] Error Handling & Resilience|Add comprehensive error handling and retry mechanisms|error-handling"
    "[TODO] Security Rules Testing|Automate Firestore rule tests in CI via Firebase Emulator Suite|testing,firebase"
    "[TODO] Docs-Lint Workflow|Add GitHub Action to fail build if TODOs remain in markdown/code|ci-cd"
    "[TODO] Code Quality Checks|Enforce dart analyze, flutter test coverage, dart_code_metrics on PRs|ci-cd,quality"
    "[TODO] Family Management Features|Implement name editing, copy ID, toggle public/share, member activity|social,family"
    "[TODO] Family Invite System|Implement share via messages, email, and generic share|social,family"
    "[TODO] Achievements System|Implement challenge generation and navigation to completed challenges|gamification"
    "[TODO] Data Protection & Privacy|Add granular privacy settings, consent management, analytics opt-out|security,privacy"
    "[TODO] Security Hardening|Input validation, SQL injection prevention, rate limiting, audit logging|security"
    "[TODO] Offline Queue System|Cache scans and classification requests while offline, auto-sync on reconnect|offline,sync"
    "[TODO] Conflict Resolution UX|Provide in-app merge/conflict dialogs when syncing offline changes|offline,sync"
    "[TODO] Connectivity Indicator|Show subtle banner/icon when offline with reconnect call-to-action|offline,ui-ux"
)

# Function to create issue
create_issue() {
    local title="$1"
    local description="$2"
    local labels="$3"
    
    echo "Creating: $title"
    gh issue create \
        --title "$title" \
        --body "$description. Priority: HIGH. References: docs/todos_consolidated_2025-06-14.md" \
        --label "todo,priority-high,$labels" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Created successfully"
    else
        echo "   ⚠️  May already exist or error occurred"
    fi
}

# Create issues
for todo_item in "${HIGH_PRIORITY_TODOS[@]}"; do
    IFS='|' read -r title description labels <<< "$todo_item"
    create_issue "$title" "$description" "$labels"
    sleep 1  # Rate limiting
done

echo ""
echo "🎉 Batch issue creation complete!"
echo "📊 View all issues: https://github.com/pranaysuyash/Waste-Segregation-App/issues?q=is%3Aissue+is%3Aopen+label%3Atodo" 