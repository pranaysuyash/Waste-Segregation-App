#!/bin/bash

# Setup script for comprehensive testing infrastructure
# This script installs all necessary tools and dependencies

set -e

echo "🚀 Setting up comprehensive testing infrastructure for Waste Segregation App"
echo "============================================================================"

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

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Install Flutter dependencies
print_status "Installing Flutter dependencies..."
flutter pub get

# Install Patrol CLI globally
print_status "Installing Patrol CLI..."
if dart pub global activate patrol_cli; then
    print_success "Patrol CLI installed successfully"
else
    print_warning "Failed to install Patrol CLI"
fi

# Check if Node.js is available for Percy
if command -v npm &> /dev/null; then
    print_status "Installing Percy CLI..."
    if npm install -g @percy/cli; then
        print_success "Percy CLI installed successfully"
    else
        print_warning "Failed to install Percy CLI"
    fi
else
    print_warning "Node.js not found. Percy CLI installation skipped."
    print_status "To install Percy CLI later, run: npm install -g @percy/cli"
fi

# Generate code
print_status "Generating code with build_runner..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Create necessary directories
print_status "Creating test directories..."
mkdir -p test/golden/goldens
mkdir -p test/fixtures
mkdir -p test/mocks
mkdir -p coverage

# Make scripts executable
print_status "Making scripts executable..."
chmod +x scripts/run_all_tests.sh
chmod +x scripts/setup_testing.sh

# Generate initial golden files
print_status "Generating initial golden test files..."
if flutter test test/golden/ --update-goldens; then
    print_success "Golden files generated successfully"
else
    print_warning "Golden file generation failed (this is normal if widgets don't exist yet)"
fi

# Run a quick test to verify setup
print_status "Running quick test verification..."
if flutter test test/ --no-coverage; then
    print_success "Test setup verification passed"
else
    print_warning "Some tests failed (this is normal during initial setup)"
fi

# Check for available devices
print_status "Checking available devices for integration testing..."
flutter devices

echo ""
echo "============================================================================"
print_success "Testing infrastructure setup complete! 🎉"
echo "============================================================================"
echo ""
echo "Next steps:"
echo "1. Run all tests: ./scripts/run_all_tests.sh"
echo "2. Run Widgetbook: flutter run -t widgetbook/main.dart -d chrome"
echo "3. Run E2E tests: patrol test"
echo "4. Setup Percy account and add PERCY_TOKEN to GitHub secrets"
echo ""
echo "Documentation:"
echo "- Testing Strategy: docs/TESTING_STRATEGY.md"
echo "- Implementation Details: COMPREHENSIVE_TESTING_IMPLEMENTATION.md"
echo ""
print_status "Happy testing! 🧪" 