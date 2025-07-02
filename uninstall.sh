#!/bin/bash

# Laravel Claude Setup Uninstaller v1.5
# Removes MCP servers and configurations created by v1.5 installer
# Supports both single project removal and complete uninstallation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Get current project info
get_project_info() {
    PROJECT_PATH="$PWD"
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    PROJECT_ID=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID="unknown"
    fi
}

# Check if this is a Laravel project
is_laravel_project() {
    [ -f "artisan" ] && [ -f "composer.json" ]
}

echo ""
echo "🗑️  Laravel Claude Setup Uninstaller v1.5"
echo "============================================"
echo ""

get_project_info

if is_laravel_project; then
    echo "📍 Current Laravel project: $PROJECT_NAME (ID: $PROJECT_ID)"
    echo ""
    echo "Choose uninstallation scope:"
    echo "1) Remove MCP servers for current project only ($PROJECT_NAME)"
    echo "2) Remove ALL Laravel projects and MCP servers (complete uninstall)"
    echo "3) Cancel"
    echo ""
    read -p "Enter choice (1, 2, or 3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            UNINSTALL_SCOPE="project"
            ;;
        2)
            UNINSTALL_SCOPE="complete"
            ;;
        3|*)
            echo "Uninstallation cancelled."
            exit 0
            ;;
    esac
else
    echo "❌ Not in a Laravel project directory."
    echo ""
    echo "Choose uninstallation scope:"
    echo "1) Remove ALL Laravel projects and MCP servers (complete uninstall)"
    echo "2) Cancel"
    echo ""
    read -p "Enter choice (1 or 2): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            UNINSTALL_SCOPE="complete"
            ;;
        2|*)
            echo "Uninstallation cancelled."
            exit 0
            ;;
    esac
fi

echo ""
if [ "$UNINSTALL_SCOPE" = "project" ]; then
    echo "This will remove MCP servers for: $PROJECT_NAME"
    echo "• filesystem-$PROJECT_ID, database-$PROJECT_ID, github-$PROJECT_ID, etc."
    echo "• Project-specific configurations and wrapper scripts"
    echo "• .claude/ directory (optional)"
    echo ""
    echo "Other Laravel projects will remain untouched."
elif [ "$UNINSTALL_SCOPE" = "complete" ]; then
    echo "This will remove:"
    echo "• ALL MCP servers (all projects)"
    echo "• All MCP server installations and configurations"
    echo "• All GitHub wrapper scripts"
    echo "• Global npm packages"
    echo "• .claude/ directory (optional)"
    echo ""
fi

read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo ""
print_status "Starting uninstallation..."

# Remove MCP servers
if command -v claude &> /dev/null; then
    if [ "$UNINSTALL_SCOPE" = "project" ]; then
        print_status "Removing MCP servers for project: $PROJECT_NAME"
        
        # Find and remove project-specific MCP servers
        PROJECT_SERVERS=$(claude mcp list 2>/dev/null | grep -E "^(filesystem|memory|github|webfetch|database|context7|debugbar)-$PROJECT_ID" | awk '{print $1}' || true)
        
        if [ ! -z "$PROJECT_SERVERS" ]; then
            echo "$PROJECT_SERVERS" | while read -r server; do
                if [ ! -z "$server" ]; then
                    claude mcp remove "$server" 2>/dev/null || true
                    print_status "Removed MCP server: $server"
                fi
            done
            print_success "Removed all MCP servers for $PROJECT_NAME"
        else
            print_warning "No MCP servers found for project $PROJECT_NAME"
        fi
        
        # Remove project-specific wrapper scripts and configs
        MCP_DIR="$HOME/.config/claude-code/mcp-servers"
        if [ -f "$MCP_DIR/github-wrapper-$PROJECT_ID.sh" ]; then
            rm -f "$MCP_DIR/github-wrapper-$PROJECT_ID.sh"
            print_status "Removed GitHub wrapper script for $PROJECT_NAME"
        fi
        
        if [ -f "$MCP_DIR/db-mcp-server/config-$PROJECT_ID.json" ]; then
            rm -f "$MCP_DIR/db-mcp-server/config-$PROJECT_ID.json"
            print_status "Removed database config for $PROJECT_NAME"
        fi
        
    elif [ "$UNINSTALL_SCOPE" = "complete" ]; then
        print_status "Removing ALL MCP servers..."
        
        # Get list of all MCP servers and remove them
        ALL_SERVERS=$(claude mcp list 2>/dev/null | grep -E "^[a-zA-Z0-9_-]+" | awk '{print $1}' || true)
        
        if [ ! -z "$ALL_SERVERS" ]; then
            echo "$ALL_SERVERS" | while read -r server; do
                if [ ! -z "$server" ]; then
                    claude mcp remove "$server" 2>/dev/null || true
                    print_status "Removed MCP server: $server"
                fi
            done
            print_success "Removed all MCP servers"
        else
            print_warning "No MCP servers found to remove"
        fi
    fi
else
    print_warning "Claude Code CLI not found - cannot remove MCP servers automatically"
    print_status "You may need to remove MCP servers manually in Claude Code"
fi

# Remove MCP installations and configurations
if [ "$UNINSTALL_SCOPE" = "complete" ]; then
    MCP_DIR="$HOME/.config/claude-code/mcp-servers"
    if [ -d "$MCP_DIR" ]; then
        print_status "Removing MCP servers directory and installations..."
        
        # List what we're removing
        if [ -d "$MCP_DIR/context7" ]; then
            print_status "Removing Context7 installation..."
            rm -rf "$MCP_DIR/context7"
        fi
        
        if [ -d "$MCP_DIR/db-mcp-server" ]; then
            print_status "Removing Database MCP server installation..."
            rm -rf "$MCP_DIR/db-mcp-server"
        fi
        
        if [ -d "$MCP_DIR/fetch-mcp" ]; then
            print_status "Removing Web Fetch MCP server installation..."
            rm -rf "$MCP_DIR/fetch-mcp"
        fi
        
        # Remove all GitHub wrapper scripts
        rm -f "$MCP_DIR"/github-wrapper*.sh 2>/dev/null || true
        
        # Remove the entire MCP servers directory
        rm -rf "$MCP_DIR"
        print_success "Removed MCP servers directory"
    else
        print_warning "MCP servers directory not found"
    fi
    
    # Remove Claude Code configuration directory if empty
    CLAUDE_CONFIG_DIR="$HOME/.config/claude-code"
    if [ -d "$CLAUDE_CONFIG_DIR" ]; then
        # Check if directory is empty (only remove if we created it)
        if [ -z "$(ls -A "$CLAUDE_CONFIG_DIR" 2>/dev/null)" ]; then
            rmdir "$CLAUDE_CONFIG_DIR" 2>/dev/null || true
            print_success "Removed empty Claude Code configuration directory"
        else
            print_status "Kept Claude Code configuration directory (contains other files)"
        fi
    fi
    
    # Remove global npm packages
    print_status "Removing global npm packages..."
    
    NPM_PACKAGES=(
        "@modelcontextprotocol/server-filesystem"
        "@modelcontextprotocol/server-github" 
        "@modelcontextprotocol/server-memory"
        "@sebdesign/debugbar-mcp-server"
        "@sylphlab/pdf-reader-mcp"
    )
    
    for package in "${NPM_PACKAGES[@]}"; do
        if npm list -g "$package" >/dev/null 2>&1; then
            npm uninstall -g "$package" >/dev/null 2>&1 || true
            print_status "Removed global package: $package"
        fi
    done
    
    print_success "Removed global npm packages"
    
    # Clean npm cache
    print_status "Cleaning npm cache..."
    npm cache clean --force >/dev/null 2>&1 || true
fi

# Handle .claude directory
if [ -d ".claude" ]; then
    echo ""
    if [ "$UNINSTALL_SCOPE" = "project" ]; then
        print_status "Found .claude/ directory for $PROJECT_NAME"
        read -p "Remove project-specific .claude/ directory? (y/N): " -n 1 -r
    else
        print_status "Found .claude/ directory"
        read -p "Remove .claude/ directory? (y/N): " -n 1 -r
    fi
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf .claude/
        print_success "Removed .claude/ directory"
    else
        print_status "Kept .claude/ directory"
    fi
fi

# Check for remaining processes
if pgrep -f "claude" >/dev/null 2>&1; then
    print_warning "Claude Code processes are still running"
    print_status "You may want to restart Claude Code for changes to take effect"
fi

echo ""
echo "🎉 Uninstallation completed successfully!"
echo ""

if [ "$UNINSTALL_SCOPE" = "project" ]; then
    print_status "What was removed for $PROJECT_NAME:"
    echo "  ✅ Project-specific MCP servers (filesystem-$PROJECT_ID, database-$PROJECT_ID, etc.)"
    echo "  ✅ Project-specific configurations and wrapper scripts"
    echo "  ✅ Project-specific database configuration"
    echo ""
    print_warning "What was preserved:"
    echo "  🔒 Other Laravel projects and their MCP servers"
    echo "  🔒 Global MCP server installations"
    echo "  🔒 Your Laravel project files"
    echo ""
    print_status "Other Laravel projects continue to work normally."
    
    # Show remaining MCP servers
    if command -v claude &> /dev/null; then
        REMAINING_SERVERS=$(claude mcp list 2>/dev/null | wc -l | tr -d ' ')
        if [ "$REMAINING_SERVERS" -gt 0 ]; then
            print_status "Remaining MCP servers: $REMAINING_SERVERS"
            claude mcp list | sed 's/^/  /'
        fi
    fi
    
elif [ "$UNINSTALL_SCOPE" = "complete" ]; then
    print_status "What was removed:"
    echo "  ✅ All MCP servers (all projects)"
    echo "  ✅ All MCP server installations and source code"
    echo "  ✅ All GitHub authentication wrapper scripts"
    echo "  ✅ All project-specific configurations"
    echo "  ✅ Global npm packages installed by the setup"
    echo ""
    print_warning "What was preserved:"
    echo "  🔒 Claude Code application (still installed)"
    echo "  🔒 All your Laravel project files (completely untouched)"
    echo "  🔒 Your GitHub Personal Access Token (if created)"
    echo "  🔒 Node.js, npm, Go installations"
fi

echo ""
print_status "Next steps:"
if [ "$UNINSTALL_SCOPE" = "project" ]; then
    echo "  1. $PROJECT_NAME is no longer accessible via Claude Code MCP"
    echo "  2. You can reinstall for this project anytime"
    echo "  3. Other Laravel projects continue to work normally"
else
    echo "  1. Restart Claude Code if it's currently running"
    echo "  2. No MCP servers will be available in Claude Code"
    echo "  3. You can safely delete your GitHub token if you no longer need it"
fi
echo ""
echo "To reinstall Laravel Claude Setup:"
echo "curl -fsSL https://raw.githubusercontent.com/laraben/laravel-claude-code-setup/main/install.sh | bash"
echo ""
print_success "Thanks for using Laravel Claude Setup! 👋"