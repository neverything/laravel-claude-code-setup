# Laravel Claude Code Setup 🚀

**One-command setup** for Claude Code with Laravel development. Automatically configures all MCP servers for the ultimate AI-powered Laravel development experience.

## 🎯 What This Does

Installs and configures Claude Code with:
- ✅ **Filesystem access** - Read/write your Laravel project files
- ✅ **Database integration** - Direct database queries and migrations
- ✅ **GitHub integration** - Access private repos, manage PRs
- ✅ **Memory system** - Remember project decisions across sessions
- ✅ **Context7** - Latest Laravel/PHP documentation access
- ✅ **Web fetch** - Access external APIs and resources
- ✅ **Laravel DebugBar** - Real-time debugging (if installed)

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

Then try these commands to test everything works:

- "Show me the database structure"
- "List recent commits from my GitHub repo"
- "Read my .env file"
- "What Laravel version is this project using?"
- "Remember that we use Filament for admin panels"

## 🛠️ What Gets Installed

The script will:

1. **Install MCP Servers**:
   - Filesystem MCP Server
   - Database MCP Server (with your Laravel DB config)
   - GitHub MCP Server
   - Memory MCP Server
   - Context7 (documentation access)
   - Web Fetch MCP Server
   - Laravel DebugBar MCP (if available)

2. **Create Project Files** in `.claude/`:
   - Project context and instructions
   - Coding standards
   - Development shortcuts
   - Memory initialization

3. **Configure Everything** automatically based on your Laravel `.env`

## 🔧 Manual Installation

If you prefer to install components manually, check the [manual installation guide](docs/MANUAL_INSTALL.md).

## 🐛 Troubleshooting

### GitHub Private Repos Not Working?

The GitHub MCP server needs the token in the Claude Code config. The installer handles this automatically, but if you need to fix it manually:

1. Edit `~/.config/claude-code/config.json`
2. Find your github server entry
3. Add the environment variable:
```json
"github-yourproject": {
  "command": "npx",
  "args": ["@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "your_token_here"
  }
}
```

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