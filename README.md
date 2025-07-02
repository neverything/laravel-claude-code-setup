# Laravel Claude Code Setup 🚀

**One-command setup for AI-powered Laravel development with Claude Code and MCP servers**

Automatically configures Claude Code with essential MCP servers for Laravel projects using **Livewire**, **Filament**, **Alpine.js**, and **Tailwind CSS**.

## ✨ Features

- 🧠 **Memory MCP** - Persistent AI memory across sessions
- 📁 **Filesystem Access** - Read and edit project files  
- 🗄️ **Database Integration** - Direct database operations from .env
- 🎨 **Laravel Docs** - Instant access to Laravel documentation
- ⚡ **Artisan Commands** - Run Laravel commands through AI
- 🐙 **GitHub Integration** - Repository management
- 🔍 **DebugBar Support** - Optional debugging integration
- 📄 **PDF Reading** - Documentation analysis
- 🌐 **Web Fetch** - Internet connectivity for AI

## 🚀 One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/laraben/laravel-claude-code-setup/main/install.sh | bash
```


## 📋 Prerequisites

- macOS (tested on macOS Sonoma+)
- Laravel project (any version)
- [Claude Code](https://claude.ai/code) installed
- Node.js 18+ and npm
- Git

## 🎯 What Gets Installed

| MCP Server | Purpose |
|------------|---------|
| **Context7** | Latest documentation access |
| **Filesystem** | File operations |
| **Database** | Database operations from .env |
| **Laravel Helper** | Artisan commands |
| **Memory** | Persistent context |
| **Laravel Docs** | Official Laravel documentation |
| **GitHub** | Repository management |
| **Web Fetch** | Internet access |
| **PDF Reader** | Document analysis |
| **DebugBar** | Optional debugging (if detected) |

## 🔧 Usage

After installation, restart Claude Code and open it in your Laravel project:

```bash
# Load helpful aliases
source .claude/shortcuts.sh

# Start coding with AI assistance!
```

### Example Commands to Try:
- `"Run php artisan route:list"`
- `"Create a Livewire component for user management"`
- `"Remember we use UUID primary keys in this project"`
- `"Show me the database schema"`
- `"Generate a Filament resource for Posts"`
- `"Analyze this error in the logs"`
- `"Optimize this database query"`

## 🗑️ Uninstalling

```bash
curl -fsSL https://raw.githubusercontent.com/laraben/laravel-claude-code-setup/main/uninstall.sh | bash
```

## 🛠️ Manual Installation

```bash
git clone https://github.com/laraben/laravel-claude-code-setup.git
cd laravel-claude-code-setup
chmod +x install.sh
./install.sh
```

## 📖 Documentation

- [Installation Guide](docs/installation.md)
- [Usage Guide](docs/usage.md)  
- [Troubleshooting](docs/troubleshooting.md)

## 🎯 Perfect For

- **Laravel** full-stack developers
- **Livewire** dynamic applications
- **Filament** admin panels
- **Alpine.js** frontend interactivity
- **Tailwind CSS** utility-first styling

## 🤝 Contributing

Contributions welcome! Feel free to:
- Report bugs
- Suggest new MCP servers
- Improve documentation
- Submit pull requests

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 🙏 Credits

Built for Laravel developers who love AI-assisted coding with Claude Code.
- Laraben

---

**⭐ Star this repo if it helped you!** | **🐛 [Report Issues](https://github.com/laraben/laravel-claude-code-setup/issues)** | **💬 [Discussions](https://github.com/laraben/laravel-claude-code-setup/discussions)**