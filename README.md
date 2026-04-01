# Apple Intelligence Inloop

![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-blue)
![Swift](https://img.shields.io/badge/swift-6.1-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Architecture](https://img.shields.io/badge/arch-Apple%20Silicon-lightgrey)

A Unix-friendly command-line wrapper for Apple's Foundation Models framework, designed for scripting, automation, and integration with any language that can spawn a subprocess.

---

## Description

**osx-ai-inloop** makes Apple's on-device language model (macOS 26+) accessible from shell scripts, Ruby, Python, JXA, or any tool that can read/write stdin/stdout. It follows the Unix philosophy: read from stdin, write to stdout, errors to stderr, signal success/failure via exit codes.

- **Privacy by default** — all inference happens on-device; no network calls, no telemetry
- **Free inference** — no API keys, no billing, no rate limits
- **JSON-first** — structured input/output for easy scripting
- **Scriptable** — designed for `Open3`, pipes, and subprocess patterns

---

## Requirements

| Requirement | Details |
|---|---|
| **macOS** | 26.0 or later (Tahoe) |
| **Hardware** | Apple Silicon (M-series chip required) |
| **Apple Intelligence** | Enabled in System Settings > Apple Intelligence & Siri |
| **Xcode** | 26.0 or later — **must build with Xcode 26** |
| **Swift** | 6.1 or later (included with Xcode 26) |

> **Why Xcode 26?** `FoundationModels` is a system framework that ships with the macOS 26 SDK inside Xcode 26. Building with any earlier Xcode/SDK means `canImport(FoundationModels)` evaluates to `false` at compile time and the binary silently falls back to a stub that always returns `UNSUPPORTED_ENVIRONMENT`. There is no Swift package to add — the framework is part of the OS and SDK.

---

## Quick Start (Pre-built Binary)

> **Architecture note:** The pre-built binary in `bin/osx-ai-inloop` is compiled for **Apple Silicon (arm64)** only. It will not run on Intel Macs. If you're on an Intel Mac, follow the [Build from Source](#build-from-source) instructions below.

If you're on an Apple Silicon Mac running macOS 26+ with Apple Intelligence enabled, you can skip the build step entirely:

```bash
git clone https://github.com/inloopstudio-team/apple-intelligence-inloop.git
cd apple-intelligence-inloop

# Make executable and run an environment check
chmod +x bin/osx-ai-inloop-arm64
./bin/osx-ai-inloop-arm64 check

# Try it
echo '{"prompt":"Explain Swift async/await in one sentence"}' | ./bin/osx-ai-inloop-arm64
```

To use it from anywhere, copy it to your PATH:

```bash
cp bin/osx-ai-inloop-arm64 /usr/local/bin/osx-ai-inloop
osx-ai-inloop check
```

---

## Installation

### 1. Install Xcode 26

Download **Xcode 26** (or later) from the [Apple Developer portal](https://developer.apple.com/xcode/) or via the Mac App Store. Xcode 16 and earlier will **not** produce a working binary.

Verify you are using the correct toolchain:

```bash
xcodebuild -version
# Xcode 26.x
# Build version ...

xcrun --sdk macosx --show-sdk-version
# 26.0
```

If you have multiple Xcode versions installed, select Xcode 26 with:

```bash
sudo xcode-select -s /Applications/Xcode-26.app/Contents/Developer
```

### 2. Enable Apple Intelligence

Open **System Settings > Apple Intelligence & Siri** and make sure Apple Intelligence is turned on and the model has finished downloading.

### 3. Build from Source {#build-from-source}

```bash
git clone https://github.com/inloopstudio-team/apple-intelligence-inloop.git
cd apple-intelligence-inloop
swift build -c release
cp .build/release/osx-ai-inloop /usr/local/bin/osx-ai-inloop
```

### 4. Verify Installation

```bash
osx-ai-inloop version
# osx-ai-inloop 0.1.0

osx-ai-inloop check
# All checks should show ✓ before using generate
```

---

## Quick Start

### Via stdin (JSON)

```bash
echo '{"prompt":"Explain Swift async/await in one sentence"}' | osx-ai-inloop
```

Response:
```json
{
  "model" : "on-device",
  "ok" : true,
  "output" : "Swift's async/await syntax lets you write asynchronous code that reads like synchronous code...",
  "usage" : {
    "duration_seconds" : 0.823
  }
}
```

### Via flags

```bash
osx-ai-inloop generate --prompt "What is an actor in Swift?" --format text
```

### Environment check

```bash
osx-ai-inloop check
```

---

## CLI Reference

### Global

```
osx-ai-inloop [subcommand] [options]
```

| Subcommand | Description |
|---|---|
| `generate` | Generate a response (default) |
| `check` | Run environment compatibility checks |
| `models` | List available model modes |
| `version` | Print the version number |

---

### `generate` — Default Command

```
osx-ai-inloop generate [options]
```

| Flag | Type | Default | Description |
|---|---|---|---|
| `--prompt <text>` | String | (stdin) | The prompt to send to the model |
| `--system <text>` | String | — | System instruction / persona |
| `--input <text>` | String | — | Additional input text, appended to prompt |
| `--model <name>` | String | `on-device` | Model mode: `on-device` or `auto` |
| `--format <fmt>` | String | `json` | Output format: `json` or `text` |
| `--stream` | Bool | false | Stream response tokens (experimental) |
| `--verbose` | Flag | false | Print diagnostic info to stderr |
| `--quiet` | Flag | false | Suppress all stderr output |

**Priority:** CLI flags > stdin JSON fields.

---

### `check` — Environment Check

```
osx-ai-inloop check [--json] [--quiet]
```

| Flag | Description |
|---|---|
| `--json` | Output machine-readable JSON to stdout |
| `--quiet` | Suppress informational messages |

---

### `models` — List Models

```
osx-ai-inloop models [--json]
```

---

### `version` — Version

```
osx-ai-inloop version [--json]
```

---

## JSON Request Contract

Send a JSON object to stdin. All fields are optional — combine with CLI flags as needed.

```json
{
  "prompt": "Your prompt text here",
  "system": "Optional system instruction / persona",
  "input": "Optional additional context or input text",
  "model": "on-device",
  "format": "json",
  "stream": false
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `prompt` | String | required | The main prompt text |
| `system` | String | — | System instruction for the model session |
| `input` | String | — | Additional input appended to prompt |
| `model` | String | `on-device` | Model mode |
| `format` | String | `json` | Output format (`json` or `text`) |
| `stream` | Bool | `false` | Whether to stream tokens |

**Note:** Plain text on stdin is treated as the prompt directly (no JSON wrapping needed).

---

## JSON Response Contract

### Success

```json
{
  "ok": true,
  "model": "on-device",
  "output": "The generated text response.",
  "usage": {
    "duration_seconds": 0.782,
    "prompt_tokens": null,
    "completion_tokens": null,
    "total_tokens": null
  },
  "warnings": null
}
```

| Field | Type | Description |
|---|---|---|
| `ok` | Bool | Always `true` for success |
| `model` | String | Model mode that was used |
| `output` | String | The generated text |
| `usage` | Object? | Optional timing and token metadata |
| `warnings` | [String]? | Optional generation warnings |

### Error

```json
{
  "ok": false,
  "error": {
    "code": "UNSUPPORTED_ENVIRONMENT",
    "message": "Apple Intelligence is not enabled. Go to System Settings > Apple Intelligence & Siri."
  }
}
```

| Field | Type | Description |
|---|---|---|
| `ok` | Bool | Always `false` for errors |
| `error.code` | String | Machine-readable error code |
| `error.message` | String | Human-readable error description |

---

## Model Selection

| Mode | Flag | Description |
|---|---|---|
| On-Device | `--model on-device` | Apple's ~3B parameter on-device model. No network. Privacy-preserving. (Default) |
| Auto | `--model auto` | Automatically selects the best available model (currently resolves to on-device). |

---

## Ruby Integration

Use `Open3` for bidirectional process communication:

```ruby
require 'open3'
require 'json'

# Via stdin JSON
request = { prompt: "Explain Swift closures", system: "Be concise." }.to_json
stdout, stderr, status = Open3.capture3("osx-ai-inloop", stdin_data: request)

if status.success?
  response = JSON.parse(stdout)
  puts response["output"] if response["ok"]
end

# Via CLI flags
stdout, stderr, status = Open3.capture3(
  "osx-ai-inloop", "generate",
  "--prompt", "What is SwiftUI?",
  "--format", "json"
)

# Environment check
stdout, _stderr, status = Open3.capture3("osx-ai-inloop", "check", "--json")
checks = JSON.parse(stdout)
abort "Not compatible!" unless checks["is_compatible"]
```

See `Examples/ruby_integration.rb` for full examples including batch processing and error handling.

---

## Shell Scripting

```bash
# Basic generation
echo '{"prompt":"Hello from shell"}' | osx-ai-inloop

# CLI flags
osx-ai-inloop generate --prompt "Explain actors" --format text

# With jq
osx-ai-inloop generate --prompt "List 3 Swift keywords" --format json \
  | jq -r '.output'

# Environment check
osx-ai-inloop check

# Check exit code
if osx-ai-inloop generate --prompt "Hello" --format json > output.json; then
  cat output.json | jq -r '.output'
else
  echo "Failed with exit code $?"
fi
```

See `Examples/shell_example.sh` for complete shell scripting examples.

---

## JXA (JavaScript for Automation)

```javascript
// Run via: osascript -l JavaScript jxa_example.js
const app = Application.currentApplication();
app.includeStandardAdditions = true;

const request = JSON.stringify({ prompt: "Hello from JXA", model: "on-device" });
const escaped = request.replace(/'/g, "'\\''");
const rawOutput = app.doShellScript(`echo '${escaped}' | /usr/local/bin/osx-ai-inloop`);
const response = JSON.parse(rawOutput);

if (response.ok) {
  app.displayDialog(response.output, { withTitle: "Apple Intelligence" });
}
```

See `Examples/jxa_example.js` for full JXA examples including notifications and batch processing.

---

## Environment Checks

Run `osx-ai-inloop check` to verify your setup:

```
Running environment checks...

  ✓ Operating System          Running on macOS.
  ✓ macOS Version             macOS 26.0.0 — compatible.
  ✓ Apple Silicon             Apple Silicon (arm64) detected.
  ✓ FoundationModels Framework  FoundationModels framework is available.
  ✓ Apple Intelligence        Apple Intelligence is available and ready. Context window: 4096 tokens.

  Result: COMPATIBLE — Apple Intelligence is ready to use.
```

Machine-readable JSON:
```bash
osx-ai-inloop check --json | jq '.is_compatible'
```

---

## Exit Codes

| Code | Name | When |
|---|---|---|
| `0` | Success | Command completed successfully |
| `1` | Invalid Arguments | Missing or invalid CLI flags |
| `2` | Unsupported Environment | Wrong OS, wrong arch, framework missing |
| `3` | Unavailable Model | Apple Intelligence not enabled, model not downloaded |
| `4` | Generation Failure | Model failed to generate (content policy, overflow, etc.) |
| `5` | Internal Error | Unexpected error |

---

## Security & Privacy

- **No telemetry** — osx-ai-inloop never phones home
- **No network calls** — all `on-device` inference stays on your Mac
- **No data storage** — prompts and responses are not persisted
- **Local process** — runs entirely within your user session
- **Foundation Models privacy** — governed by Apple's on-device model privacy guarantees
- **No API keys** — no credentials to manage or leak

---

## Architecture

```
osx-ai-inloop
├── CLI Layer (ArgumentParser)
│   ├── GenerateCommand  — parse flags, read stdin, call engine
│   ├── CheckCommand     — run preflight, report results
│   ├── ModelsCommand    — list model modes and status
│   └── VersionCommand   — print version
│
├── Engine Layer
│   ├── ModelEngineProtocol  — abstract interface
│   ├── FoundationModelEngine  — real Apple FoundationModels impl
│   └── MockModelEngine        — configurable mock for testing
│
├── Preflight Layer
│   ├── EnvironmentChecker  — run all system checks
│   └── PreflightResult     — structured result with JSON/text output
│
├── Models
│   ├── RequestPayload   — stdin JSON request schema
│   ├── ResponsePayload  — stdout JSON response schema
│   └── ModelMode        — typed model selection enum
│
└── Utilities
    ├── StdIO     — stdout/stderr/stdin helpers
    └── ExitCodes — typed exit code enum
```

The `#if canImport(FoundationModels)` guard in `FoundationModelEngine.swift` allows the package to compile and run tests on macOS versions that don't have the FoundationModels framework — it falls back to a stub that throws `GenerationEngineError.frameworkUnavailable`.

---

## Testing

```bash
swift test
```

Tests cover:
- Argument parsing and model mode validation
- Request payload JSON decoding (minimal, full, partial, invalid)
- Response payload JSON encoding (success, error, all factories)
- Preflight result formatting (JSON and human-readable)
- Exit code values and properties
- Mock engine behavior (responses, errors, call tracking, reset)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting issues, pull requests, and code style.

---

## License

MIT — see [LICENSE](LICENSE).

---

## Author

**Abhishek Parolkar**
