// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VectorTerminalSDK",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        // Dynamic, not automatic -- the same reason TUIKit is. An automatic
        // library is static, so SwiftPM emits no `libVectorTerminalSDK` and
        // links its objects into each consumer: the SDK ended up absorbed into
        // `libTUIKit.dylib` *and* into BASIC's `libBASICRTHost.a`, and a
        // program linking both got two copies of every class, which the
        // Objective-C runtime reports on stderr.
        .library(name: "VectorTerminalSDK", type: .dynamic, targets: ["VectorTerminalSDK"]),
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
