// SwiftAI Domain Repository Protocols - Clean Architecture
// Copyright © 2024 SwiftAI. All rights reserved.
// Enterprise-Grade Repository Protocol Definitions

import Foundation
import Combine
import CoreML

// MARK: - AI Model Repository Protocol

/// Protocol defining AI model repository operations
public protocol AIModelRepositoryProtocol {
    /// Load AI model by ID
    func loadModel(id: UUID) -> AnyPublisher<AIModelEntity, RepositoryError>
    
    /// Load all available models
    func loadAllModels() -> AnyPublisher<[AIModelEntity], RepositoryError>
    
    /// Save or update model
    func saveModel(_ model: AIModelEntity) -> AnyPublisher<Void, RepositoryError>
    
    /// Delete model by ID
    func deleteModel(id: UUID) -> AnyPublisher<Void, RepositoryError>
    
    /// Search models by criteria
    func searchModels(criteria: ModelSearchCriteria) -> AnyPublisher<[AIModelEntity], RepositoryError>
    
    /// Update model usage statistics
    func updateUsageStatistics(modelId: UUID, inference: Bool, success: Bool) -> Void
    
    /// Get model performance metrics
    func getPerformanceMetrics(modelId: UUID) -> AnyPublisher<AIModelEntity.PerformanceMetrics, RepositoryError>
    
    /// Download model from remote source
    func downloadModel(url: URL, metadata: AIModelEntity.ModelMetadata) -> AnyPublisher<AIModelEntity, RepositoryError>
    
    /// Cache model for offline use
    func cacheModel(_ model: AIModelEntity) -> AnyPublisher<Void, RepositoryError>
    
    /// Clear model cache
    func clearCache() -> AnyPublisher<Void, RepositoryError>
}

// MARK: - AI Inference Engine Protocol

/// Protocol defining AI inference engine operations
public protocol AIInferenceEngineProtocol {
    /// Run inference on model with input
    func runInference(
        model: AIModelEntity,
        input: MLFeatureProvider,
        configuration: ProcessingConfiguration
    ) -> AnyPublisher<MLFeatureProvider, InferenceError>
    
    /// Run batch inference
    func runBatchInference(
        model: AIModelEntity,
        inputs: [MLFeatureProvider],
        configuration: ProcessingConfiguration
    ) -> AnyPublisher<[MLFeatureProvider], InferenceError>
    
    /// Warm up model for faster inference
    func warmUpModel(_ model: AIModelEntity) -> AnyPublisher<Void, InferenceError>
    
    /// Optimize model for device
    func optimizeModel(_ model: AIModelEntity, for device: DeviceProfile) -> AnyPublisher<AIModelEntity, InferenceError>
    
    /// Get model capabilities
    func getModelCapabilities(_ model: AIModelEntity) -> ModelCapabilities
}

// MARK: - Training Data Repository Protocol

/// Protocol defining training data repository operations
public protocol TrainingDataRepositoryProtocol {
    /// Load training dataset
    func loadDataset(id: UUID) -> AnyPublisher<TrainingDataset, RepositoryError>
    
    /// Save training dataset
    func saveDataset(_ dataset: TrainingDataset) -> AnyPublisher<Void, RepositoryError>
    
    /// Stream training data in batches
    func streamTrainingData(
        datasetId: UUID,
        batchSize: Int
    ) -> AnyPublisher<TrainingBatch, RepositoryError>
    
    /// Validate dataset integrity
    func validateDataset(_ dataset: TrainingDataset) -> AnyPublisher<DatasetValidation, RepositoryError>
    
    /// Split dataset for training/validation/test
    func splitDataset(
        _ dataset: TrainingDataset,
        ratios: DatasetSplitRatios
    ) -> AnyPublisher<SplitDatasets, RepositoryError>
    
    /// Augment dataset with transformations
    func augmentDataset(
        _ dataset: TrainingDataset,
        augmentations: [DataAugmentation]
    ) -> AnyPublisher<TrainingDataset, RepositoryError>
}

// MARK: - Model Training Repository Protocol

/// Protocol defining model training repository operations
public protocol ModelTrainingRepositoryProtocol {
    /// Start model training
    func startTraining(
        configuration: TrainingConfiguration
    ) -> AnyPublisher<TrainingSession, TrainingError>
    
    /// Monitor training progress
    func monitorTraining(sessionId: UUID) -> AnyPublisher<TrainingProgress, TrainingError>
    
    /// Stop training session
    func stopTraining(sessionId: UUID) -> AnyPublisher<TrainingResult, TrainingError>
    
    /// Resume training from checkpoint
    func resumeTraining(
        checkpointId: UUID,
        configuration: TrainingConfiguration
    ) -> AnyPublisher<TrainingSession, TrainingError>
    
    /// Save training checkpoint
    func saveCheckpoint(sessionId: UUID) -> AnyPublisher<TrainingCheckpoint, TrainingError>
    
    /// Get training history
    func getTrainingHistory(modelId: UUID) -> AnyPublisher<[TrainingSession], TrainingError>
}

// MARK: - Validation Service Protocol

/// Protocol defining validation service operations
public protocol ValidationServiceProtocol {
    /// Validate input data
    func validate(_ input: AIInput) -> ValidationResult
    
    /// Validate model configuration
    func validateConfiguration(_ configuration: ProcessingConfiguration) -> ValidationResult
    
    /// Validate security constraints
    func validateSecurity(_ request: Any) -> ValidationResult
    
    /// Validate performance requirements
    func validatePerformance(requirements: PerformanceRequirements) -> ValidationResult
}

// MARK: - Performance Monitor Protocol

/// Protocol defining performance monitoring operations
public protocol PerformanceMonitorProtocol {
    /// Start tracking operation
    func startTracking(operation: String)
    
    /// Stop tracking operation
    func stopTracking(operation: String)
    
    /// Get elapsed time for operation
    func getElapsedTime(operation: String) -> TimeInterval
    
    /// Get current metrics
    func getCurrentMetrics() -> PerformanceMetrics
    
    /// Send performance alert
    func sendAlert(level: AlertLevel, message: String, context: [String: Any])
    
    /// Record custom metric
    func recordMetric(name: String, value: Double, unit: MetricUnit)
}

// MARK: - Security Manager Protocol

/// Protocol defining security management operations
public protocol SecurityManagerProtocol {
    /// Validate request security
    func validateRequest(_ request: Any) -> Bool
    
    /// Encrypt data
    func encrypt(data: Data, key: String) -> AnyPublisher<Data, SecurityError>
    
    /// Decrypt data
    func decrypt(data: Data, key: String) -> AnyPublisher<Data, SecurityError>
    
    /// Sign data
    func sign(data: Data) -> AnyPublisher<Data, SecurityError>
    
    /// Verify signature
    func verifySignature(data: Data, signature: Data) -> AnyPublisher<Bool, SecurityError>
    
    /// Log audit event
    func logAuditEvent(_ event: AuditEvent)
    
    /// Check authorization
    func checkAuthorization(for action: SecurityAction) -> Bool
}

// MARK: - Cache Manager Protocol

/// Protocol defining cache management operations
public protocol CacheManagerProtocol {
    /// Get cached result
    func getCachedResult(for request: AIProcessingRequest) -> AIProcessingResult?
    
    /// Cache result
    func cacheResult(_ result: AIProcessingResult, for request: AIProcessingRequest)
    
    /// Clear cache
    func clearCache()
    
    /// Get cache size
    func getCacheSize() -> Int64
    
    /// Set cache policy
    func setCachePolicy(_ policy: CachePolicy)
    
    /// Prune expired cache entries
    func pruneExpiredEntries()
}

// MARK: - Analytics Service Protocol

/// Protocol defining analytics service operations
public protocol AnalyticsServiceProtocol {
    /// Track analytics event
    func trackEvent(_ event: AnalyticsEvent)
    
    /// Track user action
    func trackUserAction(_ action: UserAction)
    
    /// Track performance metric
    func trackPerformance(_ metric: PerformanceMetric)
    
    /// Track error
    func trackError(_ error: Error, context: [String: Any]?)
    
    /// Get analytics summary
    func getAnalyticsSummary(timeRange: TimeRange) -> AnyPublisher<AnalyticsSummary, AnalyticsError>
}

// MARK: - Supporting Types

public struct ModelSearchCriteria {
    public let type: AIModelEntity.ModelType?
    public let minAccuracy: Double?
    public let maxInferenceTime: TimeInterval?
    public let tags: [String]?
    public let platforms: [String]?
    
    public init(
        type: AIModelEntity.ModelType? = nil,
        minAccuracy: Double? = nil,
        maxInferenceTime: TimeInterval? = nil,
        tags: [String]? = nil,
        platforms: [String]? = nil
    ) {
        self.type = type
        self.minAccuracy = minAccuracy
        self.maxInferenceTime = maxInferenceTime
        self.tags = tags
        self.platforms = platforms
    }
}

public struct DeviceProfile {
    public let deviceType: String
    public let processorType: String
    public let memoryGB: Int
    public let hasNeuralEngine: Bool
    public let hasGPU: Bool
    
    public static var current: DeviceProfile {
        DeviceProfile(
            deviceType: "iPhone",
            processorType: ProcessInfo.processInfo.processorType,
            memoryGB: Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)),
            hasNeuralEngine: true,
            hasGPU: true
        )
    }
}

public struct ModelCapabilities {
    public let supportedInputTypes: [String]
    public let supportedOutputTypes: [String]
    public let maxBatchSize: Int
    public let supportsStreaming: Bool
    public let supportsQuantization: Bool
    public let supportedComputeUnits: [MLComputeUnits]
}

public struct TrainingDataset {
    public let id: UUID
    public let name: String
    public let type: DatasetType
    public let size: Int
    public let features: [String]
    public let labels: [String]
    public let metadata: [String: Any]
    
    public enum DatasetType {
        case image
        case text
        case audio
        case tabular
        case multimodal
    }
}

public struct TrainingBatch {
    public let batchNumber: Int
    public let data: [Any]
    public let labels: [Any]
    public let size: Int
}

public struct DatasetValidation {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    public let statistics: DatasetStatistics
}

public struct DatasetStatistics {
    public let totalSamples: Int
    public let classDistribution: [String: Int]
    public let featureStatistics: [String: FeatureStats]
    public let missingValues: Int
    public let outliers: Int
}

public struct FeatureStats {
    public let mean: Double
    public let std: Double
    public let min: Double
    public let max: Double
    public let uniqueValues: Int
}

public struct DatasetSplitRatios {
    public let train: Double
    public let validation: Double
    public let test: Double
    
    public init(train: Double = 0.7, validation: Double = 0.15, test: Double = 0.15) {
        self.train = train
        self.validation = validation
        self.test = test
    }
}

public struct SplitDatasets {
    public let train: TrainingDataset
    public let validation: TrainingDataset
    public let test: TrainingDataset
}

public enum DataAugmentation {
    case rotation(degrees: Double)
    case flip(horizontal: Bool, vertical: Bool)
    case crop(ratio: Double)
    case noise(level: Double)
    case colorJitter(brightness: Double, contrast: Double, saturation: Double)
    case mixup(alpha: Double)
    case cutout(ratio: Double)
}

public struct RepositoryTrainingConfiguration {
    public let modelId: UUID
    public let datasetId: UUID
    public let hyperparameters: Hyperparameters
    public let hardware: HardwareConfiguration
    public let callbacks: [TrainingCallback]
    
    public struct Hyperparameters {
        public let learningRate: Double
        public let batchSize: Int
        public let epochs: Int
        public let optimizer: OptimizerType
        public let lossFunction: LossFunction
        public let metrics: [MetricType]
    }
    
    public struct HardwareConfiguration {
        public let computeUnits: MLComputeUnits
        public let maxMemoryGB: Int
        public let distributedTraining: Bool
    }
}

public struct RepositoryTrainingSession {
    public let id: UUID
    public let modelId: UUID
    public let startTime: Date
    public let configuration: RepositoryTrainingConfiguration
    public let status: TrainingStatus
    
    public enum TrainingStatus {
        case preparing
        case running
        case paused
        case completed
        case failed(Error)
    }
}

public struct TrainingProgress {
    public let sessionId: UUID
    public let currentEpoch: Int
    public let totalEpochs: Int
    public let currentBatch: Int
    public let totalBatches: Int
    public let loss: Double
    public let metrics: [String: Double]
    public let estimatedTimeRemaining: TimeInterval
}

public struct TrainingResult {
    public let sessionId: UUID
    public let finalLoss: Double
    public let finalMetrics: [String: Double]
    public let trainedModel: AIModelEntity
    public let trainingTime: TimeInterval
    public let checkpoints: [TrainingCheckpoint]
}

public struct TrainingCheckpoint {
    public let id: UUID
    public let sessionId: UUID
    public let epoch: Int
    public let loss: Double
    public let metrics: [String: Double]
    public let timestamp: Date
    public let modelPath: URL
}

public protocol TrainingCallback {
    func onEpochStart(epoch: Int)
    func onEpochEnd(epoch: Int, logs: [String: Double])
    func onBatchStart(batch: Int)
    func onBatchEnd(batch: Int, logs: [String: Double])
    func onTrainingEnd(logs: [String: Double])
}

public enum OptimizerType {
    case sgd(momentum: Double)
    case adam(beta1: Double, beta2: Double)
    case rmsprop(decay: Double)
    case adagrad
}

public enum LossFunction {
    case crossEntropy
    case mse
    case mae
    case huber(delta: Double)
    case focal(alpha: Double, gamma: Double)
}

public enum MetricType {
    case accuracy
    case precision
    case recall
    case f1Score
    case auc
    case map
}

public struct ValidationResult {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    
    public init(isValid: Bool, errors: [String] = [], warnings: [String] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

public struct PerformanceRequirements {
    public let maxLatencyMs: Double
    public let minThroughput: Double
    public let maxMemoryMB: Double
    public let maxCPUPercent: Double
}

public struct PerformanceMetrics {
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let diskUsage: Double
    public let networkLatency: Double
    public let activeOperations: Int
    
    public init(cpuUsage: Double, memoryUsage: Double, diskUsage: Double, networkLatency: Double, activeOperations: Int) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.networkLatency = networkLatency
        self.activeOperations = activeOperations
    }
}

public enum AlertLevel {
    case info
    case warning
    case error
    case critical
}

public enum MetricUnit {
    case milliseconds
    case seconds
    case bytes
    case kilobytes
    case megabytes
    case gigabytes
    case percentage
    case count
}

public enum AuditEvent {
    case successfulInference(modelId: UUID, requestId: UUID)
    case failedInference(modelId: UUID, requestId: UUID, error: String)
    case modelLoaded(modelId: UUID)
    case modelDeleted(modelId: UUID)
    case securityViolation(details: String)
}

public enum SecurityAction {
    case loadModel
    case runInference
    case trainModel
    case deleteModel
    case accessSensitiveData
}

public struct CachePolicy {
    public let maxSizeBytes: Int64
    public let maxAge: TimeInterval
    public let evictionPolicy: EvictionPolicy
    
    public enum EvictionPolicy {
        case lru // Least Recently Used
        case lfu // Least Frequently Used
        case fifo // First In First Out
        case ttl // Time To Live
    }
    
    public init(
        maxSizeBytes: Int64 = 100_000_000, // 100MB
        maxAge: TimeInterval = 3600, // 1 hour
        evictionPolicy: EvictionPolicy = .lru
    ) {
        self.maxSizeBytes = maxSizeBytes
        self.maxAge = maxAge
        self.evictionPolicy = evictionPolicy
    }
    
    /// Default cache policy
    public static let `default` = CachePolicy()
}

public enum AnalyticsEvent {
    case cacheHit(request: AIProcessingRequest)
    case inferenceCompleted(request: AIProcessingRequest, result: AIProcessingResult)
    case processingSuccess(request: AIProcessingRequest, result: AIProcessingResult, duration: TimeInterval)
    case processingError(request: AIProcessingRequest, error: AIProcessingError)
}

public struct UserAction {
    public let action: String
    public let category: String
    public let metadata: [String: Any]
}

public struct PerformanceMetric {
    public let name: String
    public let value: Double
    public let unit: MetricUnit
    public let timestamp: Date
}

public struct TimeRange {
    public let start: Date
    public let end: Date
}

public struct AnalyticsSummary {
    public let totalRequests: Int
    public let successRate: Double
    public let averageLatency: Double
    public let topModels: [(modelId: UUID, count: Int)]
    public let errorDistribution: [String: Int]
}

// MARK: - Error Types

public enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed(String)
    case deleteFailed(String)
    case loadFailed(String)
    case networkError(String)
    case invalidData(String)
    
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Resource not found"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .loadFailed(let message):
            return "Load failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}

public enum InferenceError: LocalizedError {
    case modelNotReady
    case inputMismatch
    case computeError(String)
    case timeout
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .modelNotReady:
            return "Model is not ready for inference"
        case .inputMismatch:
            return "Input dimensions do not match model requirements"
        case .computeError(let message):
            return "Compute error: \(message)"
        case .timeout:
            return "Inference timeout"
        case .cancelled:
            return "Inference cancelled"
        }
    }
}

public enum TrainingError: LocalizedError {
    case datasetNotFound
    case invalidConfiguration
    case insufficientResources
    case trainingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .datasetNotFound:
            return "Training dataset not found"
        case .invalidConfiguration:
            return "Invalid training configuration"
        case .insufficientResources:
            return "Insufficient resources for training"
        case .trainingFailed(let message):
            return "Training failed: \(message)"
        }
    }
}

public enum SecurityError: LocalizedError {
    case unauthorized
    case encryptionFailed
    case decryptionFailed
    case signatureFailed
    
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized access"
        case .encryptionFailed:
            return "Encryption failed"
        case .decryptionFailed:
            return "Decryption failed"
        case .signatureFailed:
            return "Signature verification failed"
        }
    }
}

public enum AnalyticsError: LocalizedError {
    case trackingFailed
    case reportGenerationFailed
    
    public var errorDescription: String? {
        switch self {
        case .trackingFailed:
            return "Analytics tracking failed"
        case .reportGenerationFailed:
            return "Report generation failed"
        }
    }
}

// MARK: - ProcessInfo Extension

extension ProcessInfo {
    var processorType: String {
        #if arch(arm64)
        return "Apple Silicon"
        #elseif arch(x86_64)
        return "Intel"
        #else
        return "Unknown"
        #endif
    }
}