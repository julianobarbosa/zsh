#!/usr/bin/env zsh
# Master test runner for all Amazon Q integration tests
# Runs both standard and edge case test suites

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}  Amazon Q Integration - Full Test Suite${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Track overall results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Run standard tests
echo "${YELLOW}[1/2] Running Standard Test Suite...${NC}"
echo ""
((TOTAL_SUITES++))

if zsh "${SCRIPT_DIR}/test-amazon-q.zsh"; then
  ((PASSED_SUITES++))
  echo ""
  echo "${GREEN}✓ Standard test suite PASSED${NC}"
else
  ((FAILED_SUITES++))
  echo ""
  echo "${RED}✗ Standard test suite FAILED${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run edge case tests
echo "${YELLOW}[2/2] Running Edge Case Test Suite...${NC}"
echo ""
((TOTAL_SUITES++))

if zsh "${SCRIPT_DIR}/test-amazon-q-edge-cases.zsh"; then
  ((PASSED_SUITES++))
  echo ""
  echo "${GREEN}✓ Edge case test suite PASSED${NC}"
else
  ((FAILED_SUITES++))
  echo ""
  echo "${RED}✗ Edge case test suite FAILED${NC}"
fi

# Final summary
echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}  Overall Test Summary${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Total Test Suites: $TOTAL_SUITES"
echo "${GREEN}Passed: $PASSED_SUITES${NC}"
echo "${RED}Failed: $FAILED_SUITES${NC}"
echo ""

if [[ $FAILED_SUITES -eq 0 ]]; then
  echo "${GREEN}✓✓✓ All test suites passed! ✓✓✓${NC}"
  echo ""
  exit 0
else
  echo "${RED}✗✗✗ Some test suites failed ✗✗✗${NC}"
  echo ""
  exit 1
fi
