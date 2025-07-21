#!/usr/bin/env bash
# Laravel Lint Hook for Claude Code
# Runs Laravel-specific linting and formatting commands
# Exit code 2 on any issues to block Claude Code

set +e  # Don't exit on first error, we want to run all checks

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Error tracking
declare -a CLAUDE_HOOKS_SUMMARY=()
declare -i CLAUDE_HOOKS_ERROR_COUNT=0

# Add error function
add_error() {
    local message="$1"
    CLAUDE_HOOKS_ERROR_COUNT+=1
    CLAUDE_HOOKS_SUMMARY+=("${RED}❌${NC} $message")
}

# Print summary function
print_summary() {
    if [[ $CLAUDE_HOOKS_ERROR_COUNT -gt 0 ]]; then
        echo -e "\n${RED}═══ Issues Found ═══${NC}" >&2
        for item in "${CLAUDE_HOOKS_SUMMARY[@]}"; do
            echo -e "$item" >&2
        done
        echo -e "\n${RED}Found $CLAUDE_HOOKS_ERROR_COUNT issue(s) that MUST be fixed!${NC}" >&2
        echo -e "${RED}❌ Fix ALL issues above before continuing!${NC}" >&2
    fi
}

# Main function
main() {
    # Print header
    echo "" >&2
    echo -e "${BLUE}🔍 Laravel Code Quality Check${NC}" >&2
    echo "──────────────────────────────────" >&2
    
    # Check if we're in a Laravel project
    if [[ ! -f "artisan" ]] || [[ ! -f "composer.json" ]]; then
        echo -e "${YELLOW}⚠️  Not a Laravel project - skipping checks${NC}" >&2
        return 0
    fi

    # Run composer refactor (Rector)
    echo -e "\n${BLUE}Running code refactoring...${NC}" >&2
    local refactor_output
    if ! refactor_output=$(composer refactor:rector 2>&1); then
        add_error "Code refactoring failed (composer refactor:rector)"
        echo "$refactor_output" >&2
    fi

    # Run composer format (Pint)
    echo -e "\n${BLUE}Running code formatting...${NC}" >&2
    local format_output
    if ! format_output=$(composer refactor:lint 2>&1); then
        add_error "Code formatting failed (composer refactor:lint)"
        echo "$format_output" >&2
    fi

    # Run composer lint (PHPStan/Larastan)
    echo -e "\n${BLUE}Running static analysis...${NC}" >&2
    local lint_output
    if ! lint_output=$(composer test:types 2>&1); then
        add_error "Static analysis failed (composer test:types)"
        echo "$lint_output" >&2
    fi

    # Return based on error count
    if [[ $CLAUDE_HOOKS_ERROR_COUNT -gt 0 ]]; then
        return 2
    else
        return 0
    fi
}

# Run main function
main
exit_code=$?

# Print summary
print_summary

# Final message and exit
if [[ $exit_code -eq 2 ]]; then
    echo -e "\n${RED}🛑 FAILED - Fix all issues above! 🛑${NC}" >&2
    exit 2
else
    # Exit with 2 so Claude sees the continuation message
    echo -e "\n${YELLOW}👉 Style clean. Continue with your task.${NC}" >&2
    exit 2
fi