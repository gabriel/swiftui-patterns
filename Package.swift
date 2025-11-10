// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIPatterns",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "SwiftUIPatterns",
            targets: ["SwiftUIPatterns"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/gabriel/swiftui-snapshot-testing", from: "0.1.12"),
    ],
    targets: [
        .target(
            name: "SwiftUIPatterns",
            dependencies: [],
            path: "Sources",
        ),
        .testTarget(
            name: "SwiftUIPatternsTests",
            dependencies: [
                "SwiftUIPatterns",
                .product(name: "SwiftUISnapshotTesting", package: "swiftui-snapshot-testing"),
            ],
            path: "Tests",
            exclude: ["__Snapshots__"],
        ),
    ],
)
