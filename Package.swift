// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ScreenshotMini",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotMini",
            path: "Sources/ScreenshotMini",
            swiftSettings: [
                .unsafeFlags(["-F", "Frameworks"])
            ],
            linkerSettings: [
                .unsafeFlags(["-F", "Frameworks", "-framework", "Sparkle",
                              "-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        )
    ]
)
