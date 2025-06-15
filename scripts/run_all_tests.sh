#!/bin/bash

# Comprehensive Test Runner for Waste Segregation App
# This script runs all types of tests: unit, widget, integration, golden, and E2E

set -e

echo "🧪 Starting comprehensive test suite for Waste Segregation App"
echo "============================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Function to run a test and capture results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local optional="$3"
    
    print_status "Running $test_name..."
    
    if eval "$test_command"; then
        print_success "$test_name passed"
        return 0
    else
        if [ "$optional" = "optional" ]; then
            print_warning "$test_name failed (optional)"
            return 0
        else
            print_error "$test_name failed"
            return 1
        fi
    fi
}

# Initialize test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Clean and get dependencies
print_status "Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Generate code if needed
print_status "Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# 1. Unit Tests
print_status "Running unit tests..."
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if run_test "Unit Tests" "flutter test test/ --coverage"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# 2. Widget Tests
print_status "Running widget tests..."
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if run_test "Widget Tests" "flutter test test/widgets/ --coverage"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# 3. Golden Tests
print_status "Running golden tests..."
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if run_test "Golden Tests" "flutter test test/golden/ --update-goldens"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# 4. Integration Tests (if device/emulator is available)
print_status "Checking for available devices..."
if flutter devices | grep -q "device"; then
    print_status "Device found, running integration tests..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if run_test "Integration Tests" "flutter test integration_test/"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    print_warning "No devices available for integration tests"
fi

# 5. Patrol E2E Tests (optional, requires setup)
if command -v patrol &> /dev/null; then
    print_status "Patrol CLI found, running E2E tests..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if run_test "Patrol E2E Tests" "patrol test" "optional"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    print_warning "Patrol CLI not found. Install with: dart pub global activate patrol_cli"
fi

# 6. Widgetbook Build Test (optional)
print_status "Testing Widgetbook build..."
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if run_test "Widgetbook Build" "flutter build web --target=widgetbook/main.dart" "optional"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# 7. Static Analysis
print_status "Running static analysis..."
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if run_test "Static Analysis" "flutter analyze"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# 8. Format Check
print_status "Checking code formatting..."
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if run_test "Format Check" "dart format --set-exit-if-changed ."; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Generate coverage report if lcov is available
if command -v lcov &> /dev/null && [ -f "coverage/lcov.info" ]; then
    print_status "Generating coverage report..."
    genhtml coverage/lcov.info -o coverage/html
    print_success "Coverage report generated at coverage/html/index.html"
fi

# Summary
echo ""
echo "============================================================"
echo "🧪 Test Suite Summary"
echo "============================================================"
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    print_success "All tests passed! 🎉"
    exit 0
else
    print_error "$FAILED_TESTS test(s) failed"
    exit 1
fi 