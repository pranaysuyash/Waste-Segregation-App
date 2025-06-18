# Markdown Linting Guide

*Last Updated: December 18, 2024*

This guide covers the markdown linting setup for the Waste Segregation App project.

## Overview

The project uses [markdownlint](https://github.com/DavidAnson/markdownlint) to ensure consistent formatting and quality of all markdown documentation.

## Configuration

### .markdownlint.json

The project uses a custom markdownlint configuration that:

- Allows longer line lengths (150 characters) for better readability
- Disables certain rules that conflict with documentation style
- Focuses on the most important formatting issues

```json
{
  "default": true,
  "MD013": {
    "line_length": 150,
    "code_blocks": false,
    "tables": false,
    "headings": false
  },
  "MD024": {
    "siblings_only": true
  },
  "MD026": false,
  "MD033": false,
  "MD036": false,
  "MD040": false,
  "MD041": false
}
```

### Rules Explanation

- **MD013**: Line length limit set to 150 characters (excludes code blocks, tables, headings)
- **MD024**: Allow duplicate headings if they're not siblings
- **MD026**: Allow trailing punctuation in headings
- **MD033**: Allow inline HTML
- **MD036**: Allow emphasis used as headings
- **MD040**: Don't require language specification for code blocks
- **MD041**: Don't require first line to be a top-level heading

## Usage

### Local Development

#### Install Dependencies

```bash
# Install markdownlint globally
npm install -g markdownlint-cli

# Or install project dependencies
npm install
```

#### Available Commands

```bash
# Check for markdown issues
npm run lint:md

# Auto-fix markdown issues
npm run lint:md:fix

# Run comprehensive lint with reporting
npm run lint:md:ci

# Or use the script directly
./scripts/lint_markdown.sh
```

#### Manual Commands

```bash
# Check specific files
markdownlint README.md docs/README.md

# Fix specific files
markdownlint --fix README.md docs/README.md

# Check all markdown files
markdownlint docs/*.md *.md

# Auto-fix all markdown files
markdownlint --fix docs/*.md *.md
```

### GitHub Actions

The project includes automated markdown linting in CI/CD:

- **Trigger**: On push/PR to main/develop branches when `.md` files change
- **Auto-fix**: Automatically fixes issues and commits changes
- **Validation**: Fails CI if unfixable issues remain

#### Workflow Features

- ✅ Automatic installation of markdownlint-cli
- 🔧 Auto-fix common formatting issues
- 📊 Reports before/after issue counts
- 💾 Commits fixes back to the branch
- ❌ Fails CI if manual fixes are needed

## Common Issues and Fixes

### Automatically Fixed Issues

These issues are automatically resolved by `markdownlint --fix`:

- **MD022**: Missing blank lines around headings
- **MD032**: Missing blank lines around lists
- **MD031**: Missing blank lines around fenced code blocks
- **MD009**: Trailing spaces
- **MD047**: Missing final newline

### Manual Fix Required

These issues need manual attention:

- **MD013**: Lines longer than 150 characters (need rewording)
- **MD024**: Duplicate headings in same section (need renaming)
- **MD040**: Missing language specification (add language to code blocks)

### Example Fixes

#### Before (Issues)

```markdown
## Heading
- List item 1
- List item 2
Next paragraph without spacing
```

#### After (Fixed)

```markdown
## Heading

- List item 1
- List item 2

Next paragraph without spacing
```

## Integration with Development Workflow

### Pre-commit Hook (Optional)

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
npm run lint:md:fix
git add -A
```

### VS Code Integration

Install the `markdownlint` extension for real-time linting in VS Code.

### Editor Configuration

Most editors support markdownlint integration:

- **VS Code**: `DavidAnson.vscode-markdownlint`
- **Vim**: `dense-analysis/ale` with markdownlint
- **Sublime**: `SublimeLinter-contrib-markdownlint`

## Best Practices

### Writing Guidelines

1. **Keep lines under 150 characters** when possible
2. **Use blank lines** around headings, lists, and code blocks
3. **Remove trailing spaces** from lines
4. **End files with a single newline**
5. **Use consistent heading styles** within sections

### Documentation Structure

```markdown
# Main Title

Brief description of the document.

## Section Heading

Content with proper spacing.

### Subsection

- List item 1
- List item 2

More content here.

```bash
# Code blocks with language specification
command --flag value
```

## Troubleshooting

### Common Errors

#### "Command not found: markdownlint"

```bash
# Install globally
npm install -g markdownlint-cli

# Or use npx
npx markdownlint docs/*.md
```

#### "No such file or directory"

Ensure you're in the project root directory with `.markdownlint.json`.

#### "Permission denied"

```bash
chmod +x scripts/lint_markdown.sh
```

### Getting Help

- Check the [markdownlint documentation](https://github.com/DavidAnson/markdownlint)
- Run `markdownlint --help` for command options
- Review the [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)

## Maintenance

### Updating Configuration

To modify linting rules:

1. Edit `.markdownlint.json`
2. Test with `npm run lint:md`
3. Update this documentation
4. Commit changes

### Updating Dependencies

```bash
# Update markdownlint-cli
npm update markdownlint-cli

# Or globally
npm update -g markdownlint-cli
```

## Benefits

### Code Quality

- **Consistent formatting** across all documentation
- **Improved readability** for contributors
- **Professional appearance** for project documentation
- **Reduced review time** for documentation changes

### Automation

- **Automatic fixes** for common issues
- **CI/CD integration** prevents broken documentation
- **Developer-friendly** with auto-fix capabilities
- **Zero-configuration** for most common use cases

---

*This guide is automatically maintained and updated as part of the project's documentation standards.* 