# Troubleshooting Guide

## 🚨 Common Issues and Solutions

### Installation Issues

#### ❌ "Command not found: claude"

**Problem:** Claude Code is not installed or not in PATH.

**Solution:**
```bash
# Download and install Claude Code from:
# https://claude.ai/code

# Verify installation
which claude
claude --version
```

#### ❌ "Not a Laravel project"

**Problem:** Running script outside Laravel project directory.

**Solution:**
```bash
# Make sure you're in Laravel project root
cd /path/to/your/laravel/project
ls -la | grep artisan  # Should show artisan file

# Then run installer again
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh | bash
```

#### ❌ "Permission denied"

**Problem:** Script doesn't have execute permissions.

**Solution:**
```bash
# Make script executable
chmod +x install.sh

# Or download with correct permissions
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh | bash
```

#### ❌ Node.js or npm not found

**Problem:** Node.js is not installed.

**Solution:**
```bash
# Install via Homebrew (recommended)
brew install node

# Verify installation
node --version
npm --version

# Update npm if needed
npm install -g npm@latest
```

### Configuration Issues

#### ❌ Claude doesn't see MCP servers

**Problem:** Claude Code configuration not loaded properly.

**Solution:**
```bash
# Check configuration file exists
cat ~/.config/claude-code/claude_desktop_config.json

# If missing, re-run installer
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh | bash

# Restart Claude Code completely
# Quit Claude Code and relaunch
```

#### ❌ MCP servers not responding

**Problem:** MCP servers failed to start or crashed.

**Solution:**
```bash
# Check MCP servers directory
ls -la ~/.config/claude-code/mcp-servers/

# Check individual server installations
cd ~/.config/claude-code/mcp-servers/laravel-helper
npm list

# Reinstall if needed
npm install

# Restart Claude Code
```

#### ❌ Database MCP not working

**Problem:** Database connection or credentials issue.

**Solution:**
```bash
# Check .env file has correct database credentials
cat .env | grep DB_

# Test database connection
php artisan migrate:status

# Verify database is accessible
mysql -u$DB_USERNAME -p$DB_PASSWORD -h$DB_HOST $DB_DATABASE

# Re-run installer to update configuration
./install.sh
```

### GitHub Integration Issues

#### ❌ GitHub MCP not working

**Problem:** Invalid or missing GitHub token.

**Solution:**
```bash
# Create new GitHub Personal Access Token:
# 1. Go to: https://github.com/settings/tokens
# 2. Generate new token (classic)
# 3. Select scopes: repo, read:user, user:email
# 4. Copy the token

# Test token manually
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user

# Re-run installer with new token
./install.sh
```

#### ❌ "API rate limit exceeded"

**Problem:** Too many GitHub API requests.

**Solution:**
```bash
# Wait for rate limit to reset (usually 1 hour)
# Or use authenticated requests with higher limits

# Check rate limit status
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/rate_limit
```

### Runtime Issues

#### ❌ "Memory MCP not persisting data"

**Problem:** Memory directory permissions or path issues.

**Solution:**
```bash
# Check memory directory exists
ls -la .claude/memory/

# Fix permissions if needed
chmod -R 755 .claude/

# Restart Claude Code
```

#### ❌ Laravel Helper not executing commands

**Problem:** Laravel Helper MCP server issues.

**Solution:**
```bash
# Check if in Laravel project root
pwd
ls artisan

# Verify Laravel Helper installation
ls ~/.config/claude-code/mcp-servers/laravel-helper/

# Test manually
cd ~/.config/claude-code/mcp-servers/laravel-helper/
node build/index.js

# Reinstall if needed
git pull origin main
npm install
```

#### ❌ Context7 not finding documentation

**Problem:** Context7 server or network issues.

**Solution:**
```bash
# Check Context7 installation
ls ~/.config/claude-code/mcp-servers/context7/

# Update Context7
cd ~/.config/claude-code/mcp-servers/context7/
git pull origin main
npm install

# Check internet connection
ping google.com
```

### Performance Issues

#### ❌ Slow response from Claude

**Problem:** Multiple MCP servers causing delays.

**Solution:**
```bash
# Disable unused MCP servers temporarily
# Edit ~/.config/claude-code/claude_desktop_config.json
# Comment out servers you don't need

# Example: Comment out PDF server if not using
# "pdf": {
#   "command": "npx",
#   "args": ["-y", "@modelcontextprotocol/server-pdf"],
#   "env": {}
# },

# Restart Claude Code
```

#### ❌ High memory usage

**Problem:** MCP servers consuming too much memory.

**Solution:**
```bash
# Monitor memory usage
top -o MEM

# Restart Claude Code to clear memory
# Or restart specific MCP servers

# Reduce memory usage by disabling heavy servers
```

### macOS Specific Issues

#### ❌ "Developer cannot be verified" error

**Problem:** macOS Gatekeeper blocking script.

**Solution:**
```bash
# Remove quarantine attribute
xattr -dr com.apple.quarantine install.sh

# Or allow in System Preferences:
# System Preferences > Security & Privacy > General
# Click "Allow Anyway" for blocked item
```

#### ❌ Homebrew not found

**Problem:** Homebrew not installed.

**Solution:**
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

#### ❌ Xcode Command Line Tools missing

**Problem:** Git or other tools not available.

**Solution:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcode-select -p
git --version
```

## 🔧 Advanced Troubleshooting

### Debug Mode

Run installer with debug output:
```bash
# Download script and run with debug
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh -o debug-install.sh
bash -x debug-install.sh
```

### Manual Configuration Check

```bash
# Check Claude Code configuration
cat ~/.config/claude-code/claude_desktop_config.json | jq .

# Validate JSON syntax
python -m json.tool ~/.config/claude-code/claude_desktop_config.json

# Check MCP server processes
ps aux | grep mcp
```

### Clean Installation

If all else fails, clean install:
```bash
# Remove all configurations
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/uninstall.sh | bash

# Clean npm cache
npm cache clean --force

# Reinstall
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh | bash
```

### Log Analysis

```bash
# Check system logs
tail -f /var/log/system.log | grep claude

# Check npm logs
npm config get cache
ls ~/.npm/_logs/

# Check Claude Code logs (if available)
# Location varies by version
```

## 📞 Getting Help

### Before Reporting Issues:

1. **Check this troubleshooting guide**
2. **Verify prerequisites are installed**
3. **Try a clean installation**
4. **Check if it's a known issue**

### Reporting Issues:

When creating an issue, include:

```bash
# System information
sw_vers  # macOS version
node --version
npm --version
claude --version  # if available

# Error messages
# Copy exact error output

# Configuration
cat ~/.config/claude-code/claude_desktop_config.json

# Installation log
# Run installer with debug mode and include output
```

### Community Support:

- [GitHub Issues](https://github.com/neverything/laravel-claude-code-setup/issues)
- [GitHub Discussions](https://github.com/neverything/laravel-claude-code-setup/discussions)
- [Laravel Community](https://laravel.com/community)

### Quick Fixes:

#### Reset Configuration:
```bash
rm ~/.config/claude-code/claude_desktop_config.json
./install.sh
```

#### Reset Project Files:
```bash
rm -rf .claude/
./install.sh
```

#### Update All MCP Servers:
```bash
cd ~/.config/claude-code/mcp-servers/
for dir in */; do
  echo "Updating $dir"
  cd "$dir"
  git pull 2>/dev/null || npm update 2>/dev/null || true
  cd ..
done
```

## 🎯 Prevention Tips

### Regular Maintenance:
```bash
# Update Node.js regularly
brew upgrade node

# Update npm packages
npm update -g

# Keep Claude Code updated
# Check for updates in the app
```

### Best Practices:
- Always run installer from Laravel project root
- Keep GitHub token secure and rotate regularly
- Don't modify configuration files manually unless necessary
- Backup working configuration before major changes

---

**Still having issues?** [Open an issue](https://github.com/neverything/laravel-claude-code-setup/issues) with detailed information about your problem.