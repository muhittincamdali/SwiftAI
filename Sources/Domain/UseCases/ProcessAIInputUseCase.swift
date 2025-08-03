import Foundation
import CoreML

// MARK: - Process AI Input Use Case Protocol
public protocol ProcessAIInputUseCaseProtocol {
    func execute(input: AIInput, type: AIInputType) async throws -> AIOutput
    func executeBatch(inputs: [AIInput], type: AIInputType) async throws -> [AIOutput]
    func validateInput(_ input: AIInput) async throws -> Bool
    func preprocessInput(_ input: AIInput) async throws -> AIInput
    func postprocessOutput(_ output: AIOutput) async throws -> AIOutput
}

// MARK: - Process AI Input Use Case Implementation
public class ProcessAIInputUseCase: ProcessAIInputUseCaseProtocol {
    
    // MARK: - Properties
    private let repository: AIRepositoryProtocol
    private let inputValidator: AIInputValidatorProtocol
    private let inputPreprocessor: AIInputPreprocessorProtocol
    private let outputPostprocessor: AIOutputPostprocessorProtocol
    private let performanceMonitor: PerformanceMonitorProtocol
    
    // MARK: - Initialization
    public init(
        repository: AIRepositoryProtocol,
        inputValidator: AIInputValidatorProtocol,
        inputPreprocessor: AIInputPreprocessorProtocol,
        outputPostprocessor: AIOutputPostprocessorProtocol,
        performanceMonitor: PerformanceMonitorProtocol
    ) {
        self.repository = repository
        self.inputValidator = inputValidator
        self.inputPreprocessor = inputPreprocessor
        self.outputPostprocessor = outputPostprocessor
        self.performanceMonitor = performanceMonitor
    }
    
    // MARK: - Execute Single Input
    public func execute(input: AIInput, type: AIInputType) async throws -> AIOutput {
        // Start performance monitoring
        performanceMonitor.startMonitoring()
        
        defer {
            performanceMonitor.stopMonitoring()
        }
        
        // Validate input
        guard try await validateInput(input) else {
            throw ProcessAIInputUseCaseError.invalidInput
        }
        
        // Preprocess input
        let preprocessedInput = try await preprocessInput(input)
        
        // Process with repository
        let output = try await repository.processAIInput(preprocessedInput, type: type)
        
        // Postprocess output
        let postprocessedOutput = try await postprocessOutput(output)
        
        // Track usage
        let usage = AIUsage(
            modelName: "ai_model",
            inputType: type,
            processingTime: performanceMonitor.getMetrics().averageInferenceTime,
            memoryUsage: performanceMonitor.getMetrics().memoryUsage,
            success: true,
            sessionId: UUID().uuidString
        )
        
        try await repository.trackUsage(usage)
        
        return postprocessedOutput
    }
    
    // MARK: - Execute Batch Inputs
    public func executeBatch(inputs: [AIInput], type: AIInputType) async throws -> [AIOutput] {
        // Start performance monitoring
        performanceMonitor.startMonitoring()
        
        defer {
            performanceMonitor.stopMonitoring()
        }
        
        // Validate all inputs
        for input in inputs {
            guard try await validateInput(input) else {
                throw ProcessAIInputUseCaseError.invalidInput
            }
        }
        
        // Preprocess all inputs
        let preprocessedInputs = try await withThrowingTaskGroup(of: AIInput.self) { group in
            for input in inputs {
                group.addTask {
                    return try await self.preprocessInput(input)
                }
            }
            
            var results: [AIInput] = []
            for try await result in group {
                results.append(result)
            }
            
            return results.sorted { inputs.firstIndex(of: $0)! < inputs.firstIndex(of: $1)! }
        }
        
        // Process batch with repository
        let outputs = try await repository.processBatchInputs(preprocessedInputs, type: type)
        
        // Postprocess all outputs
        let postprocessedOutputs = try await withThrowingTaskGroup(of: AIOutput.self) { group in
            for output in outputs {
                group.addTask {
                    return try await self.postprocessOutput(output)
                }
            }
            
            var results: [AIOutput] = []
            for try await result in group {
                results.append(result)
            }
            
            return results.sorted { outputs.firstIndex(of: $0)! < outputs.firstIndex(of: $1)! }
        }
        
        // Track batch usage
        let usage = AIUsage(
            modelName: "ai_model",
            inputType: type,
            processingTime: performanceMonitor.getMetrics().averageInferenceTime,
            memoryUsage: performanceMonitor.getMetrics().memoryUsage,
            success: true,
            sessionId: UUID().uuidString
        )
        
        try await repository.trackUsage(usage)
        
        return postprocessedOutputs
    }
    
    // MARK: - Input Validation
    public func validateInput(_ input: AIInput) async throws -> Bool {
        return try await inputValidator.validate(input)
    }
    
    // MARK: - Input Preprocessing
    public func preprocessInput(_ input: AIInput) async throws -> AIInput {
        return try await inputPreprocessor.preprocess(input)
    }
    
    // MARK: - Output Postprocessing
    public func postprocessOutput(_ output: AIOutput) async throws -> AIOutput {
        return try await outputPostprocessor.postprocess(output)
    }
}

// MARK: - AI Input Validator Protocol
public protocol AIInputValidatorProtocol {
    func validate(_ input: AIInput) async throws -> Bool
}

// MARK: - AI Input Validator Implementation
public class AIInputValidator: AIInputValidatorProtocol {
    
    public init() {}
    
    public func validate(_ input: AIInput) async throws -> Bool {
        // Basic validation
        guard input.isValid else {
            return false
        }
        
        // Type-specific validation
        switch input {
        case .text(let text):
            return validateText(text)
        case .image(let image):
            return validateImage(image)
        case .audio(let data):
            return validateAudio(data)
        case .video(let url):
            return validateVideo(url)
        case .document(let data):
            return validateDocument(data)
        case .sensor(let sensorData):
            return validateSensorData(sensorData)
        case .multimodal(let inputs):
            return validateMultimodalInputs(inputs)
        }
    }
    
    // MARK: - Private Validation Methods
    private func validateText(_ text: String) -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        guard text.count <= 10000 else {
            return false
        }
        
        guard !containsMaliciousContent(text) else {
            return false
        }
        
        return true
    }
    
    private func validateImage(_ image: UIImage) -> Bool {
        guard image.size.width > 0 && image.size.height > 0 else {
            return false
        }
        
        guard image.size.width <= 4096 && image.size.height <= 4096 else {
            return false
        }
        
        guard image.size.width >= 32 && image.size.height >= 32 else {
            return false
        }
        
        return true
    }
    
    private func validateAudio(_ data: Data) -> Bool {
        guard data.count > 0 else {
            return false
        }
        
        guard data.count <= 50 * 1024 * 1024 else { // 50MB
            return false
        }
        
        guard data.count > 1024 else { // 1KB minimum
            return false
        }
        
        return true
    }
    
    private func validateVideo(_ url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard fileSize <= 100 * 1024 * 1024 else { // 100MB
            return false
        }
        
        guard fileSize > 1024 else { // 1KB minimum
            return false
        }
        
        return true
    }
    
    private func validateDocument(_ data: Data) -> Bool {
        guard data.count > 0 else {
            return false
        }
        
        guard data.count <= 10 * 1024 * 1024 else { // 10MB
            return false
        }
        
        guard data.count > 100 else { // 100 bytes minimum
            return false
        }
        
        return true
    }
    
    private func validateSensorData(_ sensorData: SensorData) -> Bool {
        return sensorData.isValid
    }
    
    private func validateMultimodalInputs(_ inputs: [AIInput]) -> Bool {
        guard inputs.count <= 10 else {
            return false
        }
        
        for input in inputs {
            guard input.isValid else {
                return false
            }
        }
        
        return true
    }
    
    private func containsMaliciousContent(_ text: String) -> Bool {
        let maliciousPatterns = [
            "javascript:",
            "<script>",
            "SELECT *",
            "DROP TABLE",
            "UNION SELECT",
            "eval(",
            "document.cookie"
        ]
        
        let lowercasedText = text.lowercased()
        return maliciousPatterns.contains { pattern in
            lowercasedText.contains(pattern.lowercased())
        }
    }
}

// MARK: - AI Input Preprocessor Protocol
public protocol AIInputPreprocessorProtocol {
    func preprocess(_ input: AIInput) async throws -> AIInput
}

// MARK: - AI Input Preprocessor Implementation
public class AIInputPreprocessor: AIInputPreprocessorProtocol {
    
    public init() {}
    
    public func preprocess(_ input: AIInput) async throws -> AIInput {
        return try input.preprocess()
    }
}

// MARK: - AI Output Postprocessor Protocol
public protocol AIOutputPostprocessorProtocol {
    func postprocess(_ output: AIOutput) async throws -> AIOutput
}

// MARK: - AI Output Postprocessor Implementation
public class AIOutputPostprocessor: AIOutputPostprocessorProtocol {
    
    public init() {}
    
    public func postprocess(_ output: AIOutput) async throws -> AIOutput {
        // Apply postprocessing based on output type
        switch output {
        case .classification(let classifications):
            return .classification(normalizeClassifications(classifications))
        case .detection(let detections):
            return .detection(filterDetections(detections))
        case .generation(let text):
            return .generation(cleanGeneratedText(text))
        case .translation(let text):
            return .translation(cleanTranslatedText(text))
        case .sentiment(let sentiment):
            return .sentiment(normalizeSentiment(sentiment))
        }
    }
    
    // MARK: - Private Postprocessing Methods
    private func normalizeClassifications(_ classifications: [String: Double]) -> [String: Double] {
        let total = classifications.values.reduce(0, +)
        guard total > 0 else { return classifications }
        
        return classifications.mapValues { $0 / total }
    }
    
    private func filterDetections(_ detections: [DetectionResult]) -> [DetectionResult] {
        // Filter out low confidence detections
        return detections.filter { $0.confidence > 0.5 }
    }
    
    private func cleanGeneratedText(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
    }
    
    private func cleanTranslatedText(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func normalizeSentiment(_ sentiment: SentimentScore) -> SentimentScore {
        switch sentiment {
        case .positive(let value):
            return .positive(min(max(value, 0.0), 1.0))
        case .negative(let value):
            return .negative(min(max(value, 0.0), 1.0))
        case .neutral(let value):
            return .neutral(min(max(value, 0.0), 1.0))
        }
    }
}

// MARK: - Use Case Factory
public class ProcessAIInputUseCaseFactory {
    
    public static func createUseCase(repository: AIRepositoryProtocol) -> ProcessAIInputUseCase {
        let inputValidator = AIInputValidator()
        let inputPreprocessor = AIInputPreprocessor()
        let outputPostprocessor = AIOutputPostprocessor()
        let performanceMonitor = PerformanceMonitor()
        
        return ProcessAIInputUseCase(
            repository: repository,
            inputValidator: inputValidator,
            inputPreprocessor: inputPreprocessor,
            outputPostprocessor: outputPostprocessor,
            performanceMonitor: performanceMonitor
        )
    }
}

// MARK: - Error Types
public enum ProcessAIInputUseCaseError: Error {
    case invalidInput
    case preprocessingFailed
    case postprocessingFailed
    case processingFailed
    case validationFailed
    case performanceMonitoringFailed
    case usageTrackingFailed
    case batchProcessingFailed
    case inputTooLarge
    case inputTooSmall
    case maliciousContent
    case unsupportedInputType
    case processingTimeout
    case insufficientMemory
}
