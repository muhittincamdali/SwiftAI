// SwiftAI Domain Entity - Clean Architecture
// Copyright © 2024 SwiftAI. All rights reserved.
// Enterprise-Grade AI Model Entity with Domain Logic

import Foundation
import CoreML

/// Enterprise-grade AI Model domain entity
/// Represents core business logic for AI models in the domain layer
public struct AIModelEntity {
    
    // MARK: - Properties
    
    public let id: UUID
    public let name: String
    public let version: String
    public let type: ModelType
    public let status: ModelStatus
    public let configuration: ModelConfiguration
    public let metadata: ModelMetadata
    public let performance: PerformanceMetrics
    public let createdAt: Date
    public let updatedAt: Date
    
    // MARK: - Nested Types
    
    public enum ModelType: String, CaseIterable, Codable {
        case textGeneration = "text_generation"
        case imageClassification = "image_classification"
        case objectDetection = "object_detection"
        case sentimentAnalysis = "sentiment_analysis"
        case translation = "translation"
        case speechRecognition = "speech_recognition"
        case customVision = "custom_vision"
        case reinforcementLearning = "reinforcement_learning"
        
        var requiresGPU: Bool {
            switch self {
            case .imageClassification, .objectDetection, .customVision:
                return true
            default:
                return false
            }
        }
        
        var minimumMemoryMB: Int {
            switch self {
            case .textGeneration:
                return 512
            case .imageClassification, .objectDetection:
                return 1024
            case .customVision:
                return 2048
            case .reinforcementLearning:
                return 4096
            default:
                return 256
            }
        }
    }
    
    public enum ModelStatus: String, Codable {
        case idle
        case loading
        case ready
        case processing
        case error
        case updating
        case training
        case validating
        case optimizing
        
        var isOperational: Bool {
            switch self {
            case .ready, .processing:
                return true
            default:
                return false
            }
        }
    }
    
    public struct ModelConfiguration: Codable {
        public let inputShape: [Int]
        public let outputShape: [Int]
        public let batchSize: Int
        public let maxTokens: Int?
        public let temperature: Double?
        public let topK: Int?
        public let topP: Double?
        public let computeUnits: MLComputeUnits
        public let quantizationType: QuantizationType
        public let optimizationHints: [String]
        
        public enum QuantizationType: String, Codable {
            case float32
            case float16
            case int8
            case int4
            case mixed
        }
        
        public init(
            inputShape: [Int],
            outputShape: [Int],
            batchSize: Int = 1,
            maxTokens: Int? = nil,
            temperature: Double? = nil,
            topK: Int? = nil,
            topP: Double? = nil,
            computeUnits: MLComputeUnits = .all,
            quantizationType: QuantizationType = .float32,
            optimizationHints: [String] = []
        ) {
            self.inputShape = inputShape
            self.outputShape = outputShape
            self.batchSize = batchSize
            self.maxTokens = maxTokens
            self.temperature = temperature
            self.topK = topK
            self.topP = topP
            self.computeUnits = computeUnits
            self.quantizationType = quantizationType
            self.optimizationHints = optimizationHints
        }
    }
    
    public struct ModelMetadata: Codable {
        public let author: String
        public let license: String
        public let description: String
        public let tags: [String]
        public let framework: String
        public let frameworkVersion: String
        public let modelSize: Int64 // in bytes
        public let checksum: String
        public let supportedPlatforms: [String]
        public let requirements: SystemRequirements
        
        public struct SystemRequirements: Codable {
            public let minimumOSVersion: String
            public let minimumMemoryMB: Int
            public let recommendedMemoryMB: Int
            public let requiresNeuralEngine: Bool
            public let requiresGPU: Bool
            public let supportedArchitectures: [String]
        }
    }
    
    public struct PerformanceMetrics: Codable {
        public let accuracy: Double
        public let precision: Double
        public let recall: Double
        public let f1Score: Double
        public let inferenceTimeMs: Double
        public let throughput: Double // inferences per second
        public let memoryUsageMB: Double
        public let cpuUsagePercent: Double
        public let gpuUsagePercent: Double?
        public let energyImpact: EnergyImpact
        
        public enum EnergyImpact: String, Codable {
            case low
            case medium
            case high
            case veryHigh
        }
        
        public var efficiencyScore: Double {
            let accuracyWeight = 0.3
            let speedWeight = 0.3
            let memoryWeight = 0.2
            let energyWeight = 0.2
            
            let speedScore = min(1.0, 100.0 / max(1.0, inferenceTimeMs))
            let memoryScore = min(1.0, 500.0 / max(1.0, memoryUsageMB))
            let energyScore: Double = {
                switch energyImpact {
                case .low: return 1.0
                case .medium: return 0.7
                case .high: return 0.4
                case .veryHigh: return 0.1
                }
            }()
            
            return accuracy * accuracyWeight +
                   speedScore * speedWeight +
                   memoryScore * memoryWeight +
                   energyScore * energyWeight
        }
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        version: String,
        type: ModelType,
        status: ModelStatus = .idle,
        configuration: ModelConfiguration,
        metadata: ModelMetadata,
        performance: PerformanceMetrics,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.type = type
        self.status = status
        self.configuration = configuration
        self.metadata = metadata
        self.performance = performance
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Domain Logic
    
    /// Validates if the model can run on the current system
    public func canRunOnCurrentSystem() -> ValidationResult {
        var errors: [String] = []
        
        // Check memory requirements
        let availableMemory = ProcessInfo.processInfo.physicalMemory / (1024 * 1024) // Convert to MB
        let requiredMemory = Int64(metadata.requirements.minimumMemoryMB)
        
        if availableMemory < requiredMemory {
            errors.append("Insufficient memory: \(availableMemory)MB available, \(requiredMemory)MB required")
        }
        
        // Check OS version
        let currentOSVersion = ProcessInfo.processInfo.operatingSystemVersion
        let currentVersionString = "\(currentOSVersion.majorVersion).\(currentOSVersion.minorVersion)"
        
        if currentVersionString < metadata.requirements.minimumOSVersion {
            errors.append("OS version \(currentVersionString) is below minimum requirement \(metadata.requirements.minimumOSVersion)")
        }
        
        // Check architecture
        #if arch(arm64)
        let currentArch = "arm64"
        #elseif arch(x86_64)
        let currentArch = "x86_64"
        #else
        let currentArch = "unknown"
        #endif
        
        if !metadata.requirements.supportedArchitectures.contains(currentArch) {
            errors.append("Architecture \(currentArch) is not supported")
        }
        
        return errors.isEmpty ? .success : .failure(errors)
    }
    
    /// Calculates estimated processing time for given input size
    public func estimateProcessingTime(inputSize: Int) -> TimeInterval {
        let baseTime = performance.inferenceTimeMs / 1000.0 // Convert to seconds
        let batchFactor = Double(inputSize) / Double(configuration.batchSize)
        let overheadFactor = 1.1 // 10% overhead for memory management
        
        return baseTime * batchFactor * overheadFactor
    }
    
    /// Determines optimal batch size based on available memory
    public func optimalBatchSize(availableMemoryMB: Int) -> Int {
        let memoryPerBatch = performance.memoryUsageMB / Double(configuration.batchSize)
        let maxBatches = Double(availableMemoryMB) / memoryPerBatch
        let safetyFactor = 0.8 // Use only 80% of available memory
        
        return max(1, Int(maxBatches * safetyFactor))
    }
    
    /// Checks if model needs update based on version comparison
    public func needsUpdate(latestVersion: String) -> Bool {
        return version.compare(latestVersion, options: .numeric) == .orderedAscending
    }
    
    /// Validates model compatibility with another model for ensemble
    public func isCompatibleForEnsemble(with other: AIModelEntity) -> Bool {
        return type == other.type &&
               configuration.inputShape == other.configuration.inputShape &&
               configuration.outputShape == other.configuration.outputShape
    }
    
    // MARK: - Business Rules
    
    /// Determines if model should be cached based on usage patterns
    public func shouldCache(usageFrequency: Int, lastUsedDate: Date) -> Bool {
        let daysSinceLastUse = Calendar.current.dateComponents([.day], from: lastUsedDate, to: Date()).day ?? 0
        let cacheThreshold = 7 // days
        let frequencyThreshold = 10 // uses per week
        
        return daysSinceLastUse < cacheThreshold && usageFrequency >= frequencyThreshold
    }
    
    /// Calculates model priority for resource allocation
    public func resourcePriority(usageStats: UsageStatistics) -> ResourcePriority {
        let efficiencyWeight = 0.3
        let frequencyWeight = 0.4
        let criticalityWeight = 0.3
        
        let score = performance.efficiencyScore * efficiencyWeight +
                   usageStats.normalizedFrequency * frequencyWeight +
                   usageStats.criticalityScore * criticalityWeight
        
        switch score {
        case 0.8...1.0:
            return .critical
        case 0.6..<0.8:
            return .high
        case 0.4..<0.6:
            return .medium
        case 0.2..<0.4:
            return .low
        default:
            return .minimal
        }
    }
    
    // MARK: - Supporting Types
    
    public enum ValidationResult {
        case success
        case failure([String])
    }
    
    public struct UsageStatistics {
        public let totalInferences: Int
        public let weeklyInferences: Int
        public let averageResponseTime: Double
        public let errorRate: Double
        public let criticalityScore: Double // 0.0 to 1.0
        
        public var normalizedFrequency: Double {
            // Normalize weekly inferences to 0-1 scale (assuming 1000+ is very high)
            return min(1.0, Double(weeklyInferences) / 1000.0)
        }
    }
    
    public enum ResourcePriority: Int, Comparable {
        case minimal = 0
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
        
        public static func < (lhs: ResourcePriority, rhs: ResourcePriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - Equatable & Hashable

extension AIModelEntity: Equatable {
    public static func == (lhs: AIModelEntity, rhs: AIModelEntity) -> Bool {
        return lhs.id == rhs.id
    }
}

extension AIModelEntity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - MLComputeUnits Extension

extension MLComputeUnits: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value {
        case "cpuOnly":
            self = .cpuOnly
        case "cpuAndGPU":
            self = .cpuAndGPU
        case "cpuAndNeuralEngine":
            self = .cpuAndNeuralEngine
        case "all":
            self = .all
        default:
            self = .all
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .cpuOnly:
            try container.encode("cpuOnly")
        case .cpuAndGPU:
            try container.encode("cpuAndGPU")
        case .cpuAndNeuralEngine:
            try container.encode("cpuAndNeuralEngine")
        case .all:
            try container.encode("all")
        @unknown default:
            try container.encode("all")
        }
    }
}