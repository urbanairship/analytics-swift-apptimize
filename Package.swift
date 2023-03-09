// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SegmentApptimize",
    platforms: [
        .iOS(.v13),
        .tvOS(.v11),
        .watchOS(.v7),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SegmentApptimize",
            targets: ["SegmentApptimize"]),
    ],
    dependencies: [
        .package(
            name: "Segment",
            url: "https://github.com/segmentio/analytics-swift.git",
            from: "1.1.2"
        ),
        .package(
            name: "Apptimize",
            url: "https://github.com/urbanairship/apptimize-ios-kit.git",
            from: "3.5.17"
        )
    ],
    targets: [
        .target(
            name: "SegmentApptimize",
            dependencies: ["Segment", "Apptimize"]),
    ]
)

