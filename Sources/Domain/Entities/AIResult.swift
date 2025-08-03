import Foundation
import UIKit
import CoreML

// MARK: - AI Result Entity
public struct AIResult: Equatable, Hashable, Codable {
    
    // MARK: - Properties
    public let id: UUID
    public let input: AIInput
    public let output: AIOutput
    public let model: AIModel
    public let processingTime: TimeInterval
    public let memoryUsage: Int64
    public let confidence: Double
    public let timestamp: Date
    public let metadata: ResultMetadata
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        input: AIInput,
        output: AIOutput,
        model: AIModel,
        processingTime: TimeInterval,
        memoryUsage: Int64,
        confidence: Double,
        timestamp: Date = Date(),
        metadata: ResultMetadata
    ) {
        self.id = id
        self.input = input
        self.output = output
        self.model = model
        self.processingTime = processingTime
        self.memoryUsage = memoryUsage
        self.confidence = confidence
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    // MARK: - Validation
    public var isValid: Bool {
        return input.isValid &&
               processingTime >= 0 &&
               memoryUsage >= 0 &&
               confidence >= 0.0 && confidence <= 1.0 &&
               model.isValid &&
               metadata.isValid
    }
    
    public func validate() throws {
        guard isValid else {
            throw AIResultError.invalidResult
        }
        
        try input.validate()
        try model.validate()
        try metadata.validate()
    }
    
    // MARK: - Result Analysis
    public var isSuccessful: Bool {
        return confidence > 0.5 && processingTime < 30.0
    }
    
    public var isHighConfidence: Bool {
        return confidence > 0.8
    }
    
    public var isEfficient: Bool {
        return processingTime < 1.0 && memoryUsage < 100 * 1024 * 1024
    }
    
    public var performanceScore: Double {
        let confidenceScore = confidence
        let timeScore = max(0, 1.0 - (processingTime / 30.0))
        let memoryScore = max(0, 1.0 - (Double(memoryUsage) / (100.0 * 1024.0 * 1024.0)))
        
        return (confidenceScore * 0.5) + (timeScore * 0.3) + (memoryScore * 0.2)
    }
    
    // MARK: - Result Comparison
    public func isBetterThan(_ other: AIResult) -> Bool {
        return performanceScore > other.performanceScore
    }
    
    // MARK: - Result Conversion
    public func toClassificationResult() -> ClassificationResult? {
        guard case .classification(let classifications) = output else {
            return nil
        }
        
        return ClassificationResult(
            id: id,
            classifications: classifications,
            confidence: confidence,
            processingTime: processingTime,
            timestamp: timestamp
        )
    }
    
    public func toDetectionResult() -> DetectionResult? {
        guard case .detection(let detections) = output else {
            return nil
        }
        
        return DetectionResult(
            id: id,
            detections: detections,
            confidence: confidence,
            processingTime: processingTime,
            timestamp: timestamp
        )
    }
    
    public func toGenerationResult() -> GenerationResult? {
        guard case .generation(let text) = output else {
            return nil
        }
        
        return GenerationResult(
            id: id,
            generatedText: text,
            confidence: confidence,
            processingTime: processingTime,
            timestamp: timestamp
        )
    }
    
    public func toTranslationResult() -> TranslationResult? {
        guard case .translation(let text) = output else {
            return nil
        }
        
        return TranslationResult(
            id: id,
            translatedText: text,
            confidence: confidence,
            processingTime: processingTime,
            timestamp: timestamp
        )
    }
    
    public func toSentimentResult() -> SentimentResult? {
        guard case .sentiment(let sentiment) = output else {
            return nil
        }
        
        return SentimentResult(
            id: id,
            sentiment: sentiment,
            confidence: confidence,
            processingTime: processingTime,
            timestamp: timestamp
        )
    }
}

// MARK: - Classification Result
public struct ClassificationResult: Equatable, Hashable, Codable {
    public let id: UUID
    public let classifications: [String: Double]
    public let confidence: Double
    public let processingTime: TimeInterval
    public let timestamp: Date
    
    public var topClassification: (String, Double)? {
        return classifications.max { $0.value < $1.value }
    }
    
    public var sortedClassifications: [(String, Double)] {
        return classifications.sorted { $0.value > $1.value }
    }
    
    public init(
        id: UUID = UUID(),
        classifications: [String: Double],
        confidence: Double,
        processingTime: TimeInterval,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.classifications = classifications
        self.confidence = confidence
        self.processingTime = processingTime
        self.timestamp = timestamp
    }
}

// MARK: - Detection Result
public struct DetectionResult: Equatable, Hashable, Codable {
    public let id: UUID
    public let detections: [DetectionResult]
    public let confidence: Double
    public let processingTime: TimeInterval
    public let timestamp: Date
    
    public var topDetection: DetectionResult? {
        return detections.max { $0.confidence < $1.confidence }
    }
    
    public var sortedDetections: [DetectionResult] {
        return detections.sorted { $0.confidence > $1.confidence }
    }
    
    public init(
        id: UUID = UUID(),
        detections: [DetectionResult],
        confidence: Double,
        processingTime: TimeInterval,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.detections = detections
        self.confidence = confidence
        self.processingTime = processingTime
        self.timestamp = timestamp
    }
}

// MARK: - Generation Result
public struct GenerationResult: Equatable, Hashable, Codable {
    public let id: UUID
    public let generatedText: String
    public let confidence: Double
    public let processingTime: TimeInterval
    public let timestamp: Date
    
    public var wordCount: Int {
        return generatedText.components(separatedBy: .whitespacesAndNewlines).count
    }
    
    public var characterCount: Int {
        return generatedText.count
    }
    
    public init(
        id: UUID = UUID(),
        generatedText: String,
        confidence: Double,
        processingTime: TimeInterval,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.generatedText = generatedText
        self.confidence = confidence
        self.processingTime = processingTime
        self.timestamp = timestamp
    }
}

// MARK: - Translation Result
public struct TranslationResult: Equatable, Hashable, Codable {
    public let id: UUID
    public let translatedText: String
    public let confidence: Double
    public let processingTime: TimeInterval
    public let timestamp: Date
    
    public var wordCount: Int {
        return translatedText.components(separatedBy: .whitespacesAndNewlines).count
    }
    
    public var characterCount: Int {
        return translatedText.count
    }
    
    public init(
        id: UUID = UUID(),
        translatedText: String,
        confidence: Double,
        processingTime: TimeInterval,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.translatedText = translatedText
        self.confidence = confidence
        self.processingTime = processingTime
        self.timestamp = timestamp
    }
}

// MARK: - Sentiment Result
public struct SentimentResult: Equatable, Hashable, Codable {
    public let id: UUID
    public let sentiment: SentimentScore
    public let confidence: Double
    public let processingTime: TimeInterval
    public let timestamp: Date
    
    public var sentimentType: SentimentType {
        switch sentiment {
        case .positive:
            return .positive
        case .negative:
            return .negative
        case .neutral:
            return .neutral
        }
    }
    
    public var sentimentValue: Double {
        switch sentiment {
        case .positive(let value):
            return value
        case .negative(let value):
            return value
        case .neutral(let value):
            return value
        }
    }
    
    public init(
        id: UUID = UUID(),
        sentiment: SentimentScore,
        confidence: Double,
        processingTime: TimeInterval,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sentiment = sentiment
        self.confidence = confidence
        self.processingTime = processingTime
        self.timestamp = timestamp
    }
}

// MARK: - Sentiment Type
public enum SentimentType: String, CaseIterable, Codable {
    case positive
    case negative
    case neutral
}

// MARK: - Result Metadata
public struct ResultMetadata: Equatable, Hashable, Codable {
    public let modelVersion: String
    public let framework: String
    public let deviceInfo: String
    public let osVersion: String
    public let appVersion: String
    public let sessionId: String
    public let userId: String?
    public let tags: [String]
    public let customData: [String: String]
    
    public var isValid: Bool {
        return !modelVersion.isEmpty &&
               !framework.isEmpty &&
               !deviceInfo.isEmpty &&
               !osVersion.isEmpty &&
               !appVersion.isEmpty &&
               !sessionId.isEmpty
    }
    
    public func validate() throws {
        guard isValid else {
            throw AIResultError.invalidMetadata
        }
    }
    
    public init(
        modelVersion: String,
        framework: String,
        deviceInfo: String,
        osVersion: String,
        appVersion: String,
        sessionId: String,
        userId: String? = nil,
        tags: [String] = [],
        customData: [String: String] = [:]
    ) {
        self.modelVersion = modelVersion
        self.framework = framework
        self.deviceInfo = deviceInfo
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.sessionId = sessionId
        self.userId = userId
        self.tags = tags
        self.customData = customData
    }
}

// MARK: - Result Factory
public class AIResultFactory {
    
    public static func createClassificationResult(
        input: AIInput,
        classifications: [String: Double],
        model: AIModel,
        processingTime: TimeInterval,
        memoryUsage: Int64,
        confidence: Double
    ) -> AIResult {
        let output = AIOutput.classification(classifications)
        let metadata = createDefaultMetadata(model: model)
        
        return AIResult(
            input: input,
            output: output,
            model: model,
            processingTime: processingTime,
            memoryUsage: memoryUsage,
            confidence: confidence,
            metadata: metadata
        )
    }
    
    public static func createDetectionResult(
        input: AIInput,
        detections: [DetectionResult],
        model: AIModel,
        processingTime: TimeInterval,
        memoryUsage: Int64,
        confidence: Double
    ) -> AIResult {
        let output = AIOutput.detection(detections)
        let metadata = createDefaultMetadata(model: model)
        
        return AIResult(
            input: input,
            output: output,
            model: model,
            processingTime: processingTime,
            memoryUsage: memoryUsage,
            confidence: confidence,
            metadata: metadata
        )
    }
    
    public static func createGenerationResult(
        input: AIInput,
        generatedText: String,
        model: AIModel,
        processingTime: TimeInterval,
        memoryUsage: Int64,
        confidence: Double
    ) -> AIResult {
        let output = AIOutput.generation(generatedText)
        let metadata = createDefaultMetadata(model: model)
        
        return AIResult(
            input: input,
            output: output,
            model: model,
            processingTime: processingTime,
            memoryUsage: memoryUsage,
            confidence: confidence,
            metadata: metadata
        )
    }
    
    public static func createTranslationResult(
        input: AIInput,
        translatedText: String,
        model: AIModel,
        processingTime: TimeInterval,
        memoryUsage: Int64,
        confidence: Double
    ) -> AIResult {
        let output = AIOutput.translation(translatedText)
        let metadata = createDefaultMetadata(model: model)
        
        return AIResult(
            input: input,
            output: output,
            model: model,
            processingTime: processingTime,
            memoryUsage: memoryUsage,
            confidence: confidence,
            metadata: metadata
        )
    }
    
    public static func createSentimentResult(
        input: AIInput,
        sentiment: SentimentScore,
        model: AIModel,
        processingTime: TimeInterval,
        memoryUsage: Int64,
        confidence: Double
    ) -> AIResult {
        let output = AIOutput.sentiment(sentiment)
        let metadata = createDefaultMetadata(model: model)
        
        return AIResult(
            input: input,
            output: output,
            model: model,
            processingTime: processingTime,
            memoryUsage: memoryUsage,
            confidence: confidence,
            metadata: metadata
        )
    }
    
    private static func createDefaultMetadata(model: AIModel) -> ResultMetadata {
        return ResultMetadata(
            modelVersion: model.version,
            framework: "Core ML",
            deviceInfo: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            sessionId: UUID().uuidString
        )
    }
}

// MARK: - Error Types
public enum AIResultError: Error {
    case invalidResult
    case invalidMetadata
    case invalidInput
    case invalidOutput
    case invalidModel
    case invalidConfidence
    case invalidProcessingTime
    case invalidMemoryUsage
    case resultNotFound
    case resultSaveFailed
    case resultLoadFailed
    case resultDeleteFailed
    case resultValidationFailed
    case conversionFailed
}
