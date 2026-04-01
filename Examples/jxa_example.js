// jxa_example.js
// JXA (JavaScript for Automation) examples for using osx-ai-inloop from macOS automation.
//
// Run via:
//   osascript -l JavaScript jxa_example.js
//
// Or in Script Editor: Language -> JavaScript
//
// Requirements:
//   - macOS 26+
//   - Apple Intelligence enabled
//   - osx-ai-inloop binary installed at /usr/local/bin/osx-ai-inloop
//     (or adjust BINARY_PATH below)
//
// Note: JXA's doShellScript captures stdout and returns it. stderr is discarded.

"use strict";

const BINARY_PATH = "/usr/local/bin/osx-ai-inloop";
const app = Application.currentApplication();
app.includeStandardAdditions = true;

/**
 * Run osx-ai-inloop with a JSON request via stdin.
 * Returns the parsed response object, or throws on error.
 */
function runWithJSON(request) {
  const jsonInput = JSON.stringify(request);
  // Escape single quotes in the JSON for shell safety
  const escaped = jsonInput.replace(/'/g, "'\\''");
  const command = `echo '${escaped}' | ${BINARY_PATH}`;
  const rawOutput = app.doShellScript(command);
  return JSON.parse(rawOutput);
}

/**
 * Run osx-ai-inloop with CLI flags.
 * Returns the raw stdout string.
 */
function runWithFlags(flags) {
  const flagStr = flags.map(f => {
    // Quote arguments that contain spaces
    return f.includes(" ") ? `'${f.replace(/'/g, "'\\''")}'` : f;
  }).join(" ");
  const command = `${BINARY_PATH} ${flagStr}`;
  return app.doShellScript(command);
}

// ---------------------------------------------------------------------------
// Example 1: Simple prompt via stdin JSON
// ---------------------------------------------------------------------------
console.log("=== Example 1: Simple prompt ===");
try {
  const response = runWithJSON({
    prompt: "Hello from JXA! What is Swift in one sentence?",
    model: "on-device"
  });

  if (response.ok) {
    console.log("Output: " + response.output);
    console.log("Model: " + response.model);
  } else {
    console.log("Error: " + response.error.code + ": " + response.error.message);
  }
} catch (e) {
  console.log("Exception: " + e.message);
}

// ---------------------------------------------------------------------------
// Example 2: With system instruction
// ---------------------------------------------------------------------------
console.log("\n=== Example 2: With system instruction ===");
try {
  const response = runWithJSON({
    prompt: "Explain closures briefly.",
    system: "You are a Swift tutor. Always be concise. Use at most 2 sentences.",
    model: "on-device",
    format: "json"
  });

  if (response.ok) {
    console.log("Output: " + response.output);
  }
} catch (e) {
  console.log("Exception: " + e.message);
}

// ---------------------------------------------------------------------------
// Example 3: Text format output
// ---------------------------------------------------------------------------
console.log("\n=== Example 3: Text format ===");
try {
  const result = runWithFlags([
    "generate",
    "--prompt", "Say hello in exactly three words.",
    "--format", "text"
  ]);
  console.log("Output: " + result.trim());
} catch (e) {
  console.log("Exception: " + e.message);
}

// ---------------------------------------------------------------------------
// Example 4: Environment check
// ---------------------------------------------------------------------------
console.log("\n=== Example 4: Environment check ===");
try {
  const checkOutput = runWithFlags(["check", "--json"]);
  const checks = JSON.parse(checkOutput);
  console.log("Compatible: " + checks.is_compatible);
  console.log("Summary: " + checks.summary);
} catch (e) {
  console.log("Exception: " + e.message);
}

// ---------------------------------------------------------------------------
// Example 5: macOS Notification with AI response
// ---------------------------------------------------------------------------
console.log("\n=== Example 5: macOS Notification ===");
try {
  const response = runWithJSON({
    prompt: "Write a friendly greeting for a macOS notification. Keep it under 10 words.",
    model: "on-device"
  });

  if (response.ok) {
    app.displayNotification(response.output, {
      withTitle: "Apple Intelligence",
      subtitle: "osx-ai-inloop"
    });
    console.log("Notification sent: " + response.output);
  }
} catch (e) {
  console.log("Exception (notification skipped): " + e.message);
}

// ---------------------------------------------------------------------------
// Example 6: Build an automation pipeline
// ---------------------------------------------------------------------------
console.log("\n=== Example 6: Automation pipeline ===");

/**
 * Process a list of items with AI, returning results.
 */
function batchProcess(items, systemPrompt) {
  return items.map(item => {
    try {
      const response = runWithJSON({
        prompt: item,
        system: systemPrompt,
        model: "on-device"
      });
      return response.ok ? response.output : `Error: ${response.error.message}`;
    } catch (e) {
      return `Exception: ${e.message}`;
    }
  });
}

const questions = [
  "What is a struct in Swift?",
  "What is a class in Swift?"
];

const answers = batchProcess(questions, "Answer in one sentence.");
questions.forEach((q, i) => {
  console.log(`Q: ${q}`);
  console.log(`A: ${answers[i]}`);
  console.log();
});

// ---------------------------------------------------------------------------
// Example 7: Version check
// ---------------------------------------------------------------------------
console.log("=== Example 7: Version ===");
try {
  const versionOutput = runWithFlags(["version"]);
  console.log(versionOutput.trim());
} catch (e) {
  console.log("Exception: " + e.message);
}
