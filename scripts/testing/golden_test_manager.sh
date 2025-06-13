#!/bin/bash

# Golden Test Manager Script
# Helps manage golden tests and visual regression testing

set -e

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

# Function to show help
show_help() {
    echo "Golden Test Manager"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  run           Run all golden tests"
    echo "  update        Update all golden files (use when UI changes are intentional)"
    echo "  clean         Clean up old golden files and failures"
    echo "  diff          Show differences between current and golden images"
    echo "  validate      Validate that all golden tests pass"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 run                    # Run golden tests"
    echo "  $0 update                 # Update golden files after intentional UI changes"
    echo "  $0 validate               # Check if all golden tests pass (CI-friendly)"
}

# Function to run golden tests
run_golden_tests() {
    print_status "Running golden tests..."
    
    if flutter test test/golden/ --reporter=expanded; then
        print_success "All golden tests passed! ✅"
        return 0
    else
        print_error "Golden tests failed! Visual regressions detected. ❌"
        print_warning "If these changes are intentional, run: $0 update"
        return 1
    fi
}

# Function to update golden files
update_golden_files() {
    print_warning "Updating golden files..."
    print_warning "This will replace existing golden images with current UI output."
    
    read -p "Are you sure the UI changes are intentional? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Updating golden files..."
        
        if flutter test test/golden/ --update-goldens; then
            print_success "Golden files updated successfully! ✅"
            print_status "Please review the updated images and commit them."
            
            # Show what files were updated
            echo ""
            print_status "Updated golden files:"
            find test/golden/ -name "*.png" -newer test/golden/ 2>/dev/null || true
        else
            print_error "Failed to update golden files! ❌"
            return 1
        fi
    else
        print_status "Golden file update cancelled."
    fi
}

# Function to clean up old files
clean_golden_files() {
    print_status "Cleaning up golden test artifacts..."
    
    # Remove failure artifacts
    if [ -d "test/golden/failures" ]; then
        rm -rf test/golden/failures
        print_success "Removed failure artifacts"
    fi
    
    # Remove temporary test files
    find test/golden/ -name "*.tmp" -delete 2>/dev/null || true
    find test/golden/ -name "*.log" -delete 2>/dev/null || true
    
    print_success "Golden test cleanup complete! ✅"
}

# Function to show differences
show_golden_diff() {
    print_status "Checking for golden test differences..."
    
    # Run tests to generate failure artifacts
    flutter test test/golden/ --reporter=json > /tmp/golden_results.json 2>/dev/null || true
    
    if [ -d "test/golden/failures" ]; then
        print_warning "Visual differences found:"
        ls -la test/golden/failures/
        
        print_status "To view differences, check the files in test/golden/failures/"
        print_status "Each failure shows the expected vs actual image."
    else
        print_success "No visual differences found! ✅"
    fi
}

# Function to validate golden tests (CI-friendly)
validate_golden_tests() {
    print_status "Validating golden tests (CI mode)..."
    
    if flutter test test/golden/ --reporter=json > /tmp/golden_validation.json; then
        print_success "✅ All golden tests pass - no visual regressions detected"
        exit 0
    else
        print_error "❌ Golden tests failed - visual regressions detected"
        
        # Show summary of failures
        if [ -f "/tmp/golden_validation.json" ]; then
            print_status "Failed test summary:"
            grep -o '"testID":"[^"]*"' /tmp/golden_validation.json | head -5 || true
        fi
        
        exit 1
    fi
}

# Main script logic
case "${1:-help}" in
    "run")
        run_golden_tests
        ;;
    "update")
        update_golden_files
        ;;
    "clean")
        clean_golden_files
        ;;
    "diff")
        show_golden_diff
        ;;
    "validate")
        validate_golden_tests
        ;;
    "help"|*)
        show_help
        ;;
esac 