#!/usr/bin/env ruby
# ruby_integration.rb
# Examples of using osx-ai-inloop from Ruby via Open3.
# Requires: macOS 26+, Apple Intelligence enabled, osx-ai-inloop built and accessible.
#
# Build the binary first:
#   swift build -c release
#   cp .build/release/osx-ai-inloop /usr/local/bin/osx-ai-inloop
#
# Usage:
#   ruby ruby_integration.rb

require 'open3'
require 'json'

BINARY = ENV.fetch('OSX_AI_INLOOP_PATH', './osx-ai-inloop')

# ---------------------------------------------------------------------------
# Example 1: Simple prompt via stdin JSON
# ---------------------------------------------------------------------------
puts "=== Example 1: Simple prompt via stdin JSON ==="

request = { prompt: "Summarize the key features of Swift concurrency in 3 bullet points" }.to_json

stdout, stderr, status = Open3.capture3(BINARY, stdin_data: request)

if status.success?
  response = JSON.parse(stdout)
  if response["ok"]
    puts "Output: #{response["output"]}"
    puts "Model: #{response["model"]}"
    if (usage = response["usage"])
      puts "Duration: #{usage["duration_seconds"]&.round(3)}s"
    end
  else
    $stderr.puts "Error: #{response.dig("error", "code")}: #{response.dig("error", "message")}"
    exit 1
  end
else
  $stderr.puts "Process error (exit #{status.exitstatus}): #{stderr}"
  exit 1
end

puts

# ---------------------------------------------------------------------------
# Example 2: Using CLI flags for generate command
# ---------------------------------------------------------------------------
puts "=== Example 2: Using CLI flags ==="

stdout, stderr, status = Open3.capture3(
  BINARY, "generate",
  "--model", "on-device",
  "--prompt", "What is Swift? Answer in one sentence.",
  "--format", "json"
)

if status.success?
  response = JSON.parse(stdout)
  puts "Output: #{response["output"]}" if response["ok"]
else
  $stderr.puts "Error (exit #{status.exitstatus}): #{stderr}"
end

puts

# ---------------------------------------------------------------------------
# Example 3: System instruction + prompt
# ---------------------------------------------------------------------------
puts "=== Example 3: With system instruction ==="

request = {
  prompt: "What is the capital of France?",
  system: "You are a geography tutor. Always answer in exactly one sentence.",
  model: "on-device",
  format: "json"
}.to_json

stdout, stderr, status = Open3.capture3(BINARY, stdin_data: request)

if status.success?
  response = JSON.parse(stdout)
  puts "Output: #{response["output"]}" if response["ok"]
else
  $stderr.puts "Error: #{stderr}"
end

puts

# ---------------------------------------------------------------------------
# Example 4: Plain text output format
# ---------------------------------------------------------------------------
puts "=== Example 4: Plain text output format ==="

stdout, stderr, status = Open3.capture3(
  BINARY, "generate",
  "--prompt", "Say hello in exactly three words.",
  "--format", "text"
)

if status.success?
  puts "Output (text mode): #{stdout.strip}"
else
  $stderr.puts "Error (exit #{status.exitstatus}): #{stderr}"
end

puts

# ---------------------------------------------------------------------------
# Example 5: Environment check (machine-readable)
# ---------------------------------------------------------------------------
puts "=== Example 5: Environment check ==="

stdout, stderr, status = Open3.capture3(BINARY, "check", "--json")

begin
  checks = JSON.parse(stdout)
  puts "Compatible: #{checks["is_compatible"]}"
  puts "Summary: #{checks["summary"]}"
  puts "Checks:"
  checks["checks"].each do |check|
    icon = check["passed"] ? "✓" : "✗"
    puts "  #{icon} #{check["name"]}: #{check["message"]}"
  end
rescue JSON::ParserError => e
  $stderr.puts "Could not parse check output: #{e.message}"
  $stderr.puts "Stderr: #{stderr}"
end

puts

# ---------------------------------------------------------------------------
# Example 6: Batch processing multiple prompts
# ---------------------------------------------------------------------------
puts "=== Example 6: Batch processing ==="

prompts = [
  "Define polymorphism in one sentence.",
  "Define encapsulation in one sentence.",
  "Define inheritance in one sentence."
]

results = prompts.map do |prompt|
  request = { prompt: prompt, model: "on-device" }.to_json
  stdout, _stderr, status = Open3.capture3(BINARY, stdin_data: request)
  if status.success?
    response = JSON.parse(stdout)
    response["ok"] ? response["output"] : "Error: #{response.dig("error", "message")}"
  else
    "Process failed (exit #{status.exitstatus})"
  end
end

results.each_with_index do |result, i|
  puts "Q#{i + 1}: #{prompts[i]}"
  puts "A#{i + 1}: #{result}"
  puts
end

# ---------------------------------------------------------------------------
# Example 7: Error handling — missing prompt
# ---------------------------------------------------------------------------
puts "=== Example 7: Error handling ==="

stdout, stderr, status = Open3.capture3(BINARY, "generate", "--format", "json")

unless status.success?
  begin
    error_response = JSON.parse(stdout)
    puts "Caught error: #{error_response.dig("error", "code")}: #{error_response.dig("error", "message")}"
    puts "Exit code: #{status.exitstatus}"
  rescue JSON::ParserError
    puts "Non-JSON error output: #{stderr.strip}"
  end
end

# ---------------------------------------------------------------------------
# Example 8: Version check
# ---------------------------------------------------------------------------
puts
puts "=== Example 8: Version check ==="

stdout, _stderr, status = Open3.capture3(BINARY, "version")
puts "Version: #{stdout.strip}" if status.success?
