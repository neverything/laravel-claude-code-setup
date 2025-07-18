#!/usr/bin/env bash
# Laravel Test Hook for Claude Code
# Runs composer test command and checks for missing test files
# Exit code 1 on test failures or missing required tests to block Claude Code

set +e  # Don't exit on first error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print header
echo ""
echo -e "${BLUE}🧪 Laravel Test Suite${NC}"
echo "────────────────────────"

# Check if we're in a Laravel project
if [[ ! -f "artisan" ]] || [[ ! -f "composer.json" ]]; then
    echo -e "${YELLOW}⚠️  Not a Laravel project - skipping tests${NC}"
    exit 0
fi

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
    
    # Potential test file locations
    local test_candidates=(
        "tests/Unit/${base}Test.php"
        "tests/Feature/${base}Test.php"
        "tests/Unit/$(basename "$dir")/${base}Test.php"
        "tests/Feature/$(basename "$dir")/${base}Test.php"
    )
    
    # For Livewire components
    if [[ "$dir" =~ app/Livewire ]] || [[ "$dir" =~ app/Http/Livewire ]]; then
        test_candidates+=(
            "tests/Feature/Livewire/${base}Test.php"
            "tests/Unit/Livewire/${base}Test.php"
        )
    fi
    
    # For Filament resources
    if [[ "$dir" =~ app/Filament ]]; then
        test_candidates+=(
            "tests/Feature/Filament/${base}Test.php"
            "tests/Unit/Filament/${base}Test.php"
        )
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

# Check for missing test file if a specific file was edited
if [[ -n "$FILE_PATH" ]] && [[ "$FILE_PATH" =~ \.php$ ]]; then
    # Check if this file requires tests
    if ! should_skip_test_requirement "$FILE_PATH"; then
        # Try to find the test file
        if ! test_file=$(find_test_file "$FILE_PATH"); then
            echo -e "${RED}❌ Missing required test file for: $FILE_PATH${NC}"
            echo -e "${YELLOW}📝 Create a test file in one of these locations:${NC}"
            
            base=$(basename "$FILE_PATH" .php)
            echo -e "${YELLOW}   - tests/Unit/${base}Test.php${NC}"
            echo -e "${YELLOW}   - tests/Feature/${base}Test.php${NC}"
            
            echo -e "\n${RED}Create and implement the test file before continuing.${NC}"
            exit 1
        fi
    fi
fi

# Check if composer test script exists
if ! composer run-script --list | grep -q "test"; then
    echo -e "${YELLOW}⚠️  No 'test' script found in composer.json${NC}"
    exit 0
fi

# Run composer test
echo -e "\n${BLUE}Running tests...${NC}"
if ! composer test:pest 2>&1; then
    echo -e "\n${RED}❌ Tests failed!${NC}"
    echo -e "${RED}Fix the failing tests before continuing.${NC}"
    exit 1
fi

# Success - exit cleanly
echo -e "\n${GREEN}✅ All tests passed!${NC}"
exit 0