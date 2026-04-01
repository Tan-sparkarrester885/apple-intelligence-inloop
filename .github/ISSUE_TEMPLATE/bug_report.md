---
name: Bug Report
about: Report a bug or unexpected behavior in osx-ai-inloop
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

<!-- A clear and concise description of the bug. -->

## Environment

Please run `osx-ai-inloop check --json` and paste the output:

```json
<!-- Paste check output here -->
```

And run `sw_vers` and paste the output:

```
<!-- Paste sw_vers output here -->
```

| Field | Value |
|---|---|
| osx-ai-inloop version | <!-- e.g. 0.1.0 (run: osx-ai-inloop version) --> |
| macOS version | <!-- e.g. 26.0 --> |
| Mac model | <!-- e.g. MacBook Pro M3 Pro --> |
| Apple Intelligence enabled | <!-- Yes / No --> |
| Built from source / release | <!-- e.g. built from source, commit abc1234 --> |

## Steps to Reproduce

1. <!-- Step 1 -->
2. <!-- Step 2 -->
3. <!-- Step 3... -->

## Minimal Reproducible Example

<!-- The exact command or code that triggers the bug: -->

```bash
# Command:
echo '{"prompt":"..."}' | osx-ai-inloop

# Or:
osx-ai-inloop generate --prompt "..." --format json
```

## Expected Behavior

<!-- What you expected to happen. -->

## Actual Behavior

<!-- What actually happened. Include the full stdout, stderr, and exit code. -->

**stdout:**
```
<!-- Paste stdout here -->
```

**stderr:**
```
<!-- Paste stderr here -->
```

**Exit code:** <!-- e.g. 4 -->

## Additional Context

<!-- Any other relevant information: logs, screenshots, related issues, etc. -->
