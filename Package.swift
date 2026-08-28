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
        ),
        .executable(
            name: "CursorCompanionWidget",
            targets: ["CursorCompanionWidget"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.4")
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
            dependencies: [
                "CursorCompanionCore",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/CursorCompanionApp",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "CursorCompanionWidget",
            dependencies: ["CursorCompanionCore"],
            path: "Sources/CursorCompanionWidget",
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
