#!/bin/bash

# Fix Markdown Lint Issues Script
# This script automatically fixes common markdownlint issues

set -e

echo "🔧 Fixing Markdown Lint Issues..."

# Find all markdown files
find . -name "*.md" -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./macos/Pods/*" | while read -r file; do
    echo "Processing: $file"
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Fix common issues
    python3 -c "
import sys
import re

def fix_markdown_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    fixed_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Remove trailing spaces (MD009)
        line = line.rstrip()
        
        # Fix blank lines around headings (MD022)
        if line.startswith('#'):
            # Add blank line before heading if previous line is not empty
            if fixed_lines and fixed_lines[-1].strip():
                fixed_lines.append('')
            fixed_lines.append(line)
            # Add blank line after heading if next line exists and is not empty
            if i + 1 < len(lines) and lines[i + 1].strip():
                fixed_lines.append('')
        
        # Fix blank lines around lists (MD032)
        elif line.strip().startswith(('- ', '* ', '+ ')) or re.match(r'^\d+\. ', line.strip()):
            # Add blank line before list if previous line is not empty
            if fixed_lines and fixed_lines[-1].strip() and not fixed_lines[-1].strip().startswith(('- ', '* ', '+ ')) and not re.match(r'^\d+\. ', fixed_lines[-1].strip()):
                fixed_lines.append('')
            fixed_lines.append(line)
            
            # Look ahead for end of list
            j = i + 1
            while j < len(lines) and (lines[j].strip().startswith(('- ', '* ', '+ ')) or re.match(r'^\d+\. ', lines[j].strip()) or lines[j].strip() == ''):
                j += 1
            
            # Add blank line after list if next non-empty line is not a list item
            if j < len(lines) and lines[j].strip() and not lines[j].strip().startswith(('- ', '* ', '+ ')) and not re.match(r'^\d+\. ', lines[j].strip()):
                # Skip to end of current list
                while i + 1 < len(lines) and (lines[i + 1].strip().startswith(('- ', '* ', '+ ')) or re.match(r'^\d+\. ', lines[i + 1].strip()) or lines[i + 1].strip() == ''):
                    i += 1
                    fixed_lines.append(lines[i].rstrip())
                if i + 1 < len(lines) and lines[i + 1].strip():
                    fixed_lines.append('')
        
        # Fix blank lines around fenced code blocks (MD031)
        elif line.strip().startswith('```'):
            # Add blank line before code block
            if fixed_lines and fixed_lines[-1].strip():
                fixed_lines.append('')
            fixed_lines.append(line)
            
            # Find closing fence
            i += 1
            while i < len(lines) and not lines[i].strip().startswith('```'):
                fixed_lines.append(lines[i].rstrip())
                i += 1
            
            if i < len(lines):
                fixed_lines.append(lines[i].rstrip())  # closing fence
                # Add blank line after code block
                if i + 1 < len(lines) and lines[i + 1].strip():
                    fixed_lines.append('')
        
        else:
            fixed_lines.append(line)
        
        i += 1
    
    # Ensure single trailing newline (MD047)
    content = '\n'.join(fixed_lines)
    if content and not content.endswith('\n'):
        content += '\n'
    elif content.endswith('\n\n'):
        content = content.rstrip('\n') + '\n'
    
    return content

# Read the file and fix it
fixed_content = fix_markdown_file('$file')

# Write to temp file
with open('$temp_file', 'w', encoding='utf-8') as f:
    f.write(fixed_content)
"
    
    # Replace original file with fixed version
    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$file"
    else
        rm -f "$temp_file"
    fi
done

echo "✅ Markdown lint fixes completed!"
echo ""
echo "🧪 Running markdownlint to check remaining issues..."
markdownlint docs/*.md || echo "⚠️  Some issues may require manual fixing" 