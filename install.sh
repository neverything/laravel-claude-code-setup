#!/bin/bash

# Laravel Claude Code Setup for macOS
# One-command installation script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
print_header() {
    echo ""
    echo "🚀 Laravel Claude Code Setup for macOS"
    echo "======================================"
    echo ""
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS."
        print_error "For other systems, please check the documentation."
        exit 1
    fi
    print_success "macOS detected!"
}

# Check if we're in a Laravel project
check_laravel_project() {
    if [ ! -f "artisan" ] || [ ! -f "composer.json" ]; then
        print_error "Please run this script from your Laravel project root directory."
        echo ""
        echo "Usage:"
        echo "  cd /path/to/your/laravel/project"
        echo "  curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh | bash"
        echo ""
        exit 1
    fi
    print_success "Laravel project detected!"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Claude Code
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code is not installed!"
        echo ""
        echo "Please install Claude Code first:"
        echo "https://claude.ai/code"
        echo ""
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed!"
        echo ""
        echo "Install with Homebrew:"
        echo "  brew install node"
        echo ""
        echo "Or download from: https://nodejs.org"
        echo ""
        exit 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed!"
        echo ""
        echo "Install with Homebrew:"
        echo "  brew install node"
        echo ""
        exit 1
    fi
    
    # Check git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed!"
        echo ""
        echo "Install with:"
        echo "  xcode-select --install"
        echo ""
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Download and run the main setup script
run_setup() {
    print_status "Downloading Laravel Claude Code setup..."
    
    # Clone the entire repository temporarily to get hooks
    TEMP_DIR=$(mktemp -d)
    
    if git clone --quiet https://github.com/neverything/laravel-claude-code-setup.git "$TEMP_DIR"; then
        print_success "Setup files downloaded!"
    else
        print_error "Failed to download setup files"
        print_error "Please check your internet connection and try again"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Run the setup script from the cloned repository
    print_status "Running main installation script..."
    if ! bash "$TEMP_DIR/scripts/setup-claude-code-laravel.sh"; then
        print_error "Failed to execute installation script"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    print_success "Setup completed!"
}

# Main installation
main() {
    print_header
    check_macos
    check_laravel_project
    check_prerequisites
    run_setup
    
    echo ""
    echo "🎉 Installation completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Restart Claude Code completely"
    echo "2. Open Claude Code in this project directory"
    echo "3. Load helpful aliases: source .claude/shortcuts.sh"
    echo "4. Try: 'Run php artisan route:list'"
    echo "5. Start coding with AI assistance!"
    echo ""
    echo "📖 Documentation: https://github.com/neverything/laravel-claude-code-setup"
    echo "🆘 Need help? https://github.com/neverything/laravel-claude-code-setup/issues"
    echo ""
}

# Run main function
main "$@"