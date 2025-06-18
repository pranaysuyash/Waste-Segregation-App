#!/bin/bash

# Markdown Lint Script
# Runs markdownlint with auto-fix and reports results

set -e

echo "🔍 Running Markdown Lint with Auto-Fix..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Count initial issues
echo "📊 Checking initial markdown issues..."
initial_issues=$(markdownlint docs/*.md *.md 2>/dev/null | wc -l || echo "0")
echo "Initial issues found: $initial_issues"

# Run auto-fix on all markdown files
echo "🔧 Running auto-fix on all markdown files..."

# Fix docs directory
if [ -d "docs" ]; then
    print_status "Fixing docs/*.md files..."
    markdownlint --fix docs/*.md 2>/dev/null || print_warning "Some docs files could not be auto-fixed"
fi

# Fix root directory
print_status "Fixing root *.md files..."
markdownlint --fix *.md 2>/dev/null || print_warning "Some root files could not be auto-fixed"

# Count remaining issues
echo ""
echo "📊 Checking remaining markdown issues..."
remaining_issues=$(markdownlint docs/*.md *.md 2>/dev/null | wc -l || echo "0")

echo ""
echo "📈 Markdown Lint Results:"
echo "  Initial issues: $initial_issues"
echo "  Remaining issues: $remaining_issues"

if [ "$remaining_issues" -eq 0 ]; then
    print_status "All markdown files are now lint-free! 🎉"
    exit 0
elif [ "$remaining_issues" -lt "$initial_issues" ]; then
    improvement=$((initial_issues - remaining_issues))
    print_status "Fixed $improvement issues! Only $remaining_issues issues remain."
    
    echo ""
    echo "📋 Remaining issues (require manual fixing):"
    markdownlint docs/*.md *.md 2>/dev/null || echo "No remaining issues found"
    
    exit 0
else
    print_warning "No improvement detected. Manual intervention may be required."
    
    echo ""
    echo "📋 Issues that need manual fixing:"
    markdownlint docs/*.md *.md 2>/dev/null || echo "No issues found"
    
    exit 1
fi 