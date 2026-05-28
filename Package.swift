// swift-tools-version: 6.0
import PackageDescription

// External dependencies are added in the sprint that needs them:
//   Sprint 5: SQLite.swift       — https://github.com/stephencelis/SQLite.swift
//   Sprint 5: sqlite-vec wrapper — built via Scripts/build-sqlite-vec.sh
//   Sprint 7: Sparkle 2          — https://github.com/sparkle-project/Sparkle
//   Sprint 9: mlx-swift          — https://github.com/ml-explore/mlx-swift
//   Sprint 12: swift-crypto      — bundled in CryptoKit on Apple platforms; only add for Linux CI

let package = Package(
    name: "LocalMind",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "LocalMindApp", targets: ["LocalMindApp"]),
        .library(name: "LocalMindCore", targets: ["LocalMindCore"]),
        .library(name: "LocalMindRAG", targets: ["LocalMindRAG"]),
        .library(name: "LocalMindLicense", targets: ["LocalMindLicense"]),
        .library(name: "LocalMindStorage", targets: ["LocalMindStorage"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LocalMindApp",
            dependencies: ["LocalMindCore", "LocalMindRAG", "LocalMindLicense", "LocalMindStorage"],
            path: "Sources/LocalMindApp"
        ),
        .target(
            name: "LocalMindCore",
            dependencies: [
                "LocalMindStorage",
                "SwiftLlama"
            ],
            path: "Sources/LocalMindCore",
            resources: [.process("Resources")]
        ),
        // Vendored fork of ShenghaiWang/SwiftLlama 0.4.0 with LocalMind's
        // prompt-template and llama.cpp integration patches. See ADR-0005 and
        // the LICENSE in Sources/Vendor/SwiftLlama for the upstream MIT
        // attribution.
        .target(
            name: "SwiftLlama",
            dependencies: ["LlamaFramework"],
            path: "Sources/Vendor/SwiftLlama",
            exclude: ["LICENSE"]
        ),
        .binaryTarget(
            name: "LlamaFramework",
            url: "https://github.com/ggml-org/llama.cpp/releases/download/b9374/llama-b9374-xcframework.zip",
            checksum: "73f061266e532a9245899aee0060a94a3270e4b6d31c86a6c71ebecc16e6255d"
        ),
        .target(
            name: "LocalMindRAG",
            dependencies: ["LocalMindCore", "LocalMindStorage"],
            path: "Sources/LocalMindRAG"
        ),
        .target(
            name: "LocalMindLicense",
            dependencies: ["LocalMindStorage"],
            path: "Sources/LocalMindLicense"
        ),
        .target(
            name: "LocalMindStorage",
            path: "Sources/LocalMindStorage"
        ),
        .testTarget(
            name: "LocalMindCoreTests",
            dependencies: ["LocalMindCore", "LocalMindStorage"],
            path: "Tests/LocalMindCoreTests"
        ),
        .testTarget(
            name: "LocalMindRAGTests",
            dependencies: ["LocalMindRAG"],
            path: "Tests/LocalMindRAGTests"
        ),
        .testTarget(
            name: "LocalMindLicenseTests",
            dependencies: ["LocalMindLicense"],
            path: "Tests/LocalMindLicenseTests"
        )
    ]
)
