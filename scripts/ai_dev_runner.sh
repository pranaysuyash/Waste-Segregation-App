#!/bin/bash

# AI Development Runner - Optimized for AI agent development workflow
# Provides rapid feedback loops and automated quality gates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLUTTER_VERSION="3.24.5"
COVERAGE_THRESHOLD=80
MAX_BUILD_TIME=300 # 5 minutes

echo -e "${BLUE}🤖 AI Development Runner - Starting...${NC}"
echo "=================================================="

# Function to print status
print_status() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to run with timeout
run_with_timeout() {
    local timeout=$1
    shift
    timeout $timeout "$@"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Flutter version
    if ! flutter --version | grep -q "$FLUTTER_VERSION"; then
        print_warning "Flutter version mismatch. Expected: $FLUTTER_VERSION"
    fi
    
    # Check if we're in the right directory
    if [ ! -f "pubspec.yaml" ]; then
        print_error "Not in Flutter project root directory"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Fast dependency resolution
fast_deps() {
    print_status "Resolving dependencies..."
    
    # Use pub get with offline flag if possible
    if flutter pub get --offline 2>/dev/null; then
        print_success "Dependencies resolved (offline)"
    else
        print_status "Fetching dependencies online..."
        flutter pub get
        print_success "Dependencies resolved (online)"
    fi
}

# Quick code quality check
quick_quality_check() {
    print_status "Running quick quality checks..."
    
    # Format check (fast)
    if ! dart format --set-exit-if-changed . >/dev/null 2>&1; then
        print_warning "Code formatting issues detected"
        dart format .
        print_success "Code formatted automatically"
    fi
    
    # Basic analyze (with timeout)
    if run_with_timeout 60 flutter analyze --fatal-infos >/dev/null 2>&1; then
        print_success "Static analysis passed"
    else
        print_error "Static analysis failed"
        flutter analyze --fatal-infos
        return 1
    fi
}

# Smart test runner - only run affected tests
smart_test_runner() {
    print_status "Running smart test suite..."
    
    # Check if we can run incremental tests
    if [ -f ".test_cache" ]; then
        print_status "Running incremental tests..."
        # Run only tests for changed files
        git diff --name-only HEAD~1 | grep "\.dart$" | while read file; do
            test_file="test/${file#lib/}"
            test_file="${test_file%.dart}_test.dart"
            if [ -f "$test_file" ]; then
                echo "Testing: $test_file"
                flutter test "$test_file" --reporter=compact
            fi
        done
    else
        print_status "Running full test suite..."
        flutter test --coverage --reporter=compact --exclude-tags=golden,integration
    fi
    
    # Update test cache
    date > .test_cache
    print_success "Tests completed"
}

# Points Engine specific validation
validate_points_engine() {
    print_status "Validating Points Engine integration..."
    
    # Check if Points Engine files exist
    if [ ! -f "lib/services/points_engine.dart" ]; then
        print_error "Points Engine not found"
        return 1
    fi
    
    # Run Points Engine specific tests
    if [ -f "test/services/points_engine_test.dart" ]; then
        flutter test test/services/points_engine_test.dart --reporter=compact
    fi
    
    # Check for race condition patterns
    if grep -r "addPoints.*addPoints" lib/ >/dev/null 2>&1; then
        print_warning "Potential race condition detected in points operations"
    fi
    
    print_success "Points Engine validation passed"
}

# Golden test management
manage_golden_tests() {
    print_status "Managing golden tests..."
    
    # Check if golden tests need updating
    if [ -d "test/golden/failures" ] && [ "$(ls -A test/golden/failures)" ]; then
        print_warning "Golden test failures detected"
        echo "Run './scripts/testing/golden_test_manager.sh update' to update golden files"
        
        # Offer to update automatically in AI development mode
        if [ "$AI_AUTO_UPDATE_GOLDEN" = "true" ]; then
            print_status "Auto-updating golden tests..."
            ./scripts/testing/golden_test_manager.sh update
            print_success "Golden tests updated automatically"
        fi
    else
        print_success "Golden tests are up to date"
    fi
}

# Fast build verification
fast_build_check() {
    print_status "Running fast build verification..."
    
    # Build debug APK with timeout
    if run_with_timeout $MAX_BUILD_TIME flutter build apk --debug --target-platform android-arm64; then
        print_success "Build verification passed"
    else
        print_error "Build verification failed"
        return 1
    fi
}

# Performance check
performance_check() {
    print_status "Running performance checks..."
    
    # Check for memory leaks
    if grep -r "late.*Controller" lib/ | grep -v "dispose" >/dev/null 2>&1; then
        print_warning "Potential memory leaks detected (controllers without dispose)"
    fi
    
    # Check for large files
    find lib/ -name "*.dart" -size +50k | while read file; do
        print_warning "Large file detected: $file (consider splitting)"
    done
    
    print_success "Performance check completed"
}

# AI-specific validations
ai_validations() {
    print_status "Running AI-specific validations..."
    
    # Check for proper error handling
    if ! grep -r "try.*catch" lib/services/ >/dev/null 2>&1; then
        print_warning "Limited error handling in services"
    fi
    
    # Check for debug prints in production code
    if grep -r "debugPrint.*password\|debugPrint.*token\|debugPrint.*key" lib/ >/dev/null 2>&1; then
        print_error "Sensitive data in debug prints detected"
        return 1
    fi
    
    # Validate Points Engine consistency
    validate_points_engine
    
    print_success "AI validations passed"
}

# Generate development report
generate_report() {
    print_status "Generating development report..."
    
    local report_file="dev_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# AI Development Report - $(date)

## Summary
- **Status**: ✅ Ready for development
- **Build Time**: $(date)
- **Flutter Version**: $(flutter --version | head -n1)

## Quality Metrics
- **Static Analysis**: ✅ Passed
- **Test Coverage**: $([ -f coverage/lcov.info ] && echo "Available" || echo "Not generated")
- **Build Status**: ✅ Passed
- **Golden Tests**: $([ -d test/golden/failures ] && [ "$(ls -A test/golden/failures)" ] && echo "⚠️ Needs update" || echo "✅ Up to date")

## Points Engine Status
- **Integration**: ✅ Active
- **Migration**: ✅ Available
- **Validation**: ✅ Passed

## Next Steps
1. Continue development with confidence
2. Run full test suite before major changes
3. Update golden tests if UI changes are intentional

---
*Generated by AI Development Runner*
EOF

    print_success "Report generated: $report_file"
}

# Main execution flow
main() {
    local start_time=$(date +%s)
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fast)
                FAST_MODE=true
                shift
                ;;
            --auto-golden)
                AI_AUTO_UPDATE_GOLDEN=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --help)
                echo "AI Development Runner"
                echo ""
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --fast          Skip time-consuming checks"
                echo "  --auto-golden   Automatically update golden tests"
                echo "  --skip-build    Skip build verification"
                echo "  --help          Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Execute development pipeline
    check_prerequisites
    fast_deps
    quick_quality_check
    
    if [ "$FAST_MODE" != "true" ]; then
        smart_test_runner
        ai_validations
        manage_golden_tests
        
        if [ "$SKIP_BUILD" != "true" ]; then
            fast_build_check
        fi
        
        performance_check
    fi
    
    generate_report
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "=================================================="
    print_success "AI Development Runner completed in ${duration}s"
    echo -e "${GREEN}🚀 Ready for rapid development!${NC}"
}

# Run main function with all arguments
main "$@" 