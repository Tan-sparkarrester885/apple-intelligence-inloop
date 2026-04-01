// RequestPayloadTests.swift
// Tests for JSON decoding of RequestPayload.

import Testing
import Foundation
@testable import osx_ai_inloop

@Suite("RequestPayload Tests")
struct RequestPayloadTests {

    // MARK: - Minimal Payload

    @Test("Decodes minimal payload with only prompt")
    func testMinimalPayload() throws {
        let json = """
        {"prompt": "Hello, world"}
        """
        let data = try #require(json.data(using: .utf8))
        let payload = try JSONDecoder().decode(RequestPayload.self, from: data)

        #expect(payload.prompt == "Hello, world")
        #expect(payload.system == nil)
        #expect(payload.input == nil)
        #expect(payload.model == nil)
        #expect(payload.format == nil)
        #expect(payload.stream == nil)
    }

    // MARK: - Full Payload

    @Test("Decodes full payload with all fields")
    func testFullPayload() throws {
        let json = """
        {
          "prompt": "Explain Swift concurrency",
          "system": "You are a Swift expert.",
          "input": "Here is some context.",
          "model": "on-device",
          "format": "json",
          "stream": false
        }
        """
        let data = try #require(json.data(using: .utf8))
        let payload = try JSONDecoder().decode(RequestPayload.self, from: data)

        #expect(payload.prompt == "Explain Swift concurrency")
        #expect(payload.system == "You are a Swift expert.")
        #expect(payload.input == "Here is some context.")
        #expect(payload.model == "on-device")
        #expect(payload.format == "json")
        #expect(payload.stream == false)
    }

    // MARK: - Partial Fields

    @Test("Decodes payload with only system and prompt")
    func testPartialPayload() throws {
        let json = """
        {"prompt": "What is a monad?", "system": "Be brief."}
        """
        let data = try #require(json.data(using: .utf8))
        let payload = try JSONDecoder().decode(RequestPayload.self, from: data)

        #expect(payload.prompt == "What is a monad?")
        #expect(payload.system == "Be brief.")
        #expect(payload.model == nil)
    }

    // MARK: - Missing Prompt

    @Test("Decodes payload with no prompt — prompt is nil")
    func testMissingPrompt() throws {
        let json = """
        {"model": "on-device", "format": "json"}
        """
        let data = try #require(json.data(using: .utf8))
        let payload = try JSONDecoder().decode(RequestPayload.self, from: data)

        #expect(payload.prompt == nil)
        #expect(payload.hasPrompt == false)
    }

    // MARK: - Stream Flag

    @Test("Decodes stream: true correctly")
    func testStreamTrue() throws {
        let json = """
        {"prompt": "test", "stream": true}
        """
        let data = try #require(json.data(using: .utf8))
        let payload = try JSONDecoder().decode(RequestPayload.self, from: data)

        #expect(payload.stream == true)
    }

    // MARK: - hasPrompt

    @Test("hasPrompt returns false for empty prompt")
    func testHasPromptEmpty() {
        let payload = RequestPayload(prompt: "   ", model: "on-device")
        #expect(payload.hasPrompt == false)
    }

    @Test("hasPrompt returns true for non-empty prompt")
    func testHasPromptNonEmpty() {
        let payload = RequestPayload(prompt: "Hello", model: "on-device")
        #expect(payload.hasPrompt == true)
    }

    @Test("hasPrompt returns false when prompt is nil")
    func testHasPromptNil() {
        let payload = RequestPayload()
        #expect(payload.hasPrompt == false)
    }

    // MARK: - effectivePrompt

    @Test("effectivePrompt trims whitespace")
    func testEffectivePromptTrimming() {
        let payload = RequestPayload(prompt: "  Hello, world  ")
        #expect(payload.effectivePrompt == "Hello, world")
    }

    @Test("effectivePrompt returns nil for whitespace-only prompt")
    func testEffectivePromptWhitespaceOnly() {
        let payload = RequestPayload(prompt: "\n\t  \n")
        #expect(payload.effectivePrompt == nil)
    }

    // MARK: - Merged Payload

    @Test("merged prefers overrides over base values")
    func testMergedPayloadOverrides() {
        let base = RequestPayload(prompt: "Base prompt", model: "on-device", format: "json")
        let overrides = RequestPayload(prompt: "Override prompt", model: nil, format: "text")
        let merged = base.merged(withOverrides: overrides)

        #expect(merged.prompt == "Override prompt")
        #expect(merged.model == "on-device") // base wins when override is nil
        #expect(merged.format == "text")
    }

    @Test("merged keeps base values when overrides are nil")
    func testMergedPayloadKeepsBase() {
        let base = RequestPayload(prompt: "Hello", system: "Be brief", model: "auto")
        let overrides = RequestPayload()
        let merged = base.merged(withOverrides: overrides)

        #expect(merged.prompt == "Hello")
        #expect(merged.system == "Be brief")
        #expect(merged.model == "auto")
    }

    // MARK: - Encoding Round-Trip

    @Test("Encoding and decoding RequestPayload is lossless")
    func testEncodingRoundTrip() throws {
        let original = RequestPayload(
            prompt: "Test prompt",
            system: "Test system",
            input: "Test input",
            model: "on-device",
            format: "json",
            stream: false
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(RequestPayload.self, from: data)

        #expect(decoded.prompt == original.prompt)
        #expect(decoded.system == original.system)
        #expect(decoded.input == original.input)
        #expect(decoded.model == original.model)
        #expect(decoded.format == original.format)
        #expect(decoded.stream == original.stream)
    }

    // MARK: - Invalid JSON

    @Test("Decoding invalid JSON throws an error")
    func testInvalidJSON() {
        let invalidJSON = "not-json-at-all"
        let data = invalidJSON.data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(RequestPayload.self, from: data)
        }
    }
}
