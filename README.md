# Laravel Claude Code Setup 🚀

**Agent-orchestrated Laravel development** with Claude Code. Features modular templates, parallel agent execution, and automated quality enforcement.

## ✨ What's New in v3.0

- **75% smaller templates** through agent delegation
- **Parallel agent execution** for faster development
- **Modular architecture** with specialized agents
- **Smart hook recommendations** for agent spawning
- **Externalized rules** in JSON for easy updates

## 🤖 Agent Architecture

This setup leverages Claude's multi-agent capabilities with specialized agents:

| Agent | Purpose | Parallel | When to Use |
|-------|---------|----------|-------------|
| `research-agent` | Explore codebase | ✅ | Before any implementation |
| `implementation-agent` | Build features | ❌ | After research completes |
| `test-agent` | Write tests | ✅ | Alongside implementation |
| `fix-agent` | Fix issues | ✅ | When hooks detect problems |
| `refactor-agent` | Improve code | ✅ | For code modernization |
| `review-agent` | Quality check | ❌ | Before marking complete |

## 📊 Template Size Improvements

| File | Before | After | Reduction |
|------|--------|-------|-----------|
| CLAUDE.md | 495 lines | 125 lines | **75%** |
| check.md | 266 lines | 64 lines | **76%** |
| next.md | 161 lines | 83 lines | **48%** |

## 🚀 Quick Start

```bash
# Run from your Laravel project root
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh | bash
```

## 📁 New Structure

```
.claude/
├── agents/                   # Specialized agent templates (copied to .claude/agents/)
│   ├── orchestration.md     # Coordination patterns
│   ├── fix-agent.md         # Auto-fixing specialist
│   ├── research-agent.md    # Codebase explorer
│   └── ...                  # More specialists
├── rules/                    # Externalized JSON rules (copied to .claude/rules/)
│   ├── laravel-standards.json
│   ├── forbidden-patterns.json
│   └── quality-checks.json
├── commands/                 # Streamlined commands
│   ├── check.md             # Spawn fix agents
│   ├── next.md              # Orchestrated implementation
│   └── prompt.md            # Prompt synthesis
└── hooks/                    # Smart hooks with agent hints
    ├── lint.sh              # Suggests fix agents
    └── test.sh              # Suggests test/fix agents
```

## 🎯 Key Features

### Agent Orchestration
- **Automatic agent spawning** based on task type
- **Parallel execution** for research, testing, and fixing
- **Smart delegation** with clear triggers
- **Agent chaining** for complex workflows

### Quality Enforcement
- **Automated hooks** run on every file change
- **Zero-tolerance** for linting/test failures
- **Agent recommendations** when issues detected
- **Production-ready** code guaranteed

### Laravel-Specific
- **Pest testing** with comprehensive patterns
- **Livewire/Filament** best practices
- **Eloquent over raw SQL** enforcement
- **Laravel conventions** strictly followed

### Developer Experience
- **Concise templates** without losing quality
- **Clear documentation** in meta.md
- **Easy customization** through JSON rules
- **Fast development** with parallel agents

## 🎮 How It Works

1. **You request a feature** → Claude spawns research agents
2. **Research completes** → Implementation plan created
3. **Plan approved** → Implementation & test agents work in parallel
4. **Hooks detect issues** → Fix agents spawn automatically
5. **Everything green** → Review agent validates quality
6. **Feature complete** → Production-ready code delivered

## 📝 Usage Examples

### Implement a Feature
```
User: Implement user authentication with 2FA

Claude: I'll spawn research agents to explore the codebase...
[Spawns 3 parallel research agents]
[Creates implementation plan]
[Spawns implementation + test agents]
[Hooks run, spawn fix agents if needed]
[Review agent validates]
Result: Complete, tested, production-ready feature
```

### Fix All Issues
```
User: /check

Claude: I'm spawning multiple fix agents to resolve all issues:
- Agent 1: Fix linting issues
- Agent 2: Fix test failures
- Agent 3: Fix type errors
[All agents work in parallel]
Result: 100% green status achieved
```

## 🛠️ Customization

### Modify Agent Behavior
Edit templates in `.claude/agents/` to adjust:
- Agent capabilities
- Completion criteria
- Workflow patterns

### Update Rules
Edit JSON files in `.claude/rules/` to change:
- Laravel standards
- Forbidden patterns
- Quality thresholds

### Configure Hooks
Modify scripts in `.claude/hooks/` to customize:
- Check commands
- Agent recommendations
- Exit codes

## 📚 Documentation

- **[Meta Documentation](templates/meta.md)** - Architecture and usage guide
- **[Agent Orchestration](templates/agents/orchestration.md)** - Coordination patterns
- **[Installation Guide](docs/installation.md)** - Detailed setup instructions
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## 🤝 Contributing

Contributions welcome! The modular architecture makes it easy to:
- Add new agent types
- Create project-specific rules
- Improve orchestration patterns
- Enhance hook intelligence

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Credits

Created with ❤️ for the Laravel community by developers who believe in production-quality AI-assisted development.

---

*Transform your Laravel development with intelligent agent orchestration. Less verbosity, more productivity.*