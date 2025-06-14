#!/bin/bash
# AI Agent Test Validator - Comprehensive validation for AI changes

set -e

echo "🤖 AI Test Validator"
echo "==================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Unit tests
print_status "Running unit tests..."
if flutter test --coverage --exclude-tags=golden,integration; then
    print_success "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

# 2. Golden tests (with auto-update option)
print_status "Checking visual regression..."
if flutter test test/golden/; then
    print_success "Golden tests passed"
else
    print_warning "Golden tests failed - checking if intentional..."
    
    # Check if running in CI or non-interactive mode
    if [ -t 0 ] && [ -z "$CI" ]; then
        read -p "Update golden files? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f "scripts/testing/golden_test_manager.sh" ]; then
                ./scripts/testing/golden_test_manager.sh update
                print_success "Golden files updated"
            else
                print_warning "Golden test manager not found, running flutter test --update-goldens"
                flutter test test/golden/ --update-goldens
            fi
        else
            print_error "Golden test failures not resolved"
            exit 1
        fi
    else
        print_error "Golden tests failed in non-interactive mode"
        print_status "To fix: ./scripts/testing/golden_test_manager.sh update"
        exit 1
    fi
fi

# 3. Integration tests (critical paths only)
print_status "Running critical integration tests..."

# Check if navigation integration tests exist
if [ -f "test/integration/navigation_integration_test.dart" ]; then
    if flutter test test/integration/navigation_integration_test.dart; then
        print_success "Navigation integration tests passed"
    else
        print_error "Navigation integration tests failed"
        exit 1
    fi
else
    print_warning "Navigation integration tests not found"
fi

# Check if classification flow tests exist
if [ -f "test/integration/classification_flow_test.dart" ]; then
    if flutter test test/integration/classification_flow_test.dart; then
        print_success "Classification flow tests passed"
    else
        print_error "Classification flow tests failed"
        exit 1
    fi
else
    print_warning "Classification flow tests not found"
fi

# 4. Static analysis
print_status "Running static analysis..."
if flutter analyze --fatal-infos; then
    print_success "Static analysis passed"
else
    print_error "Static analysis failed"
    exit 1
fi

# 5. Code formatting check
print_status "Checking code formatting..."
if dart format --set-exit-if-changed .; then
    print_success "Code formatting is correct"
else
    print_warning "Code formatting issues found - auto-fixing..."
    dart format .
    print_success "Code formatting fixed"
fi

print_success "All AI validation tests passed!"
print_status "Ready for commit and deployment" 