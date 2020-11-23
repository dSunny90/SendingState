// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SendingState",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "SendingState",
            targets: ["SendingState"]
        )
    ],
    targets: [
        .target(
            name: "SendingState",
            path: "Sources/SendingState"
        ),
        .testTarget(
            name: "SendingStateTests",
            dependencies: ["SendingState"],
            path: "Tests/SendingStateTests"
        )
    ]
)
