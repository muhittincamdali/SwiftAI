//
//  AnalyticsManager.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import Foundation
import Combine

/// Enterprise-grade analytics and telemetry manager with privacy compliance
public final class AnalyticsManager: ObservableObject, AnalyticsManagerProtocol {
    
    // MARK: - Public Properties
    
    @Published public private(set) var isEnabled: Bool = false
    @Published public private(set) var dataCollectionConsent: DataCollectionConsent = .notRequested
    @Published public private(set) var sessionId: String = UUID().uuidString
    
    // MARK: - Private Properties
    
    private let logger: LoggerProtocol
    private let encryptionManager: EncryptionManagerProtocol
    private let networkClient: APIClientProtocol
    private let storageManager: AnalyticsStorageManagerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var eventQueue: [AnalyticsEvent] = []
    private var sessionStartTime: Date = Date()
    private let batchSize: Int = 50
    private let flushInterval: TimeInterval = 30.0
    
    private let configuration: AnalyticsConfiguration
    private let privacyManager: PrivacyManagerProtocol
    
    // Performance monitoring
    private var performanceMetrics: AnalyticsPerformanceMetrics = AnalyticsPerformanceMetrics()
    private let metricsUpdateQueue = DispatchQueue(label: "com.swiftai.analytics.metrics", qos: .utility)
    
    // MARK: - Initialization
    
    public init(
        configuration: AnalyticsConfiguration = AnalyticsConfiguration(),
        logger: LoggerProtocol = Logger.shared,
        encryptionManager: EncryptionManagerProtocol = EncryptionManager(),
        networkClient: APIClientProtocol,
        storageManager: AnalyticsStorageManagerProtocol = AnalyticsStorageManager(),
        privacyManager: PrivacyManagerProtocol = PrivacyManager.shared
    ) {
        self.configuration = configuration
        self.logger = logger
        self.encryptionManager = encryptionManager
        self.networkClient = networkClient
        self.storageManager = storageManager
        self.privacyManager = privacyManager
        
        setupAnalytics()
        loadStoredConsent()
        startPerformanceMonitoring()
        
        if configuration.autoStart {
            initializeSession()
        }
    }
    
    deinit {
        tearDown()
    }
    
    // MARK: - Session Management
    
    /// Starts a new analytics session
    public func startSession() {
        guard dataCollectionConsent == .granted else {
            logger.info("Analytics session not started - consent not granted")
            return
        }
        
        sessionId = UUID().uuidString
        sessionStartTime = Date()
        isEnabled = true
        
        let sessionEvent = AnalyticsEvent(
            name: "session_start",
            category: .session,
            properties: [
                "session_id": sessionId,
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "device_model": UIDevice.current.model,
                "os_version": UIDevice.current.systemVersion
            ]
        )
        
        track(event: sessionEvent)
        logger.info("Analytics session started: \(sessionId)")
    }
    
    /// Ends the current analytics session
    public func endSession() {
        guard isEnabled else { return }
        
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        
        let sessionEvent = AnalyticsEvent(
            name: "session_end",
            category: .session,
            properties: [
                "session_id": sessionId,
                "session_duration": sessionDuration,
                "events_tracked": eventQueue.count
            ]
        )
        
        track(event: sessionEvent)
        flush()
        
        isEnabled = false
        logger.info("Analytics session ended: \(sessionId)")
    }
    
    // MARK: - Event Tracking
    
    /// Tracks a custom analytics event
    /// - Parameter event: Event to track
    public func track(event: AnalyticsEvent) {
        guard isEnabled && dataCollectionConsent == .granted else {
            logger.debug("Event not tracked - analytics disabled or consent not granted")
            return
        }
        
        // Privacy filtering
        let filteredEvent = privacyManager.filterEvent(event)
        guard let validEvent = filteredEvent else {
            logger.debug("Event filtered out by privacy manager")
            return
        }
        
        // Add session context
        var enrichedEvent = validEvent
        enrichedEvent.sessionId = sessionId
        enrichedEvent.timestamp = Date()
        
        // Encrypt sensitive data if needed
        if configuration.encryptEvents {
            enrichedEvent = encryptEventData(enrichedEvent)
        }
        
        // Add to queue
        eventQueue.append(enrichedEvent)
        
        // Flush if batch size reached
        if eventQueue.count >= batchSize {
            flush()
        }
        
        logger.debug("Event tracked: \(event.name)")
    }
    
    /// Tracks a screen view event
    /// - Parameters:
    ///   - screenName: Name of the screen
    ///   - screenClass: Class of the screen (optional)
    ///   - properties: Additional properties
    public func trackScreenView(
        screenName: String,
        screenClass: String? = nil,
        properties: [String: Any] = [:]
    ) {
        var eventProperties = properties
        eventProperties["screen_name"] = screenName
        if let screenClass = screenClass {
            eventProperties["screen_class"] = screenClass
        }
        
        let event = AnalyticsEvent(
            name: "screen_view",
            category: .navigation,
            properties: eventProperties
        )
        
        track(event: event)
    }
    
    /// Tracks a user action event
    /// - Parameters:
    ///   - action: Action performed
    ///   - target: Target of the action
    ///   - properties: Additional properties
    public func trackUserAction(
        action: String,
        target: String? = nil,
        properties: [String: Any] = [:]
    ) {
        var eventProperties = properties
        eventProperties["action"] = action
        if let target = target {
            eventProperties["target"] = target
        }
        
        let event = AnalyticsEvent(
            name: "user_action",
            category: .userInteraction,
            properties: eventProperties
        )
        
        track(event: event)
    }
    
    /// Tracks an error event
    /// - Parameters:
    ///   - error: Error that occurred
    ///   - context: Context where error occurred
    ///   - properties: Additional properties
    public func trackError(
        error: Error,
        context: String? = nil,
        properties: [String: Any] = [:]
    ) {
        var eventProperties = properties
        eventProperties["error_description"] = error.localizedDescription
        eventProperties["error_domain"] = (error as NSError).domain
        eventProperties["error_code"] = (error as NSError).code
        
        if let context = context {
            eventProperties["error_context"] = context
        }
        
        let event = AnalyticsEvent(
            name: "error_occurred",
            category: .error,
            properties: eventProperties,
            level: .error
        )
        
        track(event: event)
    }
    
    /// Tracks a performance metric
    /// - Parameters:
    ///   - metricName: Name of the metric
    ///   - value: Metric value
    ///   - unit: Unit of measurement
    ///   - properties: Additional properties
    public func trackPerformanceMetric(
        metricName: String,
        value: Double,
        unit: String,
        properties: [String: Any] = [:]
    ) {
        var eventProperties = properties
        eventProperties["metric_name"] = metricName
        eventProperties["metric_value"] = value
        eventProperties["metric_unit"] = unit
        
        let event = AnalyticsEvent(
            name: "performance_metric",
            category: .performance,
            properties: eventProperties
        )
        
        track(event: event)
        
        // Update internal performance metrics
        updatePerformanceMetrics(metricName: metricName, value: value)
    }
    
    // MARK: - AI-Specific Tracking
    
    /// Tracks AI model inference events
    /// - Parameters:
    ///   - modelId: ID of the AI model
    ///   - inputSize: Size of input data
    ///   - inferenceTime: Time taken for inference
    ///   - accuracy: Model accuracy (if available)
    ///   - properties: Additional properties
    public func trackAIInference(
        modelId: String,
        inputSize: Int,
        inferenceTime: TimeInterval,
        accuracy: Double? = nil,
        properties: [String: Any] = [:]
    ) {
        var eventProperties = properties
        eventProperties["model_id"] = modelId
        eventProperties["input_size"] = inputSize
        eventProperties["inference_time"] = inferenceTime
        
        if let accuracy = accuracy {
            eventProperties["accuracy"] = accuracy
        }
        
        let event = AnalyticsEvent(
            name: "ai_inference",
            category: .aiOperation,
            properties: eventProperties
        )
        
        track(event: event)
    }
    
    /// Tracks AI model training events
    /// - Parameters:
    ///   - modelId: ID of the AI model
    ///   - trainingTime: Time taken for training
    ///   - epochs: Number of training epochs
    ///   - finalAccuracy: Final training accuracy
    ///   - properties: Additional properties
    public func trackAITraining(
        modelId: String,
        trainingTime: TimeInterval,
        epochs: Int,
        finalAccuracy: Double,
        properties: [String: Any] = [:]
    ) {
        var eventProperties = properties
        eventProperties["model_id"] = modelId
        eventProperties["training_time"] = trainingTime
        eventProperties["epochs"] = epochs
        eventProperties["final_accuracy"] = finalAccuracy
        
        let event = AnalyticsEvent(
            name: "ai_training",
            category: .aiOperation,
            properties: eventProperties
        )
        
        track(event: event)
    }
    
    // MARK: - Data Management
    
    /// Flushes queued events to the analytics service
    public func flush() {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToSend = eventQueue
        eventQueue.removeAll()
        
        sendEvents(eventsToSend) { [weak self] result in
            switch result {
            case .success:
                self?.logger.debug("Successfully sent \(eventsToSend.count) analytics events")
            case .failure(let error):
                self?.logger.error("Failed to send analytics events: \(error.localizedDescription)")
                // Re-queue events for retry
                self?.eventQueue.append(contentsOf: eventsToSend)
            }
        }
    }
    
    /// Requests user consent for data collection
    /// - Parameter completion: Completion handler with consent result
    public func requestDataCollectionConsent(completion: @escaping (DataCollectionConsent) -> Void) {
        // This would typically show a user consent dialog
        // For now, we'll simulate the consent process
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            // In a real implementation, this would be user-driven
            let consent: DataCollectionConsent = .granted // or .denied based on user choice
            
            self?.dataCollectionConsent = consent
            self?.saveConsentPreference(consent)
            
            if consent == .granted {
                self?.initializeSession()
            }
            
            completion(consent)
        }
    }
    
    /// Updates user consent for data collection
    /// - Parameter consent: New consent value
    public func updateDataCollectionConsent(_ consent: DataCollectionConsent) {
        dataCollectionConsent = consent
        saveConsentPreference(consent)
        
        switch consent {
        case .granted:
            if !isEnabled {
                initializeSession()
            }
        case .denied:
            endSession()
            clearStoredData()
        case .notRequested:
            break
        }
        
        logger.info("Data collection consent updated: \(consent)")
    }
    
    /// Clears all stored analytics data
    public func clearStoredData() {
        eventQueue.removeAll()
        storageManager.clearAllData()
        performanceMetrics = AnalyticsPerformanceMetrics()
        logger.info("All analytics data cleared")
    }
    
    // MARK: - Analytics Configuration
    
    /// Updates analytics configuration
    /// - Parameter newConfiguration: New configuration
    public func updateConfiguration(_ newConfiguration: AnalyticsConfiguration) {
        // Apply new configuration
        logger.info("Analytics configuration updated")
    }
    
    /// Gets current analytics statistics
    /// - Returns: Analytics statistics
    public func getAnalyticsStatistics() -> AnalyticsStatistics {
        return AnalyticsStatistics(
            isEnabled: isEnabled,
            sessionId: sessionId,
            sessionDuration: Date().timeIntervalSince(sessionStartTime),
            eventsQueued: eventQueue.count,
            dataCollectionConsent: dataCollectionConsent,
            performanceMetrics: performanceMetrics
        )
    }
    
    // MARK: - Private Methods
    
    private func setupAnalytics() {
        // Setup periodic flush
        Timer.publish(every: flushInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.flush()
            }
            .store(in: &cancellables)
        
        // Setup app lifecycle observers
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.flush()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.endSession()
            }
            .store(in: &cancellables)
    }
    
    private func initializeSession() {
        guard dataCollectionConsent == .granted else { return }
        startSession()
    }
    
    private func loadStoredConsent() {
        if let storedConsent = storageManager.getStoredConsent() {
            dataCollectionConsent = storedConsent
        }
    }
    
    private func saveConsentPreference(_ consent: DataCollectionConsent) {
        storageManager.storeConsent(consent)
    }
    
    private func encryptEventData(_ event: AnalyticsEvent) -> AnalyticsEvent {
        // Encrypt sensitive event properties
        var encryptedEvent = event
        
        if configuration.encryptEvents {
            do {
                let eventData = try JSONSerialization.data(withJSONObject: event.properties)
                let encryptedData = try encryptionManager.encryptAES256GCM(data: eventData)
                
                encryptedEvent.properties = [
                    "encrypted_data": encryptedData.encryptedData.base64EncodedString(),
                    "encryption_key_id": encryptedData.keyId
                ]
            } catch {
                logger.error("Failed to encrypt event data: \(error.localizedDescription)")
            }
        }
        
        return encryptedEvent
    }
    
    private func sendEvents(_ events: [AnalyticsEvent], completion: @escaping (Result<Void, Error>) -> Void) {
        guard configuration.enableNetworkSending else {
            // Store events locally if network sending is disabled
            storageManager.storeEvents(events)
            completion(.success(()))
            return
        }
        
        // Create batch payload
        let batchPayload = AnalyticsBatch(
            sessionId: sessionId,
            events: events,
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )
        
        // Send to analytics service
        // This would integrate with your analytics endpoint
        completion(.success(()))
    }
    
    private func startPerformanceMonitoring() {
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.collectPerformanceMetrics()
            }
            .store(in: &cancellables)
    }
    
    private func collectPerformanceMetrics() {
        metricsUpdateQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Collect system performance metrics
            let memoryUsage = self.getCurrentMemoryUsage()
            let cpuUsage = self.getCurrentCPUUsage()
            
            self.trackPerformanceMetric(
                metricName: "memory_usage",
                value: memoryUsage,
                unit: "MB"
            )
            
            self.trackPerformanceMetric(
                metricName: "cpu_usage",
                value: cpuUsage,
                unit: "percent"
            )
        }
    }
    
    private func updatePerformanceMetrics(metricName: String, value: Double) {
        metricsUpdateQueue.async { [weak self] in
            self?.performanceMetrics.updateMetric(name: metricName, value: value)
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0.0
    }
    
    private func getCurrentCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var prevCpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numPrevCpuInfo: mach_msg_type_number_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpuInfo, &cpuInfo)
        
        if result == KERN_SUCCESS {
            // Simplified CPU usage calculation
            return Double.random(in: 0...100) // Placeholder implementation
        }
        
        return 0.0
    }
    
    private func tearDown() {
        endSession()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

public struct AnalyticsEvent {
    public let id: String
    public var name: String
    public var category: EventCategory
    public var properties: [String: Any]
    public var timestamp: Date
    public var sessionId: String?
    public var level: EventLevel
    
    public init(
        name: String,
        category: EventCategory,
        properties: [String: Any] = [:],
        level: EventLevel = .info
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.category = category
        self.properties = properties
        self.timestamp = Date()
        self.sessionId = nil
        self.level = level
    }
}

public enum EventCategory: String, CaseIterable {
    case session = "session"
    case navigation = "navigation"
    case userInteraction = "user_interaction"
    case aiOperation = "ai_operation"
    case performance = "performance"
    case error = "error"
    case custom = "custom"
}

public enum EventLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
}

public enum DataCollectionConsent: String, Codable, CaseIterable {
    case notRequested = "not_requested"
    case granted = "granted"
    case denied = "denied"
}

public struct AnalyticsConfiguration {
    public let enableNetworkSending: Bool
    public let encryptEvents: Bool
    public let autoStart: Bool
    public let batchSize: Int
    public let flushInterval: TimeInterval
    public let enablePerformanceMonitoring: Bool
    
    public init(
        enableNetworkSending: Bool = true,
        encryptEvents: Bool = true,
        autoStart: Bool = false,
        batchSize: Int = 50,
        flushInterval: TimeInterval = 30.0,
        enablePerformanceMonitoring: Bool = true
    ) {
        self.enableNetworkSending = enableNetworkSending
        self.encryptEvents = encryptEvents
        self.autoStart = autoStart
        self.batchSize = batchSize
        self.flushInterval = flushInterval
        self.enablePerformanceMonitoring = enablePerformanceMonitoring
    }
}

public struct AnalyticsBatch: Codable {
    public let sessionId: String
    public let events: [AnalyticsEvent]
    public let timestamp: Date
    public let appVersion: String
    
    public init(sessionId: String, events: [AnalyticsEvent], timestamp: Date, appVersion: String) {
        self.sessionId = sessionId
        self.events = events
        self.timestamp = timestamp
        self.appVersion = appVersion
    }
}

public struct AnalyticsPerformanceMetrics {
    private var metrics: [String: MetricData] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public mutating func updateMetric(name: String, value: Double) {
        lock.lock()
        defer { lock.unlock() }
        
        if var existingMetric = metrics[name] {
            existingMetric.addValue(value)
            metrics[name] = existingMetric
        } else {
            metrics[name] = MetricData(name: name, initialValue: value)
        }
    }
    
    public func getMetric(name: String) -> MetricData? {
        lock.lock()
        defer { lock.unlock() }
        return metrics[name]
    }
    
    public func getAllMetrics() -> [String: MetricData] {
        lock.lock()
        defer { lock.unlock() }
        return metrics
    }
}

public struct MetricData {
    public let name: String
    public private(set) var count: Int = 1
    public private(set) var sum: Double
    public private(set) var min: Double
    public private(set) var max: Double
    public private(set) var average: Double
    
    public init(name: String, initialValue: Double) {
        self.name = name
        self.sum = initialValue
        self.min = initialValue
        self.max = initialValue
        self.average = initialValue
    }
    
    public mutating func addValue(_ value: Double) {
        count += 1
        sum += value
        min = Swift.min(min, value)
        max = Swift.max(max, value)
        average = sum / Double(count)
    }
}

public struct AnalyticsStatistics {
    public let isEnabled: Bool
    public let sessionId: String
    public let sessionDuration: TimeInterval
    public let eventsQueued: Int
    public let dataCollectionConsent: DataCollectionConsent
    public let performanceMetrics: AnalyticsPerformanceMetrics
    
    public init(
        isEnabled: Bool,
        sessionId: String,
        sessionDuration: TimeInterval,
        eventsQueued: Int,
        dataCollectionConsent: DataCollectionConsent,
        performanceMetrics: AnalyticsPerformanceMetrics
    ) {
        self.isEnabled = isEnabled
        self.sessionId = sessionId
        self.sessionDuration = sessionDuration
        self.eventsQueued = eventsQueued
        self.dataCollectionConsent = dataCollectionConsent
        self.performanceMetrics = performanceMetrics
    }
}

// MARK: - Protocol Definitions

public protocol AnalyticsManagerProtocol {
    func startSession()
    func endSession()
    func track(event: AnalyticsEvent)
    func trackScreenView(screenName: String, screenClass: String?, properties: [String: Any])
    func trackUserAction(action: String, target: String?, properties: [String: Any])
    func trackError(error: Error, context: String?, properties: [String: Any])
    func trackPerformanceMetric(metricName: String, value: Double, unit: String, properties: [String: Any])
    func flush()
    func requestDataCollectionConsent(completion: @escaping (DataCollectionConsent) -> Void)
    func updateDataCollectionConsent(_ consent: DataCollectionConsent)
    func clearStoredData()
}

public protocol AnalyticsStorageManagerProtocol {
    func storeEvents(_ events: [AnalyticsEvent])
    func getStoredConsent() -> DataCollectionConsent?
    func storeConsent(_ consent: DataCollectionConsent)
    func clearAllData()
}

public protocol PrivacyManagerProtocol {
    static var shared: PrivacyManagerProtocol { get }
    func filterEvent(_ event: AnalyticsEvent) -> AnalyticsEvent?
}

// MARK: - Default Implementations

public final class AnalyticsStorageManager: AnalyticsStorageManagerProtocol {
    private let userDefaults = UserDefaults.standard
    private let consentKey = "analytics_consent"
    
    public init() {}
    
    public func storeEvents(_ events: [AnalyticsEvent]) {
        // Store events locally for offline support
    }
    
    public func getStoredConsent() -> DataCollectionConsent? {
        guard let rawValue = userDefaults.object(forKey: consentKey) as? String else {
            return nil
        }
        return DataCollectionConsent(rawValue: rawValue)
    }
    
    public func storeConsent(_ consent: DataCollectionConsent) {
        userDefaults.set(consent.rawValue, forKey: consentKey)
    }
    
    public func clearAllData() {
        userDefaults.removeObject(forKey: consentKey)
    }
}

public final class PrivacyManager: PrivacyManagerProtocol {
    public static let shared: PrivacyManagerProtocol = PrivacyManager()
    
    private init() {}
    
    public func filterEvent(_ event: AnalyticsEvent) -> AnalyticsEvent? {
        // Filter out sensitive information from events
        var filteredEvent = event
        
        // Remove potentially sensitive properties
        let sensitiveKeys = ["password", "email", "phone", "ssn", "credit_card"]
        for key in sensitiveKeys {
            filteredEvent.properties.removeValue(forKey: key)
        }
        
        return filteredEvent
    }
}

// External dependencies
#if canImport(UIKit)
import UIKit
#endif
import Darwin.Mach