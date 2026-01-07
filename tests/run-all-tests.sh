#!/usr/bin/env zsh
# Master test runner for all integration tests
# Runs test suites for Kiro CLI, direnv, and other integrations

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
echo "${BLUE}  zsh-tool Integration - Full Test Suite${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Track overall results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Run Kiro CLI standard tests
echo "${YELLOW}[1/3] Running Kiro CLI Standard Test Suite...${NC}"
echo ""
((TOTAL_SUITES++))

if zsh "${SCRIPT_DIR}/test-kiro-cli.zsh"; then
  ((PASSED_SUITES++))
  echo ""
  echo "${GREEN}✓ Kiro CLI standard test suite PASSED${NC}"
else
  ((FAILED_SUITES++))
  echo ""
  echo "${RED}✗ Kiro CLI standard test suite FAILED${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run Kiro CLI edge case tests
echo "${YELLOW}[2/3] Running Kiro CLI Edge Case Test Suite...${NC}"
echo ""
((TOTAL_SUITES++))

if zsh "${SCRIPT_DIR}/test-kiro-cli-edge-cases.zsh"; then
  ((PASSED_SUITES++))
  echo ""
  echo "${GREEN}✓ Kiro CLI edge case test suite PASSED${NC}"
else
  ((FAILED_SUITES++))
  echo ""
  echo "${RED}✗ Kiro CLI edge case test suite FAILED${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run direnv + 1Password tests
echo "${YELLOW}[3/3] Running direnv + 1Password Test Suite...${NC}"
echo ""
((TOTAL_SUITES++))

if zsh "${SCRIPT_DIR}/test-direnv.zsh"; then
  ((PASSED_SUITES++))
  echo ""
  echo "${GREEN}✓ direnv + 1Password test suite PASSED${NC}"
else
  ((FAILED_SUITES++))
  echo ""
  echo "${RED}✗ direnv + 1Password test suite FAILED${NC}"
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
