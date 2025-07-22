#!/usr/bin/env bash
# Laravel Test Hook for Claude Code
# Runs composer test command and checks for missing test files
# Exit code 2 on test failures or missing required tests to block Claude Code

set +e  # Don't exit on first error

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

# Check if we have input (hook mode) or running standalone
FILE_PATH=""
if [ -t 0 ]; then
    # No input on stdin - standalone mode
    FILE_PATH=""
else
    # Read JSON input from stdin
    INPUT=$(cat)
    
    # Check if input is valid JSON
    if echo "$INPUT" | jq . >/dev/null 2>&1; then
        # Extract tool name and input
        TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
        TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')
        
        # Only process edit-related tools
        if [[ "$TOOL_NAME" =~ ^(Edit|Write|MultiEdit)$ ]]; then
            # Extract file path
            FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
        fi
    fi
fi

# Function to check if a file should skip test requirement
should_skip_test_requirement() {
    local file="$1"
    local base=$(basename "$file")
    local dir=$(dirname "$file")
    
    # Laravel-specific files that typically don't need tests
    local skip_patterns=(
        # Configuration and setup
        "config/*"
        "*/config/*"
        "database/migrations/*"
        "*/database/migrations/*"
        "database/seeders/*"
        "*/database/seeders/*"
        "database/factories/*"
        "*/database/factories/*"
        "bootstrap/*"
        "*/bootstrap/*"
        "public/*"
        "*/public/*"
        "storage/*"
        "*/storage/*"
        "vendor/*"
        "*/vendor/*"
        
        # Resources
        "resources/views/*"
        "*/resources/views/*"
        "resources/lang/*"
        "*/resources/lang/*"
        "resources/css/*"
        "*/resources/css/*"
        "resources/js/*"
        "*/resources/js/*"
        
        # Routes
        "routes/*"
        "*/routes/*"
        
        # Laravel framework files
        "*ServiceProvider.php"
        "*Middleware.php"
        "app/Http/Middleware/*"
        "*/app/Http/Middleware/*"
        "app/Providers/*"
        "*/app/Providers/*"
        "app/Console/Kernel.php"
        "*/app/Console/Kernel.php"
        "app/Http/Kernel.php"
        "*/app/Http/Kernel.php"
        "app/Exceptions/Handler.php"
        "*/app/Exceptions/Handler.php"
        
        # Non-PHP files
        "*.log"
        "*.txt"
        "*.md"
        "*.sh"
        "*.json"
        "*.lock"
        "*.xml"
        "*.yml"
        "*.yaml"
        
        # Minimal logic files
        "*/Enums/*.php"
        "*/Traits/*.php"
        "*/Interfaces/*.php"
        "*/Contracts/*.php"
        "*/DTOs/*.php"
        "*/ValueObjects/*.php"
        "*/Events/*.php"
        "*/Listeners/*.php"
        "*/Mail/*.php"
        "*/Notifications/*.php"
        "*Request.php"
        "*Resource.php"
        "*Collection.php"
        "*Policy.php"
        "*Observer.php"
        "*Scope.php"
        "*Cast.php"
        "*Rule.php"
    )
    
    # Check each skip pattern
    for pattern in "${skip_patterns[@]}"; do
        # Use bash pattern matching with proper wildcards
        case "$file" in
            $pattern)
                return 0
                ;;
        esac
    done
    
    # Check if it's a test file itself
    if [[ "$file" =~ Test\.php$ ]] || [[ "$dir" =~ /[Tt]ests/ ]]; then
        return 0
    fi
    
    return 1
}

# Function to find test file for a given source file
find_test_file() {
    local file="$1"
    local base=$(basename "$file" .php)
    local dir=$(dirname "$file")
    
    # Extract the relative path from app/ directory
    local relative_path=""
    if [[ "$dir" =~ app/(.+) ]]; then
        relative_path="${BASH_REMATCH[1]}"
    fi
    
    # Start with basic test file locations
    local test_candidates=(
        "tests/Unit/${base}Test.php"
        "tests/Feature/${base}Test.php"
    )
    
    # If we have a relative path from app/, add all possible subdirectory combinations
    if [[ -n "$relative_path" ]]; then
        # Full path preservation
        test_candidates+=(
            "tests/Unit/${relative_path}/${base}Test.php"
            "tests/Feature/${relative_path}/${base}Test.php"
        )
        
        # Just the immediate parent directory
        local parent_dir=$(basename "$dir")
        test_candidates+=(
            "tests/Unit/${parent_dir}/${base}Test.php"
            "tests/Feature/${parent_dir}/${base}Test.php"
        )
        
        # For nested paths, try intermediate levels
        # e.g., app/Filament/Pages/Onboarding/BrandLogos.php could have tests in:
        # - tests/Feature/Filament/Pages/Onboarding/BrandLogosTest.php
        # - tests/Feature/Pages/Onboarding/BrandLogosTest.php
        # - tests/Feature/Onboarding/BrandLogosTest.php
        local path_parts=(${relative_path//\// })
        if [[ ${#path_parts[@]} -gt 1 ]]; then
            for ((i=0; i<${#path_parts[@]}; i++)); do
                local partial_path="${path_parts[@]:$i}"
                partial_path="${partial_path// //}"
                test_candidates+=(
                    "tests/Unit/${partial_path}/${base}Test.php"
                    "tests/Feature/${partial_path}/${base}Test.php"
                )
            done
        fi
    fi
    
    # Check each candidate
    for candidate in "${test_candidates[@]}"; do
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    
    return 1
}

# Main function
main() {
    # Print header
    echo "" >&2
    echo -e "${BLUE}🧪 Laravel Test Suite${NC}" >&2
    echo "────────────────────────" >&2
    
    # Check if we're in a Laravel project
    if [[ ! -f "artisan" ]] || [[ ! -f "composer.json" ]]; then
        echo -e "${YELLOW}⚠️  Not a Laravel project - skipping tests${NC}" >&2
        return 0
    fi
    
    # Check for missing test file if a specific file was edited
    if [[ -n "$FILE_PATH" ]] && [[ "$FILE_PATH" =~ \.php$ ]]; then
        # Check if this file requires tests
        if ! should_skip_test_requirement "$FILE_PATH"; then
            # Try to find the test file
            if ! test_file=$(find_test_file "$FILE_PATH"); then
                echo -e "${RED}❌ Missing required test file for: $FILE_PATH${NC}" >&2
                echo -e "${YELLOW}📝 Create a test file in one of these locations:${NC}" >&2
                
                base=$(basename "$FILE_PATH" .php)
                dir=$(dirname "$FILE_PATH")
                
                # Basic locations
                echo -e "${YELLOW}   - tests/Unit/${base}Test.php${NC}" >&2
                echo -e "${YELLOW}   - tests/Feature/${base}Test.php${NC}" >&2
                
                # If file is in a subdirectory under app/, suggest subdirectory-based locations
                if [[ "$dir" =~ app/(.+) ]]; then
                    relative_path="${BASH_REMATCH[1]}"
                    echo -e "${YELLOW}   - tests/Unit/${relative_path}/${base}Test.php${NC}" >&2
                    echo -e "${YELLOW}   - tests/Feature/${relative_path}/${base}Test.php${NC}" >&2
                    
                    # Also suggest just the parent directory
                    parent_dir=$(basename "$dir")
                    if [[ "$parent_dir" != "$relative_path" ]]; then
                        echo -e "${YELLOW}   - tests/Unit/${parent_dir}/${base}Test.php${NC}" >&2
                        echo -e "${YELLOW}   - tests/Feature/${parent_dir}/${base}Test.php${NC}" >&2
                    fi
                fi
                
                add_error "Missing required test file for: $FILE_PATH"
                return 2
            fi
        fi
    fi
    
    # Check if composer test script exists
    if ! composer run-script --list | grep -q "test:pest"; then
        echo -e "${YELLOW}⚠️  No 'test:pest' script found in composer.json${NC}" >&2
        return 0
    fi
    
    # Run composer test
    echo -e "\n${BLUE}Running tests...${NC}" >&2
    local test_output
    if ! test_output=$(composer test:pest 2>&1); then
        echo -e "\n${RED}❌ Tests failed!${NC}" >&2
        echo "$test_output" >&2
        add_error "Tests failed"
        return 2
    fi
    
    # Success
    echo -e "\n${GREEN}✅ Tests passed!${NC}" >&2
    return 0
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
    echo -e "\n${YELLOW}👉 Tests pass. Continue with your task.${NC}" >&2
    exit 2
fi