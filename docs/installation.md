# Installation Guide

## 📋 Prerequisites

### macOS Requirements
- macOS 10.15+ (Catalina or later)
- [Claude Code](https://claude.ai/code) installed
- Node.js 18+
- npm
- Git

### Install Prerequisites

#### Install Node.js
```bash
# Via Homebrew (recommended)
brew install node

# Or download from nodejs.org
```

#### Install Git
```bash
# Install Xcode Command Line Tools
xcode-select --install
```

#### Install Claude Code
1. Visit [https://claude.ai/code](https://claude.ai/code)
2. Download Claude Code for macOS
3. Install and launch the application

## 🚀 Installation Methods

### Method 1: One-Line Install (Recommended)

```bash
# Navigate to your Laravel project
cd /path/to/your/laravel/project

# Run the installer
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh | bash
```

### Method 2: Manual Installation

```bash
# Clone the repository
git clone https://github.com/neverything/laravel-claude-code-setup.git
cd laravel-claude-code-setup

# Make installer executable
chmod +x install.sh

# Run the installer
./install.sh
```

### Method 3: Download Script Only

```bash
# Download just the main script
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh -o setup-claude.sh

# Make it executable
chmod +x setup-claude.sh

# Run it
./setup-claude.sh
```

## 🔧 Installation Process

### What Happens During Installation:

1. **System Check**: Verifies macOS, Laravel project, and prerequisites
2. **Token Collection**: Securely prompts for your GitHub Personal Access Token
3. **MCP Server Installation**: Downloads and configures all MCP servers
4. **Claude Configuration**: Creates `~/.config/claude-code/claude_desktop_config.json`
5. **Project Setup**: Creates `.claude/` directory with project-specific files

### Interactive Prompts:

- **GitHub Token**: Enter your GitHub Personal Access Token (input is hidden)
- **GitHub Repository** (optional): Specify a repository in `owner/repo` format

### Files Created:

```
Your Laravel Project/
├── .claude/
│   ├── instructions.md          # AI instructions for your project
│   ├── project_context.md       # Project overview
│   ├── coding_standards.md      # Your coding standards
│   ├── memory_prompts.md        # Memory initialization
│   ├── shortcuts.sh             # Helpful bash aliases
│   ├── README.md               # Setup documentation
│   └── memory/                 # Persistent AI memory storage

~/.config/claude-code/
├── claude_desktop_config.json  # Claude Code configuration
└── mcp-servers/                # MCP server installations
    ├── context7/
    ├── laravel-helper/
    ├── laravel-docs/
    └── ...
```

## 📝 GitHub Token Setup

### Creating a GitHub Personal Access Token:

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give it a name: `Claude Code MCP`
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `read:user` (Read user profile data)
   - ✅ `user:email` (Access user email addresses)
5. Click **"Generate token"**
6. **Copy the token** (you won't see it again!)

### Token Security:
- The token is stored locally in your Claude Code configuration
- It's only used for GitHub MCP server functionality
- You can revoke it anytime from GitHub settings

## ✅ Post-Installation

### 1. Restart Claude Code
```bash
# Quit Claude Code completely and relaunch it
```

### 2. Open Claude Code in Your Project
```bash
# Navigate to your Laravel project
cd /path/to/your/laravel/project

# Open Claude Code
claude
```

### 3. Load Helpful Aliases (Optional)
```bash
# Load the shortcuts
source .claude/shortcuts.sh

# Now you can use shortcuts like:
pa route:list    # Instead of php artisan route:list
pam             # Instead of php artisan migrate
```

### 4. Test the Setup
Try these commands with Claude:
- `"Run php artisan route:list"`
- `"Show me the project structure"`
- `"Create a new Livewire component"`
- `"Remember that we use UUID primary keys"`

## 🔍 Verification

### Check Installation Status:
```bash
# Verify Claude Code configuration
cat ~/.config/claude-code/claude_desktop_config.json

# Check MCP servers
ls ~/.config/claude-code/mcp-servers/

# Verify project files
ls -la .claude/
```

### Test MCP Servers:
Ask Claude to:
1. **Filesystem**: `"Show me the contents of app/Models/User.php"`
2. **Database**: `"Show me all tables in the database"`
3. **Laravel Helper**: `"Run php artisan --version"`
4. **Memory**: `"Remember that this project uses Stripe for payments"`
5. **GitHub**: `"Show me recent commits"`

## 🛠️ Troubleshooting

### Common Issues:

#### "Command not found: claude"
```bash
# Reinstall Claude Code from https://claude.ai/code
# Make sure it's in your PATH
```

#### "Permission denied"
```bash
# Fix script permissions
chmod +x install.sh
```

#### "Not a Laravel project"
```bash
# Make sure you're in your Laravel project root
ls -la | grep artisan
```

#### GitHub Token Issues
```bash
# Test your token
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
```

#### Node.js/npm Issues
```bash
# Update Node.js
brew upgrade node

# Or reinstall
brew uninstall node
brew install node
```

### Get Help:
- [Troubleshooting Guide](troubleshooting.md)
- [GitHub Issues](https://github.com/neverything/laravel-claude-code-setup/issues)
- [GitHub Discussions](https://github.com/neverything/laravel-claude-code-setup/discussions)

## 🔄 Updating

### Re-run Installation:
The installer is safe to run multiple times. It will:
- Update existing MCP servers
- Regenerate configuration files
- Preserve your project-specific settings

```bash
# Update to latest version
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh | bash
```

## 🎯 Next Steps

After successful installation:
1. Explore the [Usage Guide](usage.md)
2. Read your project's `.claude/instructions.md`
3. Try the example commands above
4. Start building with AI assistance!

---

**Need help?** [Open an issue](https://github.com/neverything/laravel-claude-code-setup/issues) or check the [troubleshooting guide](troubleshooting.md).