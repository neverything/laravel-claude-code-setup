#!/bin/bash

# Laravel Claude Code Setup Script
# Automatically configures Claude Code with MCP servers for Laravel development
# Author: Laravel Developer
# Version: 2.2
# 
# Changes in v2.2:
# - Refactored to use template files for all content (no embedded content)
# - All .md files now maintained as separate templates for easier editing
# - Fixed CLAUDE.local.md references (now uses CLAUDE.md)
#
# Changes in v2.1:
# - Added CLAUDE.md generation with production quality standards
# - Added custom command files (/check, /next, /prompt) 
# - Enhanced workflow with Research → Plan → Implement methodology
# - Integrated with hooks for automated quality enforcement
# - Uses modern import syntax for personal preferences

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a Laravel project
check_laravel_project() {
    if [ ! -f "artisan" ] || [ ! -f "composer.json" ]; then
        print_error "This doesn't appear to be a Laravel project directory!"
        print_error "Please run this script from your Laravel project root."
        exit 1
    fi
    
    if [ ! -f ".env" ]; then
        print_error ".env file not found! Please ensure your Laravel project is properly set up."
        exit 1
    fi
    
    print_success "Laravel project detected!"
}



# Better interactive detection that handles curl pipe correctly
can_interact_with_user() {
    # Check if we have a controlling terminal (even if stdin is piped)
    if [ -t 1 ] && [ -t 2 ]; then
        # stdout and stderr are terminals
        # Check if we're NOT in a true non-interactive environment
        if [ -z "$CI" ] && [ -z "$GITHUB_ACTIONS" ] && [ -z "$JENKINS_URL" ]; then
            # Try to access the controlling terminal directly
            if [ -e /dev/tty ]; then
                return 0  # We can interact with the user
            fi
        fi
    fi
    
    return 1  # Cannot interact with user
}

# Helper function to read input from controlling terminal
read_from_user() {
    local prompt="$1"
    local variable_name="$2"
    
    if can_interact_with_user; then
        # Read from controlling terminal instead of stdin
        printf "%s" "$prompt" > /dev/tty
        read -r "$variable_name" < /dev/tty
        return 0
    else
        return 1
    fi
}

# Check GitHub authentication and collect tokens if needed
collect_tokens() {
    print_status "Checking GitHub authentication..."
    echo ""
    
    # Check if GITHUB_TOKEN is already set in environment
    if [ -n "$GITHUB_TOKEN" ]; then
        print_success "Using GITHUB_TOKEN from environment: ${GITHUB_TOKEN:0:8}..."
        GITHUB_AUTH_METHOD="token"
        
        # Ask if user wants to update token
        if can_interact_with_user; then
            echo ""
            local update_token
            if read_from_user "Do you want to update this GitHub token? (y/n): " update_token; then
                if [ "$update_token" = "y" ] || [ "$update_token" = "yes" ]; then
                    GITHUB_TOKEN=""  # Clear the token to prompt for a new one
                    print_status "Please provide the new GitHub token..."
                    
                    # Actually prompt for the new token
                    local new_github_token
                    if read_from_user "Enter your new GitHub Personal Access Token: " new_github_token; then
                        if [ ! -z "$new_github_token" ]; then
                            GITHUB_TOKEN="$new_github_token"
                            print_success "GitHub token updated successfully!"
                        else
                            print_warning "No token provided - keeping original token"
                            # We need to restore the original token here
                            # But since we cleared it, we'll need to get it from config again
                        fi
                    else
                        print_status "Could not read new token - keeping original"
                    fi
                else
                    print_status "Keeping existing GitHub token"
                fi
            else
                print_status "Could not read input - keeping existing token"
            fi
        else
            print_status "Non-interactive environment - keeping existing GitHub token"
        fi
    fi
    
    # Check if token is configured in Claude config file
    CONFIG_FILE="$HOME/.claude.json"
    if [ -z "$GITHUB_TOKEN" ] && [ -f "$CONFIG_FILE" ]; then
        # Check for existing token in global config
        EXISTING_TOKEN=""
        if command -v jq &> /dev/null; then
            EXISTING_TOKEN=$(jq -r '.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
        fi
        
        if [ ! -z "$EXISTING_TOKEN" ] && [ "$EXISTING_TOKEN" != "null" ] && [ "$EXISTING_TOKEN" != "empty" ]; then
            print_success "Found existing GitHub token in Claude config: ${EXISTING_TOKEN:0:8}..."
            GITHUB_TOKEN="$EXISTING_TOKEN"
            GITHUB_AUTH_METHOD="token"
            
            # Ask if user wants to update token
            if can_interact_with_user; then
                echo ""
                local update_existing
                if read_from_user "Do you want to update this GitHub token? (y/n): " update_existing; then
                    if [ "$update_existing" = "y" ] || [ "$update_existing" = "yes" ]; then
                        print_status "Please provide the new GitHub token..."
                        
                        # Actually prompt for the new token
                        local new_github_token
                        if read_from_user "Enter your new GitHub Personal Access Token: " new_github_token; then
                            if [ ! -z "$new_github_token" ]; then
                                GITHUB_TOKEN="$new_github_token"
                                print_success "GitHub token updated successfully!"
                            else
                                print_warning "No token provided - keeping existing token"
                                # GITHUB_TOKEN already has the existing token
                            fi
                        else
                            print_status "Could not read new token - keeping existing"
                        fi
                    else
                        print_status "Keeping existing GitHub token"
                    fi
                else
                    print_status "Could not read input - keeping existing token"
                fi
            else
                print_status "Non-interactive environment - keeping existing GitHub token"
            fi
        fi
    fi
    
    # Continue with GitHub SSH detection logic if no token found...
    if [ -z "$GITHUB_TOKEN" ]; then
        # Test SSH authentication with GitHub
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            print_success "GitHub SSH authentication detected!"
            print_status "However, for MCP integration, a Personal Access Token is recommended for private repositories."
            
            # Ask for choice in interactive mode
            if can_interact_with_user; then
                echo ""
                echo "Choose GitHub authentication method:"
                echo "1) Use SSH (works for public repos, limited for private repos in MCP)"
                echo "2) Provide Personal Access Token (recommended for full private repo access)"
                local auth_choice
                if read_from_user "Enter choice (1 or 2): " auth_choice; then
                    if [ "$auth_choice" = "2" ]; then
                        GITHUB_AUTH_METHOD="token"
                        local attempts=0
                        while [ -z "$GITHUB_TOKEN" ] && [ $attempts -lt 3 ]; do
                            echo ""
                            print_status "To create a GitHub Personal Access Token:"
                            echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)"
                            echo "2. Click 'Generate new token (classic)'"
                            echo "3. Select scopes: repo, read:user, user:email"
                            echo "4. Copy the generated token"
                            echo ""
                            local github_token
                            if read_from_user "Enter your GitHub Personal Access Token (or 'skip'): " github_token; then
                                if [ "$github_token" = "skip" ]; then
                                    GITHUB_TOKEN=""
                                    GITHUB_AUTH_METHOD="none"
                                    print_warning "Skipping GitHub MCP integration"
                                    break
                                elif [ ! -z "$github_token" ]; then
                                    GITHUB_TOKEN="$github_token"
                                    print_success "GitHub token configured!"
                                    break
                                else
                                    print_warning "Token is required for GitHub MCP integration!"
                                    attempts=$((attempts + 1))
                                fi
                            else
                                print_status "Could not read input - skipping GitHub integration"
                                GITHUB_AUTH_METHOD="none"
                                break
                            fi
                        done
                    else
                        GITHUB_AUTH_METHOD="ssh"
                        print_warning "Using SSH authentication - private repository access may be limited"
                    fi
                else
                    print_status "Could not read input - using SSH authentication"
                    GITHUB_AUTH_METHOD="ssh"
                fi
            else
                GITHUB_AUTH_METHOD="ssh"
                print_warning "Non-interactive mode - using SSH authentication"
            fi
        else
            print_warning "No GitHub SSH authentication detected"
            GITHUB_AUTH_METHOD="token"
            
            # Check if truly interactive
            if ! can_interact_with_user; then
                print_error "This script requires a GitHub token for GitHub MCP integration."
                print_error "Please set the GITHUB_TOKEN environment variable and try again:"
                echo ""
                echo "export GITHUB_TOKEN=your_token_here"
                echo "curl -fsSL https://your-script-url | bash"
                echo ""
                exit 1
            fi
            
            # Interactive token collection
            local attempts=0
            while [ -z "$GITHUB_TOKEN" ] && [ $attempts -lt 3 ]; do
                echo ""
                print_status "To create a GitHub Personal Access Token:"
                echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)"
                echo "2. Click 'Generate new token (classic)'"
                echo "3. Select scopes: repo, read:user, user:email"
                echo "4. Copy the generated token"
                echo ""
                local github_token
                if read_from_user "Enter your GitHub Personal Access Token (or 'skip'): " github_token; then
                    if [ "$github_token" = "skip" ]; then
                        GITHUB_TOKEN=""
                        GITHUB_AUTH_METHOD="none"
                        print_warning "Skipping GitHub MCP integration"
                        break
                    elif [ ! -z "$github_token" ]; then
                        GITHUB_TOKEN="$github_token"
                        print_success "GitHub token configured!"
                        break
                    else
                        print_warning "Token is required for GitHub MCP integration!"
                        attempts=$((attempts + 1))
                    fi
                else
                    print_status "Could not read input - skipping GitHub integration"
                    GITHUB_AUTH_METHOD="none"
                    break
                fi
            done
        fi
    fi
    
    # Get GitHub repository information if we have authentication
    if [ "$GITHUB_AUTH_METHOD" != "none" ]; then
        # Try to detect current repository from git remote
        if command -v git &> /dev/null && [ -d ".git" ]; then
            # Extract owner/repo from git remote URL
            REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
            if [ ! -z "$REMOTE_URL" ]; then
                # Parse GitHub repository from remote URL
                if echo "$REMOTE_URL" | grep -q "github.com"; then
                    # Extract owner/repo from various URL formats
                    DETECTED_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]([^/]+/[^/]+)(\.git)?.*|\1|' | sed 's|\.git$||')
                    if [ ! -z "$DETECTED_REPO" ]; then
                        print_success "Detected GitHub repository: $DETECTED_REPO"
                        GITHUB_REPO="$DETECTED_REPO"
                    fi
                fi
            fi
        fi
        
        # Ask for repository if not detected or if user wants to specify different one
        if can_interact_with_user; then
            if [ ! -z "$GITHUB_REPO" ]; then
                local repo_choice
                if read_from_user "Use detected repository '$GITHUB_REPO'? (y/n, or enter different owner/repo): " repo_choice; then
                    if [ "$repo_choice" = "n" ] || [ "$repo_choice" = "no" ]; then
                        GITHUB_REPO=""
                    elif [ ! -z "$repo_choice" ] && [ "$repo_choice" != "y" ] && [ "$repo_choice" != "yes" ]; then
                        GITHUB_REPO="$repo_choice"
                    fi
                fi
            else
                local github_repo
                if read_from_user "Enter GitHub repository (optional, format: owner/repo): " github_repo; then
                    GITHUB_REPO="$github_repo"
                fi
            fi
        fi
    fi
    
    if [ "$GITHUB_AUTH_METHOD" != "none" ]; then
        print_success "GitHub authentication configured!"
        if [ ! -z "$GITHUB_REPO" ]; then
            print_status "Repository: $GITHUB_REPO"
        fi
        if [ ! -z "$GITHUB_TOKEN" ]; then
            print_status "Token: ${GITHUB_TOKEN:0:8}..."
        fi
    fi
    echo ""
}

# Check if Claude Code is installed
check_claude_code() {
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code is not installed!"
        print_error "Please install Claude Code first: https://claude.ai/code"
        exit 1
    fi
    print_success "Claude Code is installed!"
}

# Check if Node.js and npm are installed
check_node() {
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed! Please install Node.js first."
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed! Please install npm first."
        exit 1
    fi
    
    print_success "Node.js and npm are available!"
}

# Create MCP servers directory
create_mcp_directory() {
    print_status "Creating MCP servers directory..."
    
    MCP_DIR="$HOME/.config/claude-code/mcp-servers"
    mkdir -p "$MCP_DIR"
    
    print_success "MCP directory created at: $MCP_DIR"
}

# Install Context7 MCP Server
install_context7() {
    print_status "Installing Context7 MCP Server..."
    
    cd "$MCP_DIR"
    
    # Clean install if directory exists
    if [ -d "context7" ]; then
        print_status "Removing existing context7 installation..."
        rm -rf context7
    fi
    
    print_status "Cloning Context7 repository..."
    if ! git clone https://github.com/upstash/context7.git context7; then
        print_error "Failed to clone Context7 repository"
        return 1
    fi
    
    cd context7
    
    print_status "Installing Context7 dependencies..."
    if ! npm install; then
        print_error "Failed to install Context7 dependencies"
        return 1
    fi
    
    print_status "Building Context7..."
    if ! npm run build; then
        print_error "Failed to build Context7"
        return 1
    fi
    
    # Verify the build was successful (Context7 builds to dist/index.js, not build/index.js)
    if [ -f "dist/index.js" ]; then
        print_success "Context7 MCP Server installed and built successfully!"
    else
        print_error "Context7 build failed - dist/index.js not found"
        return 1
    fi
}

# Install Filesystem MCP Server
install_filesystem() {
    print_status "Installing Filesystem MCP Server..."
    
    npm install -g @modelcontextprotocol/server-filesystem
    
    print_success "Filesystem MCP Server installed!"
}

# Install Database MCP Server
install_database() {
    print_status "Installing Database MCP Server (Go-based)..."
    
    # Check Go version requirement (1.22+)
    if ! command -v go &> /dev/null; then
        print_warning "Go is not installed. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install go
        else
            print_error "Go is required but not installed. Please install Go first."
            print_status "Install with: brew install go (macOS) or visit https://golang.org/dl/"
            return 1
        fi
    fi
    
    # Check Go version (must be 1.22+)
    GO_VERSION=$(go version | grep -o 'go[0-9]*\.[0-9]*' | grep -o '[0-9]*\.[0-9]*')
    REQUIRED_VERSION="1.22"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
        print_error "Go version $GO_VERSION is installed, but version $REQUIRED_VERSION or higher is required."
        print_status "Please update Go: brew upgrade go (macOS) or download from https://golang.org/dl/"
        return 1
    fi
    
    print_success "Go version $GO_VERSION meets requirements!"
    
    cd "$MCP_DIR"
    
    # Clean install if directory exists
    if [ -d "db-mcp-server" ]; then
        print_status "Removing existing db-mcp-server installation..."
        rm -rf db-mcp-server
    fi
    
    print_status "Cloning db-mcp-server repository..."
    if ! git clone https://github.com/FreePeak/db-mcp-server.git db-mcp-server; then
        print_error "Failed to clone db-mcp-server repository"
        return 1
    fi
    
    cd db-mcp-server
    
    # Build the Go project with better error handling
    print_status "Building Go database MCP server..."
    
    # Try different build methods
    if [ -f "Makefile" ]; then
        print_status "Using Makefile to build..."
        if make build; then
            print_success "Database MCP server built successfully using Makefile!"
        else
            print_warning "Makefile build failed, trying direct Go build..."
            if go build -o bin/server ./cmd/server; then
                print_success "Database MCP server built successfully using Go build!"
            else
                print_error "Go build failed. Database MCP server installation failed."
                return 1
            fi
        fi
    else
        print_status "No Makefile found, using direct Go build..."
        # Ensure bin directory exists
        mkdir -p bin
        if go build -o bin/server ./cmd/server; then
            print_success "Database MCP server built successfully!"
        elif go build -o bin/server .; then
            print_success "Database MCP server built successfully (fallback method)!"
        else
            print_error "Go build failed. Database MCP server installation failed."
            print_status "This is optional - other MCP servers will still work."
            return 1
        fi
    fi
    
    # Verify the binary was created
    if [ -f "bin/server" ] || [ -f "db-mcp-server" ]; then
        print_success "Database MCP Server installed!"
    else
        print_error "Database binary not found after build"
        return 1
    fi
}

# Install Web Fetch MCP Server
install_web_fetch() {
    print_status "Installing Web Fetch MCP Server..."
    
    cd "$MCP_DIR"
    
    if [ ! -d "fetch-mcp" ]; then
        git clone https://github.com/zcaceres/fetch-mcp.git fetch-mcp
    fi
    
    cd fetch-mcp
    
    # Install dependencies and build
    npm install
    npm run build
    
    print_success "Web Fetch MCP Server installed!"
}

# Install GitHub MCP Server
install_github() {
    print_status "Installing GitHub MCP Server..."
    
    npm install -g @modelcontextprotocol/server-github
    
    print_success "GitHub MCP Server installed!"
}

# Install Memory MCP Server
install_memory() {
    print_status "Installing Memory MCP Server..."
    
    npm install -g @modelcontextprotocol/server-memory
    
    print_success "Memory MCP Server installed!"
}

# Parse Laravel .env file
parse_env() {
    print_status "Parsing Laravel .env file..."
    
    # Source the .env file
    if [ -f ".env" ]; then
        export $(grep -v '^#' .env | xargs)
    fi
    
    # Get database connection details
    DB_CONNECTION=${DB_CONNECTION:-mysql}
    DB_HOST=${DB_HOST:-127.0.0.1}
    DB_PORT=${DB_PORT:-3306}
    DB_DATABASE=${DB_DATABASE:-}
    DB_USERNAME=${DB_USERNAME:-}
    DB_PASSWORD=${DB_PASSWORD:-}
    
    print_success "Environment variables parsed!"
}

# Generate database configuration
generate_database_config() {
    print_status "Generating database configuration..."
    
    PROJECT_PATH="$PWD"
    
    # Generate database configuration if database is configured
    if [ ! -z "$DB_DATABASE" ]; then
        # Determine the correct database type
        case "$DB_CONNECTION" in
            "mysql")
                DB_TYPE="mysql"
                ;;
            "pgsql"|"postgres"|"postgresql")
                DB_TYPE="postgres"
                ;;
            "sqlite")
                DB_TYPE="sqlite"
                if [[ "$DB_DATABASE" == /* ]]; then
                    DB_PATH="$DB_DATABASE"
                else
                    DB_PATH="$PROJECT_PATH/database/$DB_DATABASE"
                fi
                ;;
            *)
                DB_TYPE="mysql"
                ;;
        esac
        
        # Create the database configuration file
        if [ "$DB_CONNECTION" = "sqlite" ]; then
            cat > "$MCP_DIR/db-mcp-server/config.json" << 'DBEOF'
{
  "connections": [
    {
      "id": "laravel",
      "type": "sqlite",
      "database": "$DB_PATH",
      "query_timeout": 60,
      "max_open_conns": 10,
      "max_idle_conns": 2,
      "conn_max_lifetime_seconds": 300,
      "conn_max_idle_time_seconds": 60
    }
  ]
}
DBEOF
        else
            cat > "$MCP_DIR/db-mcp-server/config.json" << DBEOF
{
  "connections": [
    {
      "id": "laravel",
      "type": "$DB_TYPE",
      "host": "$DB_HOST",
      "port": $DB_PORT,
      "name": "$DB_DATABASE",
      "user": "$DB_USERNAME",
      "password": "$DB_PASSWORD",
      "query_timeout": 60,
      "max_open_conns": 20,
      "max_idle_conns": 5,
      "conn_max_lifetime_seconds": 300,
      "conn_max_idle_time_seconds": 60
    }
  ]
}
DBEOF
        fi
        print_status "Database configuration created!"
    else
        print_warning "No database configured in .env file. Database MCP server will be skipped."
        print_status "To enable database MCP later, configure your database in .env and re-run the script."
    fi
    
    print_success "Database configuration completed!"
}

# Helper function to update GitHub token in config
update_github_token_in_config() {
    local CONFIG_FILE="$HOME/.claude.json"
    local TOKEN="$1"
    local PROJECT_PATH="$2"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "Claude config file not found at $CONFIG_FILE"
        return 1
    fi
    
    # Create a backup
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    
    # Try jq first (cleanest method)
    if command -v jq &> /dev/null; then
        # Update both global and project-specific GitHub server configs
        if jq --arg token "$TOKEN" --arg project "$PROJECT_PATH" \
           '# Update global config if it exists
            if .mcpServers.github then
              .mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = $token
            else . end |
            # Update project-specific config
            if .projects[$project].mcpServers.github then
              .projects[$project].mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = $token
            else . end' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"; then
            print_success "GitHub token configured using jq!"
            return 0
        fi
    fi
    
    # Try Python (more reliable than sed)
    if command -v python3 &> /dev/null; then
        cat > /tmp/update_github_token.py << PYTHON_EOF
#!/usr/bin/env python3
import json
import sys

try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    # Update global config if it exists
    if 'mcpServers' in config:
        if 'github' not in config['mcpServers']:
            config['mcpServers']['github'] = {}
        if 'env' not in config['mcpServers']['github']:
            config['mcpServers']['github']['env'] = {}
        config['mcpServers']['github']['env']['GITHUB_PERSONAL_ACCESS_TOKEN'] = '$TOKEN'
    
    # Update project-specific config
    if 'projects' in config and '$PROJECT_PATH' in config['projects']:
        project = config['projects']['$PROJECT_PATH']
        if 'mcpServers' in project and 'github' in project['mcpServers']:
            if 'env' not in project['mcpServers']['github']:
                project['mcpServers']['github']['env'] = {}
            project['mcpServers']['github']['env']['GITHUB_PERSONAL_ACCESS_TOKEN'] = '$TOKEN'
    
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    print("SUCCESS")
except Exception as e:
    print(f"ERROR: {e}")
PYTHON_EOF
        
        RESULT=$(python3 /tmp/update_github_token.py 2>&1)
        rm -f /tmp/update_github_token.py
        
        if [ "$RESULT" = "SUCCESS" ]; then
            print_success "GitHub token configured using Python!"
            return 0
        fi
    fi
    
    print_warning "Could not automatically configure GitHub token"
    return 1
}

# Configure Claude Code MCP Servers
configure_claude_mcp() {
    print_status "Configuring Claude Code MCP servers..."
    
    PROJECT_PATH="$PWD"
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    
    # Create a project identifier for unique MCP server names
    PROJECT_ID=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID="laravel$(date +%s)"
    fi
    
    print_status "Project: $PROJECT_NAME (ID: $PROJECT_ID)"
    
    # Check if claude command is available
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code CLI not found. Please ensure Claude Code is properly installed."
        return 1
    fi
    
    print_status "Setting up global MCP servers (if not already configured)..."
    
    # Setup GLOBAL MCP servers (shared across all projects)
    
    # Configure GitHub MCP server
    if ! claude mcp list 2>/dev/null | grep -q "^github:"; then
        print_status "Adding global GitHub MCP server..."
        if [ "$GITHUB_AUTH_METHOD" != "none" ]; then
            if claude mcp add "github" npx @modelcontextprotocol/server-github; then
                print_success "Global GitHub MCP server added"
                
                # Configure token if available
                if [ "$GITHUB_AUTH_METHOD" = "token" ] && [ ! -z "$GITHUB_TOKEN" ]; then
                    print_status "Configuring GitHub token..."
                    # Pass the project path to the update function
                    if update_github_token_in_config "$GITHUB_TOKEN" "$PROJECT_PATH"; then
                        print_success "GitHub token configured successfully!"
                    else
                        print_warning "⚠️  Manual configuration required for GitHub private repo access"
                        echo ""
                        echo "Please edit ~/.claude.json and add your token to BOTH:"
                        echo ""
                        echo "1. Global config (at the bottom of file):"
                        echo '  "mcpServers": {'
                        echo '    "github": {'
                        echo '      "env": {'
                        echo '        "GITHUB_PERSONAL_ACCESS_TOKEN": "'$GITHUB_TOKEN'"'
                        echo '      }'
                        echo '    }'
                        echo '  }'
                        echo ""
                        echo "2. Project-specific config (in projects.'$PROJECT_PATH'.mcpServers):"
                        echo '  "github": {'
                        echo '    "type": "stdio",'
                        echo '    "command": "npx",'
                        echo '    "args": ["@modelcontextprotocol/server-github"],'
                        echo '    "env": {'
                        echo '      "GITHUB_PERSONAL_ACCESS_TOKEN": "'$GITHUB_TOKEN'"'
                        echo '    }'
                        echo '  }'
                        echo ""
                    fi
                fi
            else
                print_error "Failed to add GitHub MCP server"
            fi
        fi
    else
        print_success "Global GitHub MCP server already configured"
        
        # Update token if provided and not already configured
        if [ "$GITHUB_AUTH_METHOD" = "token" ] && [ ! -z "$GITHUB_TOKEN" ]; then
            CONFIG_FILE="$HOME/.claude.json"
            if [ -f "$CONFIG_FILE" ]; then
                # Check if token is configured in the project-specific config
                PROJECT_HAS_TOKEN=$(jq -r --arg project "$PROJECT_PATH" \
                    '.projects[$project].mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN // "not_found"' \
                    "$CONFIG_FILE" 2>/dev/null)
                
                if [ "$PROJECT_HAS_TOKEN" = "not_found" ] || [ -z "$PROJECT_HAS_TOKEN" ]; then
                    print_warning "GitHub server exists but token not configured in project"
                    print_status "Configuring GitHub token..."
                    if update_github_token_in_config "$GITHUB_TOKEN" "$PROJECT_PATH"; then
                        print_success "GitHub token configured successfully!"
                    else
                        print_warning "Please manually add your GitHub token to ~/.claude.json"
                    fi
                else
                    print_status "GitHub token already configured in project"
                fi
            fi
        fi
    fi

    
    # Add global Memory MCP server
    if ! claude mcp list 2>/dev/null | grep -q "^memory:"; then
        print_status "Adding global Memory MCP server..."
        if claude mcp add "memory" npx @modelcontextprotocol/server-memory; then
            print_success "Global Memory MCP server added"
        else
            print_warning "Failed to add global Memory MCP server"
        fi
    else
        print_success "Global Memory MCP server already configured"
    fi
    
    # Add global Context7 MCP server
    if [ -f "$MCP_DIR/context7/dist/index.js" ]; then
        if ! claude mcp list 2>/dev/null | grep -q "^context7:"; then
            print_status "Adding global Context7 MCP server..."
            if claude mcp add "context7" node "$MCP_DIR/context7/dist/index.js"; then
                print_success "Global Context7 MCP server added"
            else
                print_warning "Failed to add global Context7 MCP server"
            fi
        else
            print_success "Global Context7 MCP server already configured"
        fi
    fi
    
    # Add global Web Fetch MCP server
    if [ -f "$MCP_DIR/fetch-mcp/dist/index.js" ]; then
        if ! claude mcp list 2>/dev/null | grep -q "^webfetch:"; then
            print_status "Adding global Web Fetch MCP server..."
            if claude mcp add "webfetch" node "$MCP_DIR/fetch-mcp/dist/index.js"; then
                print_success "Global Web Fetch MCP server added"
            else
                print_warning "Failed to add global Web Fetch MCP server"
            fi
        else
            print_success "Global Web Fetch MCP server already configured"
        fi
    fi
    
    print_status "Setting up project-specific MCP servers..."
    
    # Clean up old project-specific servers
    print_status "Cleaning up existing project-specific MCP servers..."
    claude mcp list 2>/dev/null | grep -E "^(filesystem|database)-$PROJECT_ID" | awk '{print $1}' | xargs -I {} claude mcp remove {} 2>/dev/null || true
    
    # Add PROJECT-SPECIFIC MCP servers (only filesystem and database)
    
    # Add Filesystem MCP server (project-specific)
    print_status "Adding Filesystem MCP server for $PROJECT_NAME..."
    if claude mcp add "filesystem-$PROJECT_ID" npx @modelcontextprotocol/server-filesystem "$PROJECT_PATH"; then
        print_success "Filesystem MCP server added: filesystem-$PROJECT_ID"
    else
        print_warning "Failed to add Filesystem MCP server"
    fi
    
    # Add Database MCP server (project-specific)
    if [ -f "$MCP_DIR/db-mcp-server/config.json" ] && [ ! -z "$DB_DATABASE" ]; then
        # Create project-specific database config
        PROJECT_DB_CONFIG="$MCP_DIR/db-mcp-server/config-$PROJECT_ID.json"
        cp "$MCP_DIR/db-mcp-server/config.json" "$PROJECT_DB_CONFIG"
        
        # Find database binary
        DB_BINARY=""
        if [ -f "$MCP_DIR/db-mcp-server/bin/server" ]; then
            DB_BINARY="$MCP_DIR/db-mcp-server/bin/server"
        elif [ -f "$MCP_DIR/db-mcp-server/db-mcp-server" ]; then
            DB_BINARY="$MCP_DIR/db-mcp-server/db-mcp-server"
        fi
        
        if [ ! -z "$DB_BINARY" ] && [ -x "$DB_BINARY" ]; then
            print_status "Adding Database MCP server for $PROJECT_NAME..."
            if claude mcp add "database-$PROJECT_ID" "$DB_BINARY" -- -t stdio -c "$PROJECT_DB_CONFIG"; then
                print_success "Database MCP server added: database-$PROJECT_ID"
            else
                print_warning "Failed to add Database MCP server"
            fi
        else
            print_warning "Database binary not found or not executable"
        fi
    else
        if [ -z "$DB_DATABASE" ]; then
            print_status "No database configured in .env file, skipping Database MCP server"
        fi
    fi
    
    # Display final configuration
    print_status "Final MCP server configuration:"
    claude mcp list
    
    print_success "Claude Code MCP configuration completed!"
    
    # Show summary
    echo ""
    print_status "MCP Server Configuration Summary:"
    echo ""
    print_status "Global MCP servers (shared across all projects):"
    claude mcp list | grep -E "^(github|memory|context7|webfetch):" | sed 's/^/  ✅ /' || true
    echo ""
    print_status "Project-specific MCP servers for $PROJECT_NAME:"
    claude mcp list | grep -E "^(filesystem|database)-$PROJECT_ID" | sed 's/^/  ✅ /' || true
    echo ""
    
    print_status "💡 Usage Tips:"
    echo "  • Global servers work across all your projects"
    echo "  • Filesystem access is specific to: $PROJECT_PATH"
    if [ ! -z "$DB_DATABASE" ]; then
        echo "  • Database access is configured for: $DB_DATABASE"
    fi
    echo "  • Memory is shared - decisions in one project can inform others"
    echo "  • GitHub can access any repository you have permissions for"
}

# Create project-specific Claude prompts
create_project_prompts() {
    print_status "Creating project-specific Claude prompts..."
    
    # Get current project details
    PROJECT_NAME=$(basename "$PWD")
    PROJECT_PATH="$PWD"
    
    # Ensure we're in the correct directory
    cd "$PROJECT_PATH"
    
    # Create .claude directory with explicit error checking
    if ! mkdir -p ".claude"; then
        print_error "Failed to create .claude directory in $PROJECT_PATH"
        return 1
    fi
    
    if ! mkdir -p ".claude/memory"; then
        print_error "Failed to create .claude/memory directory in $PROJECT_PATH"
        return 1
    fi
    
    # Verify directories were created
    if [ ! -d ".claude" ]; then
        print_error ".claude directory was not created successfully"
        return 1
    fi
}

# Create useful aliases and shortcuts
create_shortcuts() {
    print_status "Creating useful shortcuts..."
    
    # Ensure we're in the project directory
    PROJECT_PATH="$PWD"
    cd "$PROJECT_PATH"
    
    # Verify .claude directory exists
    if [ ! -d ".claude" ]; then
        print_error ".claude directory does not exist, cannot create shortcuts"
        return 1
    fi
    
    cat > ".claude/shortcuts.sh" << 'EOF'
#!/bin/bash

# Laravel Development Shortcuts for Claude Code

# Artisan shortcuts
alias pa='php artisan'
alias pam='php artisan migrate'
alias pams='php artisan migrate --seed'
alias par='php artisan route:list'
alias pat='php artisan test'
alias paq='php artisan queue:work'

# Livewire shortcuts
alias make-livewire='php artisan make:livewire'
alias make-component='php artisan make:component'

# Asset shortcuts
alias npm-dev='npm run dev'
alias npm-watch='npm run watch'
alias npm-build='npm run build'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Project shortcuts
alias serve='php artisan serve'
alias tinker='php artisan tinker'
alias fresh='php artisan migrate:fresh --seed'

echo "🚀 Laravel development shortcuts loaded!"
echo "Use 'pa' instead of 'php artisan', 'pam' for migrate, etc."
EOF

    chmod +x ".claude/shortcuts.sh"
    
    # Verify the file was created
    if [ -f ".claude/shortcuts.sh" ] && [ -x ".claude/shortcuts.sh" ]; then
        print_success "Shortcuts created! Source .claude/shortcuts.sh to use them."
    else
        print_error "Failed to create shortcuts.sh file"
        return 1
    fi
}

# Install Claude Code hooks
install_hooks() {
    print_status "Installing Claude Code hooks..."
    
    # Ensure we're in the project directory
    PROJECT_PATH="$PWD"
    cd "$PROJECT_PATH"
    
    # Create hooks directory
    if ! mkdir -p ".claude/hooks"; then
        print_error "Failed to create .claude/hooks directory"
        return 1
    fi
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SETUP_DIR="$(dirname "$SCRIPT_DIR")"
    
    # Copy hooks from the setup repository
    if [ -d "$SETUP_DIR/hooks" ]; then
        print_status "Copying hooks from $SETUP_DIR/hooks"
        
        # Copy lint.sh
        if [ -f "$SETUP_DIR/hooks/lint.sh" ]; then
            cp "$SETUP_DIR/hooks/lint.sh" ".claude/hooks/lint.sh"
            chmod +x ".claude/hooks/lint.sh"
            print_success "Installed lint.sh hook"
        else
            print_warning "lint.sh not found in setup directory"
        fi
        
        # Copy test.sh
        if [ -f "$SETUP_DIR/hooks/test.sh" ]; then
            cp "$SETUP_DIR/hooks/test.sh" ".claude/hooks/test.sh"
            chmod +x ".claude/hooks/test.sh"
            print_success "Installed test.sh hook"
        else
            print_warning "test.sh not found in setup directory"
        fi
    else
        print_error "Hooks directory not found in setup repository"
        return 1
    fi
    
    # Create settings.local.json
    print_status "Creating settings.local.json..."
    cat > ".claude/settings.local.json" << 'EOF'
{
  "hooks": {
    "Notification": [
        {
            "matcher": "*",
            "hooks": [
                {
                    "type": "command",
                    "command": "afplay /System/Library/Sounds/Frog.aiff"
                }
            ]
        }
    ],
    "Stop": [
        {
            "matcher": "*",
            "hooks": [
                {
                    "type": "command",
                    "command": "afplay /System/Library/Sounds/Glass.aiff"
                }
            ]
        }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/lint.sh"
          },
          {
            "type": "command",
            "command": ".claude/hooks/test.sh"
          }
        ]
      }
    ]
  }
}
EOF
    
    if [ -f ".claude/settings.local.json" ]; then
        print_success "Created settings.local.json"
    else
        print_error "Failed to create settings.local.json"
        return 1
    fi
    
    print_success "Hooks installation completed!"
    return 0
}

# Check for existing CLAUDE.md
check_claude_files() {
    print_status "Checking for existing CLAUDE documentation..."
    
    if [ -f "CLAUDE.md" ]; then
        # Create timestamped backup
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        BACKUP_FILE="CLAUDE.md.backup_${TIMESTAMP}"
        
        print_status "Found existing CLAUDE.md - creating backup as $BACKUP_FILE"
        cp "CLAUDE.md" "$BACKUP_FILE"
        
        if [ -f "$BACKUP_FILE" ]; then
            print_success "Backup created successfully: $BACKUP_FILE"
            print_status "Will now create fresh CLAUDE.md from template"
            return 1  # Return 1 to trigger creation of new file
        else
            print_error "Failed to create backup of CLAUDE.md"
            print_status "Keeping existing CLAUDE.md unchanged"
            return 0  # Don't overwrite if backup failed
        fi
    fi
    
    print_status "No CLAUDE.md found - will create one with Laravel development standards"
    return 1
}

# Create CLAUDE.md with Laravel-specific standards
create_claude_md() {
    print_status "Creating CLAUDE.md with Laravel development standards..."
    
    # Get project information
    PROJECT_NAME=$(basename "$PWD")
    PROJECT_PATH="$PWD"
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SETUP_DIR="$(dirname "$SCRIPT_DIR")"
    
    # Copy from template
    TEMPLATE_FILE="$SETUP_DIR/templates/CLAUDE.md.template"
    if [ -f "$TEMPLATE_FILE" ]; then
        cp "$TEMPLATE_FILE" "CLAUDE.md"
    else
        print_error "CLAUDE.md template not found at $TEMPLATE_FILE"
        print_error "Cannot continue without template file"
        return 1
    fi
    
    # Replace variables if file was created
    if [ -f "CLAUDE.md" ]; then
        # Replace project name variables
        sed -i '' "s/\$PROJECT_NAME/$PROJECT_NAME/g" "CLAUDE.md" 2>/dev/null || sed -i "s/\$PROJECT_NAME/$PROJECT_NAME/g" "CLAUDE.md"
        
        print_success "CLAUDE.md created successfully!"
        print_status "This file establishes development standards and quality requirements."
        print_status "Personal preferences can be added to .claude/personal-laravel-preferences.md"
        return 0
    else
        print_error "Failed to create CLAUDE.md"
        return 1
    fi
}

# Create command files for Laravel development
create_command_files() {
    print_status "Creating Claude command files..."
    
    # Create commands directory
    if ! mkdir -p ".claude/commands"; then
        print_error "Failed to create .claude/commands directory"
        return 1
    fi
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SETUP_DIR="$(dirname "$SCRIPT_DIR")"
    
    # Copy command templates
    COMMANDS_DIR="$SETUP_DIR/templates/commands"
    
    if [ ! -d "$COMMANDS_DIR" ]; then
        print_error "Command templates directory not found at $COMMANDS_DIR"
        return 1
    fi
    
    # Copy check.md
    if [ -f "$COMMANDS_DIR/check.md.template" ]; then
        cp "$COMMANDS_DIR/check.md.template" ".claude/commands/check.md"
        chmod +x ".claude/commands/check.md" 2>/dev/null || true
        print_status "Created check.md command"
    else
        print_error "check.md template not found"
        return 1
    fi
    
    # Copy next.md
    if [ -f "$COMMANDS_DIR/next.md.template" ]; then
        cp "$COMMANDS_DIR/next.md.template" ".claude/commands/next.md"
        chmod +x ".claude/commands/next.md" 2>/dev/null || true
        print_status "Created next.md command"
    else
        print_error "next.md template not found"
        return 1
    fi
    
    # Copy prompt.md
    if [ -f "$COMMANDS_DIR/prompt.md.template" ]; then
        cp "$COMMANDS_DIR/prompt.md.template" ".claude/commands/prompt.md"
        chmod +x ".claude/commands/prompt.md" 2>/dev/null || true
        print_status "Created prompt.md command"
    else
        print_error "prompt.md template not found"
        return 1
    fi
    
    # Verify commands were created
    if [ -f ".claude/commands/check.md" ] && [ -f ".claude/commands/next.md" ] && [ -f ".claude/commands/prompt.md" ]; then
        print_success "Command files created successfully!"
        return 0
    else
        print_error "Failed to create some command files"
        return 1
    fi
}

# Main installation function
main() {
        echo "======================================"
    echo "Laravel Claude Code Setup Script v2.2"
    echo "======================================"
    echo ""
    
    # Store the original directory
    ORIGINAL_DIR="$PWD"
    
    # Pre-flight checks
    check_laravel_project
    check_claude_code
    check_node
    
    # Collect tokens and keys
    collect_tokens
    
    # Parse environment
    parse_env
    
    # Create MCP directory
    create_mcp_directory
    
    # Install MCP servers (these change directories, so we need to return)
    install_context7
    cd "$ORIGINAL_DIR"
    
    install_filesystem
    cd "$ORIGINAL_DIR"
    
    install_database
    cd "$ORIGINAL_DIR"
    
    install_web_fetch
    cd "$ORIGINAL_DIR"
    
    install_github
    cd "$ORIGINAL_DIR"
    
    install_memory
    cd "$ORIGINAL_DIR"
    
    # Generate database configuration
    generate_database_config
    cd "$ORIGINAL_DIR"
    
    # Create project-specific files (these MUST run in the project directory)
    print_status "Creating project-specific files in: $ORIGINAL_DIR"
    
    if create_project_prompts; then
        print_success "Project prompts created successfully"
    else
        print_error "Failed to create project prompts"
        exit 1
    fi
    
    if create_shortcuts; then
        print_success "Shortcuts created successfully"
    else
        print_error "Failed to create shortcuts"
        exit 1
    fi
    
    if install_hooks; then
        print_success "Hooks installed successfully"
    else
        print_error "Failed to install hooks"
        exit 1
    fi
    
    # Check for CLAUDE.md and create it if needed
    if ! check_claude_files; then
        if create_claude_md; then
            print_success "CLAUDE.md created successfully"
        else
            print_error "Failed to create CLAUDE.md"
            exit 1
        fi
    fi
    
    # Create command files
    if create_command_files; then
        print_success "Command files created successfully"
    else
        print_error "Failed to create command files"
        exit 1
    fi
    
    # Configure Claude Code MCP servers
    configure_claude_mcp
    cd "$ORIGINAL_DIR"
    
    # Final verification
    print_status "Verifying project files..."
    if [ -d ".claude" ] && [ -f ".claude/shortcuts.sh" ]; then
        print_success "All project files created successfully in $(pwd)/.claude/"
        ls -la .claude/
    else
        print_error "Project files verification failed"
        exit 1
    fi
    
    echo ""
    echo "======================================"
    print_success "Setup completed successfully!"
    echo "======================================"
    echo ""
    print_status "🚀 Claude Code is now fully configured with MCP servers and quality standards!"
    echo ""
    print_status "✨ Created Files:"
    echo "  - CLAUDE.md - Development standards and workflow"
    echo "  - .claude/commands/ - Custom commands (/check, /next, /prompt)"
    echo "  - .claude/hooks/ - Automated quality checks"
    echo "  - .claude/shortcuts.sh - Laravel aliases"
    echo ""
    print_status "📋 Installed MCP Servers:"
    echo ""
    echo "  Global Servers (shared across all projects):"
    claude mcp list | grep -E "^(github|memory|context7|webfetch):" | sed 's/^/    ✅ /' || true
    echo ""
    echo "  Project-Specific Servers for $PROJECT_NAME:"
    claude mcp list | grep -E "^(filesystem|database)-$PROJECT_ID" | sed 's/^/    ✅ /' || true
    echo ""
    print_status "Next steps:"
    echo "1. Restart Claude Code to ensure all servers are loaded"
    echo "2. Load helpful aliases: source .claude/shortcuts.sh"
    echo "3. Read CLAUDE.md for development standards and workflow"
    echo "4. Try custom commands: /check, /next, /prompt"
    echo "5. Test MCP servers with: 'Can you list available MCP servers and read my .env file?'"
    echo "6. Try: 'Show me the project structure' or 'What's in my database?'"
    echo "7. Ask Claude to remember important project decisions"
    echo "8. Start coding with production-quality standards!"
    echo ""
    print_warning "💡 Pro tip: Use 'source .claude/shortcuts.sh' for Laravel aliases (pa, pam, par, etc.)"
    echo ""
    print_success "🎉 Your Laravel + Livewire + Filament + Alpine + Tailwind development environment is ready!"
    echo ""
    
    # Count successful MCP servers
    GLOBAL_MCP_COUNT=$(claude mcp list | grep -E "^(github|memory|context7|webfetch):" | wc -l | tr -d ' ')
    PROJECT_MCP_COUNT=$(claude mcp list | grep -E "^(filesystem|database)-$PROJECT_ID" | wc -l | tr -d ' ')
    TOTAL_MCP_COUNT=$(claude mcp list | wc -l | tr -d ' ')
    
    if [ "$GLOBAL_MCP_COUNT" -ge 2 ] && [ "$PROJECT_MCP_COUNT" -ge 1 ]; then
        print_success "✅ All core MCP servers installed successfully!"
        print_status "Global servers: $GLOBAL_MCP_COUNT | Project servers: $PROJECT_MCP_COUNT | Total: $TOTAL_MCP_COUNT"
    else
        print_warning "⚠️ Some MCP servers may have failed to install"
        print_status "Global servers: $GLOBAL_MCP_COUNT | Project servers: $PROJECT_MCP_COUNT | Total: $TOTAL_MCP_COUNT"
        print_status "Check the output above for any error messages"
    fi
    
    # GitHub token configuration reminder
    if [ "$GITHUB_AUTH_METHOD" = "token" ] && [ ! -z "$GITHUB_TOKEN" ]; then
        CONFIG_FILE="$HOME/.claude.json"
        if [ -f "$CONFIG_FILE" ]; then
            # Check if token is properly configured in project-specific config
            PROJECT_HAS_TOKEN=$(jq -r --arg project "$PROJECT_PATH" \
                '.projects[$project].mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN // "not_found"' \
                "$CONFIG_FILE" 2>/dev/null)
            
            if [ "$PROJECT_HAS_TOKEN" = "not_found" ] || [ -z "$PROJECT_HAS_TOKEN" ]; then
                echo ""
                print_warning "⚠️  GitHub token may need manual configuration"
                echo "If private repository access doesn't work, edit ~/.claude.json"
                echo "and ensure the token is in the project-specific GitHub config:"
                echo "projects.'$PROJECT_PATH'.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN"
            fi
        fi
    fi
}

# Run the main function
main "$@"