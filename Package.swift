// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "SendingState",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4)
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
