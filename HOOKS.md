# Laravel Claude Code Hooks

## Overview

This project now includes automated quality control hooks that run after file edits in Claude Code.

## Hook Features

### 1. **Simplified Laravel-specific hooks**
- `lint.sh` - Runs only Laravel linting commands
- `test.sh` - Runs only `composer test`
- No multi-language support or complex configuration
- Clean, minimal implementation

### 2. **Project-local installation**
- Hooks are copied to `.claude/hooks/` in each project
- Settings configured in `.claude/settings.local.json`
- No global configuration needed

### 3. **Automatic execution**
- Hooks run after Write, Edit, or MultiEdit operations
- Exit code 2 blocks Claude and shows messages
- Clear error messages guide developers

## Installation

The hooks are automatically installed when you run:
```bash
curl -fsSL https://raw.githubusercontent.com/neverything/laravel-claude-code-setup/main/install.sh | bash
```

## Required Composer Scripts

For the hooks to work properly, your Laravel project's `composer.json` should have:

```json
{
  "scripts": {
    "refactor": "vendor/bin/rector && vendor/bin/pint",
    "lint": "vendor/bin/phpstan analyse", 
    "test": "vendor/bin/pest --parallel"
  }
}
```

## Hook Behavior

### lint.sh
1. Checks if in Laravel project (artisan + composer.json)
2. Runs `composer refactor` (Rector + Pint)
3. Runs `composer lint` (PHPStan/Larastan)
4. Shows summary of any errors
5. Exits with code 2 (always) to show continuation message

### test.sh
1. Checks if in Laravel project
2. Checks if `composer test` script exists
3. Runs `composer test`
4. Exits with code 2 on failure or to show continuation message

## Customization

To customize the hooks for your project:
1. Edit `.claude/hooks/lint.sh` or `.claude/hooks/test.sh`
2. Modify commands as needed
3. Keep exit code 2 for proper Claude Code integration

## Troubleshooting

If hooks aren't running:
1. Check `.claude/settings.local.json` exists
2. Verify hooks are executable: `chmod +x .claude/hooks/*.sh`
3. Test manually: `.claude/hooks/lint.sh`

## Architecture Decision

We chose project-local hooks over global hooks because:
- Each Laravel project may have different linting/testing requirements
- Easier to customize per project
- No conflicts between projects
- Simpler installation and maintenance