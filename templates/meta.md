# 📚 Laravel Claude Code Setup - Meta Documentation

## Architecture Overview

This setup uses a **modular, agent-based architecture** to maximize Claude's multi-agent capabilities while keeping templates concise and maintainable.

## Directory Structure

When the setup script runs, it creates this structure in your Laravel project:

```
.claude/
├── CLAUDE.md                 # Main orchestration file (125 lines, down from 495)
├── agents/                   # Specialized agent templates (copied from templates/agents/)
│   ├── orchestration.md      # Agent coordination guide
│   ├── fix-agent.md         # Auto-fix specialist
│   ├── research-agent.md    # Codebase explorer
│   ├── implementation-agent.md # Feature builder
│   ├── test-agent.md        # Test writer
│   ├── refactor-agent.md    # Code improver
│   └── review-agent.md      # Quality checker
├── commands/                 # Slash commands
│   ├── check.md             # Quality verification (64 lines, down from 266)
│   ├── next.md              # Feature implementation (83 lines, down from 161)
│   └── prompt.md            # Prompt synthesis (50 lines)
├── rules/                    # Externalized rules (JSON, copied from templates/rules/)
│   ├── laravel-standards.json
│   ├── forbidden-patterns.json
│   └── quality-checks.json
└── hooks/                    # Automated checks with agent hints
    ├── lint.sh              # Linting with agent recommendations
    └── test.sh              # Testing with agent recommendations
```

## How It Works

### 1. Agent Orchestration
Instead of verbose instructions, the main CLAUDE.md file focuses on **agent delegation**:
- Each complex task triggers specialized agents
- Agents work in parallel when possible
- Clear triggers tell Claude when to spawn agents

### 2. Modular Templates
Each agent template is self-contained and focused:
- **Single responsibility** per agent
- **Clear capabilities** defined
- **Specific completion criteria**

### 3. External Rules
All rules are in JSON files for:
- **Easy updates** without template changes
- **Consistent enforcement** across agents
- **Clear reference** for standards

### 4. Smart Hooks
Hooks provide:
- **Automatic quality checks**
- **Agent recommendations** when issues found
- **Exit codes** that trigger specific behaviors

## Usage Patterns

### Starting a New Feature
```
User: Implement user authentication with 2FA

Claude reads CLAUDE.md → Sees agent delegation priority
→ Says: "I'll spawn research agents to explore the codebase"
→ Spawns 3 parallel research agents
→ Creates implementation plan
→ Spawns implementation + test agents
→ Hooks run automatically
→ If issues, spawns fix agents
→ Finally spawns review agent
```

### Fixing Issues
```
Hook fails with linting errors
→ Hook outputs: "🤖 AGENT RECOMMENDATION: Spawn fix agents"
→ Claude spawns fix agents
→ Agents work in parallel
→ All issues resolved
```

### Quality Check
```
User: /check

Claude reads check.md → Sees immediate agent spawn directive
→ Spawns multiple fix agents for different issue types
→ Works until everything is green
```

## Key Improvements

### Size Reduction
- **CLAUDE.md**: 495 → 125 lines (75% reduction)
- **check.md**: 266 → 64 lines (76% reduction)  
- **next.md**: 161 → 83 lines (48% reduction)

### Quality Improvements
- **Parallel execution** for faster development
- **Specialized agents** for better results
- **Clear delegation** reduces confusion
- **External rules** easier to maintain

### Developer Experience
- **Less verbose** templates
- **Clear agent triggers**
- **Automatic quality enforcement**
- **Smart recommendations** from hooks

## Configuration Tips

### Customizing Agents
Edit agent templates in `.claude/agents/` to:
- Adjust agent behavior
- Add project-specific patterns
- Modify completion criteria

### Updating Rules
Edit JSON files in `.claude/rules/` to:
- Add new standards
- Update forbidden patterns
- Adjust quality thresholds

### Hook Configuration
Modify hooks in `.claude/hooks/` to:
- Change agent recommendations
- Adjust checking commands
- Add project-specific checks

## Performance Optimization

### Parallel Agent Usage
- Spawn up to 3-4 agents in parallel
- Use parallel for: research, fixing, testing
- Use sequential for: implementation, review

### Context Management
- Agents share context through main thread
- Keep agent prompts focused
- Use orchestration patterns from `orchestration.md`

## Troubleshooting

### Agents Not Spawning
- Check CLAUDE.md is being read
- Verify agent templates exist
- Use explicit trigger phrases

### Hooks Not Running
- Verify hooks are executable
- Check settings.local.json configuration
- Ensure exit codes are correct (2 for blocking)

### Rules Not Applied
- Verify JSON syntax in rule files
- Check file paths in templates
- Ensure rules are referenced correctly

## Best Practices

1. **Always start with research agents** - Never skip exploration
2. **Trust the hooks** - They ensure quality
3. **Use parallel agents** - Maximize efficiency
4. **Follow orchestration patterns** - Proven workflows
5. **Keep templates focused** - One purpose per file

## Future Enhancements

Potential improvements:
- **Dynamic agent selection** based on file types
- **Learning system** for common patterns
- **Project-specific agent training**
- **Metrics tracking** for agent performance
- **Auto-generated documentation** from implementations

---

*This meta documentation helps you understand and customize the Laravel Claude Code setup. The modular architecture makes it easy to adapt to your specific needs while maintaining high quality standards.*