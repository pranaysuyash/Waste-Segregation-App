#!/bin/bash

# Solo Developer Branch Protection Setup
# Optimized for single maintainer with safety nets but no workflow friction

set -e

echo "🔒 Setting up optimized branch protection for solo development..."

# Create the protection configuration
cat > solo_branch_protection.json << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Build Flutter App",
      "Run Tests",
      "Golden Tests & Visual Diff",
      "Code Quality"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF

echo "📋 Solo Branch Protection Configuration:"
echo "✅ Require CI status checks (Build, Tests, Golden Tests, Code Quality)"
echo "✅ Block force pushes (prevents accidental history rewrites)"
echo "✅ Block branch deletion (prevents accidental main branch deletion)"
echo "❌ No required PR reviews (you can self-merge immediately)"
echo "❌ No admin enforcement (you can override if needed)"
echo "✅ Allow fork syncing (for potential contributors)"

# Apply the protection
echo ""
echo "🚀 Applying branch protection to main branch..."

gh api repos/pranaysuyash/Waste-Segregation-App/branches/main/protection \
  --method PUT \
  --input solo_branch_protection.json

echo ""
echo "✅ Solo branch protection applied successfully!"
echo ""
echo "🎯 Your AI-optimized workflow now:"
echo "1. Create feature branch: git checkout -b feat/ai-feature-\$(date +%s)"
echo "2. Make changes with AI agent assistance"
echo "3. Validate: ./scripts/testing/ai_test_validator.sh"
echo "4. Push and create PR: gh pr create --title 'AI: Feature Implementation'"
echo "5. Auto-merge when CI passes (no human review needed)"
echo "6. Clean up: git branch -d feat/ai-feature-*"
echo ""
echo "🛡️  Safety features active:"
echo "• Force push protection (no accidental history rewrites)"
echo "• Branch deletion protection (main branch is safe)"
echo "• CI quality gates (all tests must pass)"
echo "• Audit trail (PR history for all changes)"
echo ""
echo "⚡ No friction:"
echo "• No required reviews (you can merge your own PRs)"
echo "• No admin restrictions (you can override if needed)"
echo "• Auto-merge available (set it and forget it)"

# Clean up
rm solo_branch_protection.json

echo ""
echo "🎉 Ready for efficient solo development with safety nets!" 