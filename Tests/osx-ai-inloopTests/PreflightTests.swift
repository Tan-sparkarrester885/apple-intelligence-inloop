// PreflightTests.swift
// Tests for preflight check results and formatting.

import Testing
import Foundation
@testable import osx_ai_inloop

@Suite("Preflight Tests")
struct PreflightTests {

    // MARK: - CheckItem

    @Test("CheckItem stores name, passed, and message")
    func testCheckItemProperties() {
        let item = CheckItem(name: "Test Check", passed: true, message: "All good.")
        #expect(item.name == "Test Check")
        #expect(item.passed == true)
        #expect(item.message == "All good.")
    }

    @Test("CheckItem failed case stores correctly")
    func testCheckItemFailed() {
        let item = CheckItem(name: "OS Version", passed: false, message: "Requires macOS 26+")
        #expect(item.passed == false)
        #expect(item.message == "Requires macOS 26+")
    }

    // MARK: - PreflightResult

    @Test("PreflightResult isCompatible true when all checks pass")
    func testPreflightResultAllPassed() {
        let checks = [
            CheckItem(name: "Check A", passed: true, message: "OK"),
            CheckItem(name: "Check B", passed: true, message: "OK"),
            CheckItem(name: "Check C", passed: true, message: "OK")
        ]
        let result = PreflightResult(isCompatible: true, checks: checks)
        #expect(result.isCompatible == true)
        #expect(result.checks.count == 3)
    }

    @Test("PreflightResult isCompatible false when any check fails")
    func testPreflightResultSomeFailed() {
        let checks = [
            CheckItem(name: "Check A", passed: true, message: "OK"),
            CheckItem(name: "Check B", passed: false, message: "FAIL"),
        ]
        let result = PreflightResult(isCompatible: false, checks: checks)
        #expect(result.isCompatible == false)
    }

    // MARK: - toJSON()

    @Test("toJSON produces is_compatible field")
    func testToJSONIsCompatible() {
        let result = PreflightResult(
            isCompatible: true,
            checks: [CheckItem(name: "A", passed: true, message: "OK")]
        )
        let jsonOutput = result.toJSON()
        #expect(jsonOutput.isCompatible == true)
    }

    @Test("toJSON includes all checks")
    func testToJSONChecksCount() {
        let checks = [
            CheckItem(name: "A", passed: true, message: "OK"),
            CheckItem(name: "B", passed: false, message: "FAIL"),
            CheckItem(name: "C", passed: true, message: "OK")
        ]
        let result = PreflightResult(isCompatible: false, checks: checks)
        let jsonOutput = result.toJSON()
        #expect(jsonOutput.checks.count == 3)
    }

    @Test("toJSON encodes to valid JSON")
    func testToJSONEncodesSuccessfully() throws {
        let checks = [
            CheckItem(name: "OS", passed: true, message: "macOS 26.0 detected"),
            CheckItem(name: "Silicon", passed: false, message: "Requires Apple Silicon")
        ]
        let result = PreflightResult(isCompatible: false, checks: checks)
        let jsonOutput = result.toJSON()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(jsonOutput)
        let jsonString = try #require(String(data: data, encoding: .utf8))

        #expect(jsonString.contains("\"is_compatible\""))
        #expect(jsonString.contains("\"checks\""))
        #expect(jsonString.contains("\"summary\""))
    }

    @Test("toJSON summary mentions failed checks when not compatible")
    func testToJSONSummaryFailed() {
        let checks = [
            CheckItem(name: "Apple Silicon", passed: false, message: "Requires Apple Silicon")
        ]
        let result = PreflightResult(isCompatible: false, checks: checks)
        let jsonOutput = result.toJSON()

        #expect(jsonOutput.summary.contains("Apple Silicon"))
    }

    @Test("toJSON summary is positive when compatible")
    func testToJSONSummaryCompatible() {
        let result = PreflightResult(isCompatible: true, checks: [])
        let jsonOutput = result.toJSON()
        #expect(jsonOutput.summary.lowercased().contains("compatible"))
    }

    // MARK: - toHumanReadable()

    @Test("toHumanReadable contains check names")
    func testToHumanReadableContainsCheckNames() {
        let checks = [
            CheckItem(name: "Operating System", passed: true, message: "Running on macOS."),
            CheckItem(name: "Apple Silicon", passed: true, message: "arm64 detected.")
        ]
        let result = PreflightResult(isCompatible: true, checks: checks)
        let readable = result.toHumanReadable()

        #expect(readable.contains("Operating System"))
        #expect(readable.contains("Apple Silicon"))
    }

    @Test("toHumanReadable shows COMPATIBLE when all checks pass")
    func testToHumanReadableCompatible() {
        let result = PreflightResult(
            isCompatible: true,
            checks: [CheckItem(name: "A", passed: true, message: "OK")]
        )
        let readable = result.toHumanReadable()
        #expect(readable.contains("COMPATIBLE"))
    }

    @Test("toHumanReadable shows NOT COMPATIBLE when some checks fail")
    func testToHumanReadableNotCompatible() {
        let result = PreflightResult(
            isCompatible: false,
            checks: [CheckItem(name: "A", passed: false, message: "Failed")]
        )
        let readable = result.toHumanReadable()
        #expect(readable.contains("NOT COMPATIBLE"))
    }

    @Test("toHumanReadable uses checkmark for passed items")
    func testToHumanReadableCheckmark() {
        let result = PreflightResult(
            isCompatible: true,
            checks: [CheckItem(name: "A", passed: true, message: "OK")]
        )
        let readable = result.toHumanReadable()
        #expect(readable.contains("✓"))
    }

    @Test("toHumanReadable uses X for failed items")
    func testToHumanReadableCross() {
        let result = PreflightResult(
            isCompatible: false,
            checks: [CheckItem(name: "A", passed: false, message: "Fail")]
        )
        let readable = result.toHumanReadable()
        #expect(readable.contains("✗"))
    }

    // MARK: - EnvironmentChecker (Mock-friendly aspects)

    @Test("EnvironmentChecker.run() returns a PreflightResult")
    func testEnvironmentCheckerReturnsResult() async {
        let result = await EnvironmentChecker.run()
        // Result should have at least some checks
        #expect(result.checks.count > 0)
        // isCompatible should be consistent with check results
        let allPassed = result.checks.allSatisfy { $0.passed }
        // isCompatible may be false on non-macOS 26 machines (e.g., CI)
        if allPassed {
            #expect(result.isCompatible == true)
        }
    }

    @Test("EnvironmentChecker result check names are non-empty")
    func testEnvironmentCheckerCheckNames() async {
        let result = await EnvironmentChecker.run()
        for check in result.checks {
            #expect(!check.name.isEmpty)
            #expect(!check.message.isEmpty)
        }
    }
}
