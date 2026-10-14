// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftAI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "SwiftAI", targets: ["SwiftAI"])
    ],
    targets: [
        .target(
            name: "SwiftAI",
            path: "Sources/SwiftAI"
        ),
        .testTarget(
            name: "SwiftAITests",
            dependencies: ["SwiftAI"]
        )
    ]
)
