#!/bin/bash

# Enhanced Pre-commit Hook for Sensitive Data Protection
# This script prevents commits containing sensitive API keys

echo "🔍 Checking for sensitive data before commit..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Patterns to check for sensitive data
PATTERNS=(
    # OpenAI API Keys
    "sk-[a-zA-Z0-9]{15,}"
    "sk-proj-[a-zA-Z0-9_-]{15,}"
    
    # Google/Gemini API Keys (non-Firebase) - Look for context clues
    "GEMINI_API_KEY.*=.*AIzaSy"
    "gemini.*api.*key.*AIzaSy"
    "AIzaSy[A-Za-z0-9_-]{33}.*gemini"
    "AIzaSy[A-Za-z0-9_-]{33}.*GEMINI"
    
    # Environment variable assignments with sensitive values
    "OPENAI_API_KEY.*=.*sk-"
    "OPENAI.*=.*sk-"
    "GEMINI.*=.*AIzaSy"
    
    # Other sensitive patterns
    "password\s*[=:]\s*['\"][^'\"]{8,}['\"]"
    "secret\s*[=:]\s*['\"][^'\"]{8,}['\"]"
    "private_key.*BEGIN.*PRIVATE.*KEY"
    
    # Database credentials
    "postgresql://.*:.*@"
    "mysql://.*:.*@"
    "mongodb://.*:.*@"
    
    # AWS credentials
    "AKIA[0-9A-Z]{16}"
    "aws_secret_access_key.*[A-Za-z0-9/+=]{40}"
)

# Files to check (staged files)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No staged files to check"
    exit 0
fi

SENSITIVE_FOUND=0
TOTAL_CHECKED=0

echo "📁 Checking staged files..."

for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        echo "🔍 Checking $file..."
        TOTAL_CHECKED=$((TOTAL_CHECKED + 1))
        
        for pattern in "${PATTERNS[@]}"; do
            if grep -qE "$pattern" "$file" 2>/dev/null; then
                echo -e "${RED}🚨 SECURITY ALERT: Potential sensitive data found in $file${NC}"
                echo -e "${RED}   Pattern: $pattern${NC}"
                
                # Show the line (with redacted sensitive parts)
                grep -nE "$pattern" "$file" | head -3 | sed 's/sk-[a-zA-Z0-9_-]\{20,\}/sk-[REDACTED]/g' | sed 's/AIzaSy[A-Za-z0-9_-]\{33\}/AIzaSy[REDACTED]/g'
                
                SENSITIVE_FOUND=$((SENSITIVE_FOUND + 1))
            fi
        done
        
        # Special check for .env files
        if [[ "$file" == *.env ]] && [[ "$file" != *.env.example ]] && [[ "$file" != *.env.template ]]; then
            echo -e "${RED}🚨 WARNING: Attempting to commit .env file: $file${NC}"
            echo -e "${RED}   This file likely contains sensitive data and should not be committed${NC}"
            SENSITIVE_FOUND=$((SENSITIVE_FOUND + 1))
        fi
    fi
done

echo "📊 Checked $TOTAL_CHECKED files"

if [ $SENSITIVE_FOUND -gt 0 ]; then
    echo -e "${RED}❌ COMMIT BLOCKED: $SENSITIVE_FOUND potential security issues detected!${NC}"
    echo ""
    echo -e "${YELLOW}🔧 To fix:${NC}"
    echo "1. Remove sensitive data from the files"
    echo "2. Use environment variables instead"
    echo "3. Add sensitive files to .gitignore"
    echo "4. Use .env.example templates for sharing configuration"
    echo ""
    echo -e "${YELLOW}🚫 To bypass this check (NOT RECOMMENDED):${NC}"
    echo "   git commit --no-verify"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ No sensitive data detected. Proceeding with commit.${NC}"
    exit 0
fi