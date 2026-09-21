// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MagicTouch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MagicTouch",
            targets: ["MagicTouch"]
        )
    ],
    targets: [
        .target(
            name: "MultitouchBridge",
            dependencies: [],
            path: "Sources/MultitouchBridge",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "MagicTouch",
            dependencies: ["MultitouchBridge"],
            path: "Sources/MagicTouch",
            linkerSettings: [
                .unsafeFlags([
                    "-F/System/Library/PrivateFrameworks",
                    "-framework", "MultitouchSupport"
                ])
            ]
        ),
        .testTarget(
            name: "MagicTouchTests",
            dependencies: ["MagicTouch", "MultitouchBridge"],
            path: "Tests/MagicTouchTests"
        )
    ]
)
