import Foundation
import CoreML

// MARK: - AI Analytics Manager Protocol
public protocol AIAnalyticsManagerProtocol {
    func trackEvent(_ event: AnalyticsEvent) async throws
    func trackMetric(_ metric: AnalyticsMetric) async throws
    func trackError(_ error: Error, context: String) async throws
    func trackPerformance(_ performance: PerformanceMetrics) async throws
    func trackUsage(_ usage: AIUsage) async throws
    func getAnalytics() async throws -> AIAnalytics
    func getUsageStatistics() async throws -> AIUsageStatistics
    func clearAnalytics() async throws
}

// MARK: - AI Analytics Manager Implementation
public class AIAnalyticsManager: AIAnalyticsManagerProtocol {
    
    // MARK: - Properties
    private let storage: AnalyticsStorageProtocol
    private let processor: AnalyticsProcessorProtocol
    private let reporter: AnalyticsReporterProtocol
    private let privacyManager: PrivacyManagerProtocol
    
    // MARK: - Initialization
    public init(
        storage: AnalyticsStorageProtocol = AnalyticsStorage(),
        processor: AnalyticsProcessorProtocol = AnalyticsProcessor(),
        reporter: AnalyticsReporterProtocol = AnalyticsReporter(),
        privacyManager: PrivacyManagerProtocol = PrivacyManager()
    ) {
        self.storage = storage
        self.processor = processor
        self.reporter = reporter
        self.privacyManager = privacyManager
    }
    
    // MARK: - Event Tracking
    public func trackEvent(_ event: AnalyticsEvent) async throws {
        // Check privacy settings
        guard privacyManager.isAnalyticsEnabled() else {
            return
        }
        
        // Process event
        let processedEvent = try await processor.processEvent(event)
        
        // Store event
        try await storage.storeEvent(processedEvent)
        
        // Report event if needed
        if event.shouldReport {
            try await reporter.reportEvent(processedEvent)
        }
    }
    
    // MARK: - Metric Tracking
    public func trackMetric(_ metric: AnalyticsMetric) async throws {
        // Check privacy settings
        guard privacyManager.isAnalyticsEnabled() else {
            return
        }
        
        // Process metric
        let processedMetric = try await processor.processMetric(metric)
        
        // Store metric
        try await storage.storeMetric(processedMetric)
        
        // Report metric if needed
        if metric.shouldReport {
            try await reporter.reportMetric(processedMetric)
        }
    }
    
    // MARK: - Error Tracking
    public func trackError(_ error: Error, context: String) async throws {
        // Check privacy settings
        guard privacyManager.isErrorTrackingEnabled() else {
            return
        }
        
        // Create error event
        let errorEvent = AnalyticsEvent(
            name: "error_occurred",
            category: "error",
            properties: [
                "error_type": String(describing: type(of: error)),
                "error_message": error.localizedDescription,
                "context": context,
                "timestamp": Date()
            ],
            shouldReport: true
        )
        
        // Track error event
        try await trackEvent(errorEvent)
    }
    
    // MARK: - Performance Tracking
    public func trackPerformance(_ performance: PerformanceMetrics) async throws {
        // Check privacy settings
        guard privacyManager.isAnalyticsEnabled() else {
            return
        }
        
        // Create performance metric
        let performanceMetric = AnalyticsMetric(
            name: "performance_metrics",
            value: performance.averageInferenceTime,
            properties: [
                "memory_usage": performance.memoryUsage,
                "cache_hit_rate": performance.cacheHitRate,
                "model_load_time": performance.modelLoadTime
            ],
            shouldReport: true
        )
        
        // Track performance metric
        try await trackMetric(performanceMetric)
    }
    
    // MARK: - Usage Tracking
    public func trackUsage(_ usage: AIUsage) async throws {
        // Check privacy settings
        guard privacyManager.isAnalyticsEnabled() else {
            return
        }
        
        // Create usage event
        let usageEvent = AnalyticsEvent(
            name: "ai_usage",
            category: "usage",
            properties: [
                "model_name": usage.modelName,
                "input_type": usage.inputType.rawValue,
                "processing_time": usage.processingTime,
                "memory_usage": usage.memoryUsage,
                "success": usage.success,
                "session_id": usage.sessionId,
                "timestamp": usage.timestamp
            ],
            shouldReport: true
        )
        
        // Track usage event
        try await trackEvent(usageEvent)
    }
    
    // MARK: - Analytics Retrieval
    public func getAnalytics() async throws -> AIAnalytics {
        // Get events from storage
        let events = try await storage.getEvents()
        
        // Get metrics from storage
        let metrics = try await storage.getMetrics()
        
        // Process analytics
        let analytics = try await processor.processAnalytics(events: events, metrics: metrics)
        
        return analytics
    }
    
    // MARK: - Usage Statistics
    public func getUsageStatistics() async throws -> AIUsageStatistics {
        // Get usage events from storage
        let usageEvents = try await storage.getUsageEvents()
        
        // Process usage statistics
        let statistics = try await processor.processUsageStatistics(events: usageEvents)
        
        return statistics
    }
    
    // MARK: - Analytics Management
    public func clearAnalytics() async throws {
        try await storage.clearAll()
    }
}

// MARK: - Analytics Event
public struct AnalyticsEvent: Codable {
    public let id: UUID
    public let name: String
    public let category: String
    public let properties: [String: Any]
    public let timestamp: Date
    public let shouldReport: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        properties: [String: Any],
        timestamp: Date = Date(),
        shouldReport: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.properties = properties
        self.timestamp = timestamp
        self.shouldReport = shouldReport
    }
}

// MARK: - Analytics Metric
public struct AnalyticsMetric: Codable {
    public let id: UUID
    public let name: String
    public let value: Double
    public let properties: [String: Any]
    public let timestamp: Date
    public let shouldReport: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        value: Double,
        properties: [String: Any],
        timestamp: Date = Date(),
        shouldReport: Bool = false
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.properties = properties
        self.timestamp = timestamp
        self.shouldReport = shouldReport
    }
}

// MARK: - Analytics Storage Protocol
public protocol AnalyticsStorageProtocol {
    func storeEvent(_ event: AnalyticsEvent) async throws
    func storeMetric(_ metric: AnalyticsMetric) async throws
    func getEvents() async throws -> [AnalyticsEvent]
    func getMetrics() async throws -> [AnalyticsMetric]
    func getUsageEvents() async throws -> [AnalyticsEvent]
    func clearAll() async throws
}

// MARK: - Analytics Storage Implementation
public class AnalyticsStorage: AnalyticsStorageProtocol {
    
    private let fileManager = FileManager.default
    private let eventsURL: URL
    private let metricsURL: URL
    
    public init() throws {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AnalyticsError.storageInitializationFailed
        }
        
        self.eventsURL = documentsDirectory.appendingPathComponent("analytics_events.json")
        self.metricsURL = documentsDirectory.appendingPathComponent("analytics_metrics.json")
        
        try createDirectoriesIfNeeded()
    }
    
    public func storeEvent(_ event: AnalyticsEvent) async throws {
        var events = try await getEvents()
        events.append(event)
        
        let data = try JSONEncoder().encode(events)
        try data.write(to: eventsURL)
    }
    
    public func storeMetric(_ metric: AnalyticsMetric) async throws {
        var metrics = try await getMetrics()
        metrics.append(metric)
        
        let data = try JSONEncoder().encode(metrics)
        try data.write(to: metricsURL)
    }
    
    public func getEvents() async throws -> [AnalyticsEvent] {
        guard fileManager.fileExists(atPath: eventsURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: eventsURL)
        return try JSONDecoder().decode([AnalyticsEvent].self, from: data)
    }
    
    public func getMetrics() async throws -> [AnalyticsMetric] {
        guard fileManager.fileExists(atPath: metricsURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: metricsURL)
        return try JSONDecoder().decode([AnalyticsMetric].self, from: data)
    }
    
    public func getUsageEvents() async throws -> [AnalyticsEvent] {
        let events = try await getEvents()
        return events.filter { $0.category == "usage" }
    }
    
    public func clearAll() async throws {
        try? fileManager.removeItem(at: eventsURL)
        try? fileManager.removeItem(at: metricsURL)
    }
    
    private func createDirectoriesIfNeeded() throws {
        let directory = eventsURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Analytics Processor Protocol
public protocol AnalyticsProcessorProtocol {
    func processEvent(_ event: AnalyticsEvent) async throws -> AnalyticsEvent
    func processMetric(_ metric: AnalyticsMetric) async throws -> AnalyticsMetric
    func processAnalytics(events: [AnalyticsEvent], metrics: [AnalyticsMetric]) async throws -> AIAnalytics
    func processUsageStatistics(events: [AnalyticsEvent]) async throws -> AIUsageStatistics
}

// MARK: - Analytics Processor Implementation
public class AnalyticsProcessor: AnalyticsProcessorProtocol {
    
    public init() {}
    
    public func processEvent(_ event: AnalyticsEvent) async throws -> AnalyticsEvent {
        // Add processing timestamp
        var processedEvent = event
        processedEvent.properties["processed_at"] = Date()
        
        return processedEvent
    }
    
    public func processMetric(_ metric: AnalyticsMetric) async throws -> AnalyticsMetric {
        // Add processing timestamp
        var processedMetric = metric
        processedMetric.properties["processed_at"] = Date()
        
        return processedMetric
    }
    
    public func processAnalytics(events: [AnalyticsEvent], metrics: [AnalyticsMetric]) async throws -> AIAnalytics {
        let totalInferences = events.filter { $0.category == "usage" }.count
        let averageProcessingTime = calculateAverageProcessingTime(from: events)
        let averageMemoryUsage = calculateAverageMemoryUsage(from: events)
        let successRate = calculateSuccessRate(from: events)
        let errorRate = calculateErrorRate(from: events)
        let mostUsedModels = calculateMostUsedModels(from: events)
        let mostProcessedInputTypes = calculateMostProcessedInputTypes(from: events)
        let performanceTrends = calculatePerformanceTrends(from: metrics)
        
        return AIAnalytics(
            totalInferences: totalInferences,
            averageProcessingTime: averageProcessingTime,
            averageMemoryUsage: averageMemoryUsage,
            successRate: successRate,
            errorRate: errorRate,
            mostUsedModels: mostUsedModels,
            mostProcessedInputTypes: mostProcessedInputTypes,
            performanceTrends: performanceTrends,
            lastUpdated: Date()
        )
    }
    
    public func processUsageStatistics(events: [AnalyticsEvent]) async throws -> AIUsageStatistics {
        let totalUsage = events.count
        let successfulUsage = events.filter { $0.properties["success"] as? Bool == true }.count
        let failedUsage = totalUsage - successfulUsage
        let averageProcessingTime = calculateAverageProcessingTime(from: events)
        let averageMemoryUsage = calculateAverageMemoryUsage(from: events)
        let usageByModel = calculateUsageByModel(from: events)
        let usageByInputType = calculateUsageByInputType(from: events)
        let usageByHour = calculateUsageByHour(from: events)
        let usageByDay = calculateUsageByDay(from: events)
        let lastUsage = events.max { $0.timestamp < $1.timestamp }?.timestamp
        
        return AIUsageStatistics(
            totalUsage: totalUsage,
            successfulUsage: successfulUsage,
            failedUsage: failedUsage,
            averageProcessingTime: averageProcessingTime,
            averageMemoryUsage: averageMemoryUsage,
            usageByModel: usageByModel,
            usageByInputType: usageByInputType,
            usageByHour: usageByHour,
            usageByDay: usageByDay,
            lastUsage: lastUsage
        )
    }
    
    // MARK: - Private Helper Methods
    private func calculateAverageProcessingTime(from events: [AnalyticsEvent]) -> TimeInterval {
        let processingTimes = events.compactMap { $0.properties["processing_time"] as? TimeInterval }
        return processingTimes.isEmpty ? 0 : processingTimes.reduce(0, +) / Double(processingTimes.count)
    }
    
    private func calculateAverageMemoryUsage(from events: [AnalyticsEvent]) -> Int64 {
        let memoryUsages = events.compactMap { $0.properties["memory_usage"] as? Int64 }
        return memoryUsages.isEmpty ? 0 : memoryUsages.reduce(0, +) / Int64(memoryUsages.count)
    }
    
    private func calculateSuccessRate(from events: [AnalyticsEvent]) -> Double {
        let usageEvents = events.filter { $0.category == "usage" }
        let successfulEvents = usageEvents.filter { $0.properties["success"] as? Bool == true }
        return usageEvents.isEmpty ? 0 : Double(successfulEvents.count) / Double(usageEvents.count)
    }
    
    private func calculateErrorRate(from events: [AnalyticsEvent]) -> Double {
        let errorEvents = events.filter { $0.category == "error" }
        let totalEvents = events.count
        return totalEvents == 0 ? 0 : Double(errorEvents.count) / Double(totalEvents)
    }
    
    private func calculateMostUsedModels(from events: [AnalyticsEvent]) -> [String: Int] {
        let usageEvents = events.filter { $0.category == "usage" }
        var modelCounts: [String: Int] = [:]
        
        for event in usageEvents {
            if let modelName = event.properties["model_name"] as? String {
                modelCounts[modelName, default: 0] += 1
            }
        }
        
        return modelCounts
    }
    
    private func calculateMostProcessedInputTypes(from events: [AnalyticsEvent]) -> [AIInputType: Int] {
        let usageEvents = events.filter { $0.category == "usage" }
        var inputTypeCounts: [AIInputType: Int] = [:]
        
        for event in usageEvents {
            if let inputTypeString = event.properties["input_type"] as? String,
               let inputType = AIInputType(rawValue: inputTypeString) {
                inputTypeCounts[inputType, default: 0] += 1
            }
        }
        
        return inputTypeCounts
    }
    
    private func calculatePerformanceTrends(from metrics: [AnalyticsMetric]) -> [PerformanceTrend] {
        // Group metrics by date and calculate trends
        let groupedMetrics = Dictionary(grouping: metrics) { metric in
            Calendar.current.startOfDay(for: metric.timestamp)
        }
        
        return groupedMetrics.map { date, metrics in
            let averageProcessingTime = metrics.map { $0.value }.reduce(0, +) / Double(metrics.count)
            let averageMemoryUsage = metrics.compactMap { $0.properties["memory_usage"] as? Int64 }.reduce(0, +) / Int64(metrics.count)
            let successRate = 0.95 // Placeholder
            let inferenceCount = metrics.count
            
            return PerformanceTrend(
                date: date,
                averageProcessingTime: averageProcessingTime,
                averageMemoryUsage: averageMemoryUsage,
                successRate: successRate,
                inferenceCount: inferenceCount
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func calculateUsageByModel(from events: [AnalyticsEvent]) -> [String: Int] {
        return calculateMostUsedModels(from: events)
    }
    
    private func calculateUsageByInputType(from events: [AnalyticsEvent]) -> [AIInputType: Int] {
        return calculateMostProcessedInputTypes(from: events)
    }
    
    private func calculateUsageByHour(from events: [AnalyticsEvent]) -> [Int: Int] {
        var hourCounts: [Int: Int] = [:]
        
        for event in events {
            let hour = Calendar.current.component(.hour, from: event.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        
        return hourCounts
    }
    
    private func calculateUsageByDay(from events: [AnalyticsEvent]) -> [String: Int] {
        var dayCounts: [String: Int] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for event in events {
            let day = dateFormatter.string(from: event.timestamp)
            dayCounts[day, default: 0] += 1
        }
        
        return dayCounts
    }
}

// MARK: - Analytics Reporter Protocol
public protocol AnalyticsReporterProtocol {
    func reportEvent(_ event: AnalyticsEvent) async throws
    func reportMetric(_ metric: AnalyticsMetric) async throws
}

// MARK: - Analytics Reporter Implementation
public class AnalyticsReporter: AnalyticsReporterProtocol {
    
    public init() {}
    
    public func reportEvent(_ event: AnalyticsEvent) async throws {
        // In a real implementation, this would send data to analytics service
        // For now, we'll just log the event
        print("Reporting event: \(event.name)")
    }
    
    public func reportMetric(_ metric: AnalyticsMetric) async throws {
        // In a real implementation, this would send data to analytics service
        // For now, we'll just log the metric
        print("Reporting metric: \(metric.name) = \(metric.value)")
    }
}

// MARK: - Privacy Manager Protocol
public protocol PrivacyManagerProtocol {
    func isAnalyticsEnabled() -> Bool
    func isErrorTrackingEnabled() -> Bool
    func enableAnalytics()
    func disableAnalytics()
    func enableErrorTracking()
    func disableErrorTracking()
}

// MARK: - Privacy Manager Implementation
public class PrivacyManager: PrivacyManagerProtocol {
    
    private var analyticsEnabled = false
    private var errorTrackingEnabled = false
    
    public init() {}
    
    public func isAnalyticsEnabled() -> Bool {
        return analyticsEnabled
    }
    
    public func isErrorTrackingEnabled() -> Bool {
        return errorTrackingEnabled
    }
    
    public func enableAnalytics() {
        analyticsEnabled = true
    }
    
    public func disableAnalytics() {
        analyticsEnabled = false
    }
    
    public func enableErrorTracking() {
        errorTrackingEnabled = true
    }
    
    public func disableErrorTracking() {
        errorTrackingEnabled = false
    }
}

// MARK: - Analytics Error Types
public enum AnalyticsError: Error {
    case storageInitializationFailed
    case eventProcessingFailed
    case metricProcessingFailed
    case analyticsProcessingFailed
    case reportingFailed
    case privacyViolation
}
