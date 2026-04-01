// GenerateCommand.swift
// The primary generation command for osx-ai-inloop.
// Accepts prompts via --prompt flag or stdin (JSON or plain text).
// Outputs results to stdout as JSON (default) or plain text.

import ArgumentParser
import Foundation

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate a response using Apple's on-device language model.",
        discussion: """
        Reads a prompt from --prompt flag or from stdin. If stdin contains JSON, it will be
        parsed as a RequestPayload (CLI flags take precedence over JSON fields).
        Plain text on stdin is treated as the prompt directly.

        OUTPUT FORMATS:
          json  (default) — Structured JSON response: { ok, model, output, usage, warnings }
          text            — Raw output text only, suitable for piping

        EXAMPLES:
          osx-ai-inloop generate --prompt "Explain closures in Swift"
          echo "What is a monad?" | osx-ai-inloop generate --format text
          echo '{"prompt":"Hello","system":"Be concise"}' | osx-ai-inloop
        """
    )

    // MARK: - Options

    @Option(name: .long, help: "The prompt text to send to the model.")
    var prompt: String?

    @Option(name: .long, help: "System instruction / persona for the model session.")
    var system: String?

    @Option(name: .long, help: "Additional input text appended to the prompt.")
    var input: String?

    @Option(name: .long, help: "Model mode to use: on-device (default) or auto.")
    var model: String = "on-device"

    @Option(name: .long, help: "Output format: json (default) or text.")
    var format: String = "json"

    @Flag(name: .long, help: "Stream the response token by token (not yet fully supported).")
    var stream: Bool = false

    @Flag(name: .long, help: "Enable verbose diagnostic output on stderr.")
    var verbose: Bool = false

    @Flag(name: .long, help: "Suppress all stderr output.")
    var quiet: Bool = false

    // MARK: - Run

    func run() async throws {
        // Step 1: Read stdin if available
        let stdinContent = readStdin()

        // Step 2: Build the effective request by merging stdin + CLI flags
        let request = try buildRequest(stdinContent: stdinContent)

        // Step 3: Validate the request
        guard let effectivePrompt = request.prompt, !effectivePrompt.isEmpty else {
            let errorResp = ErrorResponse.make(
                code: "INVALID_ARGUMENTS",
                message: "No prompt provided. Use --prompt <text> or pipe input via stdin."
            )
            outputError(errorResp, format: format)
            throw ExitCode(rawValue: AppExitCode.invalidArguments.rawValue)
        }

        // Step 4: Validate model mode
        let modelMode: ModelMode
        do {
            modelMode = try ModelMode.validate(request.model ?? model)
        } catch {
            let errorResp = ErrorResponse.make(
                code: "INVALID_ARGUMENTS",
                message: "Unknown model '\(request.model ?? model)'. Valid options: on-device, auto."
            )
            outputError(errorResp, format: format)
            throw ExitCode(rawValue: AppExitCode.invalidArguments.rawValue)
        }

        // Step 5: Validate output format
        let outputFormat = OutputFormat(rawValue: request.format ?? format) ?? .json
        if verbose && !quiet {
            writeStderr("[verbose] model=\(modelMode.rawValue) format=\(outputFormat.rawValue) stream=\(request.stream ?? stream)")
        }

        // Step 6: Run preflight checks
        if verbose && !quiet {
            writeStderr("[verbose] Running preflight checks...")
        }
        let preflight = await EnvironmentChecker.run()
        if !preflight.isCompatible {
            let failedChecks = preflight.checks.filter { !$0.passed }.map { "\($0.name): \($0.message)" }.joined(separator: "; ")
            let errorResp = ErrorResponse.make(
                code: "UNSUPPORTED_ENVIRONMENT",
                message: "Environment is not compatible: \(failedChecks)"
            )
            outputError(errorResp, format: outputFormat.rawValue)
            if !quiet {
                writeStderr("[error] Preflight failed: \(failedChecks)")
            }
            throw ExitCode(rawValue: AppExitCode.unsupportedEnvironment.rawValue)
        }

        // Step 7: Create engine and generate response
        let engine = FoundationModelEngine()
        let systemInstruction: String? = {
            if let sys = request.system, !sys.isEmpty { return sys }
            if let sys = system, !sys.isEmpty { return sys }
            return nil
        }()
        let inputText: String? = {
            if let inp = request.input, !inp.isEmpty { return inp }
            if let inp = input, !inp.isEmpty { return inp }
            return nil
        }()

        let options = GenerationOptions()

        if verbose && !quiet {
            writeStderr("[verbose] Calling model engine...")
        }

        do {
            let result = try await engine.generate(
                prompt: effectivePrompt,
                systemInstruction: systemInstruction,
                inputText: inputText,
                options: options
            )

            // Step 8: Output response
            let successResp = SuccessResponse(
                ok: true,
                model: result.model,
                output: result.output,
                usage: result.usage,
                warnings: nil
            )

            switch outputFormat {
            case .json:
                writeJSONStdout(successResp)
            case .text:
                writeStdout(result.output)
            }

        } catch let genError as GenerationEngineError {
            let (code, message) = genError.toExitInfo()
            let errorResp = ErrorResponse.make(code: code, message: message)
            outputError(errorResp, format: outputFormat.rawValue)
            if !quiet {
                writeStderr("[error] Generation failed: \(message)")
            }
            throw ExitCode(rawValue: genError.exitCode.rawValue)
        } catch {
            let errorResp = ErrorResponse.make(
                code: "GENERATION_FAILURE",
                message: error.localizedDescription
            )
            outputError(errorResp, format: outputFormat.rawValue)
            if !quiet {
                writeStderr("[error] \(error.localizedDescription)")
            }
            throw ExitCode(rawValue: AppExitCode.generationFailure.rawValue)
        }
    }

    // MARK: - Private Helpers

    /// Build a merged RequestPayload from stdin content and CLI flags.
    /// CLI flags take precedence over JSON fields from stdin.
    private func buildRequest(stdinContent: String?) throws -> RequestPayload {
        var base = RequestPayload(
            prompt: prompt,
            system: system,
            input: input,
            model: model,
            format: format,
            stream: stream
        )

        guard let stdin = stdinContent, !stdin.isEmpty else {
            return base
        }

        let trimmed = stdin.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if stdin looks like JSON
        if trimmed.hasPrefix("{") {
            if let data = trimmed.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(RequestPayload.self, from: data) {
                // Merge: CLI flags override JSON fields
                base.prompt = prompt ?? decoded.prompt
                base.system = system ?? decoded.system
                base.input = input ?? decoded.input
                base.model = (model != "on-device") ? model : (decoded.model ?? model)
                base.format = (format != "json") ? format : (decoded.format ?? format)
                base.stream = stream || (decoded.stream ?? false)
                return base
            }
            // If JSON parse fails, treat as plain text
        }

        // Plain text on stdin becomes the prompt (if not overridden by --prompt flag)
        if prompt == nil {
            base.prompt = trimmed
        }
        return base
    }

    /// Output an error response to stdout and/or stderr.
    private func outputError(_ errorResp: ErrorResponse, format: String) {
        if format == "text" {
            writeStderr("[error] \(errorResp.error.code): \(errorResp.error.message)")
        } else {
            writeJSONStdout(errorResp)
        }
    }
}

/// Output format for the generate command.
enum OutputFormat: String {
    case json
    case text
}
