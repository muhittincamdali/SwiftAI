// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftAI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftAI",
            targets: ["SwiftAI"]
        ),
    ],
    dependencies: [
        // Core ML for AI/ML capabilities
        .package(url: "https://github.com/apple/swift-coreml-tools", from: "1.0.0"),
        
        // Vision framework for computer vision
        .package(url: "https://github.com/apple/swift-vision", from: "1.0.0"),
        
        // Natural Language framework
        .package(url: "https://github.com/apple/swift-natural-language", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SwiftAI",
            dependencies: [
                .product(name: "CoreMLTools", package: "swift-coreml-tools"),
                .product(name: "Vision", package: "swift-vision"),
                .product(name: "NaturalLanguage", package: "swift-natural-language")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftAITests",
            dependencies: ["SwiftAI"],
            path: "Tests"
        ),
    ]
) 