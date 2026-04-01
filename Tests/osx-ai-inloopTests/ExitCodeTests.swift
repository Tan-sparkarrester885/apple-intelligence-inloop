// ExitCodeTests.swift
// Tests for AppExitCode values and properties.

import Testing
import Foundation
@testable import osx_ai_inloop

@Suite("Exit Code Tests")
struct ExitCodeTests {

    // MARK: - Raw Values

    @Test("success has raw value 0")
    func testSuccessValue() {
        #expect(AppExitCode.success.rawValue == 0)
    }

    @Test("invalidArguments has raw value 1")
    func testInvalidArgumentsValue() {
        #expect(AppExitCode.invalidArguments.rawValue == 1)
    }

    @Test("unsupportedEnvironment has raw value 2")
    func testUnsupportedEnvironmentValue() {
        #expect(AppExitCode.unsupportedEnvironment.rawValue == 2)
    }

    @Test("unavailableModel has raw value 3")
    func testUnavailableModelValue() {
        #expect(AppExitCode.unavailableModel.rawValue == 3)
    }

    @Test("generationFailure has raw value 4")
    func testGenerationFailureValue() {
        #expect(AppExitCode.generationFailure.rawValue == 4)
    }

    @Test("internalError has raw value 5")
    func testInternalErrorValue() {
        #expect(AppExitCode.internalError.rawValue == 5)
    }

    // MARK: - All Cases

    @Test("AppExitCode has 6 cases")
    func testAllCasesCount() {
        #expect(AppExitCode.allCases.count == 6)
    }

    @Test("All exit codes have unique raw values")
    func testUniqueRawValues() {
        let rawValues = AppExitCode.allCases.map { $0.rawValue }
        let uniqueValues = Set(rawValues)
        #expect(uniqueValues.count == rawValues.count)
    }

    // MARK: - Names

    @Test("success name is 'Success'")
    func testSuccessName() {
        #expect(AppExitCode.success.name == "Success")
    }

    @Test("All exit codes have non-empty names")
    func testAllNamesNonEmpty() {
        for code in AppExitCode.allCases {
            #expect(!code.name.isEmpty)
        }
    }

    // MARK: - Error Codes

    @Test("success code is 'SUCCESS'")
    func testSuccessCode() {
        #expect(AppExitCode.success.code == "SUCCESS")
    }

    @Test("invalidArguments code is 'INVALID_ARGUMENTS'")
    func testInvalidArgumentsCode() {
        #expect(AppExitCode.invalidArguments.code == "INVALID_ARGUMENTS")
    }

    @Test("unsupportedEnvironment code is 'UNSUPPORTED_ENVIRONMENT'")
    func testUnsupportedEnvironmentCode() {
        #expect(AppExitCode.unsupportedEnvironment.code == "UNSUPPORTED_ENVIRONMENT")
    }

    @Test("unavailableModel code is 'UNAVAILABLE_MODEL'")
    func testUnavailableModelCode() {
        #expect(AppExitCode.unavailableModel.code == "UNAVAILABLE_MODEL")
    }

    @Test("generationFailure code is 'GENERATION_FAILURE'")
    func testGenerationFailureCode() {
        #expect(AppExitCode.generationFailure.code == "GENERATION_FAILURE")
    }

    @Test("internalError code is 'INTERNAL_ERROR'")
    func testInternalErrorCode() {
        #expect(AppExitCode.internalError.code == "INTERNAL_ERROR")
    }

    @Test("All exit codes have non-empty error codes")
    func testAllErrorCodesNonEmpty() {
        for code in AppExitCode.allCases {
            #expect(!code.code.isEmpty)
        }
    }

    // MARK: - Descriptions

    @Test("All exit codes have non-empty descriptions")
    func testAllDescriptionsNonEmpty() {
        for code in AppExitCode.allCases {
            #expect(!code.description.isEmpty)
        }
    }

    // MARK: - Init from Int32

    @Test("Init from Int32 0 gives success")
    func testInitFromInt32Success() {
        let code = AppExitCode(int32: 0)
        #expect(code == .success)
    }

    @Test("Init from Int32 3 gives unavailableModel")
    func testInitFromInt32UnavailableModel() {
        let code = AppExitCode(int32: 3)
        #expect(code == .unavailableModel)
    }

    @Test("Init from unknown Int32 returns nil")
    func testInitFromUnknownInt32() {
        let code = AppExitCode(int32: 99)
        #expect(code == nil)
    }

    // MARK: - GenerationEngineError Exit Codes

    @Test("frameworkUnavailable maps to unsupportedEnvironment")
    func testFrameworkUnavailableExitCode() {
        let error = GenerationEngineError.frameworkUnavailable
        #expect(error.exitCode == .unsupportedEnvironment)
    }

    @Test("modelUnavailable maps to unavailableModel")
    func testModelUnavailableExitCode() {
        let error = GenerationEngineError.modelUnavailable(reason: "test")
        #expect(error.exitCode == .unavailableModel)
    }

    @Test("generationFailed maps to generationFailure")
    func testGenerationFailedExitCode() {
        let error = GenerationEngineError.generationFailed(underlying: "test")
        #expect(error.exitCode == .generationFailure)
    }

    @Test("internalError maps to internalError")
    func testInternalErrorExitCode() {
        let error = GenerationEngineError.internalError(message: "test")
        #expect(error.exitCode == .internalError)
    }
}
