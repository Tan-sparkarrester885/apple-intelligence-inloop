---
name: Feature Request
about: Suggest a new feature or improvement for osx-ai-inloop
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Feature Description

<!-- A clear and concise description of the feature you're requesting. -->

## Problem / Motivation

<!-- What problem does this solve? What use case does it enable?
     Example: "I want to use osx-ai-inloop in Python via subprocess but currently there is no..."
-->

## Proposed Solution

<!-- Describe the solution you'd like. Be specific about:
     - New CLI flags or subcommands
     - New JSON request/response fields
     - Changes to existing behavior
-->

### Proposed API / CLI Example

```bash
# Example of how the feature would be used:
osx-ai-inloop generate --prompt "..." --new-flag value
```

```json
// Example JSON request with new fields:
{
  "prompt": "...",
  "new_field": "value"
}
```

```json
// Example JSON response with new fields:
{
  "ok": true,
  "model": "on-device",
  "output": "...",
  "new_response_field": "value"
}
```

## Alternatives Considered

<!-- Have you considered any alternative approaches or workarounds? -->

## Use Case

<!-- Describe a concrete real-world use case. Who would use this feature and how?
     Example: "Ruby automation scripts that need to process streaming output token by token."
-->

## Additional Context

<!-- Any other context, references, or screenshots. If this is related to a macOS Foundation Models API feature, link to the relevant documentation. -->

## Checklist

- [ ] I have searched existing issues and discussions for this feature
- [ ] This feature is consistent with the Unix-philosophy design of the project
- [ ] I am willing to submit a PR for this feature (optional)
