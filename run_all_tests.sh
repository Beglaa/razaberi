#!/bin/bash

# run_tests.sh - Scan for tests and run them all

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================"
echo "Starting Test Runner"
echo -e "========================================${NC}"

# Step 1: Scan for tests and generate run_all_tests.nim
echo -e "${YELLOW}Step 1: Scanning for test files...${NC}"
echo "Running: nim c -r ./test/run_scan_for_tests.nim"

nim c -r --verbosity:0 --hints:off --warnings:off ./test/run_scan_for_tests.nim

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error: Failed to scan for tests${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Running all tests...${NC}"
echo "Running: nim c -r ./test/run_all_tests.nim"
echo "----------------------------------------"

# Step 2: Run all tests
nim c -r --verbosity:0 --hints:off --warnings:off ./test/run_all_tests.nim 2>&1 | tee /tmp/test_output.log | grep -v "\[OK\]" | sed $'s/\\[FAILED\\]/\033[0;31m[FAILED]\033[0m/g'

echo  "Step 3: Run isolate"
nim c -r --verbosity:0 --hints:off --warnings:off ./test/isolate/isolate.nim