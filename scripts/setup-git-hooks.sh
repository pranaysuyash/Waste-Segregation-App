#!/bin/bash

# Git Hooks Setup Script for Waste Segregation App
# This script sets up git hooks to prevent sensitive data commits

echo "🔧 Setting up Git hooks for security..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository. Please run this from the project root."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy our pre-commit hook
if [ -f ".pre-commit-hook.sh" ]; then
    cp .pre-commit-hook.sh .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook installed"
else
    echo "❌ Error: .pre-commit-hook.sh not found"
    exit 1
fi

# Create a simple pre-push hook to remind about sensitive data
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash

echo "🔍 Pre-push security reminder..."

# Check if .env file exists and is not in .gitignore
if [ -f ".env" ]; then
    if ! git check-ignore .env >/dev/null 2>&1; then
        echo "🚨 WARNING: .env file exists but is not in .gitignore!"
        echo "   Please add .env to .gitignore to prevent accidental commits"
        read -p "   Continue with push? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Push cancelled"
            exit 1
        fi
    fi
fi

echo "✅ Pre-push checks passed"
EOF

chmod +x .git/hooks/pre-push
echo "✅ Pre-push hook installed"

# Test the hooks
echo "🧪 Testing hooks..."
if .git/hooks/pre-commit; then
    echo "✅ Pre-commit hook test passed"
else
    echo "⚠️ Pre-commit hook test had warnings (this is normal if no staged files)"
fi

echo ""
echo "🎉 Git hooks setup complete!"
echo ""
echo "📋 What was installed:"
echo "  • Pre-commit hook: Scans for API keys, passwords, and sensitive data"
echo "  • Pre-push hook: Reminds about .env file protection"
echo ""
echo "🔒 Your repository is now protected against accidental sensitive data commits!"
echo ""
echo "💡 To test the protection:"
echo "  1. Try staging a file with 'sk-test123' in it"
echo "  2. Run 'git commit' - it should be blocked"
echo "  3. Use 'git commit --no-verify' only if you're sure the file is safe"