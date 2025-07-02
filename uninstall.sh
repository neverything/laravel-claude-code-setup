#!/bin/bash

# Laravel Claude Setup Uninstaller
# Removes all MCP servers and configurations

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

echo ""
echo "🗑️  Laravel Claude Setup Uninstaller"
echo "===================================="
echo ""

# Confirm uninstallation
read -p "Are you sure you want to uninstall Laravel Claude Setup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo ""
print_status "Starting uninstallation..."

# Remove Claude Code configuration
if [ -f ~/.config/claude-code/claude_desktop_config.json ]; then
    rm -f ~/.config/claude-code/claude_desktop_config.json
    print_success "Removed Claude Code configuration"
else
    print_warning "Claude Code configuration not found"
fi

# Remove MCP servers directory
if [ -d ~/.config/claude-code/mcp-servers ]; then
    rm -rf ~/.config/claude-code/mcp-servers/
    print_success "Removed MCP servers"
else
    print_warning "MCP servers directory not found"
fi

# Remove project-specific files (if in Laravel project)
if [ -f "artisan" ] && [ -d ".claude" ]; then
    echo ""
    read -p "Remove project-specific .claude/ directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf .claude/
        print_success "Removed project-specific Claude files"
    else
        print_status "Kept project-specific files"
    fi
elif [ -d ".claude" ]; then
    print_warning "Found .claude/ directory but this doesn't appear to be a Laravel project"
    echo "You may want to remove .claude/ manually if it's from this setup"
fi

# Remove global npm packages
print_status "Removing global npm packages..."
npm uninstall -g @modelcontextprotocol/server-filesystem 2>/dev/null || true
npm uninstall -g @modelcontextprotocol/server-postgres 2>/dev/null || true
npm uninstall -g @modelcontextprotocol/server-pdf 2>/dev/null || true
npm uninstall -g @modelcontextprotocol/server-fetch 2>/dev/null || true
npm uninstall -g @modelcontextprotocol/server-github 2>/dev/null || true
npm uninstall -g @modelcontextprotocol/server-memory 2>/dev/null || true
npm uninstall -g @sebdesign/debugbar-mcp-server 2>/dev/null || true
print_success "Removed global npm packages"

# Clean up npm cache
print_status "Cleaning npm cache..."
npm cache clean --force >/dev/null 2>&1 || true

echo ""
echo "🎉 Uninstallation completed!"
echo ""
print_warning "Claude Code itself is still installed"
print_warning "Your Laravel project files are untouched"
print_status "You may need to restart Claude Code"
echo ""
echo "To reinstall, run:"
echo "curl -fsSL https://raw.githubusercontent.com/laraben/laravel-claude-setup/main/install.sh | bash"
echo ""