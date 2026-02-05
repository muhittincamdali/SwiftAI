// swift-tools-version: 5.9
// SwiftAI - Pure Swift Machine Learning Framework
// Copyright © 2024 Muhittin Camdali. All rights reserved.

import PackageDescription

let package = Package(
    name: "SwiftAI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SwiftAI",
            targets: ["SwiftAI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SwiftAI",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics")
            ],
            path: "Sources/SwiftAI"
        ),
        .testTarget(
            name: "SwiftAITests",
            dependencies: ["SwiftAI"],
            path: "Tests/SwiftAITests"
        )
    ]
)
