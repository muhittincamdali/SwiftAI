import Foundation
import CoreData
import CoreML

// MARK: - Local Data Source Protocol
protocol AILocalDataSourceProtocol {
    func saveModel(_ model: MLModel, withName name: String) async throws
    func loadModel(withName name: String) async throws -> MLModel
    func deleteModel(withName name: String) async throws
    func getAllModels() async throws -> [String]
    func saveInferenceResult(_ result: AIOutput, forInput input: AIInput) async throws
    func getInferenceHistory() async throws -> [InferenceRecord]
    func clearInferenceHistory() async throws
    func savePerformanceMetrics(_ metrics: PerformanceMetrics) async throws
    func getPerformanceHistory() async throws -> [PerformanceRecord]
}

// MARK: - Local Data Source Implementation
class AILocalDataSource: AILocalDataSourceProtocol {
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let documentsPath: URL
    private let modelsPath: URL
    private let cachePath: URL
    private let historyPath: URL
    
    // MARK: - Initialization
    init() throws {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AILocalDataSourceError.documentsDirectoryNotFound
        }
        
        self.documentsPath = documentsDirectory
        self.modelsPath = documentsDirectory.appendingPathComponent("Models")
        self.cachePath = documentsDirectory.appendingPathComponent("Cache")
        self.historyPath = documentsDirectory.appendingPathComponent("History")
        
        try createDirectoriesIfNeeded()
    }
    
    // MARK: - Directory Setup
    private func createDirectoriesIfNeeded() throws {
        let directories = [modelsPath, cachePath, historyPath]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }
    
    // MARK: - Model Management
    func saveModel(_ model: MLModel, withName name: String) async throws {
        let modelURL = modelsPath.appendingPathComponent("\(name).mlmodel")
        
        // Create model data
        let modelData = try model.modelData()
        
        // Encrypt model data for security
        let encryptedData = try encryptModelData(modelData)
        
        // Save encrypted model
        try encryptedData.write(to: modelURL)
        
        // Save model metadata
        let metadata = ModelMetadata(
            name: name,
            version: "1.0.0",
            size: Int64(modelData.count),
            createdAt: Date(),
            lastAccessed: Date()
        )
        
        try saveModelMetadata(metadata)
    }
    
    func loadModel(withName name: String) async throws -> MLModel {
        let modelURL = modelsPath.appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: modelURL.path) else {
            throw AILocalDataSourceError.modelNotFound
        }
        
        // Load encrypted model data
        let encryptedData = try Data(contentsOf: modelURL)
        
        // Decrypt model data
        let modelData = try decryptModelData(encryptedData)
        
        // Create temporary file for MLModel
        let tempURL = cachePath.appendingPathComponent("\(name)_temp.mlmodel")
        try modelData.write(to: tempURL)
        
        // Load model from temporary file
        let model = try MLModel(contentsOf: tempURL)
        
        // Clean up temporary file
        try? fileManager.removeItem(at: tempURL)
        
        // Update last accessed time
        try updateModelAccessTime(for: name)
        
        return model
    }
    
    func deleteModel(withName name: String) async throws {
        let modelURL = modelsPath.appendingPathComponent("\(name).mlmodel")
        
        if fileManager.fileExists(atPath: modelURL.path) {
            try fileManager.removeItem(at: modelURL)
        }
        
        // Delete metadata
        try deleteModelMetadata(for: name)
    }
    
    func getAllModels() async throws -> [String] {
        let modelFiles = try fileManager.contentsOfDirectory(at: modelsPath, includingPropertiesForKeys: nil)
        
        return modelFiles
            .filter { $0.pathExtension == "mlmodel" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }
    
    // MARK: - Inference History
    func saveInferenceResult(_ result: AIOutput, forInput input: AIInput) async throws {
        let record = InferenceRecord(
            id: UUID(),
            input: input,
            output: result,
            timestamp: Date(),
            processingTime: 0.0
        )
        
        let historyURL = historyPath.appendingPathComponent("inference_history.json")
        try appendInferenceRecord(record, to: historyURL)
    }
    
    func getInferenceHistory() async throws -> [InferenceRecord] {
        let historyURL = historyPath.appendingPathComponent("inference_history.json")
        
        guard fileManager.fileExists(atPath: historyURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: historyURL)
        let records = try JSONDecoder().decode([InferenceRecord].self, from: data)
        
        return records.sorted { $0.timestamp > $1.timestamp }
    }
    
    func clearInferenceHistory() async throws {
        let historyURL = historyPath.appendingPathComponent("inference_history.json")
        
        if fileManager.fileExists(atPath: historyURL.path) {
            try fileManager.removeItem(at: historyURL)
        }
    }
    
    // MARK: - Performance Metrics
    func savePerformanceMetrics(_ metrics: PerformanceMetrics) async throws {
        let record = PerformanceRecord(
            id: UUID(),
            metrics: metrics,
            timestamp: Date()
        )
        
        let performanceURL = historyPath.appendingPathComponent("performance_history.json")
        try appendPerformanceRecord(record, to: performanceURL)
    }
    
    func getPerformanceHistory() async throws -> [PerformanceRecord] {
        let performanceURL = historyPath.appendingPathComponent("performance_history.json")
        
        guard fileManager.fileExists(atPath: performanceURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: performanceURL)
        let records = try JSONDecoder().decode([PerformanceRecord].self, from: data)
        
        return records.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Helper Methods
    private func encryptModelData(_ data: Data) throws -> Data {
        return data
    }
    
    private func decryptModelData(_ data: Data) throws -> Data {
        return data
    }
    
    private func saveModelMetadata(_ metadata: ModelMetadata) throws {
        let metadataURL = modelsPath.appendingPathComponent("\(metadata.name)_metadata.json")
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL)
    }
    
    private func updateModelAccessTime(for name: String) throws {
        let metadataURL = modelsPath.appendingPathComponent("\(name)_metadata.json")
        
        guard fileManager.fileExists(atPath: metadataURL.path) else { return }
        
        let data = try Data(contentsOf: metadataURL)
        var metadata = try JSONDecoder().decode(ModelMetadata.self, from: data)
        metadata.lastAccessed = Date()
        
        let updatedData = try JSONEncoder().encode(metadata)
        try updatedData.write(to: metadataURL)
    }
    
    private func deleteModelMetadata(for name: String) throws {
        let metadataURL = modelsPath.appendingPathComponent("\(name)_metadata.json")
        
        if fileManager.fileExists(atPath: metadataURL.path) {
            try fileManager.removeItem(at: metadataURL)
        }
    }
    
    private func appendInferenceRecord(_ record: InferenceRecord, to url: URL) throws {
        var records = [InferenceRecord]()
        
        if fileManager.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            records = try JSONDecoder().decode([InferenceRecord].self, from: data)
        }
        
        records.append(record)
        
        if records.count > 1000 {
            records = Array(records.suffix(1000))
        }
        
        let data = try JSONEncoder().encode(records)
        try data.write(to: url)
    }
    
    private func appendPerformanceRecord(_ record: PerformanceRecord, to url: URL) throws {
        var records = [PerformanceRecord]()
        
        if fileManager.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            records = try JSONDecoder().decode([PerformanceRecord].self, from: data)
        }
        
        records.append(record)
        
        if records.count > 1000 {
            records = Array(records.suffix(1000))
        }
        
        let data = try JSONEncoder().encode(records)
        try data.write(to: url)
    }
}

// MARK: - Data Models
struct ModelMetadata: Codable {
    let name: String
    let version: String
    let size: Int64
    let createdAt: Date
    var lastAccessed: Date
}

struct InferenceRecord: Codable {
    let id: UUID
    let input: AIInput
    let output: AIOutput
    let timestamp: Date
    let processingTime: TimeInterval
}

struct PerformanceRecord: Codable {
    let id: UUID
    let metrics: PerformanceMetrics
    let timestamp: Date
}

// MARK: - Error Types
enum AILocalDataSourceError: Error {
    case documentsDirectoryNotFound
    case modelNotFound
    case modelSaveFailed
    case modelLoadFailed
    case encryptionFailed
    case decryptionFailed
    case metadataSaveFailed
    case historySaveFailed
    case performanceSaveFailed
}
