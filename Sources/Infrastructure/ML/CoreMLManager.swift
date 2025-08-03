import Foundation
import CoreML
import Vision
import NaturalLanguage

// MARK: - Core ML Manager Protocol
public protocol CoreMLManagerProtocol {
    func loadModel(withName name: String) async throws -> MLModel
    func compileModel(at url: URL) async throws -> MLModel
    func validateModel(_ model: MLModel) async throws -> Bool
    func optimizeModel(_ model: MLModel) async throws -> MLModel
    func getModelMetadata(_ model: MLModel) async throws -> MLModelMetadata
    func predict(with model: MLModel, input: MLFeatureProvider) async throws -> MLFeatureProvider
    func batchPredict(with model: MLModel, inputs: [MLFeatureProvider]) async throws -> [MLFeatureProvider]
}

// MARK: - Core ML Manager Implementation
public class CoreMLManager: CoreMLManagerProtocol {
    
    // MARK: - Properties
    private let modelCache: NSCache<NSString, MLModel>
    private let configuration: MLModelConfiguration
    private let performanceMonitor: PerformanceMonitorProtocol
    
    // MARK: - Initialization
    public init(performanceMonitor: PerformanceMonitorProtocol = PerformanceMonitor()) {
        self.modelCache = NSCache<NSString, MLModel>()
        self.modelCache.countLimit = 10
        self.modelCache.totalCostLimit = 500 * 1024 * 1024 // 500MB
        
        self.configuration = MLModelConfiguration()
        self.configuration.computeUnits = .all
        
        self.performanceMonitor = performanceMonitor
    }
    
    // MARK: - Model Loading
    public func loadModel(withName name: String) async throws -> MLModel {
        // Check cache first
        if let cachedModel = modelCache.object(forKey: name as NSString) {
            return cachedModel
        }
        
        // Load from bundle
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "mlmodel") else {
            throw CoreMLError.modelNotFound
        }
        
        // Load model
        let model = try MLModel(contentsOf: modelURL, configuration: configuration)
        
        // Cache model
        modelCache.setObject(model, forKey: name as NSString)
        
        return model
    }
    
    // MARK: - Model Compilation
    public func compileModel(at url: URL) async throws -> MLModel {
        // Compile model
        let compiledURL = try MLModel.compileModel(at: url)
        
        // Load compiled model
        let model = try MLModel(contentsOf: compiledURL, configuration: configuration)
        
        return model
    }
    
    // MARK: - Model Validation
    public func validateModel(_ model: MLModel) async throws -> Bool {
        // Check model description
        guard model.modelDescription != nil else {
            return false
        }
        
        // Check input features
        guard !model.modelDescription.inputDescriptionsByName.isEmpty else {
            return false
        }
        
        // Check output features
        guard !model.modelDescription.outputDescriptionsByName.isEmpty else {
            return false
        }
        
        // Validate model metadata
        let metadata = try await getModelMetadata(model)
        guard metadata.isValid else {
            return false
        }
        
        return true
    }
    
    // MARK: - Model Optimization
    public func optimizeModel(_ model: MLModel) async throws -> MLModel {
        // Create optimized configuration
        let optimizedConfig = MLModelConfiguration()
        optimizedConfig.computeUnits = .cpuAndNeuralEngine
        
        // Recompile with optimized configuration
        let optimizedModel = try MLModel(contentsOf: model.url, configuration: optimizedConfig)
        
        return optimizedModel
    }
    
    // MARK: - Model Metadata
    public func getModelMetadata(_ model: MLModel) async throws -> MLModelMetadata {
        let description = model.modelDescription
        
        let inputFeatures = description.inputDescriptionsByName.map { name, description in
            FeatureDescription(name: name, type: description.type, isOptional: description.isOptional)
        }
        
        let outputFeatures = description.outputDescriptionsByName.map { name, description in
            FeatureDescription(name: name, type: description.type, isOptional: description.isOptional)
        }
        
        return MLModelMetadata(
            name: description.metadata[MLModelMetadataKey.name] as? String ?? "Unknown",
            version: description.metadata[MLModelMetadataKey.versionString] as? String ?? "1.0.0",
            author: description.metadata[MLModelMetadataKey.author] as? String ?? "Unknown",
            license: description.metadata[MLModelMetadataKey.license] as? String ?? "Unknown",
            description: description.metadata[MLModelMetadataKey.description] as? String ?? "",
            inputFeatures: inputFeatures,
            outputFeatures: outputFeatures,
            metadata: description.metadata
        )
    }
    
    // MARK: - Prediction
    public func predict(with model: MLModel, input: MLFeatureProvider) async throws -> MLFeatureProvider {
        performanceMonitor.startMonitoring()
        
        defer {
            performanceMonitor.stopMonitoring()
        }
        
        // Perform prediction
        let prediction = try model.prediction(from: input)
        
        return prediction
    }
    
    // MARK: - Batch Prediction
    public func batchPredict(with model: MLModel, inputs: [MLFeatureProvider]) async throws -> [MLFeatureProvider] {
        performanceMonitor.startMonitoring()
        
        defer {
            performanceMonitor.stopMonitoring()
        }
        
        var predictions: [MLFeatureProvider] = []
        
        for input in inputs {
            let prediction = try model.prediction(from: input)
            predictions.append(prediction)
        }
        
        return predictions
    }
    
    // MARK: - Cache Management
    public func clearCache() {
        modelCache.removeAllObjects()
    }
    
    public func removeModelFromCache(_ name: String) {
        modelCache.removeObject(forKey: name as NSString)
    }
    
    public func getCachedModels() -> [String] {
        let keys = modelCache.allKeys
        return keys.map { $0 as String }
    }
}

// MARK: - ML Model Metadata
public struct MLModelMetadata: Codable {
    public let name: String
    public let version: String
    public let author: String
    public let license: String
    public let description: String
    public let inputFeatures: [FeatureDescription]
    public let outputFeatures: [FeatureDescription]
    public let metadata: [String: Any]
    
    public var isValid: Bool {
        return !name.isEmpty &&
               !version.isEmpty &&
               !author.isEmpty &&
               !license.isEmpty &&
               !inputFeatures.isEmpty &&
               !outputFeatures.isEmpty
    }
    
    public init(
        name: String,
        version: String,
        author: String,
        license: String,
        description: String,
        inputFeatures: [FeatureDescription],
        outputFeatures: [FeatureDescription],
        metadata: [String: Any]
    ) {
        self.name = name
        self.version = version
        self.author = author
        self.license = license
        self.description = description
        self.inputFeatures = inputFeatures
        self.outputFeatures = outputFeatures
        self.metadata = metadata
    }
}

// MARK: - Feature Description
public struct FeatureDescription: Codable {
    public let name: String
    public let type: MLFeatureType
    public let isOptional: Bool
    
    public init(name: String, type: MLFeatureType, isOptional: Bool) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
    }
}

// MARK: - Core ML Error Types
public enum CoreMLError: Error {
    case modelNotFound
    case modelLoadFailed
    case modelCompilationFailed
    case modelValidationFailed
    case modelOptimizationFailed
    case predictionFailed
    case invalidInput
    case invalidOutput
    case modelMetadataFailed
    case cacheError
    case insufficientMemory
    case processingTimeout
}

// MARK: - MLFeatureType Extension for Codable
extension MLFeatureType: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(UInt32.self)
        self.init(rawValue: rawValue)!
    }
}
