#!/usr/bin/env bash
# Laravel Lint Hook for Claude Code
# Runs Laravel-specific linting and formatting commands
# Exit code 1 on any issues to block Claude Code

set +e  # Don't exit on first error, we want to run all checks

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Error tracking
ERRORS=()
HAS_ERRORS=false

# Print header
echo ""
echo -e "${BLUE}🔍 Laravel Code Quality Check${NC}"
echo "──────────────────────────────────"

# Check if we're in a Laravel project
if [[ ! -f "artisan" ]] || [[ ! -f "composer.json" ]]; then
    echo -e "${YELLOW}⚠️  Not a Laravel project - skipping checks${NC}"
    exit 0
fi

# Run composer refactor (Rector + Pint)
echo -e "\n${BLUE}Running code refactoring...${NC}"
if ! composer refactor:rector &&  2>&1; then
    ERRORS+=("${RED}❌ Code refactoring failed${NC}")
    HAS_ERRORS=true
fi

# Run composer lint (PHPStan/Larastan)
echo -e "\n${BLUE}Running linter...${NC}"
if ! composer refactor:lint 2>&1; then
    ERRORS+=("${RED}❌ Linter failed${NC}")
    HAS_ERRORS=true
fi

# Run composer lint (PHPStan/Larastan)
echo -e "\n${BLUE}Running static analysis...${NC}"
if ! composer test:types 2>&1; then
    ERRORS+=("${RED}❌ Static analysis failed${NC}")
    HAS_ERRORS=true
fi

# Print summary if there are errors
if [[ "$HAS_ERRORS" == "true" ]]; then
    echo -e "\n${RED}═══ Issues Found ═══${NC}"
    for error in "${ERRORS[@]}"; do
        echo -e "$error"
    done
    echo -e "\n${RED}❌ Fix all issues above before continuing!${NC}"
    exit 1
fi

# Success - exit cleanly
echo -e "\n${GREEN}✅ All checks passed!${NC}"
exit 0