import Foundation
import CoreML

// MARK: - AI Repository Protocol
public protocol AIRepositoryProtocol {
    
    // MARK: - AI Processing
    func processAIInput(_ input: AIInput, type: AIInputType) async throws -> AIOutput
    func processBatchInputs(_ inputs: [AIInput], type: AIInputType) async throws -> [AIOutput]
    
    // MARK: - Model Management
    func loadModel(withName name: String) async throws -> MLModel
    func saveModel(_ model: MLModel, withName name: String) async throws
    func deleteModel(withName name: String) async throws
    func getAllModels() async throws -> [String]
    func validateModel(_ model: MLModel) async throws -> Bool
    func optimizeModel(_ model: MLModel) async throws -> MLModel
    
    // MARK: - History Management
    func getInferenceHistory() async throws -> [InferenceRecord]
    func clearInferenceHistory() async throws
    func getPerformanceMetrics() async throws -> PerformanceMetrics
    
    // MARK: - Remote Sync
    func syncWithRemote() async throws
    func checkForUpdates() async throws -> [ModelUpdate]
    func downloadUpdate(_ update: ModelUpdate) async throws -> MLModel
    
    // MARK: - Analytics
    func getAnalytics() async throws -> AIAnalytics
    func trackUsage(_ usage: AIUsage) async throws
    func getUsageStatistics() async throws -> AIUsageStatistics
}

// MARK: - AI Analytics
public struct AIAnalytics: Codable {
    public let totalInferences: Int
    public let averageProcessingTime: TimeInterval
    public let averageMemoryUsage: Int64
    public let successRate: Double
    public let errorRate: Double
    public let mostUsedModels: [String: Int]
    public let mostProcessedInputTypes: [AIInputType: Int]
    public let performanceTrends: [PerformanceTrend]
    public let lastUpdated: Date
    
    public init(
        totalInferences: Int,
        averageProcessingTime: TimeInterval,
        averageMemoryUsage: Int64,
        successRate: Double,
        errorRate: Double,
        mostUsedModels: [String: Int],
        mostProcessedInputTypes: [AIInputType: Int],
        performanceTrends: [PerformanceTrend],
        lastUpdated: Date = Date()
    ) {
        self.totalInferences = totalInferences
        self.averageProcessingTime = averageProcessingTime
        self.averageMemoryUsage = averageMemoryUsage
        self.successRate = successRate
        self.errorRate = errorRate
        self.mostUsedModels = mostUsedModels
        self.mostProcessedInputTypes = mostProcessedInputTypes
        self.performanceTrends = performanceTrends
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Performance Trend
public struct PerformanceTrend: Codable {
    public let date: Date
    public let averageProcessingTime: TimeInterval
    public let averageMemoryUsage: Int64
    public let successRate: Double
    public let inferenceCount: Int
    
    public init(
        date: Date,
        averageProcessingTime: TimeInterval,
        averageMemoryUsage: Int64,
        successRate: Double,
        inferenceCount: Int
    ) {
        self.date = date
        self.averageProcessingTime = averageProcessingTime
        self.averageMemoryUsage = averageMemoryUsage
        self.successRate = successRate
        self.inferenceCount = inferenceCount
    }
}

// MARK: - AI Usage
public struct AIUsage: Codable {
    public let modelName: String
    public let inputType: AIInputType
    public let processingTime: TimeInterval
    public let memoryUsage: Int64
    public let success: Bool
    public let errorMessage: String?
    public let timestamp: Date
    public let userId: String?
    public let sessionId: String
    
    public init(
        modelName: String,
        inputType: AIInputType,
        processingTime: TimeInterval,
        memoryUsage: Int64,
        success: Bool,
        errorMessage: String? = nil,
        timestamp: Date = Date(),
        userId: String? = nil,
        sessionId: String
    ) {
        self.modelName = modelName
        self.inputType = inputType
        self.processingTime = processingTime
        self.memoryUsage = memoryUsage
        self.success = success
        self.errorMessage = errorMessage
        self.timestamp = timestamp
        self.userId = userId
        self.sessionId = sessionId
    }
}

// MARK: - AI Usage Statistics
public struct AIUsageStatistics: Codable {
    public let totalUsage: Int
    public let successfulUsage: Int
    public let failedUsage: Int
    public let averageProcessingTime: TimeInterval
    public let averageMemoryUsage: Int64
    public let usageByModel: [String: Int]
    public let usageByInputType: [AIInputType: Int]
    public let usageByHour: [Int: Int]
    public let usageByDay: [String: Int]
    public let lastUsage: Date?
    
    public init(
        totalUsage: Int,
        successfulUsage: Int,
        failedUsage: Int,
        averageProcessingTime: TimeInterval,
        averageMemoryUsage: Int64,
        usageByModel: [String: Int],
        usageByInputType: [AIInputType: Int],
        usageByHour: [Int: Int],
        usageByDay: [String: Int],
        lastUsage: Date? = nil
    ) {
        self.totalUsage = totalUsage
        self.successfulUsage = successfulUsage
        self.failedUsage = failedUsage
        self.averageProcessingTime = averageProcessingTime
        self.averageMemoryUsage = averageMemoryUsage
        self.usageByModel = usageByModel
        self.usageByInputType = usageByInputType
        self.usageByHour = usageByHour
        self.usageByDay = usageByDay
        self.lastUsage = lastUsage
    }
    
    public var successRate: Double {
        guard totalUsage > 0 else { return 0.0 }
        return Double(successfulUsage) / Double(totalUsage)
    }
    
    public var failureRate: Double {
        guard totalUsage > 0 else { return 0.0 }
        return Double(failedUsage) / Double(totalUsage)
    }
}

// MARK: - Model Update
public struct ModelUpdate: Codable {
    public let modelName: String
    public let version: String
    public let downloadURL: URL
    public let releaseNotes: String
    public let isRequired: Bool
    public let releaseDate: Date
    public let size: Int64
    public let checksum: String
    
    public init(
        modelName: String,
        version: String,
        downloadURL: URL,
        releaseNotes: String,
        isRequired: Bool,
        releaseDate: Date,
        size: Int64,
        checksum: String
    ) {
        self.modelName = modelName
        self.version = version
        self.downloadURL = downloadURL
        self.releaseNotes = releaseNotes
        self.isRequired = isRequired
        self.releaseDate = releaseDate
        self.size = size
        self.checksum = checksum
    }
}

// MARK: - Repository Error Types
public enum AIRepositoryError: Error {
    case modelNotFound
    case modelLoadFailed
    case modelSaveFailed
    case modelDeleteFailed
    case modelValidationFailed
    case modelOptimizationFailed
    case inferenceFailed
    case batchProcessingFailed
    case historyLoadFailed
    case historyClearFailed
    case performanceMetricsFailed
    case remoteSyncFailed
    case networkError
    case invalidInput
    case processingTimeout
    case insufficientMemory
    case modelUpdateFailed
    case analyticsFailed
    case usageTrackingFailed
}
