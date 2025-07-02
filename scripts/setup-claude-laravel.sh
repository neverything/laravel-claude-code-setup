#!/bin/bash

# Laravel Claude Code Setup Script
# Automatically configures Claude Code with MCP servers for Laravel development
# Author: Laravel Developer
# Version: 1.0

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
    
    # Test SSH authentication with GitHub
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "GitHub SSH authentication detected!"
        print_status "Using existing SSH credentials for GitHub integration"
        GITHUB_AUTH_METHOD="ssh"
        
        # Optional: GitHub repository
        if [ -t 0 ]; then
            echo -n "Enter GitHub repository (optional, format: owner/repo): "
            read GITHUB_REPO
        fi
    else
        print_warning "GitHub SSH authentication not available"
        print_status "Personal Access Token required for GitHub MCP integration..."
        GITHUB_AUTH_METHOD="token"
        
        # Check if GITHUB_TOKEN is already set
        if [ -n "$GITHUB_TOKEN" ]; then
            print_success "Using GITHUB_TOKEN from environment"
        else
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
                echo -n "Enter your GitHub Personal Access Token (required for GitHub MCP): "
                read -s GITHUB_TOKEN
                echo ""
                if [ -z "$GITHUB_TOKEN" ]; then
                    print_warning "GitHub token is required for GitHub integration!"
                fi
            done
        fi
        
        # Optional: GitHub repository
        if [ -z "$GITHUB_REPO" ]; then
            if [ -t 0 ]; then
                echo -n "Enter GitHub repository (optional, format: owner/repo): "
                read GITHUB_REPO
            fi
        fi
    fi
    
    print_success "GitHub authentication configured!"
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
    
    if [ ! -d "context7" ]; then
        git clone https://github.com/upstash/context7.git context7
    fi
    
    cd context7
    npm install
    
    print_success "Context7 MCP Server installed!"
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
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        print_warning "Go is not installed. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install go
        else
            print_error "Go is required but not installed. Please install Go first."
            print_status "Install with: brew install go"
            return 1
        fi
    fi
    
    cd "$MCP_DIR"
    
    if [ ! -d "db-mcp-server" ]; then
        git clone https://github.com/FreePeak/db-mcp-server.git db-mcp-server
    fi
    
    cd db-mcp-server
    
    # Build the Go project
    print_status "Building Go database MCP server..."
    if [ -f "Makefile" ]; then
        make build
    else
        go build -o db-mcp-server ./cmd/...
    fi
    
    # Auto-generate config file from Laravel .env
    print_status "Generating database configuration from .env..."
    
    # Validate required database environment variables
    if [ -z "$DB_DATABASE" ]; then
        print_warning "DB_DATABASE not set in .env file, skipping database MCP"
        return 0
    fi
    
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
            print_warning "Unknown database type: $DB_CONNECTION, defaulting to MySQL"
            ;;
    esac
    
    # Create the configuration file with correct FreePeak format
    if [ "$DB_CONNECTION" = "sqlite" ]; then
        cat > config.json << EOF
{
  "connections": [
    {
      "id": "laravel",
      "type": "$DB_TYPE",
      "database": "$DB_PATH",
      "query_timeout": 60,
      "max_open_conns": 10,
      "max_idle_conns": 2,
      "conn_max_lifetime_seconds": 300,
      "conn_max_idle_time_seconds": 60
    }
  ]
}
EOF
    else
        cat > config.json << EOF
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
EOF
    fi
    
    print_success "Database configuration created!"
    print_success "Database MCP Server installed and configured!"
}

# Install PDF MCP Server
install_pdf() {
    print_status "Installing PDF MCP Server..."
    
    # The sylphxltd/pdf-reader-mcp is published as @sylphlab/pdf-reader-mcp on npm
    npm install -g @sylphlab/pdf-reader-mcp
    
    print_success "PDF MCP Server installed!"
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
    
    # Create project-specific memory directory
    MEMORY_DIR="$PROJECT_PATH/.claude/memory"
    mkdir -p "$MEMORY_DIR"
    
    print_success "Memory MCP Server installed!"
    print_status "Memory will be stored in: $MEMORY_DIR"
}

# Install Laravel Documentation MCP Server
install_laravel_docs() {
    print_status "Installing Laravel Documentation MCP Server..."
    
    cd "$MCP_DIR"
    
    if [ ! -d "laravel-docs" ]; then
        git clone https://github.com/brianirish/laravel-docs-mcp.git laravel-docs
    fi
    
    cd laravel-docs
    
    # Create virtual environment and install dependencies
    if command -v uv &> /dev/null; then
        uv venv
        source .venv/bin/activate
        uv pip install .
    else
        python3 -m venv .venv
        source .venv/bin/activate
        pip install .
    fi
    
    print_success "Laravel Documentation MCP Server installed!"
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

# Generate Claude Code configuration
generate_config() {
    print_status "Generating Claude Code configuration..."
    
    PROJECT_NAME=$(basename "$PWD")
    PROJECT_PATH="$PWD"
    
    # Create claude-code config directory if it doesn't exist
    mkdir -p "$HOME/.config/claude-code"
    
    # Build database connection string based on DB type
    if [ "$DB_CONNECTION" = "mysql" ]; then
        DB_CONNECTION_STRING="mysql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_DATABASE"
    elif [ "$DB_CONNECTION" = "pgsql" ] || [ "$DB_CONNECTION" = "postgres" ]; then
        DB_CONNECTION_STRING="postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_DATABASE"
    else
        DB_CONNECTION_STRING="$DB_CONNECTION://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_DATABASE"
    fi
    
    # Configure GitHub MCP based on authentication method
    if [ "$GITHUB_AUTH_METHOD" = "ssh" ]; then
        GITHUB_MCP_CONFIG='{
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {}'
        if [ ! -z "$GITHUB_REPO" ]; then
            GITHUB_MCP_CONFIG='{
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_REPOSITORY": "'$GITHUB_REPO'"
      }'
        fi
    else
        GITHUB_MCP_CONFIG='{
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "'$GITHUB_TOKEN'"'
        if [ ! -z "$GITHUB_REPO" ]; then
            GITHUB_MCP_CONFIG+=',
        "GITHUB_REPOSITORY": "'$GITHUB_REPO'"'
        fi
        GITHUB_MCP_CONFIG+='
      }'
    fi
    
# Generate the configuration
cat > "$HOME/.config/claude-code/claude_desktop_config.json" << EOF
{
  "mcpServers": {
    "context7": {
      "command": "node",
      "args": ["$MCP_DIR/context7/build/index.js"],
      "env": {
        "PROJECT_PATH": "$PROJECT_PATH"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$PROJECT_PATH"],
      "env": {}
    },
    "database": {
        "command": "$MCP_DIR/db-mcp-server/db-mcp-server",
        "args": ["--config", "$MCP_DIR/db-mcp-server/config.json"],
        "env": {}
    },
    "pdf": {
        "command": "npx",
        "args": ["-y", "@sylphlab/pdf-reader-mcp"],
        "env": {}
    },
    "web_fetch": {
        "command": "node",
        "args": ["$MCP_DIR/fetch-mcp/dist/index.js"],
        "env": {}
    },
    "github": $GITHUB_MCP_CONFIG,
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_STORAGE_PATH": "$PROJECT_PATH/.claude/memory"
      }
    },
    "laravel_docs": {
      "command": "python",
      "args": ["$MCP_DIR/laravel-docs/.venv/bin/python", "$MCP_DIR/laravel-docs/laravel_docs_server.py"],
      "env": {}
    }
  },
  "globalShortcut": "CommandOrControl+Shift+Space"
}
EOF

    # Add optional DebugBar MCP if available
    if grep -q "barryvdh/laravel-debugbar" composer.json 2>/dev/null; then
        # Update JSON to include debugbar
        python3 -c "
import json
with open('$HOME/.config/claude-code/claude_desktop_config.json', 'r') as f:
    config = json.load(f)
config['mcpServers']['debugbar'] = {
    'command': 'npx',
    'args': ['-y', '@sebdesign/debugbar-mcp-server'],
    'env': {
        'LARAVEL_PROJECT_PATH': '$PROJECT_PATH'
    }
}
with open('$HOME/.config/claude-code/claude_desktop_config.json', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || true
    fi
    
    print_success "Configuration generated!"
}

# Create project-specific Claude prompts
create_project_prompts() {
    print_status "Creating project-specific Claude prompts..."
    
    PROJECT_NAME=$(basename "$PWD")
    mkdir -p ".claude"
    
    cat > ".claude/project_context.md" << EOF
# $PROJECT_NAME - Laravel Project Context

## Project Overview
This is a Laravel project using the following stack:
- **Framework**: Laravel
- **Frontend**: Livewire, Alpine.js, Tailwind CSS
- **Admin Panel**: Filament
- **Database**: $DB_CONNECTION

## Key Directories
- \`app/\` - Application logic (Models, Controllers, etc.)
- \`resources/views/\` - Blade templates
- \`resources/js/\` - Alpine.js components
- \`resources/css/\` - Tailwind CSS styles
- \`database/\` - Migrations, seeders, factories
- \`routes/\` - Route definitions
- \`config/\` - Configuration files

## Development Guidelines
- Follow Laravel best practices
- Use Livewire for dynamic components
- Style with Tailwind CSS utility classes
- Use Alpine.js for simple interactivity
- Follow PSR-12 coding standards
- Write feature tests for new functionality

## Common Commands
- \`php artisan serve\` - Start development server
- \`php artisan migrate\` - Run migrations
- \`php artisan make:livewire ComponentName\` - Create Livewire component
- \`npm run dev\` - Build assets for development
- \`php artisan test\` - Run tests
EOF

    cat > ".claude/coding_standards.md" << EOF
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

    # Create optimized Claude instructions
    cat > ".claude/instructions.md" << EOF
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
- **Laravel Helper**: Run Artisan commands directly
- **Filesystem**: Read and edit project files
- **Database**: Query and modify database
- **Memory**: Remember project decisions and patterns
- **Context7**: Access latest Laravel documentation
- **GitHub**: Manage repository operations
- **Web Fetch**: Access external resources
- **PDF**: Read documentation PDFs

Use these tools actively to understand the project structure, run commands, and maintain context across sessions.

## Project-Specific Notes
- Database connection: $DB_CONNECTION
- Project started: $(date)
- Initial setup completed with full MCP server configuration

Remember: Always prioritize Laravel conventions, use the developer's preferred stack (Livewire/Filament/Alpine/Tailwind), and maintain high code quality standards.
EOF

    cat > ".claude/memory_prompts.md" << EOF
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
    
    print_success "Project prompts created!"
}

# Create useful aliases and shortcuts
create_shortcuts() {
    print_status "Creating useful shortcuts..."
    
    cat > ".claude/shortcuts.sh" << EOF
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

echo "Laravel development shortcuts loaded!"
echo "Use 'pa' instead of 'php artisan', 'pam' for migrate, etc."
EOF

    chmod +x ".claude/shortcuts.sh"
    print_success "Shortcuts created! Source .claude/shortcuts.sh to use them."
}

# Generate project documentation
generate_docs() {
    print_status "Generating project documentation..."
    
    cat > ".claude/README.md" << EOF
# Claude Code Setup for $PROJECT_NAME

This Laravel project has been configured with Claude Code and the following MCP servers:

## Available MCP Servers

### 1. Context7
- **Purpose**: Always access the latest documentation
- **Features**: Real-time doc lookup, API reference

### 2. Filesystem
- **Purpose**: Read and edit project files
- **Features**: File operations, code analysis

### 3. Database
- **Purpose**: Database operations
- **Connection**: $DB_CONNECTION database
- **Features**: Query execution, schema inspection

### 4. PDF Reader
- **Purpose**: Read PDF documentation
- **Features**: Extract text from PDFs, analyze documents

### 5. Web Fetch
- **Purpose**: Fetch internet resources
- **Features**: API calls, web scraping, documentation lookup

### 6. GitHub Integration
- **Purpose**: GitHub operations
- **Features**: Repository management, issue tracking, PR reviews

### 7. Memory
- **Purpose**: Persistent memory across sessions
- **Features**: Remember project details, coding patterns, preferences, decisions

### 8. Laravel Documentation
- **Purpose**: Access Laravel documentation and package recommendations
- **Features**: Documentation search, package suggestions, version-specific docs

### 9. Laravel DebugBar (Optional)
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
Run \`source .claude/shortcuts.sh\` to load helpful aliases.

Happy coding! 🚀
EOF

    print_success "Documentation generated!"
}

# Main installation function
main() {
    echo "======================================"
    echo "Laravel Claude Code Setup Script"
    echo "======================================"
    echo ""
    
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
    
    # Install MCP servers
    install_context7
    install_filesystem
    install_database
    install_pdf
    install_web_fetch
    install_github
    install_memory
    install_laravel_docs
    install_debugbar_mcp
    
    # Generate configuration
    generate_config
    
    # Create project-specific files
    create_project_prompts
    create_shortcuts
    generate_docs
    
    echo ""
    echo "======================================"
    print_success "Setup completed successfully!"
    echo "======================================"
    echo ""
    print_status "Next steps:"
    echo "1. Restart Claude Code to load the new configuration"
    echo "2. Open Claude Code in this project directory"
    echo "3. Reference .claude/instructions.md for optimal AI assistance"
    echo "4. Try asking Claude to run 'php artisan route:list' using the Laravel Helper"
    echo "5. Ask Claude to remember important project decisions in Memory"
    echo "6. Start coding with AI assistance!"
    echo ""
    print_warning "Don't forget to source .claude/shortcuts.sh for helpful aliases!"
    echo ""
}

# Run the main function
main "$@"