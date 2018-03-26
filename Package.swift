// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SwiftLog",
    products: [
        .library(
            name: "SwiftLog",
            targets: ["SwiftLog"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftLog",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "SwiftLogTests",
            dependencies: ["SwiftLog"],
            path: "Tests")
    ]
)
