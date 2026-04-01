#!/usr/bin/env bash
# shell_example.sh
# Examples of using osx-ai-inloop from shell scripts.
# Requires: macOS 26+, Apple Intelligence enabled, osx-ai-inloop in PATH or current directory.
#
# Build the binary first:
#   swift build -c release
#   cp .build/release/osx-ai-inloop /usr/local/bin/osx-ai-inloop
#   # or set the path below:
#
# Usage:
#   chmod +x shell_example.sh
#   ./shell_example.sh

set -euo pipefail

# Path to the binary — adjust if needed
BINARY="${OSX_AI_INLOOP_PATH:-./osx-ai-inloop}"

# Check binary exists
if [[ ! -f "$BINARY" ]] && ! command -v osx-ai-inloop &>/dev/null; then
  echo "Error: osx-ai-inloop binary not found." >&2
  echo "Build it with: swift build -c release" >&2
  echo "Then: cp .build/release/osx-ai-inloop /usr/local/bin/osx-ai-inloop" >&2
  exit 1
fi

echo "=== Shell Examples for osx-ai-inloop ==="
echo

# ---------------------------------------------------------------------------
# Example 1: Pipe JSON prompt via stdin
# ---------------------------------------------------------------------------
echo "--- Example 1: Pipe JSON prompt via stdin ---"
echo '{"prompt":"Hello, explain what Swift is in one sentence"}' | "$BINARY"
echo

# ---------------------------------------------------------------------------
# Example 2: Direct CLI flags
# ---------------------------------------------------------------------------
echo "--- Example 2: Direct CLI flags ---"
"$BINARY" generate --prompt "Explain async/await in Swift in two sentences" --format text
echo

# ---------------------------------------------------------------------------
# Example 3: With system instruction
# ---------------------------------------------------------------------------
echo "--- Example 3: With system instruction ---"
"$BINARY" generate \
  --prompt "What is 2+2?" \
  --system "You are a helpful assistant. Always respond in exactly one word." \
  --format text
echo

# ---------------------------------------------------------------------------
# Example 4: Check environment
# ---------------------------------------------------------------------------
echo "--- Example 4: Environment check (human-readable) ---"
"$BINARY" check || true  # Don't fail if not fully compatible
echo

# ---------------------------------------------------------------------------
# Example 5: Environment check with JSON output
# ---------------------------------------------------------------------------
echo "--- Example 5: Environment check (JSON) ---"
"$BINARY" check --json || true
echo

# ---------------------------------------------------------------------------
# Example 6: Use with jq for JSON processing
# ---------------------------------------------------------------------------
if command -v jq &>/dev/null; then
  echo "--- Example 6: JSON processing with jq ---"

  # Extract just the output field
  output=$("$BINARY" generate --prompt "List 3 Swift features in a comma-separated list" --format json | jq -r '.output')
  echo "Swift features: $output"
  echo

  # Check if ok is true
  result=$("$BINARY" generate --prompt "Say hi" --format json)
  is_ok=$(echo "$result" | jq -r '.ok')
  model=$(echo "$result" | jq -r '.model')
  echo "ok=$is_ok, model=$model"
  echo
else
  echo "--- Example 6: jq not installed, skipping ---"
  echo
fi

# ---------------------------------------------------------------------------
# Example 7: List available models
# ---------------------------------------------------------------------------
echo "--- Example 7: List available models ---"
"$BINARY" models
echo

# ---------------------------------------------------------------------------
# Example 8: Show version
# ---------------------------------------------------------------------------
echo "--- Example 8: Show version ---"
"$BINARY" version
echo

# ---------------------------------------------------------------------------
# Example 9: Heredoc prompt
# ---------------------------------------------------------------------------
echo "--- Example 9: Heredoc prompt via stdin JSON ---"
json_request=$(cat <<'EOF'
{
  "prompt": "Describe the actor model in Swift concurrency in two sentences.",
  "system": "You are a Swift concurrency expert.",
  "model": "on-device",
  "format": "json"
}
EOF
)
echo "$json_request" | "$BINARY"
echo

# ---------------------------------------------------------------------------
# Example 10: Error handling in shell scripts
# ---------------------------------------------------------------------------
echo "--- Example 10: Error handling ---"
if "$BINARY" generate --prompt "Hello" --format json > /tmp/ai_output.json 2>/tmp/ai_errors.txt; then
  echo "Success! Output saved to /tmp/ai_output.json"
  if command -v jq &>/dev/null; then
    jq -r '.output' /tmp/ai_output.json
  fi
else
  exit_code=$?
  echo "Failed with exit code: $exit_code" >&2
  echo "Errors:" >&2
  cat /tmp/ai_errors.txt >&2

  # Check error JSON from stdout
  if [[ -s /tmp/ai_output.json ]]; then
    echo "Error response:" >&2
    cat /tmp/ai_output.json >&2
  fi
fi
echo

# ---------------------------------------------------------------------------
# Example 11: Process a file as input
# ---------------------------------------------------------------------------
echo "--- Example 11: Process a text file as prompt ---"
if [[ -f /tmp/sample_input.txt ]]; then
  prompt_text=$(cat /tmp/sample_input.txt)
  "$BINARY" generate --prompt "Summarize the following: $prompt_text" --format text
else
  echo "No sample file found at /tmp/sample_input.txt — skipping."
fi
echo

echo "=== All examples complete ==="
