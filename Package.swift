// swift-tools-version: 5.9
// SwiftAI Framework Package Configuration
// Copyright © 2024 SwiftAI. All rights reserved.
// Enterprise-Grade AI Framework for iOS - Clean Architecture

import PackageDescription

let package = Package(
    name: "SwiftAI",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Main library product
        .library(
            name: "SwiftAI",
            targets: ["SwiftAI"]
        )
    ],
    dependencies: [
        // Core dependencies
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        
        // Networking
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0"),
        
        // Security
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.8.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.0"),
        
        // Logging & Monitoring
        .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-metrics", from: "2.4.0"),
        
        // Testing dependencies
        .package(url: "https://github.com/Quick/Quick", from: "7.3.0"),
        .package(url: "https://github.com/Quick/Nimble", from: "14.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0")
    ],
    targets: [
        // MARK: - Main Framework Target (all layers combined)
        .target(
            name: "SwiftAI",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics")
            ],
            path: "Sources/SwiftAI"
        ),
        
        // MARK: - Test Targets
        .testTarget(
            name: "SwiftAITests",
            dependencies: [
                "SwiftAI",
                "Quick",
                "Nimble",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/SwiftAITests"
        ),
        
        .testTarget(
            name: "SwiftAIDomainTests",
            dependencies: [
                "SwiftAI",
                "Quick",
                "Nimble"
            ],
            path: "Tests/DomainTests"
        ),
        
        .testTarget(
            name: "SwiftAIDataTests",
            dependencies: [
                "SwiftAI",
                "Quick",
                "Nimble"
            ],
            path: "Tests/DataTests"
        ),
        
        .testTarget(
            name: "SwiftAIInfrastructureTests",
            dependencies: [
                "SwiftAI",
                "Quick",
                "Nimble",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/InfrastructureTests"
        ),
        
        .testTarget(
            name: "SwiftAIPresentationTests",
            dependencies: [
                "SwiftAI",
                "Quick",
                "Nimble",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/PresentationTests"
        )
    ]
)
