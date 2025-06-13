#!/bin/bash

# Open GitHub Branch Settings Script
# Opens the branch protection settings page in the browser

echo "🔗 Opening GitHub branch protection settings..."
echo ""
echo "Configure these settings:"
echo ""
echo "✅ Branch name pattern: main"
echo ""
echo "✅ Require a pull request before merging"
echo "   - Require approvals: 1"
echo "   - Dismiss stale PR approvals when new commits are pushed"
echo ""
echo "✅ Require status checks to pass before merging"
echo "   - Require branches to be up to date before merging"
echo "   - Required status checks:"
echo "     • Build Flutter App"
echo "     • Run Tests"
echo "     • Golden Tests & Visual Diff"
echo "     • Code Quality"
echo ""
echo "✅ Require linear history"
echo "✅ Block force pushes"
echo ""

# Open the settings page
if command -v open &> /dev/null; then
    # macOS
    open "https://github.com/pranaysuyash/Waste-Segregation-App/settings/branches"
elif command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open "https://github.com/pranaysuyash/Waste-Segregation-App/settings/branches"
elif command -v start &> /dev/null; then
    # Windows
    start "https://github.com/pranaysuyash/Waste-Segregation-App/settings/branches"
else
    echo "Please manually visit:"
    echo "https://github.com/pranaysuyash/Waste-Segregation-App/settings/branches"
fi 