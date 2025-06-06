#!/bin/bash

# GitHub TODO Integration Setup Script
# This script helps you set up the GitHub TODO tracking system

echo "🚀 Setting up GitHub TODO Integration..."
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "📥 Install it from: https://cli.github.com/"
    echo "   Or run: brew install gh"
    exit 1
fi

# Check if user is logged in to GitHub
if ! gh auth status &> /dev/null; then
    echo "🔐 Please login to GitHub CLI first:"
    echo "   gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is ready!"
echo ""

# Get repository info
REPO_OWNER=$(gh repo view --json owner --jq .owner.login)
REPO_NAME=$(gh repo view --json name --jq .name)

echo "📁 Repository: $REPO_OWNER/$REPO_NAME"
echo ""

# Create labels for TODO tracking
echo "🏷️  Creating GitHub labels..."

LABELS=(
    "todo:📝 TODO items from code and docs:#FFA500"
    "priority-high:🔥 High priority items:#FF0000"
    "priority-medium:⚡ Medium priority items:#FFA500"
    "priority-low:📋 Low priority items:#0075CA"
    "ui-ux:🎨 User interface and experience:#E99695"
    "backend:⚙️ Backend and server-side:#5319E7"
    "firebase:🔥 Firebase related:#FF6B35"
    "technical-debt:🔧 Technical debt and refactoring:#FBCA04"
    "auto-generated:🤖 Automatically created:#EDEDED"
    "needs-triage:🔍 Needs review and prioritization:#D4C5F9"
    "good-first-issue:👋 Good for newcomers:#7057FF"
)

for label in "${LABELS[@]}"; do
    IFS=':' read -r name description color <<< "$label"
    
    # Check if label exists
    if gh label list --search "$name" --json name --jq '.[].name' | grep -q "^$name$"; then
        echo "   ⏭️  Label '$name' already exists"
    else
        gh label create "$name" --description "$description" --color "$color"
        echo "   ✅ Created label '$name'"
    fi
done

echo ""

# Create project board
echo "📊 Setting up Project Board..."

# Check if project exists
PROJECT_EXISTS=$(gh project list --owner "$REPO_OWNER" --format json | jq -r '.projects[] | select(.title=="TODO Tracking") | .title' 2>/dev/null)

if [ "$PROJECT_EXISTS" = "TODO Tracking" ]; then
    echo "   ⏭️  Project 'TODO Tracking' already exists"
else
    # Create project
    gh project create --title "TODO Tracking" --body "Centralized tracking of all TODO items from code, docs, and issues"
    echo "   ✅ Created project 'TODO Tracking'"
fi

echo ""

# Count existing TODOs
echo "📊 Analyzing existing TODOs..."

# Count TODOs in code
CODE_TODOS=$(find lib/ -name "*.dart" -exec grep -l "TODO:" {} \; 2>/dev/null | wc -l)
echo "   📝 Code files with TODOs: $CODE_TODOS"

# Count TODOs in markdown
MD_TODOS=$(grep -r "- \[ \]" docs/ 2>/dev/null | wc -l)
echo "   📋 Incomplete TODOs in docs: $MD_TODOS"

# Count existing GitHub issues with todo label
GH_TODOS=$(gh issue list --label "todo" --json number | jq length)
echo "   🐙 GitHub issues with 'todo' label: $GH_TODOS"

echo ""

# Offer to create sample issues
echo "🎯 Next Steps:"
echo ""
echo "1. 📋 Review the GitHub TODO Integration Guide:"
echo "   📖 docs/GITHUB_TODO_INTEGRATION.md"
echo ""
echo "2. 🔄 The GitHub Actions will automatically:"
echo "   • Create issues from new TODO comments in code"
echo "   • Update markdown files when issues are closed"
echo ""
echo "3. 🚀 Start using the system:"
echo "   • Add TODO comments in code: // TODO: Description"
echo "   • Create issues from existing TODOs using templates"
echo "   • Use commit messages to close issues: 'Closes #123'"
echo ""
echo "4. 📊 Access your project board:"
echo "   🌐 https://github.com/$REPO_OWNER/$REPO_NAME/projects"
echo ""

# Ask if user wants to create sample issues from high-priority TODOs
read -p "🤔 Would you like to create GitHub issues for high-priority TODOs now? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🎯 Creating sample issues from high-priority TODOs..."
    
    # Create a few sample issues from critical TODOs
    CRITICAL_TODOS=(
        "Fix RenderFlex overflow errors in UI components"
        "Implement real community stats calculation"
        "Fix duplicate classification detection logic"
        "Resolve Firebase authentication issues"
        "Implement proper error handling for network failures"
    )
    
    for todo in "${CRITICAL_TODOS[@]}"; do
        # Check if similar issue already exists
        EXISTING=$(gh issue list --search "$todo" --json title --jq '.[].title' | head -1)
        
        if [ -z "$EXISTING" ]; then
            gh issue create \
                --title "[TODO] $todo" \
                --body "**TODO Source**
- [x] From analysis of current codebase issues
- [ ] From docs/MASTER_TODO_COMPREHENSIVE.md
- [ ] From code comments (// TODO:)
- [ ] New TODO item

**TODO Description**
$todo

**Priority**
- [x] High
- [ ] Medium
- [ ] Low

**Category**
- [x] Bug Fix
- [ ] Core Features
- [ ] UI/UX
- [ ] Firebase/Backend

**Effort Estimate**
- [ ] Small (< 4 hours)
- [x] Medium (1-2 days)
- [ ] Large (3-5 days)
- [ ] Epic (1+ weeks)" \
                --label "todo,priority-high,needs-triage"
            
            echo "   ✅ Created issue: $todo"
        else
            echo "   ⏭️  Similar issue already exists: $todo"
        fi
    done
fi

echo ""
echo "🎉 GitHub TODO Integration setup complete!"
echo ""
echo "📚 Resources:"
echo "   📖 Integration Guide: docs/GITHUB_TODO_INTEGRATION.md"
echo "   🐙 GitHub Issues: https://github.com/$REPO_OWNER/$REPO_NAME/issues"
echo "   📊 Project Board: https://github.com/$REPO_OWNER/$REPO_NAME/projects"
echo ""
echo "Happy coding! 🚀" 