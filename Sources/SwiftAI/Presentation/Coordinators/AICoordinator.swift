//
//  AICoordinator.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import Foundation
import SwiftUI
import Combine

/// Enterprise-grade coordinator implementing MVVM-C navigation pattern
@MainActor
public final class AICoordinator: ObservableObject, AICoordinatorProtocol {
    
    // MARK: - Published Properties
    
    @Published public private(set) var navigationStack: [AIDestination] = []
    @Published public private(set) var presentedSheet: AISheet?
    @Published public private(set) var presentedAlert: AIAlert?
    @Published public private(set) var presentedFullScreen: AIFullScreen?
    
    // MARK: - Private Properties
    
    private let logger: LoggerProtocol
    private let analyticsManager: AnalyticsManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Navigation state management
    private var navigationHistory: [AIDestination] = []
    private let maxHistorySize: Int = 50
    
    // Deep linking support
    private var pendingDeepLink: URL?
    private var isReadyForDeepLinking = false
    
    // MARK: - Initialization
    
    public init(
        logger: LoggerProtocol = Logger.shared,
        analyticsManager: AnalyticsManagerProtocol = AnalyticsManager(networkClient: APIClient(baseURL: URL(string: "https://api.swiftai.com")!))
    ) {
        self.logger = logger
        self.analyticsManager = analyticsManager
        
        setupNavigationMonitoring()
        setupDeepLinkHandling()
        
        logger.info("AICoordinator initialized")
    }
    
    // MARK: - Public Navigation Methods
    
    /// Navigates to a specific destination
    /// - Parameter destination: The destination to navigate to
    public func navigate(to destination: AIDestination) {
        logger.debug("Navigating to: \(destination)")
        
        // Add to navigation stack
        navigationStack.append(destination)
        
        // Update navigation history
        addToHistory(destination)
        
        // Track navigation analytics
        analyticsManager.trackScreenView(
            screenName: destination.analyticsName,
            properties: destination.analyticsProperties
        )
        
        logger.info("Navigation completed to: \(destination)")
    }
    
    /// Navigates back to the previous screen
    public func navigateBack() {
        guard !navigationStack.isEmpty else {
            logger.warning("Cannot navigate back - navigation stack is empty")
            return
        }
        
        let removedDestination = navigationStack.removeLast()
        logger.debug("Navigated back from: \(removedDestination)")
        
        // Track back navigation
        analyticsManager.trackUserAction(
            action: "navigate_back",
            properties: ["from_screen": removedDestination.analyticsName]
        )
    }
    
    /// Navigates to the root screen
    public func navigateToRoot() {
        guard !navigationStack.isEmpty else { return }
        
        let previousStackCount = navigationStack.count
        navigationStack.removeAll()
        
        logger.info("Navigated to root, cleared \(previousStackCount) screens from stack")
        
        // Track root navigation
        analyticsManager.trackUserAction(
            action: "navigate_to_root",
            properties: ["screens_cleared": previousStackCount]
        )
    }
    
    /// Pops to a specific destination in the stack
    /// - Parameter destination: The destination to pop to
    public func popTo(_ destination: AIDestination) {
        guard let index = navigationStack.firstIndex(of: destination) else {
            logger.warning("Destination not found in navigation stack: \(destination)")
            return
        }
        
        let removedCount = navigationStack.count - index - 1
        navigationStack.removeSubrange((index + 1)...)
        
        logger.info("Popped to \(destination), removed \(removedCount) screens")
        
        // Track pop navigation
        analyticsManager.trackUserAction(
            action: "pop_to_destination",
            properties: [
                "destination": destination.analyticsName,
                "screens_removed": removedCount
            ]
        )
    }
    
    // MARK: - Sheet Presentation
    
    /// Presents a sheet modal
    /// - Parameter sheet: The sheet to present
    public func presentSheet(_ sheet: AISheet) {
        logger.debug("Presenting sheet: \(sheet)")
        
        presentedSheet = sheet
        
        // Track sheet presentation
        analyticsManager.trackScreenView(
            screenName: sheet.analyticsName,
            properties: sheet.analyticsProperties
        )
    }
    
    /// Dismisses the currently presented sheet
    public func dismissSheet() {
        guard let currentSheet = presentedSheet else {
            logger.warning("No sheet to dismiss")
            return
        }
        
        logger.debug("Dismissing sheet: \(currentSheet)")
        presentedSheet = nil
        
        // Track sheet dismissal
        analyticsManager.trackUserAction(
            action: "dismiss_sheet",
            properties: ["sheet_type": currentSheet.analyticsName]
        )
    }
    
    // MARK: - Alert Presentation
    
    /// Presents an alert
    /// - Parameter alert: The alert to present
    public func presentAlert(_ alert: AIAlert) {
        logger.debug("Presenting alert: \(alert.title)")
        
        presentedAlert = alert
        
        // Track alert presentation
        analyticsManager.trackUserAction(
            action: "present_alert",
            properties: [
                "alert_title": alert.title,
                "alert_type": alert.type.rawValue
            ]
        )
    }
    
    /// Dismisses the currently presented alert
    public func dismissAlert() {
        guard let currentAlert = presentedAlert else {
            logger.warning("No alert to dismiss")
            return
        }
        
        logger.debug("Dismissing alert: \(currentAlert.title)")
        presentedAlert = nil
        
        // Track alert dismissal
        analyticsManager.trackUserAction(
            action: "dismiss_alert",
            properties: ["alert_title": currentAlert.title]
        )
    }
    
    // MARK: - Full Screen Presentation
    
    /// Presents a full screen modal
    /// - Parameter fullScreen: The full screen content to present
    public func presentFullScreen(_ fullScreen: AIFullScreen) {
        logger.debug("Presenting full screen: \(fullScreen)")
        
        presentedFullScreen = fullScreen
        
        // Track full screen presentation
        analyticsManager.trackScreenView(
            screenName: fullScreen.analyticsName,
            properties: fullScreen.analyticsProperties
        )
    }
    
    /// Dismisses the currently presented full screen modal
    public func dismissFullScreen() {
        guard let currentFullScreen = presentedFullScreen else {
            logger.warning("No full screen to dismiss")
            return
        }
        
        logger.debug("Dismissing full screen: \(currentFullScreen)")
        presentedFullScreen = nil
        
        // Track full screen dismissal
        analyticsManager.trackUserAction(
            action: "dismiss_full_screen",
            properties: ["full_screen_type": currentFullScreen.analyticsName]
        )
    }
    
    // MARK: - AI-Specific Navigation Methods
    
    /// Shows the model selection interface
    public func showModelSelection() {
        presentSheet(.modelSelection)
    }
    
    /// Shows the training interface
    public func showTrainingInterface() {
        navigate(to: .training)
    }
    
    /// Shows the performance dashboard
    public func showPerformanceDashboard() {
        presentSheet(.performanceDashboard)
    }
    
    /// Shows the settings interface
    public func showSettings() {
        presentSheet(.settings)
    }
    
    /// Shows the inference results
    public func showInferenceResults() {
        navigate(to: .results)
    }
    
    /// Shows the model management interface
    public func showModelManagement() {
        navigate(to: .modelManagement)
    }
    
    /// Shows the analytics dashboard
    public func showAnalytics() {
        navigate(to: .analytics)
    }
    
    // MARK: - Deep Linking Support
    
    /// Handles a deep link URL
    /// - Parameter url: The deep link URL to handle
    /// - Returns: True if the URL was handled, false otherwise
    public func handleDeepLink(_ url: URL) -> Bool {
        logger.debug("Handling deep link: \(url.absoluteString)")
        
        guard isReadyForDeepLinking else {
            pendingDeepLink = url
            logger.info("Deep link queued for later processing")
            return true
        }
        
        return processDeepLink(url)
    }
    
    /// Marks the coordinator as ready for deep linking
    public func setReadyForDeepLinking() {
        isReadyForDeepLinking = true
        
        // Process any pending deep link
        if let pendingURL = pendingDeepLink {
            pendingDeepLink = nil
            _ = handleDeepLink(pendingURL)
        }
    }
    
    // MARK: - Navigation History
    
    /// Gets the navigation history
    /// - Returns: Array of previously visited destinations
    public func getNavigationHistory() -> [AIDestination] {
        return navigationHistory
    }
    
    /// Clears the navigation history
    public func clearNavigationHistory() {
        navigationHistory.removeAll()
        logger.debug("Navigation history cleared")
    }
    
    // MARK: - Coordinator State
    
    /// Gets the current navigation state
    /// - Returns: Current coordinator state
    public func getCurrentState() -> AICoordinatorState {
        return AICoordinatorState(
            navigationStack: navigationStack,
            presentedSheet: presentedSheet,
            presentedAlert: presentedAlert,
            presentedFullScreen: presentedFullScreen,
            navigationHistory: navigationHistory
        )
    }
    
    /// Restores coordinator state
    /// - Parameter state: The state to restore
    public func restoreState(_ state: AICoordinatorState) {
        navigationStack = state.navigationStack
        presentedSheet = state.presentedSheet
        presentedAlert = state.presentedAlert
        presentedFullScreen = state.presentedFullScreen
        navigationHistory = state.navigationHistory
        
        logger.info("Coordinator state restored")
    }
    
    // MARK: - Private Methods
    
    private func setupNavigationMonitoring() {
        // Monitor navigation stack changes
        $navigationStack
            .dropFirst()
            .sink { [weak self] stack in
                self?.logger.debug("Navigation stack updated: \(stack.count) items")
            }
            .store(in: &cancellables)
        
        // Monitor sheet presentation changes
        $presentedSheet
            .dropFirst()
            .sink { [weak self] sheet in
                if let sheet = sheet {
                    self?.logger.debug("Sheet presented: \(sheet)")
                } else {
                    self?.logger.debug("Sheet dismissed")
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupDeepLinkHandling() {
        // Setup deep link notification handling
        NotificationCenter.default.publisher(for: .deepLinkReceived)
            .compactMap { $0.object as? URL }
            .sink { [weak self] url in
                _ = self?.handleDeepLink(url)
            }
            .store(in: &cancellables)
    }
    
    private func addToHistory(_ destination: AIDestination) {
        navigationHistory.append(destination)
        
        // Maintain history size limit
        if navigationHistory.count > maxHistorySize {
            navigationHistory.removeFirst(navigationHistory.count - maxHistorySize)
        }
    }
    
    private func processDeepLink(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            logger.error("Invalid deep link URL: \(url.absoluteString)")
            return false
        }
        
        switch host {
        case "inference":
            navigate(to: .inference)
            return true
            
        case "training":
            navigate(to: .training)
            return true
            
        case "models":
            navigate(to: .models)
            return true
            
        case "analytics":
            navigate(to: .analytics)
            return true
            
        case "settings":
            showSettings()
            return true
            
        default:
            logger.warning("Unhandled deep link host: \(host)")
            return false
        }
    }
}

// MARK: - Supporting Types

public enum AIDestination: Equatable, Hashable {
    case inference
    case training
    case models
    case analytics
    case results
    case modelManagement
    case settings
    
    var analyticsName: String {
        switch self {
        case .inference:
            return "ai_inference"
        case .training:
            return "ai_training"
        case .models:
            return "ai_models"
        case .analytics:
            return "ai_analytics"
        case .results:
            return "inference_results"
        case .modelManagement:
            return "model_management"
        case .settings:
            return "settings"
        }
    }
    
    var analyticsProperties: [String: Any] {
        switch self {
        case .inference:
            return ["feature": "inference", "type": "primary"]
        case .training:
            return ["feature": "training", "type": "primary"]
        case .models:
            return ["feature": "models", "type": "primary"]
        case .analytics:
            return ["feature": "analytics", "type": "primary"]
        case .results:
            return ["feature": "results", "type": "secondary"]
        case .modelManagement:
            return ["feature": "model_management", "type": "secondary"]
        case .settings:
            return ["feature": "settings", "type": "utility"]
        }
    }
}

public enum AISheet: Equatable {
    case modelSelection
    case performanceDashboard
    case settings
    case resultsHistory
    case modelDetails(String)
    case trainingConfiguration
    
    var analyticsName: String {
        switch self {
        case .modelSelection:
            return "model_selection_sheet"
        case .performanceDashboard:
            return "performance_dashboard_sheet"
        case .settings:
            return "settings_sheet"
        case .resultsHistory:
            return "results_history_sheet"
        case .modelDetails:
            return "model_details_sheet"
        case .trainingConfiguration:
            return "training_configuration_sheet"
        }
    }
    
    var analyticsProperties: [String: Any] {
        switch self {
        case .modelSelection:
            return ["sheet_type": "model_selection"]
        case .performanceDashboard:
            return ["sheet_type": "performance_dashboard"]
        case .settings:
            return ["sheet_type": "settings"]
        case .resultsHistory:
            return ["sheet_type": "results_history"]
        case .modelDetails(let modelId):
            return ["sheet_type": "model_details", "model_id": modelId]
        case .trainingConfiguration:
            return ["sheet_type": "training_configuration"]
        }
    }
}

public struct AIAlert: Equatable {
    public let title: String
    public let message: String
    public let type: AlertType
    public let primaryAction: AlertAction
    public let secondaryAction: AlertAction?
    
    public init(
        title: String,
        message: String,
        type: AlertType = .info,
        primaryAction: AlertAction,
        secondaryAction: AlertAction? = nil
    ) {
        self.title = title
        self.message = message
        self.type = type
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    public enum AlertType: String {
        case info = "info"
        case warning = "warning"
        case error = "error"
        case success = "success"
    }
    
    public struct AlertAction: Equatable {
        public let title: String
        public let style: ActionStyle
        public let handler: () -> Void
        
        public init(title: String, style: ActionStyle = .default, handler: @escaping () -> Void) {
            self.title = title
            self.style = style
            self.handler = handler
        }
        
        public enum ActionStyle {
            case `default`
            case cancel
            case destructive
        }
        
        public static func == (lhs: AlertAction, rhs: AlertAction) -> Bool {
            return lhs.title == rhs.title && lhs.style == rhs.style
        }
    }
}

public enum AIFullScreen: Equatable {
    case onboarding
    case tutorial
    case maintenance
    
    var analyticsName: String {
        switch self {
        case .onboarding:
            return "onboarding_full_screen"
        case .tutorial:
            return "tutorial_full_screen"
        case .maintenance:
            return "maintenance_full_screen"
        }
    }
    
    var analyticsProperties: [String: Any] {
        switch self {
        case .onboarding:
            return ["full_screen_type": "onboarding"]
        case .tutorial:
            return ["full_screen_type": "tutorial"]
        case .maintenance:
            return ["full_screen_type": "maintenance"]
        }
    }
}

public struct AICoordinatorState: Codable {
    public let navigationStack: [AIDestination]
    public let presentedSheet: AISheet?
    public let presentedAlert: AIAlert?
    public let presentedFullScreen: AIFullScreen?
    public let navigationHistory: [AIDestination]
    
    public init(
        navigationStack: [AIDestination],
        presentedSheet: AISheet?,
        presentedAlert: AIAlert?,
        presentedFullScreen: AIFullScreen?,
        navigationHistory: [AIDestination]
    ) {
        self.navigationStack = navigationStack
        self.presentedSheet = presentedSheet
        self.presentedAlert = presentedAlert
        self.presentedFullScreen = presentedFullScreen
        self.navigationHistory = navigationHistory
    }
}

// MARK: - Protocol Extensions

extension AICoordinatorProtocol {
    /// Convenience method to show an error alert
    /// - Parameters:
    ///   - error: The error to display
    ///   - onDismiss: Optional closure called when alert is dismissed
    public func showError(_ error: Error, onDismiss: (() -> Void)? = nil) {
        let alert = AIAlert(
            title: "Error",
            message: error.localizedDescription,
            type: .error,
            primaryAction: AIAlert.AlertAction(
                title: "OK",
                style: .default,
                handler: { onDismiss?() }
            )
        )
        presentAlert(alert)
    }
    
    /// Convenience method to show a success message
    /// - Parameters:
    ///   - message: The success message to display
    ///   - onDismiss: Optional closure called when alert is dismissed
    public func showSuccess(_ message: String, onDismiss: (() -> Void)? = nil) {
        let alert = AIAlert(
            title: "Success",
            message: message,
            type: .success,
            primaryAction: AIAlert.AlertAction(
                title: "OK",
                style: .default,
                handler: { onDismiss?() }
            )
        )
        presentAlert(alert)
    }
    
    /// Convenience method to show a confirmation dialog
    /// - Parameters:
    ///   - title: The dialog title
    ///   - message: The dialog message
    ///   - confirmTitle: The confirm button title
    ///   - onConfirm: Closure called when confirmed
    ///   - onCancel: Optional closure called when cancelled
    public func showConfirmation(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let alert = AIAlert(
            title: title,
            message: message,
            type: .warning,
            primaryAction: AIAlert.AlertAction(
                title: confirmTitle,
                style: .default,
                handler: onConfirm
            ),
            secondaryAction: AIAlert.AlertAction(
                title: "Cancel",
                style: .cancel,
                handler: { onCancel?() }
            )
        )
        presentAlert(alert)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
}

// MARK: - Codable Conformance

extension AIDestination: Codable {}
extension AISheet: Codable {}
extension AIFullScreen: Codable {}

extension AIAlert: Codable {
    enum CodingKeys: String, CodingKey {
        case title, message, type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        type = try container.decode(AlertType.self, forKey: .type)
        
        // Default actions for decoded alerts
        primaryAction = AlertAction(title: "OK", handler: {})
        secondaryAction = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encode(type, forKey: .type)
    }
}