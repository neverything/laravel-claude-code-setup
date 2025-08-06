# 🎭 Agent Orchestration Guide

## Agent Capabilities Matrix

| Agent Type | Parallel | Primary Use | When to Spawn |
|------------|----------|-------------|---------------|
| `fix-agent` | ✅ Yes | Fix linting/test issues | After any code changes or failed checks |
| `research-agent` | ✅ Yes | Explore codebase | Before any implementation |
| `implementation-agent` | ❌ No | Write features | After research completes |
| `test-agent` | ✅ Yes | Write tests | Alongside implementation |
| `refactor-agent` | ✅ Yes | Improve code | After features work |
| `review-agent` | ❌ No | Quality check | Before marking complete |

## Orchestration Patterns

### Pattern 1: Feature Development
```
1. Spawn research-agent → Understand codebase
2. Main thread → Create implementation plan
3. Spawn implementation-agent → Build feature
4. Spawn test-agent (parallel) → Write tests
5. Spawn fix-agent → Clean up any issues
6. Spawn review-agent → Final quality check
```

### Pattern 2: Bug Fixing
```
1. Spawn research-agent → Find root cause
2. Spawn fix-agent → Resolve issue
3. Spawn test-agent → Add regression tests
4. Spawn review-agent → Verify fix quality
```

### Pattern 3: Refactoring
```
1. Spawn test-agent → Ensure test coverage
2. Spawn refactor-agent → Improve code
3. Spawn fix-agent → Handle any issues
4. Spawn review-agent → Validate changes
```

### Pattern 4: Quality Check
```
1. Spawn multiple fix-agents → Fix different file groups
   - Agent 1: Fix PHP files
   - Agent 2: Fix JavaScript files
   - Agent 3: Fix test failures
2. Main thread → Coordinate results
3. Spawn review-agent → Final validation
```

## Agent Communication

### Triggering Agents

Use these phrases to spawn agents:

- **Research**: "I'll spawn a research agent to explore the codebase"
- **Fix**: "I'll spawn fix agents to resolve all issues in parallel"
- **Implementation**: "I'll delegate implementation to a specialist agent"
- **Test**: "I'll spawn a test agent to write comprehensive tests"
- **Refactor**: "I'll spawn a refactor agent to modernize this code"
- **Review**: "I'll spawn a review agent for quality assurance"

### Agent Coordination

```xml
<agent-spawn parallel="true">
  <agent type="research" focus="database-schema" />
  <agent type="research" focus="api-endpoints" />
  <agent type="research" focus="frontend-components" />
</agent-spawn>

<agent-wait>
  <!-- Wait for all research agents to complete -->
</agent-wait>

<agent-spawn parallel="false">
  <agent type="implementation" task="build-feature" />
</agent-spawn>
```

## Efficiency Guidelines

### Parallel Execution
**DO spawn in parallel:**
- Multiple fix agents for different files
- Research agents for different areas
- Test agents for different features

**DON'T spawn in parallel:**
- Implementation agents (maintain consistency)
- Review agents (need complete context)

### Agent Specialization
- Don't use general-purpose for specific tasks
- Use the right specialist for each job
- Combine agents for complex tasks

### Resource Optimization
- Limit parallel agents to 3-4 for performance
- Sequential for critical path items
- Batch similar tasks together

## Error Recovery

### When Agents Fail

1. **Fix Agent Fails**
   - Spawn a research agent to understand the issue
   - Try manual fix in main thread
   - Spawn another fix agent with more context

2. **Test Agent Fails**
   - Check if implementation is complete
   - Verify test environment setup
   - Try writing simpler tests first

3. **Implementation Agent Fails**
   - Ensure research was thorough
   - Break down into smaller tasks
   - Try incremental implementation

## Success Metrics

### Agent Performance Indicators
- ✅ Fix agents: All checks green
- ✅ Research agents: Complete understanding
- ✅ Implementation agents: Feature works
- ✅ Test agents: Coverage achieved
- ✅ Refactor agents: Code improved
- ✅ Review agents: Quality assured

## Best Practices

1. **Always research first** - Never skip exploration
2. **Fix immediately** - Don't accumulate technical debt
3. **Test in parallel** - Write tests alongside code
4. **Review before complete** - Quality gate everything
5. **Document decisions** - Help future agents

## Agent Chaining

For complex workflows, chain agents:

```
research-agent → implementation-agent → test-agent → fix-agent → review-agent
     ↓                                      ↓            ↓            ↓
  [context]                              [tests]     [clean]     [approved]
```

Each agent passes context to the next for seamless execution.