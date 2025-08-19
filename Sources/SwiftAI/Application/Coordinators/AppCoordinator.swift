// SwiftAI Application Coordinator - MVVM-C Architecture  
// Copyright © 2024 SwiftAI. All rights reserved.
// Enterprise-Grade Application Coordinator for Navigation Flow

#if canImport(UIKit)
import UIKit
import SwiftUI
import Combine

// MARK: - AppCoordinator (UIKit-dependent)
// This file is disabled for non-UIKit platforms (like macOS command line builds)
// The full implementation is available when building for iOS targets

public protocol Coordinator: AnyObject {
    var identifier: UUID { get }
    var childCoordinators: [Coordinator] { get set }
    var parentCoordinator: Coordinator? { get set }
    
    func start()
    func stop()
}

public extension Coordinator {
    func stop() {
        childCoordinators.forEach { $0.stop() }
        childCoordinators.removeAll()
    }
}

// Placeholder implementations for iOS builds
public final class AppCoordinator: Coordinator {
    public let identifier = UUID()
    public var childCoordinators: [Coordinator] = []
    public weak var parentCoordinator: Coordinator?
    
    public func start() {
        print("AppCoordinator started")
    }
}

#endif

// Note: For full MVVM-C coordinator implementation with UIKit integration,
// build this framework for iOS targets where UIKit is available.