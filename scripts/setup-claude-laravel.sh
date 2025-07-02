#!/bin/bash

# Laravel Claude Code Setup Script
# Automatically configures Claude Code with MCP servers for Laravel development
# Author: Laravel Developer
# Version: 1.4 - Enhanced GitHub token collection and authentication setup

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

# Check GitHub authentication and collect tokens if needed
collect_tokens() {
    print_status "Checking GitHub authentication..."
    echo ""
    
    # Check if GITHUB_TOKEN is already set
    if [ -n "$GITHUB_TOKEN" ]; then
        print_success "Using GITHUB_TOKEN from environment"
        GITHUB_AUTH_METHOD="token"
    else
        # Test SSH authentication with GitHub
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            print_success "GitHub SSH authentication detected!"
            print_status "However, for MCP integration, a Personal Access Token is recommended for private repositories."
            
            # Ask if user wants to use SSH or provide a token
            if [ -t 0 ]; then
                echo ""
                echo "Choose GitHub authentication method:"
                echo "1) Use SSH (works for public repos, limited for private repos in MCP)"
                echo "2) Provide Personal Access Token (recommended for full private repo access)"
                echo -n "Enter choice (1 or 2): "
                read auth_choice
                
                if [ "$auth_choice" = "2" ]; then
                    GITHUB_AUTH_METHOD="token"
                    while [ -z "$GITHUB_TOKEN" ]; do
                        echo ""
                        print_status "To create a GitHub Personal Access Token:"
                        echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)"
                        echo "2. Click 'Generate new token (classic)'"
                        echo "3. Select scopes: repo, read:user, user:email"
                        echo "4. Copy the generated token"
                        echo ""
                        echo -n "Enter your GitHub Personal Access Token (or 'skip' to continue without): "
                        read -s GITHUB_TOKEN
                        echo ""
                        
                        if [ "$GITHUB_TOKEN" = "skip" ]; then
                            GITHUB_TOKEN=""
                            GITHUB_AUTH_METHOD="none"
                            print_warning "Skipping GitHub MCP integration"
                            break
                        elif [ -z "$GITHUB_TOKEN" ]; then
                            print_warning "Token is required for GitHub MCP integration!"
                        fi
                    done
                else
                    GITHUB_AUTH_METHOD="ssh"
                fi
            else
                GITHUB_AUTH_METHOD="ssh"
            fi
        else
            print_warning "No GitHub SSH authentication detected"
            GITHUB_AUTH_METHOD="token"
            
            # Check if running in a pipe (non-interactive mode)
            if [ ! -t 0 ]; then
                print_error "This script requires a GitHub token for GitHub MCP integration."
                print_error "Please set the GITHUB_TOKEN environment variable and try again:"
                echo ""
                echo "export GITHUB_TOKEN=your_token_here"
                echo "curl -fsSL https://raw.githubusercontent.com/laraben/laravel-claude-code-setup/main/install.sh | bash"
                echo ""
                print_status "Or download and run the script directly for interactive setup:"
                echo "curl -fsSL https://raw.githubusercontent.com/laraben/laravel-claude-code-setup/main/scripts/setup-claude-laravel.sh -o setup.sh"
                echo "chmod +x setup.sh && ./setup.sh"
                echo ""
                exit 1
            fi
            
            # Interactive input for direct execution
            while [ -z "$GITHUB_TOKEN" ]; do
                echo ""
                print_status "To create a GitHub Personal Access Token:"
                echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)"
                echo "2. Click 'Generate new token (classic)'"
                echo "3. Select scopes: repo, read:user, user:email"
                echo "4. Copy the generated token"
                echo ""
                echo -n "Enter your GitHub Personal Access Token (or 'skip' to continue without): "
                read -s GITHUB_TOKEN
                echo ""
                
                if [ "$GITHUB_TOKEN" = "skip" ]; then
                    GITHUB_TOKEN=""
                    GITHUB_AUTH_METHOD="none"
                    print_warning "Skipping GitHub MCP integration"
                    break
                elif [ -z "$GITHUB_TOKEN" ]; then
                    print_warning "Token is required for GitHub MCP integration!"
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
        if [ -t 0 ]; then
            if [ ! -z "$GITHUB_REPO" ]; then
                echo -n "Use detected repository '$GITHUB_REPO'? (y/n, or enter different owner/repo): "
                read repo_choice
                if [ "$repo_choice" = "n" ] || [ "$repo_choice" = "no" ]; then
                    GITHUB_REPO=""
                elif [ ! -z "$repo_choice" ] && [ "$repo_choice" != "y" ] && [ "$repo_choice" != "yes" ]; then
                    GITHUB_REPO="$repo_choice"
                fi
            else
                echo -n "Enter GitHub repository (optional, format: owner/repo): "
                read GITHUB_REPO
            fi
        fi
    fi
    
    if [ "$GITHUB_AUTH_METHOD" != "none" ]; then
        print_success "GitHub authentication configured!"
        if [ ! -z "$GITHUB_REPO" ]; then
            print_status "Repository: $GITHUB_REPO"
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

# Install Laravel DebugBar MCP Server (optional, requires DebugBar package)
install_debugbar_mcp() {
    print_status "Installing Laravel DebugBar MCP Server (optional)..."
    
    # Check if Laravel DebugBar is installed
    if grep -q "barryvdh/laravel-debugbar" composer.json 2>/dev/null; then
        print_status "Laravel DebugBar detected, installing MCP server..."
        npm install -g @sebdesign/debugbar-mcp-server
        print_success "Laravel DebugBar MCP Server installed!"
    else
        print_warning "Laravel DebugBar not found. Skipping DebugBar MCP installation."
        print_status "To use DebugBar MCP later, install: composer require barryvdh/laravel-debugbar --dev"
    fi
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

# Configure Claude Code MCP Servers
configure_claude_mcp() {
    print_status "Configuring Claude Code MCP servers..."
    
    PROJECT_PATH="$PWD"
    
    # Check if claude command is available
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code CLI not found. Please ensure Claude Code is properly installed."
        return 1
    fi
    
    # Remove any existing servers first to avoid conflicts
    print_status "Cleaning up existing MCP servers..."
    claude mcp list 2>/dev/null | grep -E "^[a-z]" | awk '{print $1}' | xargs -I {} claude mcp remove {} 2>/dev/null || true
    
    print_status "Adding Filesystem MCP server..."
    if claude mcp add filesystem npx @modelcontextprotocol/server-filesystem "$PROJECT_PATH"; then
        print_success "Filesystem MCP server added"
    else
        print_warning "Failed to add Filesystem MCP server"
    fi
    
    print_status "Adding Memory MCP server..."
    if claude mcp add memory npx @modelcontextprotocol/server-memory; then
        print_success "Memory MCP server added"
    else
        print_warning "Failed to add Memory MCP server"
    fi
    
    print_status "Adding GitHub MCP server..."
    if [ "$GITHUB_AUTH_METHOD" = "token" ] && [ ! -z "$GITHUB_TOKEN" ]; then
        # Configure GitHub MCP with token authentication
        # Note: GitHub MCP server gets token via environment variable, not command flags
        print_status "Configuring GitHub MCP with token authentication"
        
        # Create a wrapper script that sets the environment variable
        GITHUB_WRAPPER="$MCP_DIR/github-wrapper.sh"
        cat > "$GITHUB_WRAPPER" << WRAPPER_EOF
#!/bin/bash
export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
exec npx @modelcontextprotocol/server-github "\$@"
WRAPPER_EOF
        chmod +x "$GITHUB_WRAPPER"
        
        if claude mcp add github "$GITHUB_WRAPPER"; then
            print_success "GitHub MCP server added with token authentication (all repositories)"
            if [ ! -z "$GITHUB_REPO" ]; then
                print_status "Note: Repository-specific flags not supported, but you have access to all your repositories including: $GITHUB_REPO"
            fi
        else
            print_error "Failed to add GitHub MCP server with wrapper script"
            print_status "Falling back to direct method..."
            # Fallback: try direct method
            if GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN" claude mcp add github npx @modelcontextprotocol/server-github; then
                print_success "GitHub MCP server added with token authentication (fallback method)"
            else
                print_error "Failed to add GitHub MCP server"
                print_status "Manual fix needed - see documentation for GitHub MCP setup"
            fi
        fi
    elif [ "$GITHUB_AUTH_METHOD" = "ssh" ]; then
        # Configure GitHub MCP with SSH (limited functionality for private repos)
        print_warning "SSH authentication has limited access to private repositories via MCP"
        if claude mcp add github npx @modelcontextprotocol/server-github; then
            print_success "GitHub MCP server added with SSH authentication"
            print_warning "Note: SSH authentication may not work for private repository data via MCP"
            print_status "Consider using a Personal Access Token for full private repository access"
        else
            print_warning "Failed to add GitHub MCP server"
        fi
    else
        print_status "Skipping GitHub MCP server (no authentication configured)"
    fi
    
    # Add Context7 if build exists
    if [ -f "$MCP_DIR/context7/dist/index.js" ]; then
        print_status "Adding Context7 MCP server..."
        if claude mcp add context7 node "$MCP_DIR/context7/dist/index.js"; then
            print_success "Context7 MCP server added"
        else
            print_warning "Failed to add Context7 MCP server"
        fi
    else
        print_warning "Context7 build not found, skipping Context7 MCP server"
        print_status "Run 'cd $MCP_DIR/context7 && npm run build' to build it manually"
        print_status "Note: Context7 builds to dist/index.js not build/index.js"
    fi
    
    # Add Web Fetch if build exists
    if [ -f "$MCP_DIR/fetch-mcp/dist/index.js" ]; then
        print_status "Adding Web Fetch MCP server..."
        if claude mcp add webfetch node "$MCP_DIR/fetch-mcp/dist/index.js"; then
            print_success "Web Fetch MCP server added"
        else
            print_warning "Failed to add Web Fetch MCP server"
        fi
    else
        print_warning "Web Fetch build not found, skipping Web Fetch MCP server"
    fi
    
    # Add Database if binary exists and database is configured
    if [ -f "$MCP_DIR/db-mcp-server/config.json" ] && [ ! -z "$DB_DATABASE" ]; then
        # Try different possible binary locations
        DB_BINARY=""
        if [ -f "$MCP_DIR/db-mcp-server/bin/server" ]; then
            DB_BINARY="$MCP_DIR/db-mcp-server/bin/server"
        elif [ -f "$MCP_DIR/db-mcp-server/db-mcp-server" ]; then
            DB_BINARY="$MCP_DIR/db-mcp-server/db-mcp-server"
        fi
        
        if [ ! -z "$DB_BINARY" ] && [ -x "$DB_BINARY" ]; then
            print_status "Adding Database MCP server..."
            # Try the format that Claude Code expects for stdio servers with config
            if claude mcp add database "$DB_BINARY" -- -t stdio -c "$MCP_DIR/db-mcp-server/config.json"; then
                print_success "Database MCP server added"
            else
                print_warning "Failed with -- separator, trying without separator..."
                # Try without the -- separator
                if claude mcp add database "$DB_BINARY" -t stdio -c "$MCP_DIR/db-mcp-server/config.json"; then
                    print_success "Database MCP server added"
                else
                    print_warning "Failed with flags, trying config-only format..."
                    # Try with just the config file
                    if claude mcp add database "$DB_BINARY" "$MCP_DIR/db-mcp-server/config.json"; then
                        print_success "Database MCP server added (config-only format)"
                    else
                        print_error "All database MCP add formats failed"
                        print_status "Skipping database MCP - other servers will work perfectly"
                        print_status "Manual fix: claude mcp add database $DB_BINARY -- -t stdio -c $MCP_DIR/db-mcp-server/config.json"
                    fi
                fi
            fi
        else
            print_warning "Database binary not found or not executable, skipping Database MCP server"
            print_status "You can manually build it later if needed"
        fi
    else
        if [ -z "$DB_DATABASE" ]; then
            print_status "No database configured in .env file, skipping Database MCP server"
        else
            print_warning "Database config missing, skipping Database MCP server"
        fi
    fi
    
    # Add Laravel DebugBar MCP if available
    if grep -q "barryvdh/laravel-debugbar" composer.json 2>/dev/null; then
        print_status "Adding Laravel DebugBar MCP server..."
        if LARAVEL_PROJECT_PATH="$PROJECT_PATH" claude mcp add debugbar npx @sebdesign/debugbar-mcp-server; then
            print_success "Laravel DebugBar MCP server added"
        else
            print_warning "Failed to add Laravel DebugBar MCP server"
        fi
    else
        print_status "Laravel DebugBar not detected, skipping DebugBar MCP server"
    fi
    
    # Display final MCP server list
    print_status "Final MCP server configuration:"
    claude mcp list
    
    print_success "Claude Code MCP configuration completed!"
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
    
    print_status "Creating project context file..."
    cat > ".claude/project_context.md" << 'EOF'
# $PROJECT_NAME - Laravel Project Context

## Project Overview
This is a Laravel project using the following stack:
- **Framework**: Laravel
- **Frontend**: Livewire, Alpine.js, Tailwind CSS
- **Admin Panel**: Filament
- **Database**: $DB_CONNECTION

## Key Directories
- `app/` - Application logic (Models, Controllers, etc.)
- `resources/views/` - Blade templates
- `resources/js/` - Alpine.js components
- `resources/css/` - Tailwind CSS styles
- `database/` - Migrations, seeders, factories
- `routes/` - Route definitions
- `config/` - Configuration files

## Development Guidelines
- Follow Laravel best practices
- Use Livewire for dynamic components
- Style with Tailwind CSS utility classes
- Use Alpine.js for simple interactivity
- Follow PSR-12 coding standards
- Write feature tests for new functionality

## Common Commands
- `php artisan serve` - Start development server
- `php artisan migrate` - Run migrations
- `php artisan make:livewire ComponentName` - Create Livewire component
- `npm run dev` - Build assets for development
- `php artisan test` - Run tests
EOF

    # Replace variables in the file
    sed -i '' "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/project_context.md" 2>/dev/null || sed -i "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/project_context.md"
    sed -i '' "s/\$DB_CONNECTION/$DB_CONNECTION/g" ".claude/project_context.md" 2>/dev/null || sed -i "s/\$DB_CONNECTION/$DB_CONNECTION/g" ".claude/project_context.md"

    if [ ! -f ".claude/project_context.md" ]; then
        print_error "Failed to create project_context.md"
        return 1
    fi

    print_status "Creating coding standards file..."
    cat > ".claude/coding_standards.md" << 'EOF'
# Coding Standards for $PROJECT_NAME

## Laravel Conventions
- Use singular model names (User, Post, not Users, Posts)
- Use plural table names (users, posts)
- Use snake_case for database columns
- Use camelCase for model attributes
- Use PascalCase for class names

## Livewire Best Practices
- Keep components focused and single-purpose
- Use public properties for data binding
- Validate input in the component
- Use lifecycle hooks appropriately
- Emit events for component communication

## Tailwind CSS Guidelines
- Use utility classes over custom CSS
- Follow mobile-first responsive design
- Use consistent spacing scale
- Leverage Tailwind's color palette
- Use component classes for repeated patterns

## Filament Conventions
- Organize resources logically
- Use proper form validation
- Implement proper authorization
- Use custom pages when needed
- Follow Filament's naming conventions
EOF

    # Replace variables in the file
    sed -i '' "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/coding_standards.md" 2>/dev/null || sed -i "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/coding_standards.md"

    print_status "Creating Claude instructions file..."
    cat > ".claude/instructions.md" << 'EOF'
# Claude Instructions for $PROJECT_NAME Laravel Project

## Project Context & Tech Stack
You are working with a Laravel full-stack developer on the "$PROJECT_NAME" project. This is a Laravel application using:

- **Framework**: Laravel (latest version)
- **Frontend Stack**: Livewire + Alpine.js + Tailwind CSS
- **Admin Interface**: Filament
- **Database**: $DB_CONNECTION
- **Development Focus**: Full-stack Laravel development with modern frontend tools

## Developer Preferences & Coding Style

### Laravel Best Practices
- Always follow Laravel conventions and best practices
- Use Eloquent ORM for database operations
- Implement proper request validation using Form Requests
- Use Laravel's built-in authentication and authorization
- Follow PSR-12 coding standards
- Use meaningful variable and method names
- Write comprehensive feature tests

### Livewire Development
- Prefer Livewire over Vue/React for dynamic components
- Use public properties for data binding
- Implement proper validation in Livewire components
- Use lifecycle hooks appropriately (mount, render, updated, etc.)
- Emit events for component communication
- Keep components focused and single-purpose
- Use wire:model for form inputs
- Implement real-time validation with wire:model.lazy or wire:model.debounce

### Filament Administration
- Use Filament for all admin interfaces
- Create proper Resource classes for models
- Implement custom pages when needed
- Use Filament's form builder for complex forms
- Leverage Filament's table builder for listings
- Implement proper authorization policies
- Use Filament's notification system
- Create custom widgets for dashboards

### Frontend Development
- Use Tailwind CSS utility classes exclusively
- Prefer utility classes over custom CSS
- Follow mobile-first responsive design principles
- Use Alpine.js for simple client-side interactivity
- Keep Alpine.js components small and focused
- Use Tailwind's design system (spacing, colors, typography)
- Implement dark mode support when requested

### Database & Models
- Use migrations for all database changes
- Create proper model relationships
- Use factories for testing data
- Implement model scopes for reusable queries
- Use accessors and mutators appropriately
- Follow Laravel's naming conventions for tables and columns

## Available Tools
You have access to the following MCP servers:
- **Context7**: Access latest Laravel documentation and any other framework docs
- **Filesystem**: Read and edit project files
- **Database**: Query and modify database directly
- **Memory**: Remember project decisions and patterns
- **GitHub**: Manage repository operations
- **Web Fetch**: Access external resources

Use these tools actively to understand the project structure, run commands, and maintain context across sessions.

## Project-Specific Notes
- Database connection: $DB_CONNECTION
- Project started: $(date)
- Initial setup completed with full MCP server configuration

Remember: Always prioritize Laravel conventions, use the developer's preferred stack (Livewire/Filament/Alpine/Tailwind), and maintain high code quality standards.
EOF

    # Replace variables in the file
    sed -i '' "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/instructions.md" 2>/dev/null || sed -i "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/instructions.md"
    sed -i '' "s/\$DB_CONNECTION/$DB_CONNECTION/g" ".claude/instructions.md" 2>/dev/null || sed -i "s/\$DB_CONNECTION/$DB_CONNECTION/g" ".claude/instructions.md"

    print_status "Creating memory prompts file..."
    cat > ".claude/memory_prompts.md" << 'EOF'
# Memory Initialization for $PROJECT_NAME

## Project Information
- **Project Name**: $PROJECT_NAME
- **Tech Stack**: Laravel + Livewire + Filament + Alpine.js + Tailwind CSS
- **Database**: $DB_CONNECTION
- **Main Developer**: Laravel Full-Stack Developer
- **Preferred Tools**: Livewire, Filament, Alpine, Tailwind

## Development Preferences
- Follow Laravel best practices and conventions
- Use Livewire for dynamic components over Vue/React
- Prefer Tailwind utility classes over custom CSS
- Use Filament for admin interfaces
- Write feature tests for new functionality
- Follow PSR-12 coding standards

## Project Structure Notes
- Custom Livewire components in app/Http/Livewire/
- Filament resources in app/Filament/Resources/
- Alpine.js components in resources/js/
- Custom Tailwind components in resources/css/

## Remember These Decisions
(This section will be updated as the project evolves)
- [Date] - Decision made about X
- [Date] - Architectural choice for Y
- [Date] - Code pattern established for Z

## Common Tasks for This Project
- Creating Livewire components with proper validation
- Setting up Filament resource pages
- Implementing Alpine.js interactivity
- Database migrations and model relationships
- Feature testing with PHPUnit
EOF

    # Replace variables in the file
    sed -i '' "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/memory_prompts.md" 2>/dev/null || sed -i "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/memory_prompts.md"
    sed -i '' "s/\$DB_CONNECTION/$DB_CONNECTION/g" ".claude/memory_prompts.md" 2>/dev/null || sed -i "s/\$DB_CONNECTION/$DB_CONNECTION/g" ".claude/memory_prompts.md"
    
    # Verify all files were created successfully
    local files_created=0
    for file in "project_context.md" "coding_standards.md" "instructions.md" "memory_prompts.md"; do
        if [ -f ".claude/$file" ]; then
            ((files_created++))
        else
            print_error "Failed to create .claude/$file"
        fi
    done
    
    if [ $files_created -eq 4 ]; then
        print_success "Project prompts created! ($files_created/4 files)"
    else
        print_error "Only $files_created/4 project files were created successfully"
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

# Generate project documentation
generate_docs() {
    print_status "Generating project documentation..."
    
    # Ensure we're in the project directory
    PROJECT_PATH="$PWD"
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    cd "$PROJECT_PATH"
    
    # Verify .claude directory exists
    if [ ! -d ".claude" ]; then
        print_error ".claude directory does not exist, cannot create documentation"
        return 1
    fi
    
    cat > ".claude/README.md" << 'EOF'
# Claude Code Setup for $PROJECT_NAME

This Laravel project has been configured with Claude Code and the following MCP servers:

## Available MCP Servers

### 1. Context7
- **Purpose**: Access latest documentation (Laravel + all frameworks)
- **Features**: Real-time doc lookup, API reference, always up-to-date

### 2. Filesystem
- **Purpose**: Read and edit project files
- **Features**: File operations, code analysis

### 3. Database
- **Purpose**: Database operations
- **Connection**: $DB_CONNECTION database
- **Features**: Query execution, schema inspection

### 4. Web Fetch
- **Purpose**: Fetch internet resources
- **Features**: API calls, web scraping, documentation lookup

### 5. GitHub Integration
- **Purpose**: GitHub operations
- **Features**: Repository management, issue tracking, PR reviews

### 6. Memory
- **Purpose**: Persistent memory across sessions
- **Features**: Remember project details, coding patterns, preferences, decisions

### 7. Laravel DebugBar (Optional)
- **Purpose**: Real-time debug information access
- **Features**: Query analysis, performance metrics, request debugging
- **Note**: Only installed if Laravel DebugBar package is detected

## Usage
1. Open Claude Code in this project directory
2. All MCP servers are automatically configured
3. Use natural language to interact with your codebase
4. Ask Claude to help with Laravel, Livewire, Filament, and Tailwind tasks

## Environment
- Laravel Framework
- Livewire for dynamic components
- Filament for admin interface
- Alpine.js for frontend interactivity
- Tailwind CSS for styling

## Getting Started
Run `source .claude/shortcuts.sh` to load helpful aliases.

Happy coding! 🚀
EOF

    # Replace variables in the file
    sed -i '' "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/README.md" 2>/dev/null || sed -i "s/\$PROJECT_NAME/$PROJECT_NAME/g" ".claude/README.md"
    sed -i '' "s/\$DB_CONNECTION/$DB_CONNECTION/g" ".claude/README.md" 2>/dev/null || sed -i "s/\$DB_CONNECTION/$DB_CONNECTION/g" ".claude/README.md"

    # Verify the file was created
    if [ -f ".claude/README.md" ]; then
        print_success "Documentation generated!"
    else
        print_error "Failed to create README.md file"
        return 1
    fi
}

# Main installation function
main() {
    echo "======================================"
    echo "Laravel Claude Code Setup Script"
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
    
    install_debugbar_mcp
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
    
    if generate_docs; then
        print_success "Documentation created successfully"
    else
        print_error "Failed to create documentation"
        exit 1
    fi
    
    # Configure Claude Code MCP servers
    configure_claude_mcp
    cd "$ORIGINAL_DIR"
    
    # Final verification
    print_status "Verifying project files..."
    if [ -d ".claude" ] && [ -f ".claude/shortcuts.sh" ] && [ -f ".claude/project_context.md" ]; then
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
    print_status "🚀 Claude Code is now fully configured with MCP servers!"
    echo ""
    print_status "📋 Installed MCP Servers:"
    claude mcp list | sed 's/^/    /'
    echo ""
    print_status "Next steps:"
    echo "1. Claude Code is ready to use immediately"
    echo "2. Load helpful aliases: source .claude/shortcuts.sh"
    echo "3. Test MCP servers with: 'Can you list available MCP servers and read my .env file?'"
    echo "4. Try: 'Show me the project structure' or 'What's in my database?'"
    echo "5. Ask Claude to remember important project decisions"
    echo "6. Start coding with full AI assistance!"
    echo ""
    print_warning "💡 Pro tip: Use 'source .claude/shortcuts.sh' for Laravel aliases (pa, pam, par, etc.)"
    echo ""
    print_success "🎉 Your Laravel + Livewire + Filament + Alpine + Tailwind development environment is ready!"
    echo ""
    
    # Count successful MCP servers
    MCP_COUNT=$(claude mcp list | wc -l | tr -d ' ')
    if [ "$MCP_COUNT" -ge 5 ]; then
        print_success "✅ All core MCP servers installed successfully! ($MCP_COUNT servers active)"
    elif [ "$MCP_COUNT" -ge 3 ]; then
        print_warning "⚠️ Most MCP servers installed ($MCP_COUNT servers active) - you're ready to code!"
    else
        print_warning "⚠️ Some MCP servers may have failed to install ($MCP_COUNT servers active)"
        print_status "Check the output above for any error messages"
    fi
}

# Run the main function
main "$@"