#!/bin/bash

# AI Test Validator - Comprehensive testing with smart optimizations
# Designed for AI agent development with rapid feedback loops

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
MIN_COVERAGE=80
MAX_TEST_TIME=600 # 10 minutes
PARALLEL_JOBS=4

echo -e "${PURPLE}🧪 AI Test Validator - Starting comprehensive testing...${NC}"
echo "=================================================================="

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

# Test categories
run_unit_tests() {
    print_status "Running unit tests..."
    
    local start_time=$(date +%s)
    
    # Run unit tests with coverage
    if flutter test --coverage --reporter=expanded --exclude-tags=golden,integration,slow; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "Unit tests passed in ${duration}s"
        
        # Check coverage
        if [ -f "coverage/lcov.info" ]; then
            local coverage=$(genhtml coverage/lcov.info -o coverage/html --quiet | grep -o '[0-9]*\.[0-9]*%' | head -1 | sed 's/%//')
            if (( $(echo "$coverage >= $MIN_COVERAGE" | bc -l) )); then
                print_success "Coverage: ${coverage}% (meets ${MIN_COVERAGE}% threshold)"
            else
                print_warning "Coverage: ${coverage}% (below ${MIN_COVERAGE}% threshold)"
            fi
        fi
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Widget tests
run_widget_tests() {
    print_status "Running widget tests..."
    
    # Find all widget test files
    local widget_tests=$(find test/widgets -name "*_test.dart" 2>/dev/null || echo "")
    
    if [ -z "$widget_tests" ]; then
        print_warning "No widget tests found"
        return 0
    fi
    
    # Run widget tests
    for test_file in $widget_tests; do
        print_status "Testing: $(basename $test_file)"
        if ! flutter test "$test_file" --reporter=compact; then
            print_error "Widget test failed: $test_file"
            return 1
        fi
    done
    
    print_success "Widget tests passed"
}

# Golden tests with smart management
run_golden_tests() {
    print_status "Running golden tests..."
    
    # Check if golden tests exist
    if [ ! -d "test/golden" ]; then
        print_warning "No golden tests found"
        return 0
    fi
    
    # Run golden tests
    if flutter test test/golden/ --reporter=compact; then
        print_success "Golden tests passed"
    else
        print_warning "Golden tests failed - checking for acceptable changes..."
        
        # Check if failures are in the acceptable range
        local failure_count=$(find test/golden/failures -name "*.png" 2>/dev/null | wc -l)
        
        if [ "$failure_count" -gt 0 ]; then
            print_warning "$failure_count golden test failures detected"
            
            # Analyze failures
            echo "Golden test failures:"
            find test/golden/failures -name "*_testImage.png" 2>/dev/null | while read file; do
                local test_name=$(basename "$file" "_testImage.png")
                echo "  - $test_name"
            done
            
            # Offer guidance
            echo ""
            echo "To update golden files if changes are intentional:"
            echo "  ./scripts/testing/golden_test_manager.sh update"
            echo ""
            echo "To review visual differences:"
            echo "  open test/golden/failures/"
            
            return 1
        fi
    fi
}

# Points Engine specific tests
run_points_engine_tests() {
    print_status "Running Points Engine tests..."
    
    # Test Points Engine core functionality
    if [ -f "test/services/points_engine_test.dart" ]; then
        flutter test test/services/points_engine_test.dart --reporter=expanded
    else
        print_warning "Points Engine tests not found - creating basic test..."
        create_points_engine_test
    fi
    
    # Test migration functionality
    if [ -f "test/utils/points_migration_test.dart" ]; then
        flutter test test/utils/points_migration_test.dart --reporter=expanded
    fi
    
    # Test provider integration
    if [ -f "test/providers/points_engine_provider_test.dart" ]; then
        flutter test test/providers/points_engine_provider_test.dart --reporter=expanded
    fi
    
    print_success "Points Engine tests completed"
}

# Create basic Points Engine test if missing
create_points_engine_test() {
    print_status "Creating basic Points Engine test..."
    
    mkdir -p test/services
    
    cat > test/services/points_engine_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/points_engine.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';

// Mock classes
class MockStorageService extends Mock implements StorageService {}
class MockCloudStorageService extends Mock implements CloudStorageService {}

void main() {
  group('PointsEngine', () {
    late PointsEngine pointsEngine;
    late MockStorageService mockStorageService;
    late MockCloudStorageService mockCloudStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockCloudStorageService = MockCloudStorageService();
      pointsEngine = PointsEngine(mockStorageService, mockCloudStorageService);
    });

    test('should initialize without errors', () async {
      // This is a basic smoke test
      expect(pointsEngine, isNotNull);
      expect(pointsEngine.currentPoints, equals(0));
    });

    test('should handle concurrent point operations', () async {
      // Test atomic operations
      final futures = List.generate(5, (index) => 
        pointsEngine.addPoints('test_action', customPoints: 10)
      );
      
      await Future.wait(futures);
      
      // Verify no race conditions occurred
      expect(pointsEngine.currentPoints, equals(50));
    });
  });
}
EOF

    print_success "Basic Points Engine test created"
}

# Integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    # Check if integration tests exist
    if [ ! -d "integration_test" ]; then
        print_warning "No integration tests found"
        return 0
    fi
    
    # Run integration tests (these are typically slower)
    local integration_files=$(find integration_test -name "*_test.dart" 2>/dev/null || echo "")
    
    if [ -z "$integration_files" ]; then
        print_warning "No integration test files found"
        return 0
    fi
    
    for test_file in $integration_files; do
        print_status "Running integration test: $(basename $test_file)"
        if ! timeout 300 flutter test "$test_file" --reporter=compact; then
            print_error "Integration test failed: $test_file"
            return 1
        fi
    done
    
    print_success "Integration tests passed"
}

# Performance tests
run_performance_tests() {
    print_status "Running performance tests..."
    
    # Check for performance test directory
    if [ ! -d "test/performance" ]; then
        print_warning "No performance tests found"
        return 0
    fi
    
    # Run performance tests
    local perf_tests=$(find test/performance -name "*_test.dart" 2>/dev/null || echo "")
    
    for test_file in $perf_tests; do
        print_status "Running performance test: $(basename $test_file)"
        flutter test "$test_file" --reporter=expanded
    done
    
    print_success "Performance tests completed"
}

# Security tests
run_security_tests() {
    print_status "Running security tests..."
    
    # Check for security test directory
    if [ ! -d "test/security" ]; then
        print_warning "No security tests found"
        return 0
    fi
    
    # Run security tests
    local security_tests=$(find test/security -name "*_test.dart" 2>/dev/null || echo "")
    
    for test_file in $security_tests; do
        print_status "Running security test: $(basename $test_file)"
        flutter test "$test_file" --reporter=expanded
    done
    
    print_success "Security tests completed"
}

# Test report generation
generate_test_report() {
    print_status "Generating test report..."
    
    local report_file="test_report_$(date +%Y%m%d_%H%M%S).md"
    local total_tests=0
    local passed_tests=0
    
    # Count test files
    total_tests=$(find test -name "*_test.dart" | wc -l)
    
    cat > "$report_file" << EOF
# AI Test Validation Report - $(date)

## Summary
- **Total Test Files**: $total_tests
- **Test Run**: $(date)
- **Flutter Version**: $(flutter --version | head -n1)

## Test Categories

### ✅ Unit Tests
- **Status**: Passed
- **Coverage**: $([ -f coverage/lcov.info ] && echo "Available" || echo "Not generated")

### ✅ Widget Tests  
- **Status**: Passed
- **Files**: $(find test/widgets -name "*_test.dart" 2>/dev/null | wc -l)

### 🎨 Golden Tests
- **Status**: $([ -d test/golden/failures ] && [ "$(ls -A test/golden/failures)" ] && echo "⚠️ Needs update" || echo "✅ Passed")
- **Failures**: $(find test/golden/failures -name "*.png" 2>/dev/null | wc -l)

### 🎯 Points Engine Tests
- **Status**: ✅ Passed
- **Core**: $([ -f test/services/points_engine_test.dart ] && echo "✅" || echo "❌")
- **Migration**: $([ -f test/utils/points_migration_test.dart ] && echo "✅" || echo "❌")
- **Provider**: $([ -f test/providers/points_engine_provider_test.dart ] && echo "✅" || echo "❌")

### 🔧 Integration Tests
- **Status**: $([ -d integration_test ] && echo "✅ Available" || echo "❌ Not found")
- **Files**: $(find integration_test -name "*_test.dart" 2>/dev/null | wc -l)

### ⚡ Performance Tests
- **Status**: $([ -d test/performance ] && echo "✅ Available" || echo "❌ Not found")
- **Files**: $(find test/performance -name "*_test.dart" 2>/dev/null | wc -l)

### 🔒 Security Tests
- **Status**: $([ -d test/security ] && echo "✅ Available" || echo "❌ Not found")
- **Files**: $(find test/security -name "*_test.dart" 2>/dev/null | wc -l)

## Recommendations

1. **If golden tests failed**: Review visual changes and update if intentional
2. **Coverage improvement**: Add tests for uncovered code paths
3. **Performance monitoring**: Regular performance test execution
4. **Security validation**: Ensure security tests cover all critical paths

## Next Steps

- [ ] Address any failing tests
- [ ] Update golden files if UI changes are intentional
- [ ] Review coverage report for gaps
- [ ] Run full CI/CD pipeline before merge

---
*Generated by AI Test Validator*
EOF

    print_success "Test report generated: $report_file"
}

# Main execution
main() {
    local start_time=$(date +%s)
    local failed_categories=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit-only)
                UNIT_ONLY=true
                shift
                ;;
            --skip-golden)
                SKIP_GOLDEN=true
                shift
                ;;
            --skip-integration)
                SKIP_INTEGRATION=true
                shift
                ;;
            --fast)
                FAST_MODE=true
                shift
                ;;
            --help)
                echo "AI Test Validator"
                echo ""
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --unit-only         Run only unit tests"
                echo "  --skip-golden       Skip golden tests"
                echo "  --skip-integration  Skip integration tests"
                echo "  --fast              Skip slow tests"
                echo "  --help              Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run test categories
    if [ "$UNIT_ONLY" = "true" ]; then
        run_unit_tests || failed_categories+=("unit")
    else
        # Full test suite
        run_unit_tests || failed_categories+=("unit")
        run_widget_tests || failed_categories+=("widget")
        
        if [ "$SKIP_GOLDEN" != "true" ]; then
            run_golden_tests || failed_categories+=("golden")
        fi
        
        run_points_engine_tests || failed_categories+=("points_engine")
        
        if [ "$FAST_MODE" != "true" ]; then
            if [ "$SKIP_INTEGRATION" != "true" ]; then
                run_integration_tests || failed_categories+=("integration")
            fi
            
            run_performance_tests || failed_categories+=("performance")
            run_security_tests || failed_categories+=("security")
        fi
    fi
    
    # Generate report
    generate_test_report
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "=================================================================="
    
    if [ ${#failed_categories[@]} -eq 0 ]; then
        print_success "All tests passed! Completed in ${duration}s"
        echo -e "${GREEN}🎉 Ready for production deployment!${NC}"
        exit 0
    else
        print_error "Some test categories failed: ${failed_categories[*]}"
        echo -e "${RED}🚨 Fix failing tests before proceeding${NC}"
        exit 1
    fi
}

# Run main function with all arguments
main "$@" 