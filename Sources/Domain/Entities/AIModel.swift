import Foundation
import CoreML
import Vision

// MARK: - AI Model Entity
public struct AIModel: Equatable, Hashable, Codable {
    
    // MARK: - Properties
    public let id: UUID
    public let name: String
    public let version: String
    public let type: ModelType
    public let inputType: AIInputType
    public let outputType: AIOutputType
    public let size: Int64
    public let accuracy: Double
    public let createdAt: Date
    public let updatedAt: Date
    public let metadata: ModelMetadata
    public let configuration: ModelConfiguration
    public let performance: ModelPerformance
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        name: String,
        version: String,
        type: ModelType,
        inputType: AIInputType,
        outputType: AIOutputType,
        size: Int64,
        accuracy: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: ModelMetadata,
        configuration: ModelConfiguration,
        performance: ModelPerformance
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.type = type
        self.inputType = inputType
        self.outputType = outputType
        self.size = size
        self.accuracy = accuracy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
        self.configuration = configuration
        self.performance = performance
    }
    
    // MARK: - Validation
    public var isValid: Bool {
        return !name.isEmpty &&
               !version.isEmpty &&
               size > 0 &&
               accuracy >= 0.0 && accuracy <= 1.0 &&
               metadata.isValid &&
               configuration.isValid &&
               performance.isValid
    }
    
    public func validate() throws {
        guard isValid else {
            throw AIModelError.invalidModel
        }
        
        try metadata.validate()
        try configuration.validate()
        try performance.validate()
    }
    
    // MARK: - Model Operations
    public func canProcess(_ input: AIInput) -> Bool {
        return input.type == inputType
    }
    
    public func estimateProcessingTime(for input: AIInput) -> TimeInterval {
        let baseTime = performance.averageInferenceTime
        let inputSize = Double(input.size)
        let modelSize = Double(size)
        
        return baseTime * (inputSize / 1024.0) * (modelSize / 1024.0)
    }
    
    public func estimateMemoryUsage(for input: AIInput) -> Int64 {
        let baseMemory = performance.averageMemoryUsage
        let inputSize = Double(input.size)
        let modelSize = Double(size)
        
        return Int64(baseMemory * (inputSize / 1024.0) * (modelSize / 1024.0))
    }
    
    // MARK: - Model Comparison
    public func isBetterThan(_ other: AIModel) -> Bool {
        let accuracyWeight = 0.7
        let performanceWeight = 0.3
        
        let accuracyScore = accuracy - other.accuracy
        let performanceScore = (other.performance.averageInferenceTime - performance.averageInferenceTime) / max(performance.averageInferenceTime, 0.001)
        
        let totalScore = accuracyScore * accuracyWeight + performanceScore * performanceWeight
        return totalScore > 0
    }
    
    // MARK: - Model Updates
    public func updatePerformance(_ newPerformance: ModelPerformance) -> AIModel {
        return AIModel(
            id: id,
            name: name,
            version: version,
            type: type,
            inputType: inputType,
            outputType: outputType,
            size: size,
            accuracy: accuracy,
            createdAt: createdAt,
            updatedAt: Date(),
            metadata: metadata,
            configuration: configuration,
            performance: newPerformance
        )
    }
    
    public func updateAccuracy(_ newAccuracy: Double) -> AIModel {
        return AIModel(
            id: id,
            name: name,
            version: version,
            type: type,
            inputType: inputType,
            outputType: outputType,
            size: size,
            accuracy: newAccuracy,
            createdAt: createdAt,
            updatedAt: Date(),
            metadata: metadata,
            configuration: configuration,
            performance: performance
        )
    }
}

// MARK: - Model Type
public enum ModelType: String, CaseIterable, Codable {
    case classification
    case detection
    case generation
    case translation
    case sentiment
    case summarization
    case questionAnswering
    case textToSpeech
    case speechToText
    case imageToText
    case textToImage
    case custom
}

// MARK: - AI Output Type
public enum AIOutputType: String, CaseIterable, Codable {
    case classification
    case detection
    case generation
    case translation
    case sentiment
    case summarization
    case questionAnswering
    case audio
    case image
    case custom
}

// MARK: - Model Metadata
public struct ModelMetadata: Equatable, Hashable, Codable {
    public let description: String
    public let author: String
    public let license: String
    public let tags: [String]
    public let framework: String
    public let trainingData: String
    public let trainingMetrics: [String: Double]
    public let validationMetrics: [String: Double]
    public let testMetrics: [String: Double]
    
    public var isValid: Bool {
        return !description.isEmpty &&
               !author.isEmpty &&
               !license.isEmpty &&
               !framework.isEmpty &&
               !trainingData.isEmpty
    }
    
    public func validate() throws {
        guard isValid else {
            throw AIModelError.invalidMetadata
        }
    }
    
    public init(
        description: String,
        author: String,
        license: String,
        tags: [String] = [],
        framework: String,
        trainingData: String,
        trainingMetrics: [String: Double] = [:],
        validationMetrics: [String: Double] = [:],
        testMetrics: [String: Double] = [:]
    ) {
        self.description = description
        self.author = author
        self.license = license
        self.tags = tags
        self.framework = framework
        self.trainingData = trainingData
        self.trainingMetrics = trainingMetrics
        self.validationMetrics = validationMetrics
        self.testMetrics = testMetrics
    }
}

// MARK: - Model Configuration
public struct ModelConfiguration: Equatable, Hashable, Codable {
    public let enableGPU: Bool
    public let enableNeuralEngine: Bool
    public let batchSize: Int
    public let maxConcurrentRequests: Int
    public let timeout: TimeInterval
    public let memoryLimit: Int64
    public let quantization: QuantizationType
    public let optimization: OptimizationType
    
    public var isValid: Bool {
        return batchSize > 0 &&
               maxConcurrentRequests > 0 &&
               timeout > 0 &&
               memoryLimit > 0
    }
    
    public func validate() throws {
        guard isValid else {
            throw AIModelError.invalidConfiguration
        }
    }
    
    public init(
        enableGPU: Bool = true,
        enableNeuralEngine: Bool = true,
        batchSize: Int = 1,
        maxConcurrentRequests: Int = 4,
        timeout: TimeInterval = 30.0,
        memoryLimit: Int64 = 100 * 1024 * 1024,
        quantization: QuantizationType = .none,
        optimization: OptimizationType = .none
    ) {
        self.enableGPU = enableGPU
        self.enableNeuralEngine = enableNeuralEngine
        self.batchSize = batchSize
        self.maxConcurrentRequests = maxConcurrentRequests
        self.timeout = timeout
        self.memoryLimit = memoryLimit
        self.quantization = quantization
        self.optimization = optimization
    }
}

// MARK: - Quantization Type
public enum QuantizationType: String, CaseIterable, Codable {
    case none
    case int8
    case int16
    case float16
    case dynamic
}

// MARK: - Optimization Type
public enum OptimizationType: String, CaseIterable, Codable {
    case none
    case pruning
    case distillation
    case quantization
    case mixed
}

// MARK: - Model Performance
public struct ModelPerformance: Equatable, Hashable, Codable {
    public let averageInferenceTime: TimeInterval
    public let averageMemoryUsage: Int64
    public let peakMemoryUsage: Int64
    public let cacheHitRate: Double
    public let modelLoadTime: TimeInterval
    public let throughput: Double
    public let latency: TimeInterval
    public let accuracy: Double
    public let precision: Double
    public let recall: Double
    public let f1Score: Double
    
    public var isValid: Bool {
        return averageInferenceTime >= 0 &&
               averageMemoryUsage >= 0 &&
               peakMemoryUsage >= 0 &&
               cacheHitRate >= 0.0 && cacheHitRate <= 1.0 &&
               modelLoadTime >= 0 &&
               throughput >= 0 &&
               latency >= 0 &&
               accuracy >= 0.0 && accuracy <= 1.0 &&
               precision >= 0.0 && precision <= 1.0 &&
               recall >= 0.0 && recall <= 1.0 &&
               f1Score >= 0.0 && f1Score <= 1.0
    }
    
    public func validate() throws {
        guard isValid else {
            throw AIModelError.invalidPerformance
        }
    }
    
    public init(
        averageInferenceTime: TimeInterval,
        averageMemoryUsage: Int64,
        peakMemoryUsage: Int64,
        cacheHitRate: Double,
        modelLoadTime: TimeInterval,
        throughput: Double,
        latency: TimeInterval,
        accuracy: Double,
        precision: Double,
        recall: Double,
        f1Score: Double
    ) {
        self.averageInferenceTime = averageInferenceTime
        self.averageMemoryUsage = averageMemoryUsage
        self.peakMemoryUsage = peakMemoryUsage
        self.cacheHitRate = cacheHitRate
        self.modelLoadTime = modelLoadTime
        self.throughput = throughput
        self.latency = latency
        self.accuracy = accuracy
        self.precision = precision
        self.recall = recall
        self.f1Score = f1Score
    }
    
    // MARK: - Performance Metrics
    public var isEfficient: Bool {
        return averageInferenceTime < 1.0 &&
               averageMemoryUsage < 100 * 1024 * 1024 &&
               throughput > 1.0
    }
    
    public var isAccurate: Bool {
        return accuracy > 0.8 &&
               precision > 0.8 &&
               recall > 0.8 &&
               f1Score > 0.8
    }
    
    public var performanceScore: Double {
        let efficiencyScore = (1.0 / max(averageInferenceTime, 0.001)) * 
                             (1.0 / max(Double(averageMemoryUsage), 1.0)) * 
                             throughput
        
        let accuracyScore = (accuracy + precision + recall + f1Score) / 4.0
        
        return (efficiencyScore * 0.4) + (accuracyScore * 0.6)
    }
}

// MARK: - Model Factory
public class AIModelFactory {
    
    public static func createClassificationModel(
        name: String,
        version: String,
        inputType: AIInputType,
        accuracy: Double,
        performance: ModelPerformance
    ) -> AIModel {
        return AIModel(
            name: name,
            version: version,
            type: .classification,
            inputType: inputType,
            outputType: .classification,
            size: 50 * 1024 * 1024,
            accuracy: accuracy,
            metadata: ModelMetadata(
                description: "Classification model for \(inputType)",
                author: "SwiftAI",
                license: "MIT",
                framework: "Core ML",
                trainingData: "Custom dataset"
            ),
            configuration: ModelConfiguration(),
            performance: performance
        )
    }
    
    public static func createDetectionModel(
        name: String,
        version: String,
        inputType: AIInputType,
        accuracy: Double,
        performance: ModelPerformance
    ) -> AIModel {
        return AIModel(
            name: name,
            version: version,
            type: .detection,
            inputType: inputType,
            outputType: .detection,
            size: 100 * 1024 * 1024,
            accuracy: accuracy,
            metadata: ModelMetadata(
                description: "Detection model for \(inputType)",
                author: "SwiftAI",
                license: "MIT",
                framework: "Core ML",
                trainingData: "Custom dataset"
            ),
            configuration: ModelConfiguration(),
            performance: performance
        )
    }
    
    public static func createGenerationModel(
        name: String,
        version: String,
        inputType: AIInputType,
        accuracy: Double,
        performance: ModelPerformance
    ) -> AIModel {
        return AIModel(
            name: name,
            version: version,
            type: .generation,
            inputType: inputType,
            outputType: .generation,
            size: 200 * 1024 * 1024,
            accuracy: accuracy,
            metadata: ModelMetadata(
                description: "Generation model for \(inputType)",
                author: "SwiftAI",
                license: "MIT",
                framework: "Core ML",
                trainingData: "Custom dataset"
            ),
            configuration: ModelConfiguration(),
            performance: performance
        )
    }
}

// MARK: - Error Types
public enum AIModelError: Error {
    case invalidModel
    case invalidMetadata
    case invalidConfiguration
    case invalidPerformance
    case modelNotFound
    case modelLoadFailed
    case modelSaveFailed
    case modelDeleteFailed
    case modelValidationFailed
    case modelOptimizationFailed
    case incompatibleInputType
    case incompatibleOutputType
    case insufficientMemory
    case processingTimeout
    case modelCorrupted
}
