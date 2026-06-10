// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VectorTerminalSDK",
    platforms: [
        .macOS("16.0")
    ],
    products: [
        .library(name: "VectorTerminalSDK", targets: ["VectorTerminalSDK"]),
        .executable(name: "VectorTerminalSDKDemo", targets: ["VectorTerminalSDKDemo"])
    ],
    targets: [
        .target(
            name: "VectorTerminalSDK",
            path: "Sources/VectorTerminalSDK"
        ),
        .executableTarget(
            name: "VectorTerminalSDKDemo",
            dependencies: ["VectorTerminalSDK"],
            path: "Sources/VectorTerminalSDKDemo"
        ),
        .testTarget(
            name: "VectorTerminalSDKTests",
            dependencies: ["VectorTerminalSDK"],
            path: "Tests/VectorTerminalSDKTests"
        )
    ]
)
