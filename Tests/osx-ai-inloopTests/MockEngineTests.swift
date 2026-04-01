// MockEngineTests.swift
// Tests for MockModelEngine behavior.

import Testing
import Foundation
@testable import osx_ai_inloop

@Suite("Mock Engine Tests")
struct MockEngineTests {

    // MARK: - Basic Response

    @Test("MockModelEngine returns fixed response")
    func testFixedResponse() async throws {
        let engine = MockModelEngine(fixedResponse: "Hello from mock!")
        let result = try await engine.generate(
            prompt: "test",
            systemInstruction: nil,
            inputText: nil,
            options: nil
        )
        #expect(result.output == "Hello from mock!")
    }

    @Test("MockModelEngine returns configured model name")
    func testModelName() async throws {
        let engine = MockModelEngine(fixedResponse: "response", modelName: "test-model")
        let result = try await engine.generate(
            prompt: "test",
            systemInstruction: nil,
            inputText: nil,
            options: nil
        )
        #expect(result.model == "test-model")
    }

    @Test("MockModelEngine default response is non-empty")
    func testDefaultResponse() async throws {
        let engine = MockModelEngine()
        let result = try await engine.generate(
            prompt: "anything",
            systemInstruction: nil,
            inputText: nil,
            options: nil
        )
        #expect(!result.output.isEmpty)
    }

    // MARK: - Error Cases

    @Test("MockModelEngine throws configured error")
    func testThrowsConfiguredError() async throws {
        let expectedError = GenerationEngineError.generationFailed(underlying: "mock fail")
        let engine = MockModelEngine(errorToThrow: expectedError)

        await #expect(throws: GenerationEngineError.self) {
            _ = try await engine.generate(
                prompt: "test",
                systemInstruction: nil,
                inputText: nil,
                options: nil
            )
        }
    }

    @Test("MockModelEngine.failing() throws generationFailed error")
    func testFailingPreset() async throws {
        let engine = MockModelEngine.failing(reason: "Context too long")

        do {
            _ = try await engine.generate(prompt: "test", systemInstruction: nil, inputText: nil, options: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as GenerationEngineError {
            if case .generationFailed(let underlying) = error {
                #expect(underlying == "Context too long")
            } else {
                Issue.record("Expected generationFailed error")
            }
        }
    }

    @Test("MockModelEngine.unavailable() throws modelUnavailable error")
    func testUnavailablePreset() async throws {
        let engine = MockModelEngine.unavailable(reason: "Model not ready")

        do {
            _ = try await engine.generate(prompt: "test", systemInstruction: nil, inputText: nil, options: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as GenerationEngineError {
            if case .modelUnavailable(let reason) = error {
                #expect(reason == "Model not ready")
            } else {
                Issue.record("Expected modelUnavailable error")
            }
        }
    }

    // MARK: - Call Tracking

    @Test("MockModelEngine tracks call count")
    func testCallCount() async throws {
        let engine = MockModelEngine()

        #expect(engine.callCount == 0)

        _ = try await engine.generate(prompt: "first", systemInstruction: nil, inputText: nil, options: nil)
        #expect(engine.callCount == 1)

        _ = try await engine.generate(prompt: "second", systemInstruction: nil, inputText: nil, options: nil)
        #expect(engine.callCount == 2)
    }

    @Test("MockModelEngine tracks last prompt")
    func testLastPrompt() async throws {
        let engine = MockModelEngine()

        _ = try await engine.generate(prompt: "first prompt", systemInstruction: nil, inputText: nil, options: nil)
        #expect(engine.lastPrompt == "first prompt")

        _ = try await engine.generate(prompt: "second prompt", systemInstruction: nil, inputText: nil, options: nil)
        #expect(engine.lastPrompt == "second prompt")
    }

    @Test("MockModelEngine tracks last system instruction")
    func testLastSystemInstruction() async throws {
        let engine = MockModelEngine()
        _ = try await engine.generate(
            prompt: "prompt",
            systemInstruction: "Be concise.",
            inputText: nil,
            options: nil
        )
        #expect(engine.lastSystemInstruction == "Be concise.")
    }

    @Test("MockModelEngine tracks last input text")
    func testLastInputText() async throws {
        let engine = MockModelEngine()
        _ = try await engine.generate(
            prompt: "prompt",
            systemInstruction: nil,
            inputText: "extra context",
            options: nil
        )
        #expect(engine.lastInputText == "extra context")
    }

    // MARK: - Reset

    @Test("MockModelEngine reset clears call count")
    func testReset() async throws {
        let engine = MockModelEngine()
        _ = try await engine.generate(prompt: "test", systemInstruction: nil, inputText: nil, options: nil)
        #expect(engine.callCount == 1)

        engine.reset()
        #expect(engine.callCount == 0)
        #expect(engine.lastPrompt == nil)
        #expect(engine.lastSystemInstruction == nil)
        #expect(engine.lastInputText == nil)
        #expect(engine.errorToThrow == nil)
    }

    // MARK: - Custom Handler

    @Test("MockModelEngine uses custom handler when set")
    func testCustomHandler() async throws {
        let engine = MockModelEngine()
        engine.customHandler = { prompt, _, _, _ in
            GenerationResult(output: "Custom: \(prompt)", model: "custom")
        }

        let result = try await engine.generate(
            prompt: "my prompt",
            systemInstruction: nil,
            inputText: nil,
            options: nil
        )
        #expect(result.output == "Custom: my prompt")
        #expect(result.model == "custom")
    }

    // MARK: - Echo Engine

    @Test("echoEngine returns echo of prompt")
    func testEchoEngine() async throws {
        let engine = MockModelEngine.echoEngine()
        let result = try await engine.generate(
            prompt: "Hello",
            systemInstruction: nil,
            inputText: nil,
            options: nil
        )
        #expect(result.output == "Echo: Hello")
        #expect(result.model == "mock-echo")
    }

    // MARK: - Usage Info

    @Test("MockModelEngine returns usage with duration")
    func testUsageInfo() async throws {
        let engine = MockModelEngine()
        let result = try await engine.generate(
            prompt: "test",
            systemInstruction: nil,
            inputText: nil,
            options: nil
        )
        #expect(result.usage != nil)
        #expect(result.usage?.durationSeconds != nil)
    }

    // MARK: - GenerationEngineError properties

    @Test("GenerationEngineError.frameworkUnavailable has correct exit code")
    func testFrameworkUnavailableError() {
        let error = GenerationEngineError.frameworkUnavailable
        let (code, message) = error.toExitInfo()
        #expect(code == "UNSUPPORTED_ENVIRONMENT")
        #expect(!message.isEmpty)
    }

    @Test("GenerationEngineError.modelUnavailable includes reason in message")
    func testModelUnavailableError() {
        let error = GenerationEngineError.modelUnavailable(reason: "not ready")
        let (code, _) = error.toExitInfo()
        #expect(code == "UNAVAILABLE_MODEL")
    }

    @Test("GenerationEngineError.generationFailed includes underlying message")
    func testGenerationFailedError() {
        let error = GenerationEngineError.generationFailed(underlying: "context overflow")
        let (code, message) = error.toExitInfo()
        #expect(code == "GENERATION_FAILURE")
        #expect(message == "context overflow")
    }
}
