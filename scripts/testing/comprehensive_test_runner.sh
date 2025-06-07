#!/bin/bash

# Comprehensive Test Runner for Waste Segregation App
# This script runs all test categories and provides detailed reporting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
COVERAGE_THRESHOLD=80
PERFORMANCE_THRESHOLD=5000  # milliseconds
MEMORY_THRESHOLD=200  # MB

echo -e "${BLUE}🧪 Comprehensive Test Suite - Waste Segregation App${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '%.0s-' {1..50})${NC}"
}

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        return 1
    fi
}

# Function to run tests with timeout and error handling
run_test_category() {
    local category=$1
    local description=$2
    local test_path=$3
    local timeout_duration=${4:-30}
    
    echo -e "${YELLOW}Running $description...${NC}"
    
    if timeout ${timeout_duration}s flutter test "$test_path" --reporter=expanded 2>/dev/null; then
        print_result 0 "$description completed successfully"
        return 0
    else
        print_result 1 "$description failed or timed out"
        return 1
    fi
}

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0
start_time=$(date +%s)

# Clean up previous test artifacts
echo -e "${YELLOW}🧹 Cleaning up previous test artifacts...${NC}"
flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1
echo -e "${GREEN}✅ Cleanup completed${NC}"
echo ""

# =============================================================================
# UNIT TESTS
# =============================================================================

print_section "📋 UNIT TESTS"

# Model Tests
echo -e "${PURPLE}Testing Models...${NC}"
if run_test_category "models" "Model Tests" "test/models/"; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

# Service Tests
echo -e "${PURPLE}Testing Services...${NC}"
test_services=(
    "test/services/ai_service_test.dart:AI Service"
    "test/services/analytics_service_test.dart:Analytics Service"
    "test/services/firebase_family_service_test.dart:Firebase Family Service"
    "test/services/cache_service_test.dart:Cache Service"
    "test/services/community_service_test.dart:Community Service"
    "test/services/gamification_service_test.dart:Gamification Service"
    "test/services/storage_service_test.dart:Storage Service"
)

for service_test in "${test_services[@]}"; do
    IFS=':' read -r test_path test_name <<< "$service_test"
    if [ -f "$test_path" ]; then
        if run_test_category "service" "$test_name" "$test_path"; then
            ((passed_tests++))
        else
            ((failed_tests++))
        fi
    else
        echo -e "${YELLOW}⚠️  $test_name test file not found, skipping...${NC}"
    fi
    ((total_tests++))
done

echo ""

# =============================================================================
# WIDGET TESTS
# =============================================================================

print_section "🎨 WIDGET TESTS"

# Screen Tests
echo -e "${PURPLE}Testing Screens...${NC}"
screen_tests=(
    "test/screens/home_screen_test.dart:Home Screen"
    "test/screens/result_screen_test.dart:Result Screen"
)

for screen_test in "${screen_tests[@]}"; do
    IFS=':' read -r test_path test_name <<< "$screen_test"
    if [ -f "$test_path" ]; then
        if run_test_category "screen" "$test_name" "$test_path" 45; then
            ((passed_tests++))
        else
            ((failed_tests++))
        fi
    else
        echo -e "${YELLOW}⚠️  $test_name test file not found, skipping...${NC}"
    fi
    ((total_tests++))
done

# Widget Component Tests
echo -e "${PURPLE}Testing Widget Components...${NC}"
if [ -d "test/widgets" ]; then
    if run_test_category "widgets" "Widget Components" "test/widgets/"; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
else
    echo -e "${YELLOW}⚠️  Widget tests directory not found, skipping...${NC}"
fi
((total_tests++))

echo ""

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

print_section "🔗 INTEGRATION TESTS"

# Full Workflow Integration
echo -e "${PURPLE}Testing Integration Workflows...${NC}"
if [ -f "test/integration/full_workflow_integration_test.dart" ]; then
    if run_test_category "integration" "Full Workflow Integration" "test/integration/full_workflow_integration_test.dart" 60; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
else
    echo -e "${YELLOW}⚠️  Integration tests not found, skipping...${NC}"
fi
((total_tests++))

# Flow Tests
echo -e "${PURPLE}Testing User Flows...${NC}"
if [ -d "test/flows" ]; then
    if run_test_category "flows" "User Flow Tests" "test/flows/"; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
else
    echo -e "${YELLOW}⚠️  Flow tests directory not found, skipping...${NC}"
fi
((total_tests++))

echo ""

# =============================================================================
# PERFORMANCE TESTS
# =============================================================================

print_section "⚡ PERFORMANCE TESTS"

echo -e "${PURPLE}Testing Performance...${NC}"
if [ -f "test/performance/performance_tests.dart" ]; then
    if run_test_category "performance" "Performance Tests" "test/performance/performance_tests.dart" 120; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
else
    echo -e "${YELLOW}⚠️  Performance tests not found, skipping...${NC}"
fi
((total_tests++))

echo ""

# =============================================================================
# SECURITY TESTS
# =============================================================================

print_section "🔒 SECURITY TESTS"

echo -e "${PURPLE}Testing Security...${NC}"
if [ -f "test/security/security_tests.dart" ]; then
    if run_test_category "security" "Security Tests" "test/security/security_tests.dart" 45; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
else
    echo -e "${YELLOW}⚠️  Security tests not found, skipping...${NC}"
fi
((total_tests++))

echo ""

# =============================================================================
# ACCESSIBILITY TESTS
# =============================================================================

print_section "♿ ACCESSIBILITY TESTS"

echo -e "${PURPLE}Testing Accessibility...${NC}"
if [ -f "test/accessibility/accessibility_tests.dart" ]; then
    if run_test_category "accessibility" "Accessibility Tests" "test/accessibility/accessibility_tests.dart" 60; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
else
    echo -e "${YELLOW}⚠️  Accessibility tests not found, skipping...${NC}"
fi
((total_tests++))

echo ""

# =============================================================================
# CODE COVERAGE ANALYSIS
# =============================================================================

print_section "📊 CODE COVERAGE ANALYSIS"

echo -e "${PURPLE}Generating code coverage report...${NC}"
if flutter test --coverage > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Coverage data generated${NC}"
    
    # Check if lcov is available for HTML report generation
    if command -v lcov >/dev/null 2>&1 && command -v genhtml >/dev/null 2>&1; then
        echo -e "${PURPLE}Generating HTML coverage report...${NC}"
        lcov --summary coverage/lcov.info 2>/dev/null | grep "lines......" | while read line; do
            echo -e "${BLUE}$line${NC}"
        done
        
        # Generate HTML report
        genhtml coverage/lcov.info -o coverage/html --quiet 2>/dev/null
        echo -e "${GREEN}✅ HTML coverage report generated in coverage/html/${NC}"
        
        # Extract coverage percentage
        coverage_percent=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines......" | grep -o '[0-9]*\.[0-9]*%' | head -1 | sed 's/%//')
        
        if [ -n "$coverage_percent" ]; then
            coverage_num=$(echo "$coverage_percent" | cut -d'.' -f1)
            if [ "$coverage_num" -ge $COVERAGE_THRESHOLD ]; then
                echo -e "${GREEN}✅ Coverage ($coverage_percent%) meets threshold ($COVERAGE_THRESHOLD%)${NC}"
            else
                echo -e "${RED}❌ Coverage ($coverage_percent%) below threshold ($COVERAGE_THRESHOLD%)${NC}"
                ((failed_tests++))
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  lcov not found, HTML report not generated${NC}"
        echo -e "${BLUE}Install lcov with: brew install lcov (macOS) or apt-get install lcov (Ubuntu)${NC}"
    fi
else
    echo -e "${RED}❌ Failed to generate coverage data${NC}"
    ((failed_tests++))
fi

echo ""

# =============================================================================
# GOLDEN TESTS (if available)
# =============================================================================

print_section "🖼️  GOLDEN TESTS"

echo -e "${PURPLE}Testing UI Golden Files...${NC}"
if [ -d "test/golden" ]; then
    if run_test_category "golden" "Golden Tests" "test/golden/"; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
else
    echo -e "${YELLOW}⚠️  Golden tests directory not found, skipping...${NC}"
fi

echo ""

# =============================================================================
# REGRESSION TESTS
# =============================================================================

print_section "🔄 REGRESSION TESTS"

echo -e "${PURPLE}Running Regression Tests...${NC}"
regression_files=(
    "test/regression_tests.dart:General Regression"
    "test/history_duplication_fix_test.dart:History Duplication Fix"
    "test/ui_overflow_fixes_test.dart:UI Overflow Fixes"
    "test/achievement_unlock_logic_test.dart:Achievement Logic"
)

for regression_test in "${regression_files[@]}"; do
    IFS=':' read -r test_path test_name <<< "$regression_test"
    if [ -f "$test_path" ]; then
        if run_test_category "regression" "$test_name" "$test_path"; then
            ((passed_tests++))
        else
            ((failed_tests++))
        fi
    else
        echo -e "${YELLOW}⚠️  $test_name test file not found, skipping...${NC}"
    fi
    ((total_tests++))
done

echo ""

# =============================================================================
# TEST SUMMARY AND ANALYSIS
# =============================================================================

end_time=$(date +%s)
execution_time=$((end_time - start_time))

print_section "📈 TEST EXECUTION SUMMARY"

echo -e "${BLUE}Execution Time: ${execution_time}s${NC}"
echo -e "${BLUE}Total Test Categories: $total_tests${NC}"
echo -e "${GREEN}Passed: $passed_tests${NC}"
echo -e "${RED}Failed: $failed_tests${NC}"

# Calculate success rate
if [ $total_tests -gt 0 ]; then
    success_rate=$((passed_tests * 100 / total_tests))
    echo -e "${BLUE}Success Rate: $success_rate%${NC}"
else
    success_rate=0
fi

echo ""

# =============================================================================
# RECOMMENDATIONS AND NEXT STEPS
# =============================================================================

print_section "💡 RECOMMENDATIONS"

if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! The application is in excellent shape.${NC}"
    echo ""
    echo -e "${BLUE}Recommendations:${NC}"
    echo -e "  • Consider adding more edge case tests"
    echo -e "  • Review and update test data periodically"
    echo -e "  • Add performance benchmarks for critical paths"
    echo -e "  • Consider adding more integration test scenarios"
else
    echo -e "${RED}⚠️  Some tests failed. Please review and fix the following:${NC}"
    echo ""
    echo -e "${BLUE}Immediate Actions:${NC}"
    echo -e "  • Check failed test output above for specific issues"
    echo -e "  • Fix any failing unit tests first (fastest feedback loop)"
    echo -e "  • Review integration test failures for workflow issues"
    echo -e "  • Address any security or accessibility issues immediately"
    echo ""
    echo -e "${BLUE}Long-term Improvements:${NC}"
    echo -e "  • Increase test coverage to meet $COVERAGE_THRESHOLD% threshold"
    echo -e "  • Add missing test files for comprehensive coverage"
    echo -e "  • Consider adding property-based testing for complex logic"
    echo -e "  • Set up continuous integration to run tests automatically"
fi

echo ""

# =============================================================================
# COVERAGE AND QUALITY METRICS
# =============================================================================

print_section "📊 QUALITY METRICS"

echo -e "${BLUE}Test Coverage Analysis:${NC}"
if [ -f "coverage/lcov.info" ]; then
    echo -e "  • Coverage report available in coverage/html/index.html"
    echo -e "  • Raw coverage data in coverage/lcov.info"
else
    echo -e "  • ${YELLOW}No coverage data generated${NC}"
fi

echo ""
echo -e "${BLUE}Test Categories Coverage:${NC}"
echo -e "  • Unit Tests: $(ls test/models/ test/services/ 2>/dev/null | wc -l | tr -d ' ') files"
echo -e "  • Widget Tests: $(find test/widgets/ test/screens/ -name "*.dart" 2>/dev/null | wc -l | tr -d ' ') files"
echo -e "  • Integration Tests: $(find test/integration/ test/flows/ -name "*.dart" 2>/dev/null | wc -l | tr -d ' ') files"
echo -e "  • Performance Tests: $(find test/performance/ -name "*.dart" 2>/dev/null | wc -l | tr -d ' ') files"
echo -e "  • Security Tests: $(find test/security/ -name "*.dart" 2>/dev/null | wc -l | tr -d ' ') files"
echo -e "  • Accessibility Tests: $(find test/accessibility/ -name "*.dart" 2>/dev/null | wc -l | tr -d ' ') files"

echo ""

# =============================================================================
# FINAL STATUS
# =============================================================================

print_section "🎯 FINAL STATUS"

if [ $failed_tests -eq 0 ] && [ $success_rate -ge 90 ]; then
    echo -e "${GREEN}🏆 EXCELLENT: All systems green! Ready for production.${NC}"
    exit_code=0
elif [ $failed_tests -le 2 ] && [ $success_rate -ge 80 ]; then
    echo -e "${YELLOW}🟡 GOOD: Minor issues detected. Address before release.${NC}"
    exit_code=1
elif [ $success_rate -ge 60 ]; then
    echo -e "${YELLOW}🟠 MODERATE: Several issues need attention.${NC}"
    exit_code=2
else
    echo -e "${RED}🔴 CRITICAL: Significant issues detected. Do not release.${NC}"
    exit_code=3
fi

echo ""
echo -e "${BLUE}Test execution completed in ${execution_time}s${NC}"
echo -e "${BLUE}Check individual test outputs above for detailed information.${NC}"

# =============================================================================
# CLEANUP AND EXIT
# =============================================================================

# Restore normal output
set +e

exit $exit_code
