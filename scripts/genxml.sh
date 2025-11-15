#!/usr/bin/env bash

set -e

# Directory paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUN_TESTS_DIR="$PROJECT_ROOT/tests/fixtures/bun_tests"
TESTS_DIR="$BUN_TESTS_DIR/tests"
JUNIT_DIR="$PROJECT_ROOT/tests/fixtures/junit"

# Ensure junit directory exists
mkdir -p "$JUNIT_DIR"

# Change to the bun_tests directory (where package.json is)
cd "$BUN_TESTS_DIR"

# Find and iterate over all test files
for test_file in tests/*.test.ts tests/*.test.tsx; do
  # Skip if no files match the pattern
  [ -e "$test_file" ] || continue

  # Extract just the filename (e.g., simple.test.ts)
  filename=$(basename "$test_file")

  # Output path with full filename preserved (e.g., simple.test.ts.xml)
  output_file="$JUNIT_DIR/${filename}.xml"

  echo "Running tests in $filename..."

  # Run bun test with junit reporter
  # Allow non-zero exit status (test failures are expected)
  bun test "$test_file" --reporter=junit --reporter-outfile="$output_file" || true

  echo "Generated $output_file"
  echo ""
done

echo "Done! All test results generated in $JUNIT_DIR"
