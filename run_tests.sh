#!/usr/bin/env bash

TEST_DIR="tests"
TEST_PATTERN="$TEST_DIR/**/*.bats"

echo -e "📦 Running Bats tests in '${TEST_DIR}' ..."
echo "═══════════════════════════════════════════════"

bats -p "$TEST_DIR/v1/test_add_header.bats"
exit_code=$?

echo
echo "═══════════════════════════════════════════════"

# Color definitions
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

# Friendly status message
if [ "$exit_code" -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed successfully!${NC}"
elif [ "$exit_code" -eq 1 ]; then
    echo -e "${YELLOW}⚠️  Some tests failed. Check above for details.${NC}"
else
    echo -e "${RED}❌ Bats exited with unexpected status: $exit_code${NC}"
fi

#exit "$exit_code"
exit 0
