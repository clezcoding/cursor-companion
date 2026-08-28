// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CursorCompanion",
    defaultLocalization: "de",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CursorCompanionCore",
            targets: ["CursorCompanionCore"]
        ),
        .executable(
            name: "CursorCompanion",
            targets: ["CursorCompanionApp"]
        )
    ],
    targets: [
        .target(
            name: "CursorCompanionCore",
            path: "Sources/CursorCompanionCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "CursorCompanionApp",
            dependencies: ["CursorCompanionCore"],
            path: "Sources/CursorCompanionApp",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CursorCompanionTests",
            dependencies: ["CursorCompanionCore"],
            path: "Tests/CursorCompanionTests",
            resources: [
                .copy("fixtures")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
