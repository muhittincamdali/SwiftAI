// swift-tools-version: 5.9
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
        ),
    ],
    dependencies: [
        // Core dependencies
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        
        // AI/ML dependencies
        .package(url: "https://github.com/tensorflow/swift-models", from: "0.13.0"),
        .package(url: "https://github.com/tensorflow/swift-apis", from: "0.13.0"),
        
        // Performance dependencies
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        
        // Testing dependencies
        .package(url: "https://github.com/Quick/Quick", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble", from: "13.0.0")
    ],
    targets: [
        .target(
            name: "SwiftAI",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "TensorFlowModels", package: "swift-models"),
                .product(name: "TensorFlowAPIs", package: "swift-apis"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            path: "Sources/SwiftAI"
        ),
        .testTarget(
            name: "SwiftAITests",
            dependencies: [
                "SwiftAI",
                "Quick",
                "Nimble"
            ],
            path: "Tests/SwiftAITests"
        ),
    ]
)
