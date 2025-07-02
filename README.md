# Laravel Claude Code Setup 🚀

**One-command setup** for Claude Code with Laravel development. Automatically configures all MCP servers for the ultimate AI-powered Laravel development experience.

## 🎯 What This Does

Installs and configures Claude Code with:

### Global MCP Servers (shared across all projects)
- ✅ **GitHub integration** - Access all your repositories, manage PRs (with automatic token configuration!)
- ✅ **Memory system** - Remember decisions across all projects
- ✅ **Context7** - Latest Laravel/PHP documentation access
- ✅ **Web fetch** - Access external APIs and resources

### Project-Specific MCP Servers
- ✅ **Filesystem access** - Read/write your specific Laravel project files
- ✅ **Database integration** - Direct access to your project's database
- ✅ **Laravel DebugBar** - Real-time debugging (if installed)

The installer intelligently sets up global servers once and adds project-specific servers for each Laravel project.

## 🚀 Quick Install

### Option 1: Direct Installation (Recommended)

Run this single command from your Laravel project root:

```bash
curl -fsSL https://raw.githubusercontent.com/laraben/laravel-claude-code-setup/main/install.sh | bash
```

### Option 2: With GitHub Token Pre-configured

If you want to skip the interactive GitHub token prompt:

```bash
export GITHUB_TOKEN="your_github_personal_access_token"
curl -fsSL https://raw.githubusercontent.com/laraben/laravel-claude-code-setup/main/install.sh | bash
```

### Option 3: Download and Run

For more control or if you prefer to review the script first:

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/laraben/laravel-claude-code-setup/main/install.sh -o setup.sh

# Make it executable
chmod +x setup.sh

# Run it
./setup.sh
```

## 📋 Prerequisites

Before running the installer, make sure you have:

1. **Claude Code** installed ([Download here](https://claude.ai/code))
2. **Node.js & npm** installed
3. **A Laravel project** with `.env` file configured
4. **GitHub Personal Access Token** (the installer will guide you)

## 🔑 GitHub Token Setup

You'll need a GitHub Personal Access Token for private repository access:

1. Go to [GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Select these scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `read:user` (Read user profile data)
   - ✅ `user:email` (Access user email addresses)
4. Copy the generated token when prompted by the installer

## 🎮 Usage After Installation

Once installed, just open Claude Code in your Laravel project:

```bash
cd /path/to/your/laravel/project
claude
```

Then test everything works:

- "Show me the database structure"
- "List commits from my private GitHub repo"
- "Read my .env file"
- "What Laravel version is this project using?"
- "Remember that we use Filament for admin panels"

The installer automatically configures your GitHub token for private repository access!

## 🛠️ What Gets Installed

The script intelligently manages global vs project-specific resources:

### Global MCP Servers (installed once, shared by all projects)
1. **GitHub MCP Server** - Repository access across all projects
2. **Memory MCP Server** - Shared knowledge base
3. **Context7** - Documentation access 
4. **Web Fetch** - External API access

### Project-Specific MCP Servers (per Laravel project)
1. **Filesystem MCP Server** - Access to your project files
2. **Database MCP Server** - Connected to your project's database
3. **Laravel DebugBar MCP** (if available)

### Project Files (created in `.claude/`)
- Project context and instructions
- Coding standards
- Development shortcuts
- Memory initialization

The installer automatically configures everything based on your Laravel `.env` file.

## 🔧 Manual Installation

If you prefer to install components manually, check the [manual installation guide](docs/MANUAL_INSTALL.md).

## ⚠️ Important: GitHub Private Repository Access

**Note:** The GitHub MCP server requires manual configuration for private repository access due to how Claude Code handles environment variables.

### Quick Fix for Private Repos

After running the installer, if you can't access private repositories:

1. Open your Claude Code config:
```bash
nano ~/.config/claude-code/config.json
```

2. Find your GitHub server entry (e.g., `github-yourproject`)

3. Add your token to the environment section:
```json
"github-yourproject": {
  "command": "npx",
  "args": ["@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_YourTokenHere"
  }
}
```

4. Save and restart Claude Code

### Alternative: Use the Wrapper Script

The installer creates a wrapper script that should handle this automatically. If it's not working:

```bash
# Check if the wrapper exists
ls ~/.config/claude-code/mcp-servers/github-wrapper-*.sh

# Re-run just the GitHub MCP setup
claude mcp remove github-yourproject
claude mcp add github-yourproject ~/.config/claude-code/mcp-servers/github-wrapper-yourproject.sh
```

## 🐛 Other Troubleshooting

### Database Connection Failed?

Make sure your Laravel `.env` file has valid database credentials before running the installer.

### Missing Dependencies?

The installer will tell you what's missing, but you can check manually:
```bash
# Check Claude Code
claude --version

# Check Node.js
node --version

# Check npm
npm --version
```

## 🤝 Contributing

Found a bug or want to add a feature? PRs are welcome!

## 📝 License

MIT License - feel free to use this in your projects!

---

Made with ❤️ for the Laravel community by [@laraben](https://github.com/laraben)