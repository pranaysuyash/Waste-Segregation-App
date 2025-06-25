# Git Security Setup Guide

**Date**: June 25, 2025  
**Purpose**: Prevent accidental commit of sensitive data (API keys, passwords, etc.)

## 🎯 Overview

This guide sets up automated git hooks to prevent accidental commits of sensitive data like API keys, passwords, and environment files.

## 🚀 Quick Setup

### Option 1: Automated Setup (Recommended)
```bash
# Run from project root
./scripts/setup-git-hooks.sh
```

### Option 2: Manual Setup
```bash
# Copy pre-commit hook
cp .pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 🔒 What Gets Protected

### ❌ Automatically Blocked Patterns

**OpenAI API Keys:**
- `sk-[alphanumeric]{20,}` - Legacy OpenAI keys
- `sk-proj-[alphanumeric_-]{20,}` - New project-based OpenAI keys

**Google/Gemini API Keys:**
- `AIzaSy[alphanumeric_-]{33}` when associated with Gemini
- Environment variables with Gemini API keys

**Other Sensitive Data:**
- Database connection strings
- AWS credentials
- Private keys
- Password fields with actual values

**Files:**
- `.env` files (except `.env.example`, `.env.template`)
- Any file with obvious sensitive content

### ✅ Allowed (Firebase Client Keys)
Firebase client API keys are specifically allowed as they're designed to be public:
- Firebase API keys in `firebase_options.dart`
- Configuration files like `google-services.json`
- Public client identifiers

## 🧪 Testing the Protection

### Test 1: Try to commit a fake API key
```bash
# Create a test file
echo "OPENAI_API_KEY=sk-test123456789" > test_sensitive.txt

# Try to commit it
git add test_sensitive.txt
git commit -m "test"

# Should be BLOCKED with security warning
```

### Test 2: Try to commit .env file
```bash
# Try to add your .env file
git add .env
git commit -m "test env"

# Should be BLOCKED
```

### Test 3: Bypass protection (if needed)
```bash
# Only use this if you're absolutely sure the file is safe
git commit --no-verify -m "bypass security check"
```

## 📁 Environment File Management

### ✅ Proper Setup
```bash
# 1. Copy template
cp .env.example .env

# 2. Fill in your keys
nano .env

# 3. Verify .env is ignored
git check-ignore .env  # Should return: .env

# 4. Commit template (safe)
git add .env.example
git commit -m "Add environment template"
```

### ❌ What NOT to Do
```bash
# DON'T commit actual .env files
git add .env  # ❌ Will be blocked

# DON'T put real keys in example files
# .env.example should only have placeholders
```

## 🛠️ Hook Details

### Pre-commit Hook (`/.git/hooks/pre-commit`)
- **Triggers**: Every `git commit`
- **Scans**: All staged files
- **Action**: Blocks commit if sensitive data detected
- **Bypass**: `git commit --no-verify` (use with caution)

### Pre-push Hook (`/.git/hooks/pre-push`)
- **Triggers**: Every `git push`
- **Checks**: .env file protection
- **Action**: Warns if .env exists and not ignored
- **Interactive**: Asks for confirmation

## 🔧 Customizing Protection

### Add New Patterns
Edit `.pre-commit-hook.sh` and add to the `PATTERNS` array:
```bash
PATTERNS=(
    "your_custom_pattern_here"
    "another_sensitive_pattern"
)
```

### Exclude Specific Files
Add exclusions in the pre-commit hook:
```bash
# Skip certain files
if [[ "$file" == "path/to/safe/file.txt" ]]; then
    continue
fi
```

## 🚨 If Sensitive Data Gets Committed

### Option 1: Amend Last Commit (if not pushed)
```bash
# Remove sensitive file
git rm --cached sensitive_file.txt

# Amend the commit
git commit --amend --no-edit
```

### Option 2: Rewrite History (dangerous)
```bash
# Remove file from all history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch sensitive_file.txt' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (if already pushed)
git push --force-with-lease
```

### Option 3: Rotate Compromised Keys
1. **Immediately revoke** the exposed API key
2. **Generate new** API key
3. **Update** your `.env` file
4. **Test** that everything works
5. **Monitor** usage for any suspicious activity

## 📊 Security Checklist

### ✅ Initial Setup
- [ ] Git hooks installed (`./scripts/setup-git-hooks.sh`)
- [ ] `.env` file created from template
- [ ] `.env` properly ignored (`git check-ignore .env`)
- [ ] Sensitive keys added to `.env`
- [ ] Test protection works

### ✅ Ongoing Maintenance
- [ ] Never commit `.env` files
- [ ] Use `.env.example` for sharing configuration
- [ ] Regularly test hook functionality
- [ ] Update patterns as needed
- [ ] Rotate API keys periodically

### ✅ Team Setup
- [ ] All team members run setup script
- [ ] Document sensitive data handling
- [ ] Regular security training
- [ ] Incident response procedures

## 🆘 Troubleshooting

### Hook Not Working
```bash
# Check if hook exists and is executable
ls -la .git/hooks/pre-commit

# Reinstall if needed
./scripts/setup-git-hooks.sh
```

### False Positives
```bash
# Temporarily bypass (use carefully)
git commit --no-verify

# Or update hook patterns to be more specific
```

### Need to Commit Firebase Keys
Firebase client keys are already whitelisted and should commit normally. If blocked, check that they're in the correct files (`firebase_options.dart`, etc.).

## 📚 Related Documentation

- [Firebase API Keys Clarification](../analysis/FIREBASE_API_KEYS_CLARIFICATION.md)
- [Environment Variables Setup](./ENVIRONMENT_VARIABLES_SETUP.md)
- [Security Best Practices](../planning/SECURITY_BEST_PRACTICES.md)

---

**Remember**: These hooks are your safety net, but security starts with awareness. Always double-check what you're committing!