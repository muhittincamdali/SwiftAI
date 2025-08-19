//
//  AIViewModel.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import Foundation
import Combine
import SwiftUI

/// Enterprise-grade AI ViewModel implementing MVVM-C pattern with reactive architecture
@MainActor
public final class AIViewModel: ObservableObject, AIViewModelProtocol {
    
    // MARK: - Published Properties
    
    @Published public private(set) var models: [AIModel] = []
    @Published public private(set) var selectedModel: AIModel?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: AIViewError?
    @Published public private(set) var operationStatus: AIOperationStatus = .idle
    @Published public private(set) var trainingProgress: TrainingProgress?
    @Published public private(set) var inferenceResults: [AIInferenceResult] = []
    @Published public private(set) var performance: AIPerformanceMetrics = AIPerformanceMetrics()
    
    // Input/Output Management
    @Published public var inputText: String = ""
    @Published public var inputImage: UIImage?
    @Published public var inputAudio: Data?
    @Published public var outputText: String = ""
    @Published public var outputImage: UIImage?
    @Published public var confidence: Double = 0.0
    
    // Configuration
    @Published public var configuration: AIConfiguration
    @Published public var isConfigurationValid = false
    
    // MARK: - Private Properties
    
    private let mlService: MLServiceProtocol
    private let analyticsManager: AnalyticsManagerProtocol
    private let logger: LoggerProtocol
    private let coordinator: AICoordinatorProtocol
    private let validationService: ValidationServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private let operationQueue = OperationQueue()
    private var currentInferenceTask: Task<Void, Never>?
    private var currentTrainingTask: Task<Void, Never>?
    
    // Performance tracking
    private var inferenceStartTime: Date?
    private var lastInferenceTime: TimeInterval = 0.0
    private var totalInferences: Int = 0
    
    // MARK: - Initialization
    
    public init(
        mlService: MLServiceProtocol,
        analyticsManager: AnalyticsManagerProtocol = AnalyticsManager(networkClient: APIClient(baseURL: URL(string: "https://api.swiftai.com")!)),
        logger: LoggerProtocol = Logger.shared,
        coordinator: AICoordinatorProtocol,
        validationService: ValidationServiceProtocol = DIValidationService(),
        configuration: AIConfiguration = AIConfiguration()
    ) {
        self.mlService = mlService
        self.analyticsManager = analyticsManager
        self.logger = logger
        self.coordinator = coordinator
        self.validationService = validationService
        self.configuration = configuration
        
        setupBindings()
        setupValidation()
        setupPerformanceMonitoring()
        loadInitialData()
    }
    
    deinit {
        cancelAllOperations()
    }
    
    // MARK: - Model Management
    
    /// Loads available AI models
    public func loadModels() async {
        logger.info("Loading AI models")
        
        do {
            setLoading(true)
            setError(nil)
            
            // Simulate loading models from service
            let availableModels = await createSampleModels()
            
            await MainActor.run {
                self.models = availableModels
                self.logger.info("Loaded \(availableModels.count) AI models")
                
                // Auto-select first model if none selected
                if self.selectedModel == nil, let firstModel = availableModels.first {
                    self.selectModel(firstModel)
                }
            }
            
            // Track analytics
            analyticsManager.trackUserAction(
                action: "load_models",
                properties: ["model_count": availableModels.count]
            )
            
        } catch {
            await MainActor.run {
                self.setError(.modelLoadFailed(error))
                self.logger.error("Failed to load models: \(error.localizedDescription)")
            }
        }
        
        setLoading(false)
    }
    
    /// Selects an AI model for operations
    /// - Parameter model: Model to select
    public func selectModel(_ model: AIModel) {
        logger.info("Selecting AI model: \(model.name)")
        
        Task {
            do {
                setLoading(true)
                setError(nil)
                
                // Load the model in ML service
                try await mlService.loadModel(model).async()
                
                await MainActor.run {
                    self.selectedModel = model
                    self.logger.info("Selected model: \(model.name)")
                }
                
                // Track analytics
                analyticsManager.trackUserAction(
                    action: "select_model",
                    properties: [
                        "model_id": model.id.uuidString,
                        "model_name": model.name,
                        "model_type": model.modelType.rawValue
                    ]
                )
                
            } catch {
                await MainActor.run {
                    self.setError(.modelSelectionFailed(error))
                    self.logger.error("Failed to select model: \(error.localizedDescription)")
                }
            }
            
            setLoading(false)
        }
    }
    
    /// Unloads the currently selected model
    public func unloadCurrentModel() {
        guard let model = selectedModel else { return }
        
        logger.info("Unloading current model: \(model.name)")
        
        let success = mlService.unloadModel(withId: model.id.uuidString)
        
        if success {
            selectedModel = nil
            clearOutputs()
            logger.info("Model unloaded successfully")
            
            analyticsManager.trackUserAction(
                action: "unload_model",
                properties: ["model_id": model.id.uuidString]
            )
        } else {
            setError(.modelUnloadFailed)
            logger.error("Failed to unload model")
        }
    }
    
    // MARK: - AI Operations
    
    /// Performs AI inference with current inputs
    public func performInference() async {
        guard let model = selectedModel else {
            setError(.noModelSelected)
            return
        }
        
        logger.info("Starting AI inference with model: \(model.name)")
        inferenceStartTime = Date()
        
        do {
            setOperationStatus(.inference)
            setError(nil)
            
            // Validate inputs
            try validateInputs()
            
            // Prepare input data
            let inputData = try prepareInputData()
            
            // Perform inference
            let result: AIInferenceOutput = try await mlService.predict(
                modelId: model.id.uuidString,
                input: inputData
            ).async()
            
            // Process results
            await processInferenceResult(result)
            
            // Update performance metrics
            updatePerformanceMetrics()
            
            logger.info("AI inference completed successfully")
            
        } catch {
            await MainActor.run {
                self.setError(.inferenceFailed(error))
                self.logger.error("AI inference failed: \(error.localizedDescription)")
            }
            
            analyticsManager.trackError(
                error: error,
                context: "ai_inference",
                properties: ["model_id": model.id.uuidString]
            )
        }
        
        setOperationStatus(.idle)
    }
    
    /// Starts training a new AI model
    /// - Parameter trainingData: Data to train the model with
    public func startTraining(with trainingData: TrainingData) async {
        logger.info("Starting AI model training")
        
        do {
            setOperationStatus(.training)
            setError(nil)
            
            // Validate training data
            let validationResult = trainingData.validateDataset()
            guard validationResult.isValid else {
                throw AIViewError.invalidTrainingData("Training data validation failed")
            }
            
            // Create training configuration
            let trainingConfig = TrainingConfiguration(
                modelName: "custom_model_\(Date().timeIntervalSince1970)",
                modelType: .deepLearning,
                epochs: 50,
                batchSize: 32,
                learningRate: 0.001
            )
            
            // Start training session
            let trainingSession = try await mlService.startTraining(
                configuration: trainingConfig,
                trainingData: trainingData
            ).async()
            
            // Monitor training progress
            await monitorTrainingProgress(session: trainingSession)
            
            logger.info("AI model training completed")
            
        } catch {
            await MainActor.run {
                self.setError(.trainingFailed(error))
                self.logger.error("AI training failed: \(error.localizedDescription)")
            }
            
            analyticsManager.trackError(
                error: error,
                context: "ai_training"
            )
        }
        
        setOperationStatus(.idle)
    }
    
    /// Cancels current training operation
    public func cancelTraining() {
        guard operationStatus == .training else { return }
        
        currentTrainingTask?.cancel()
        currentTrainingTask = nil
        setOperationStatus(.cancelled)
        
        logger.info("AI training cancelled")
        
        analyticsManager.trackUserAction(
            action: "cancel_training",
            properties: ["operation_status": operationStatus.rawValue]
        )
    }
    
    /// Evaluates model performance
    /// - Parameter testData: Data to evaluate the model with
    public func evaluateModel(with testData: TrainingData) async {
        guard let model = selectedModel else {
            setError(.noModelSelected)
            return
        }
        
        logger.info("Starting model evaluation")
        
        do {
            setOperationStatus(.evaluation)
            setError(nil)
            
            let evaluationResult = try await mlService.evaluateModel(
                modelId: model.id.uuidString,
                testData: testData,
                metrics: [.accuracy, .precision, .recall, .f1Score]
            ).async()
            
            await MainActor.run {
                self.updateEvaluationResults(evaluationResult)
                self.logger.info("Model evaluation completed")
            }
            
            analyticsManager.trackPerformanceMetric(
                metricName: "model_accuracy",
                value: evaluationResult.accuracy,
                unit: "percent",
                properties: ["model_id": model.id.uuidString]
            )
            
        } catch {
            await MainActor.run {
                self.setError(.evaluationFailed(error))
                self.logger.error("Model evaluation failed: \(error.localizedDescription)")
            }
        }
        
        setOperationStatus(.idle)
    }
    
    // MARK: - Input/Output Management
    
    /// Clears all input data
    public func clearInputs() {
        inputText = ""
        inputImage = nil
        inputAudio = nil
        
        logger.debug("Input data cleared")
        
        analyticsManager.trackUserAction(action: "clear_inputs")
    }
    
    /// Clears all output data
    public func clearOutputs() {
        outputText = ""
        outputImage = nil
        confidence = 0.0
        inferenceResults.removeAll()
        
        logger.debug("Output data cleared")
        
        analyticsManager.trackUserAction(action: "clear_outputs")
    }
    
    /// Clears all data (inputs and outputs)
    public func clearAll() {
        clearInputs()
        clearOutputs()
        
        logger.debug("All data cleared")
        
        analyticsManager.trackUserAction(action: "clear_all")
    }
    
    // MARK: - Configuration Management
    
    /// Updates AI configuration
    /// - Parameter newConfiguration: New configuration to apply
    public func updateConfiguration(_ newConfiguration: AIConfiguration) {
        logger.info("Updating AI configuration")
        
        configuration = newConfiguration
        
        // Validate new configuration
        validateConfiguration()
        
        // Apply configuration changes
        applyConfigurationChanges()
        
        analyticsManager.trackUserAction(
            action: "update_configuration",
            properties: ["configuration_valid": isConfigurationValid]
        )
    }
    
    /// Resets configuration to defaults
    public func resetConfiguration() {
        logger.info("Resetting AI configuration to defaults")
        
        configuration = AIConfiguration()
        validateConfiguration()
        
        analyticsManager.trackUserAction(action: "reset_configuration")
    }
    
    // MARK: - Performance & Analytics
    
    /// Gets current performance statistics
    /// - Returns: Current performance metrics
    public func getPerformanceStatistics() -> AIPerformanceMetrics {
        return performance
    }
    
    /// Exports inference results
    /// - Parameter format: Export format
    /// - Returns: Exported data
    public func exportResults(format: ExportFormat = .json) throws -> Data {
        logger.info("Exporting inference results in \(format.rawValue) format")
        
        switch format {
        case .json:
            return try JSONEncoder().encode(inferenceResults)
        case .csv:
            return try exportResultsToCSV()
        case .binary:
            return try NSKeyedArchiver.archivedData(withRootObject: inferenceResults, requiringSecureCoding: false)
        }
    }
    
    // MARK: - Navigation & Coordination
    
    /// Shows model selection interface
    public func showModelSelection() {
        coordinator.showModelSelection()
        
        analyticsManager.trackScreenView(
            screenName: "model_selection",
            properties: ["current_model": selectedModel?.name ?? "none"]
        )
    }
    
    /// Shows training interface
    public func showTrainingInterface() {
        coordinator.showTrainingInterface()
        
        analyticsManager.trackScreenView(
            screenName: "training_interface",
            properties: ["has_model": selectedModel != nil]
        )
    }
    
    /// Shows performance dashboard
    public func showPerformanceDashboard() {
        coordinator.showPerformanceDashboard()
        
        analyticsManager.trackScreenView(
            screenName: "performance_dashboard",
            properties: [
                "total_inferences": totalInferences,
                "average_inference_time": performance.averageInferenceTime
            ]
        )
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind configuration validation
        $configuration
            .map { [weak self] config in
                self?.validationService.validateModelConfiguration(config.modelConfiguration).isSuccess ?? false
            }
            .assign(to: &$isConfigurationValid)
        
        // Bind input validation
        Publishers.CombineLatest3($inputText, $inputImage, $inputAudio)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.validateInputsAsync()
            }
            .store(in: &cancellables)
    }
    
    private func setupValidation() {
        // Setup real-time validation
        validateConfiguration()
    }
    
    private func setupPerformanceMonitoring() {
        // Monitor performance metrics
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePerformanceMetrics()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        Task {
            await loadModels()
        }
    }
    
    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    private func setError(_ error: AIViewError?) {
        self.error = error
    }
    
    private func setOperationStatus(_ status: AIOperationStatus) {
        operationStatus = status
    }
    
    private func validateInputs() throws {
        guard selectedModel != nil else {
            throw AIViewError.noModelSelected
        }
        
        let hasTextInput = !inputText.isEmpty
        let hasImageInput = inputImage != nil
        let hasAudioInput = inputAudio != nil
        
        guard hasTextInput || hasImageInput || hasAudioInput else {
            throw AIViewError.noInputProvided
        }
    }
    
    private func validateInputsAsync() {
        do {
            try validateInputs()
            setError(nil)
        } catch {
            // Don't set error for async validation to avoid UI spam
        }
    }
    
    private func validateConfiguration() {
        let result = validationService.validateModelConfiguration(configuration.modelConfiguration)
        isConfigurationValid = result.isSuccess
        
        if !result.isSuccess {
            logger.warning("Configuration validation failed")
        }
    }
    
    private func applyConfigurationChanges() {
        // Apply configuration changes to ML service
        logger.debug("Applying configuration changes")
        
        // Restart model if needed
        if let model = selectedModel {
            Task {
                await selectModel(model)
            }
        }
    }
    
    private func prepareInputData() throws -> AIInputData {
        var inputData = AIInputData()
        
        if !inputText.isEmpty {
            inputData.text = inputText
        }
        
        if let image = inputImage {
            inputData.imageData = image.pngData()
        }
        
        if let audio = inputAudio {
            inputData.audioData = audio
        }
        
        return inputData
    }
    
    private func processInferenceResult(_ result: AIInferenceOutput) async {
        await MainActor.run {
            // Update outputs
            if let text = result.text {
                self.outputText = text
            }
            
            if let imageData = result.imageData {
                self.outputImage = UIImage(data: imageData)
            }
            
            self.confidence = result.confidence
            
            // Add to results history
            let inferenceResult = AIInferenceResult(
                id: UUID(),
                modelId: self.selectedModel?.id.uuidString ?? "",
                input: AIInputData(text: self.inputText, imageData: self.inputImage?.pngData(), audioData: self.inputAudio),
                output: result,
                inferenceTime: self.lastInferenceTime,
                timestamp: Date()
            )
            
            self.inferenceResults.append(inferenceResult)
            
            // Limit results history
            if self.inferenceResults.count > 100 {
                self.inferenceResults.removeFirst()
            }
        }
        
        // Track analytics
        if let model = selectedModel {
            analyticsManager.trackAIInference(
                modelId: model.id.uuidString,
                inputSize: calculateInputSize(),
                inferenceTime: lastInferenceTime,
                accuracy: confidence
            )
        }
    }
    
    private func updatePerformanceMetrics() {
        if let startTime = inferenceStartTime {
            lastInferenceTime = Date().timeIntervalSince(startTime)
            totalInferences += 1
            
            performance.updateMetrics(
                inferenceTime: lastInferenceTime,
                totalInferences: totalInferences
            )
            
            inferenceStartTime = nil
        }
    }
    
    private func monitorTrainingProgress(session: TrainingSession) async {
        // Monitor training progress in real-time
        for await progress in session.$progress.values {
            await MainActor.run {
                self.trainingProgress = progress
            }
        }
    }
    
    private func updateEvaluationResults(_ result: ModelEvaluationResult) {
        performance.updateEvaluationMetrics(
            accuracy: result.accuracy,
            precision: result.precision,
            recall: result.recall,
            f1Score: result.f1Score
        )
        
        logger.info("Evaluation results updated - Accuracy: \(result.accuracy)")
    }
    
    private func calculateInputSize() -> Int {
        var size = 0
        
        size += inputText.utf8.count
        
        if let imageData = inputImage?.pngData() {
            size += imageData.count
        }
        
        if let audioData = inputAudio {
            size += audioData.count
        }
        
        return size
    }
    
    private func exportResultsToCSV() throws -> Data {
        var csvContent = "id,model_id,inference_time,confidence,timestamp\n"
        
        for result in inferenceResults {
            csvContent += "\(result.id),\(result.modelId),\(result.inferenceTime),\(result.output.confidence),\(result.timestamp.iso8601String)\n"
        }
        
        guard let data = csvContent.data(using: .utf8) else {
            throw AIViewError.exportFailed("Failed to encode CSV data")
        }
        
        return data
    }
    
    private func cancelAllOperations() {
        currentInferenceTask?.cancel()
        currentTrainingTask?.cancel()
        cancellables.removeAll()
    }
    
    private func createSampleModels() async -> [AIModel] {
        return [
            AIModel(
                name: "GPT-4 Vision",
                version: "1.0.0",
                modelType: .naturalLanguageProcessing,
                framework: .coreML,
                metadata: ModelMetadata(
                    description: "Advanced language model with vision capabilities",
                    author: "SwiftAI Team",
                    tags: ["nlp", "vision", "multimodal"],
                    expectedInferenceTime: 0.5,
                    accuracy: 0.95
                )
            ),
            AIModel(
                name: "ResNet-50",
                version: "2.1.0",
                modelType: .computerVision,
                framework: .coreML,
                metadata: ModelMetadata(
                    description: "Deep residual network for image classification",
                    author: "SwiftAI Team",
                    tags: ["computer_vision", "classification"],
                    expectedInferenceTime: 0.1,
                    accuracy: 0.92
                )
            ),
            AIModel(
                name: "Whisper",
                version: "1.5.0",
                modelType: .speechRecognition,
                framework: .coreML,
                metadata: ModelMetadata(
                    description: "Automatic speech recognition model",
                    author: "SwiftAI Team",
                    tags: ["speech", "transcription"],
                    expectedInferenceTime: 0.3,
                    accuracy: 0.97
                )
            )
        ]
    }
}

// MARK: - Supporting Types

public enum AIOperationStatus: String, CaseIterable {
    case idle = "idle"
    case inference = "inference"
    case training = "training"
    case evaluation = "evaluation"
    case cancelled = "cancelled"
}

public struct AIInputData: AIInputValidatable {
    public var text: String?
    public var imageData: Data?
    public var audioData: Data?
    
    public init(text: String? = nil, imageData: Data? = nil, audioData: Data? = nil) {
        self.text = text
        self.imageData = imageData
        self.audioData = audioData
    }
    
    public func validate() throws {
        let hasText = text?.isEmpty == false
        let hasImage = imageData != nil
        let hasAudio = audioData != nil
        
        guard hasText || hasImage || hasAudio else {
            throw AIInputValidationError.missingRequiredFields(["text", "image", "audio"])
        }
    }
}

public struct AIInferenceOutput: AIOutputValidatable {
    public let text: String?
    public let imageData: Data?
    public let audioData: Data?
    public let confidence: Double
    public let metadata: [String: Any]
    
    public init(
        text: String? = nil,
        imageData: Data? = nil,
        audioData: Data? = nil,
        confidence: Double,
        metadata: [String: Any] = [:]
    ) {
        self.text = text
        self.imageData = imageData
        self.audioData = audioData
        self.confidence = confidence
        self.metadata = metadata
    }
    
    public func validate() throws {
        guard confidence >= 0.0 && confidence <= 1.0 else {
            throw AIOutputValidationError.confidenceThresholdNotMet(confidence, 1.0)
        }
        
        let hasText = text?.isEmpty == false
        let hasImage = imageData != nil
        let hasAudio = audioData != nil
        
        guard hasText || hasImage || hasAudio else {
            throw AIOutputValidationError.incompleteOutput("No output data provided")
        }
    }
}

public struct AIInferenceResult: Identifiable, Codable {
    public let id: UUID
    public let modelId: String
    public let input: AIInputData
    public let output: AIInferenceOutput
    public let inferenceTime: TimeInterval
    public let timestamp: Date
    
    public init(
        id: UUID,
        modelId: String,
        input: AIInputData,
        output: AIInferenceOutput,
        inferenceTime: TimeInterval,
        timestamp: Date
    ) {
        self.id = id
        self.modelId = modelId
        self.input = input
        self.output = output
        self.inferenceTime = inferenceTime
        self.timestamp = timestamp
    }
}

public struct AIPerformanceMetrics: Codable {
    public private(set) var totalInferences: Int = 0
    public private(set) var averageInferenceTime: TimeInterval = 0.0
    public private(set) var minInferenceTime: TimeInterval = 0.0
    public private(set) var maxInferenceTime: TimeInterval = 0.0
    public private(set) var successRate: Double = 1.0
    public private(set) var accuracy: Double = 0.0
    public private(set) var precision: Double = 0.0
    public private(set) var recall: Double = 0.0
    public private(set) var f1Score: Double = 0.0
    
    public init() {}
    
    public mutating func updateMetrics(inferenceTime: TimeInterval, totalInferences: Int) {
        self.totalInferences = totalInferences
        
        if totalInferences == 1 {
            averageInferenceTime = inferenceTime
            minInferenceTime = inferenceTime
            maxInferenceTime = inferenceTime
        } else {
            averageInferenceTime = ((averageInferenceTime * Double(totalInferences - 1)) + inferenceTime) / Double(totalInferences)
            minInferenceTime = min(minInferenceTime, inferenceTime)
            maxInferenceTime = max(maxInferenceTime, inferenceTime)
        }
    }
    
    public mutating func updateEvaluationMetrics(accuracy: Double, precision: Double, recall: Double, f1Score: Double) {
        self.accuracy = accuracy
        self.precision = precision
        self.recall = recall
        self.f1Score = f1Score
    }
}

// MARK: - Error Types

public enum AIViewError: LocalizedError, Equatable {
    case noModelSelected
    case noInputProvided
    case modelLoadFailed(Error)
    case modelSelectionFailed(Error)
    case modelUnloadFailed
    case inferenceFailed(Error)
    case trainingFailed(Error)
    case evaluationFailed(Error)
    case invalidTrainingData(String)
    case exportFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noModelSelected:
            return "No AI model selected"
        case .noInputProvided:
            return "No input data provided"
        case .modelLoadFailed(let error):
            return "Failed to load model: \(error.localizedDescription)"
        case .modelSelectionFailed(let error):
            return "Failed to select model: \(error.localizedDescription)"
        case .modelUnloadFailed:
            return "Failed to unload model"
        case .inferenceFailed(let error):
            return "AI inference failed: \(error.localizedDescription)"
        case .trainingFailed(let error):
            return "AI training failed: \(error.localizedDescription)"
        case .evaluationFailed(let error):
            return "Model evaluation failed: \(error.localizedDescription)"
        case .invalidTrainingData(let message):
            return "Invalid training data: \(message)"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
    
    public static func == (lhs: AIViewError, rhs: AIViewError) -> Bool {
        switch (lhs, rhs) {
        case (.noModelSelected, .noModelSelected),
             (.noInputProvided, .noInputProvided),
             (.modelUnloadFailed, .modelUnloadFailed):
            return true
        case (.modelLoadFailed(let lhsError), .modelLoadFailed(let rhsError)),
             (.modelSelectionFailed(let lhsError), .modelSelectionFailed(let rhsError)),
             (.inferenceFailed(let lhsError), .inferenceFailed(let rhsError)),
             (.trainingFailed(let lhsError), .trainingFailed(let rhsError)),
             (.evaluationFailed(let lhsError), .evaluationFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.invalidTrainingData(let lhsMessage), .invalidTrainingData(let rhsMessage)),
             (.exportFailed(let lhsMessage), .exportFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Protocol Definitions

public protocol AIViewModelProtocol: ObservableObject {
    var models: [AIModel] { get }
    var selectedModel: AIModel? { get }
    var isLoading: Bool { get }
    var error: AIViewError? { get }
    var operationStatus: AIOperationStatus { get }
    
    func loadModels() async
    func selectModel(_ model: AIModel)
    func performInference() async
    func startTraining(with trainingData: TrainingData) async
    func evaluateModel(with testData: TrainingData) async
}

public protocol AICoordinatorProtocol {
    func showModelSelection()
    func showTrainingInterface()
    func showPerformanceDashboard()
}

// MARK: - Extensions

extension Publisher {
    func async() async throws -> Output {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = self
                .first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}

extension ValidationResult {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

// UIKit import for UIImage
#if canImport(UIKit)
import UIKit
#endif