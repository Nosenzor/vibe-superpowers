#!/bin/bash

# Test script for the superpowers installer
# This tests the installer logic without actually installing

set -euo pipefail

echo "=== Testing Superpowers Installer ==="
echo ""

# Test 1: Check if install.sh is executable
echo "Test 1: Checking if install.sh is executable..."
if [[ -x "/Users/Romain/UltraVibe/superpowers/install.sh" ]]; then
    echo "✓ install.sh is executable"
else
    echo "✗ install.sh is not executable"
    exit 1
fi

# Test 2: Check if install.sh has proper syntax
echo ""
echo "Test 2: Checking bash syntax..."
if bash -n "/Users/Romain/UltraVibe/superpowers/install.sh" 2>/dev/null; then
    echo "✓ install.sh has valid bash syntax"
else
    echo "✗ install.sh has syntax errors"
    exit 1
fi

# Test 3: Check if help works
echo ""
echo "Test 3: Checking --help option..."
help_output=$(/Users/Romain/UltraVibe/superpowers/install.sh --help 2>&1)
if echo "${help_output}" | grep -q "Usage"; then
    echo "✓ --help option works"
else
    echo "✗ --help option failed"
    exit 1
fi

# Test 4: Check if git is available
echo ""
echo "Test 4: Checking git availability..."
if command -v git >/dev/null 2>&1; then
    echo "✓ git is available"
else
    echo "✗ git is not available"
    exit 1
fi

# Test 5: Check if curl or wget is available
echo ""
echo "Test 5: Checking curl or wget availability..."
if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
    echo "✓ curl or wget is available"
else
    echo "✗ Neither curl nor wget is available"
    exit 1
fi

# Test 6: Check file structure
echo ""
echo "Test 6: Checking file structure..."
expected_files=("install.sh" "README.md" ".gitignore")
for file in "${expected_files[@]}"; do
    if [[ -f "/Users/Romain/UltraVibe/superpowers/${file}" ]]; then
        echo "  ✓ ${file} exists"
    else
        echo "  ✗ ${file} is missing"
        exit 1
    fi
done

echo ""
echo "=== All tests passed! ==="
echo ""
echo "The installer appears to be working correctly."
echo "To install superpowers, run:"
echo "  cd /Users/Romain/UltraVibe/superpowers && ./install.sh"
