// swift-tools-version: 5.9

import PackageDescription
import Foundation

// ACTIVEUI_STATIC (ActiveUI's convention, set for Linux builds through XCompile):
// XCompile links the Swift runtime statically on glibc, and a dynamic library
// cannot be built against a static runtime, so the library goes static there.
// `getenv`, not `ProcessInfo`: swift.org 6.3.1 crashes on a manifest that reads it.
let libraryType: Product.Library.LibraryType = getenv("ACTIVEUI_STATIC") != nil ? .static : .dynamic

let package = Package(
    name: "VectorTerminalSDK",
    platforms: [
        .macOS("15.0"),
        .iOS("17.0")
    ],
    products: [
        // Dynamic, not automatic -- the same reason TUIKit is. An automatic
        // library is static, so SwiftPM emits no `libVectorTerminalSDK` and
        // links its objects into each consumer: the SDK ended up absorbed into
        // `libTUIKit.dylib` *and* into BASIC's `libBASICRTHost.a`, and a
        // program linking both got two copies of every class, which the
        // Objective-C runtime reports on stderr.
        .library(name: "VectorTerminalSDK", type: libraryType, targets: ["VectorTerminalSDK"]),
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
