// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "osx-ai-inloop",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(
            name: "osx-ai-inloop",
            targets: ["osx-ai-inloop"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.5.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "osx-ai-inloop",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/osx-ai-inloop",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "osx-ai-inloopTests",
            dependencies: [
                "osx-ai-inloop",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Tests/osx-ai-inloopTests"
        )
    ]
)
