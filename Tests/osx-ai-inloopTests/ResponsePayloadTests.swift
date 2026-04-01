// ResponsePayloadTests.swift
// Tests for JSON encoding of SuccessResponse and ErrorResponse.

import Testing
import Foundation
@testable import osx_ai_inloop

@Suite("ResponsePayload Tests")
struct ResponsePayloadTests {

    // MARK: - Helpers

    private func jsonDecode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
        let data = try #require(json.data(using: .utf8))
        return try JSONDecoder().decode(type, from: data)
    }

    private func jsonEncode<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        let obj = try JSONSerialization.jsonObject(with: data)
        return try #require(obj as? [String: Any])
    }

    // MARK: - SuccessResponse Encoding

    @Test("SuccessResponse encodes ok as true")
    func testSuccessResponseOkTrue() throws {
        let response = SuccessResponse(ok: true, model: "on-device", output: "Hello!")
        let dict = try jsonEncode(response)
        #expect(dict["ok"] as? Bool == true)
    }

    @Test("SuccessResponse encodes model correctly")
    func testSuccessResponseModel() throws {
        let response = SuccessResponse(ok: true, model: "on-device", output: "output text")
        let dict = try jsonEncode(response)
        #expect(dict["model"] as? String == "on-device")
    }

    @Test("SuccessResponse encodes output correctly")
    func testSuccessResponseOutput() throws {
        let response = SuccessResponse(ok: true, model: "on-device", output: "This is the generated text.")
        let dict = try jsonEncode(response)
        #expect(dict["output"] as? String == "This is the generated text.")
    }

    @Test("SuccessResponse with nil usage omits usage key")
    func testSuccessResponseNilUsage() throws {
        let response = SuccessResponse(ok: true, model: "on-device", output: "text", usage: nil)
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        // usage should be absent or null
        // Swift's default encoder omits nil optionals by default
        let hasUsageKey = obj?.keys.contains("usage") ?? false
        // Either absent or explicitly null is acceptable
        if hasUsageKey {
            #expect(obj?["usage"] is NSNull)
        }
    }

    @Test("SuccessResponse with usage encodes duration")
    func testSuccessResponseWithUsage() throws {
        let usage = UsageInfo(durationSeconds: 0.456)
        let response = SuccessResponse(ok: true, model: "on-device", output: "text", usage: usage)
        let dict = try jsonEncode(response)

        if let usageDict = dict["usage"] as? [String: Any] {
            #expect(usageDict["duration_seconds"] as? Double == 0.456)
        } else {
            Issue.record("Expected usage dictionary in response")
        }
    }

    @Test("SuccessResponse factory make(model:output:) works")
    func testSuccessResponseFactory() throws {
        let response = SuccessResponse.make(model: "on-device", output: "test output")
        #expect(response.ok == true)
        #expect(response.model == "on-device")
        #expect(response.output == "test output")
        #expect(response.usage == nil)
        #expect(response.warnings == nil)
    }

    @Test("SuccessResponse factory make(model:output:durationSeconds:) includes usage")
    func testSuccessResponseFactoryWithDuration() throws {
        let response = SuccessResponse.make(model: "on-device", output: "test", durationSeconds: 1.23)
        #expect(response.usage?.durationSeconds == 1.23)
    }

    // MARK: - ErrorResponse Encoding

    @Test("ErrorResponse encodes ok as false")
    func testErrorResponseOkFalse() throws {
        let response = ErrorResponse.make(code: "TEST_ERROR", message: "test message")
        let dict = try jsonEncode(response)
        #expect(dict["ok"] as? Bool == false)
    }

    @Test("ErrorResponse encodes error code and message")
    func testErrorResponseDetail() throws {
        let response = ErrorResponse.make(code: "GENERATION_FAILURE", message: "Content policy violation")
        let dict = try jsonEncode(response)

        if let errorDict = dict["error"] as? [String: Any] {
            #expect(errorDict["code"] as? String == "GENERATION_FAILURE")
            #expect(errorDict["message"] as? String == "Content policy violation")
        } else {
            Issue.record("Expected error dictionary in response")
        }
    }

    // MARK: - ErrorResponse Factory Methods

    @Test("ErrorResponse.invalidArguments factory works")
    func testErrorResponseInvalidArguments() {
        let response = ErrorResponse.invalidArguments("Missing prompt")
        #expect(response.ok == false)
        #expect(response.error.code == "INVALID_ARGUMENTS")
        #expect(response.error.message == "Missing prompt")
    }

    @Test("ErrorResponse.unsupportedEnvironment factory works")
    func testErrorResponseUnsupportedEnvironment() {
        let response = ErrorResponse.unsupportedEnvironment("Requires macOS 26+")
        #expect(response.error.code == "UNSUPPORTED_ENVIRONMENT")
    }

    @Test("ErrorResponse.unavailableModel factory works")
    func testErrorResponseUnavailableModel() {
        let response = ErrorResponse.unavailableModel("Model still downloading")
        #expect(response.error.code == "UNAVAILABLE_MODEL")
    }

    @Test("ErrorResponse.generationFailure factory works")
    func testErrorResponseGenerationFailure() {
        let response = ErrorResponse.generationFailure("Context too long")
        #expect(response.error.code == "GENERATION_FAILURE")
    }

    @Test("ErrorResponse.internalError factory works")
    func testErrorResponseInternalError() {
        let response = ErrorResponse.internalError("Unexpected nil")
        #expect(response.error.code == "INTERNAL_ERROR")
    }

    // MARK: - UsageInfo

    @Test("UsageInfo encodes all fields with snake_case keys")
    func testUsageInfoEncoding() throws {
        let usage = UsageInfo(
            promptTokens: 10,
            completionTokens: 50,
            totalTokens: 60,
            durationSeconds: 0.789
        )
        let dict = try jsonEncode(usage)

        #expect(dict["prompt_tokens"] as? Int == 10)
        #expect(dict["completion_tokens"] as? Int == 50)
        #expect(dict["total_tokens"] as? Int == 60)
        #expect(dict["duration_seconds"] as? Double == 0.789)
    }

    @Test("UsageInfo round-trips through encode/decode")
    func testUsageInfoRoundTrip() throws {
        let original = UsageInfo(promptTokens: 5, completionTokens: 20, totalTokens: 25, durationSeconds: 0.1)
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(UsageInfo.self, from: data)

        #expect(decoded.promptTokens == 5)
        #expect(decoded.completionTokens == 20)
        #expect(decoded.totalTokens == 25)
        #expect(decoded.durationSeconds == 0.1)
    }

    // MARK: - JSON Structure Verification

    @Test("SuccessResponse JSON matches expected contract shape")
    func testSuccessResponseJSONShape() throws {
        let response = SuccessResponse(
            ok: true,
            model: "on-device",
            output: "Swift concurrency uses async/await.",
            usage: UsageInfo(durationSeconds: 0.5),
            warnings: []
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(response)
        let jsonString = try #require(String(data: data, encoding: .utf8))

        // Verify top-level keys are present
        #expect(jsonString.contains("\"ok\""))
        #expect(jsonString.contains("\"model\""))
        #expect(jsonString.contains("\"output\""))
    }

    @Test("ErrorResponse JSON matches expected contract shape")
    func testErrorResponseJSONShape() throws {
        let response = ErrorResponse.make(code: "INVALID_ARGUMENTS", message: "No prompt")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(response)
        let jsonString = try #require(String(data: data, encoding: .utf8))

        #expect(jsonString.contains("\"ok\""))
        #expect(jsonString.contains("\"error\""))
        #expect(jsonString.contains("\"code\""))
        #expect(jsonString.contains("\"message\""))
    }
}
