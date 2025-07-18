#!/bin/bash

# Test script for the enhanced Laravel Claude Code setup

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing Enhanced Laravel Claude Code Setup Script"
echo "================================================"
echo ""

# Create a temporary test directory
TEST_DIR="/tmp/laravel-claude-test-$(date +%s)"
echo "Creating test Laravel project in: $TEST_DIR"

# Create a minimal Laravel project structure
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Create minimal Laravel files
cat > artisan << 'EOF'
#!/usr/bin/env php
<?php
// Minimal artisan file for testing
EOF
chmod +x artisan

cat > composer.json << 'EOF'
{
    "name": "laravel/laravel",
    "type": "project",
    "description": "Test Laravel Application"
}
EOF

cat > .env << 'EOF'
APP_NAME=TestLaravel
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=test_db
DB_USERNAME=test_user
DB_PASSWORD=test_pass
EOF

# Create a git repo (required by the setup script)
git init
git add .
git commit -m "Initial test commit" || true

# Run the setup script
echo ""
echo "Running setup script..."
echo ""

# Use the actual path to the setup script
SCRIPT_PATH="/Users/neverything/Development/Projects/laravel-claude-code-setup/scripts/setup-claude-code-laravel.sh"

if [ -f "$SCRIPT_PATH" ]; then
    # Set a test GitHub token to avoid interactive prompts
    export GITHUB_TOKEN="test-token-12345"
    
    # Run the script
    if bash "$SCRIPT_PATH"; then
        echo -e "${GREEN}✓ Setup script completed successfully${NC}"
    else
        echo -e "${RED}✗ Setup script failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Setup script not found at: $SCRIPT_PATH${NC}"
    exit 1
fi

# Verify created files
echo ""
echo "Verifying created files..."
echo ""

FILES_TO_CHECK=(
    "CLAUDE.md"
    ".claude/commands/check.md"
    ".claude/commands/next.md"
    ".claude/commands/prompt.md"
    ".claude/shortcuts.sh"
    ".claude/hooks/lint.sh"
    ".claude/hooks/test.sh"
    ".claude/settings.local.json"
)

FAILED=0
for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $file exists${NC}"
    else
        echo -e "${RED}✗ $file missing${NC}"
        FAILED=1
    fi
done

# Check CLAUDE.md content
echo ""
echo "Checking CLAUDE.md content..."
if grep -q "Laravel Development Partnership with Claude" CLAUDE.md; then
    echo -e "${GREEN}✓ CLAUDE.md has correct header${NC}"
else
    echo -e "${RED}✗ CLAUDE.md missing correct header${NC}"
    FAILED=1
fi

if grep -q "@.claude/personal-laravel-preferences.md" CLAUDE.md; then
    echo -e "${GREEN}✓ CLAUDE.md has import directive${NC}"
else
    echo -e "${RED}✗ CLAUDE.md missing import directive${NC}"
    FAILED=1
fi

# Check command files
echo ""
echo "Checking command files..."
for cmd in check next prompt; do
    if [ -f ".claude/commands/$cmd.md" ] && [ -s ".claude/commands/$cmd.md" ]; then
        echo -e "${GREEN}✓ /commands/$cmd.md exists and has content${NC}"
    else
        echo -e "${RED}✗ /commands/$cmd.md missing or empty${NC}"
        FAILED=1
    fi
done

# Cleanup
echo ""
echo "Cleaning up test directory..."
cd /
rm -rf "$TEST_DIR"

# Final result
echo ""
echo "================================================"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo "The enhanced setup script is working correctly."
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo "Please check the output above for details."
    exit 1
fi