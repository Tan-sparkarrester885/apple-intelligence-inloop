# Contributing to Apple Intelligence Inloop

Thank you for your interest in contributing! This guide explains how to submit issues, propose features, and open pull requests.

---

## Code of Conduct

Be respectful and constructive. We follow the standard open-source community norms: assume good intent, give clear feedback, and collaborate to improve the project.

---

## Getting Started

### Prerequisites

- macOS 26.0 or later
- Xcode 26.0 or later
- Apple Silicon Mac with Apple Intelligence enabled (for full testing)
- Swift 6.1+

### Setup

```bash
git clone https://github.com/parolkar/apple-intelligence-inloop.git
cd apple-intelligence-inloop
swift build
swift test
```

---

## Reporting Bugs

1. Search [existing issues](https://github.com/parolkar/apple-intelligence-inloop/issues) to avoid duplicates.
2. Open a new issue using the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md).
3. Include:
   - macOS version (`sw_vers`)
   - Output of `osx-ai-inloop check --json`
   - Exact command that failed
   - Expected vs. actual behavior
   - Full stdout and stderr output

---

## Suggesting Features

1. Check the [existing issues](https://github.com/parolkar/apple-intelligence-inloop/issues) and [discussions](https://github.com/parolkar/apple-intelligence-inloop/discussions).
2. Open a new issue using the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md).
3. Explain:
   - The use case / problem being solved
   - Proposed API or behavior
   - How it fits the Unix-philosophy design of the project

---

## Pull Requests

### Branch Naming

| Type | Pattern | Example |
|---|---|---|
| Feature | `feature/short-description` | `feature/streaming-support` |
| Bug fix | `fix/short-description` | `fix/stdin-detection-on-linux` |
| Docs | `docs/short-description` | `docs/jxa-examples` |
| Refactor | `refactor/short-description` | `refactor/engine-protocol` |

### Workflow

1. Fork the repository.
2. Create a branch from `main`:
   ```bash
   git checkout -b feature/my-feature
   ```
3. Make your changes.
4. Run all tests:
   ```bash
   swift test
   ```
5. Ensure your code builds cleanly:
   ```bash
   swift build -c release
   ```
6. Commit with a descriptive message (see below).
7. Push to your fork and open a pull request against `main`.

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) style:

```
type(scope): Short summary in imperative mood

Longer explanation if needed (wrap at 72 chars).
Explain WHY, not just what.

Fixes #123
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `perf`

Examples:
- `feat(engine): add streaming response support`
- `fix(stdin): handle non-pipe stdin on macOS 26`
- `docs(readme): add Python integration example`
- `test(mock): add concurrent call tracking tests`

---

## Code Style

### Swift

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- Use Swift 6.1 concurrency: `async/await`, `Sendable`, actors where appropriate.
- No force unwraps (`!`) in production code — use `guard`, `if let`, or `try`.
- Use `#if canImport(FoundationModels)` guards for platform-specific code.
- Keep functions small and focused; prefer composition.
- Write self-documenting code; add doc comments (`///`) for all public APIs.
- Use `writeStderr()` for all diagnostic output; never use `print()` for stderr.
- Use `writeStdout()` / `writeJSONStdout()` for all stdout output.

### Tests

- Write tests using Swift Testing (`@Suite`, `@Test`, `#expect`).
- Use `MockModelEngine` for tests that would otherwise require a real model.
- Test both happy paths and error cases.
- New features must include corresponding tests.
- Tests must pass on macOS without Apple Intelligence (mock-based tests).

### JSON

- All JSON responses must use the established `ok`/`model`/`output`/`error` contract.
- Use `JSONEncoder` with `.prettyPrinted` and `.sortedKeys` for stdout output.
- Use explicit `CodingKeys` (snake_case) for stable JSON field names.

---

## Testing Without Apple Intelligence

The project is designed to compile and run tests on machines without Apple Intelligence by using `#if canImport(FoundationModels)` guards. The `MockModelEngine` provides full test coverage without the real framework:

```bash
# Tests run on any Mac with Swift 6.1
swift test
```

For full integration testing (actual model calls), you need macOS 26+ with Apple Intelligence enabled.

---

## Adding a New Engine Backend

1. Implement `ModelEngine` protocol in `Sources/osx-ai-inloop/Engine/`.
2. Add any required `#if canImport(...)` guards.
3. Wire it up in `GenerateCommand.swift` as a new `--model` option.
4. Add a new `ModelMode` case in `ModelMode.swift`.
5. Write unit tests using a mock or stub.

---

## Adding a New CLI Command

1. Create a new `AsyncParsableCommand` in `Sources/osx-ai-inloop/Commands/`.
2. Register it in the `subcommands` list in `Main.swift`.
3. Follow the existing pattern: errors to stderr, results to stdout.
4. Add tests in `Tests/osx-ai-inloopTests/`.
5. Document the new command in `README.md`.

---

## Release Process

Releases are managed by the maintainer. To propose a release:

1. Ensure all tests pass on `main`.
2. Update `AppVersion` in `Main.swift`.
3. Open a PR updating the version and changelog.
4. Maintainer will tag the release after merge.

---

## Questions?

Open a [GitHub Discussion](https://github.com/parolkar/apple-intelligence-inloop/discussions) or email [abhishek@parolkar.com](mailto:abhishek@parolkar.com).
