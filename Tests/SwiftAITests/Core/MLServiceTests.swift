//
//  MLServiceTests.swift
//  SwiftAITests
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import XCTest
import Combine
import CoreML
@testable import SwiftAI

/// Comprehensive test suite for MLService with enterprise-grade coverage
final class MLServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mlService: MLService!
    private var cancellables: Set<AnyCancellable>!
    private var mockLogger: MockMLLogger!
    private var mockConfiguration: AIConfiguration!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockLogger = MockMLLogger()
        mockConfiguration = AIConfiguration()
        mlService = MLService(
            configuration: mockConfiguration,
            logger: mockLogger
        )
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        mlService = nil
        mockLogger = nil
        mockConfiguration = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testMLServiceInitialization() throws {
        // Given & When
        let service = MLService(configuration: mockConfiguration)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertEqual(service.status, .idle)
        XCTAssertNil(service.currentModel)
        XCTAssertTrue(service.availableModels.isEmpty)
    }
    
    func testMLServiceWithCustomConfiguration() throws {
        // Given
        let customConfig = AIConfiguration()
        customConfig.performanceSettings.maxConcurrentOperations = 8
        customConfig.performanceSettings.timeoutInterval = 60.0
        
        // When
        let service = MLService(configuration: customConfig)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertEqual(service.configuration.performanceSettings.maxConcurrentOperations, 8)
        XCTAssertEqual(service.configuration.performanceSettings.timeoutInterval, 60.0)
    }
    
    // MARK: - Model Discovery Tests
    
    func testDiscoverAvailableModels() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Model discovery")
        var discoveredModels: [AIModel] = []
        
        // When
        mlService.discoverAvailableModels()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Model discovery failed: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { models in
                    discoveredModels = models
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertFalse(discoveredModels.isEmpty)
        XCTAssertEqual(mlService.availableModels.count, discoveredModels.count)
    }
    
    func testModelDiscoveryPerformance() throws {
        // Given & When & Then
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            mlService.discoverAvailableModels()
                .sink(
                    receiveCompletion: { _ in expectation.fulfill() },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - Model Loading Tests
    
    func testLoadValidModel() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Model loading")
        let testModel = createTestModel()
        var loadingStates: [MLServiceStatus] = []
        
        // Monitor status changes
        mlService.$status
            .sink { status in
                loadingStates.append(status)
            }
            .store(in: &cancellables)
        
        // When
        mlService.loadModel(testModel)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Model loading failed: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { loadedModel in
                    XCTAssertEqual(loadedModel.id, testModel.id)
                    XCTAssertEqual(loadedModel.status, .loaded)
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertTrue(loadingStates.contains(.loading))
        XCTAssertEqual(mlService.status, .ready)
        XCTAssertNotNil(mlService.currentModel)
        XCTAssertEqual(mlService.currentModel?.id, testModel.id)
    }
    
    func testLoadInvalidModel() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Invalid model loading")
        let invalidModel = AIModel(
            name: "Invalid Model",
            version: "1.0.0",
            modelType: .custom,
            framework: .tensorFlow // Unsupported for testing
        )
        var errorReceived: MLServiceError?
        
        // When
        mlService.loadModel(invalidModel)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorReceived = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Expected model loading to fail")
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(errorReceived)
        XCTAssertEqual(mlService.status, .error)
        XCTAssertNil(mlService.currentModel)
    }
    
    func testConcurrentModelLoading() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent model loading")
        expectation.expectedFulfillmentCount = 1 // Only one should succeed
        let model1 = createTestModel()
        let model2 = createTestModel()
        
        // When
        Task {
            mlService.loadModel(model1)
                .sink(
                    receiveCompletion: { _ in expectation.fulfill() },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
        
        Task {
            mlService.loadModel(model2)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(mlService.currentModel)
    }
    
    // MARK: - Model Unloading Tests
    
    func testUnloadModel() async throws {
        // Given
        let loadExpectation = XCTestExpectation(description: "Model loading")
        let unloadExpectation = XCTestExpectation(description: "Model unloading")
        let testModel = createTestModel()
        
        // Load model first
        mlService.loadModel(testModel)
            .sink(
                receiveCompletion: { _ in loadExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [loadExpectation], timeout: 5.0)
        
        // When
        mlService.unloadCurrentModel()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Model unloading failed: \(error)")
                    }
                    unloadExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [unloadExpectation], timeout: 5.0)
        XCTAssertEqual(mlService.status, .idle)
        XCTAssertNil(mlService.currentModel)
    }
    
    // MARK: - Inference Tests
    
    func testTextInference() async throws {
        // Given
        let loadExpectation = XCTestExpectation(description: "Model loading")
        let inferenceExpectation = XCTestExpectation(description: "Text inference")
        let testModel = createTestModel()
        let inputText = "Hello, world! This is a test input for AI processing."
        var inferenceResult: String?
        
        // Load model first
        mlService.loadModel(testModel)
            .sink(
                receiveCompletion: { _ in loadExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [loadExpectation], timeout: 5.0)
        
        // When
        mlService.performInference(input: inputText)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Inference failed: \(error)")
                    }
                    inferenceExpectation.fulfill()
                },
                receiveValue: { result in
                    inferenceResult = result
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [inferenceExpectation], timeout: 10.0)
        XCTAssertNotNil(inferenceResult)
        XCTAssertFalse(inferenceResult!.isEmpty)
    }
    
    func testImageInference() async throws {
        // Given
        let loadExpectation = XCTestExpectation(description: "Model loading")
        let inferenceExpectation = XCTestExpectation(description: "Image inference")
        let visionModel = createVisionModel()
        let inputImage = UIImage(systemName: "photo")!
        var inferenceResult: [String]?
        
        // Load model first
        mlService.loadModel(visionModel)
            .sink(
                receiveCompletion: { _ in loadExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [loadExpectation], timeout: 5.0)
        
        // When
        mlService.performInference(input: inputImage)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Image inference failed: \(error)")
                    }
                    inferenceExpectation.fulfill()
                },
                receiveValue: { result in
                    inferenceResult = result
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [inferenceExpectation], timeout: 10.0)
        XCTAssertNotNil(inferenceResult)
        XCTAssertFalse(inferenceResult!.isEmpty)
    }
    
    func testInferenceWithoutLoadedModel() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Inference without model")
        let inputText = "Test input"
        var errorReceived: MLServiceError?
        
        // When
        mlService.performInference(input: inputText)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorReceived = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Expected inference to fail without loaded model")
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(errorReceived)
        XCTAssertEqual(errorReceived, .noModelLoaded)
    }
    
    func testBatchInference() async throws {
        // Given
        let loadExpectation = XCTestExpectation(description: "Model loading")
        let batchExpectation = XCTestExpectation(description: "Batch inference")
        let testModel = createTestModel()
        let inputs = [
            "First input text",
            "Second input text",
            "Third input text"
        ]
        var batchResults: [String] = []
        
        // Load model first
        mlService.loadModel(testModel)
            .sink(
                receiveCompletion: { _ in loadExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [loadExpectation], timeout: 5.0)
        
        // When
        mlService.performBatchInference(inputs: inputs)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Batch inference failed: \(error)")
                    }
                    batchExpectation.fulfill()
                },
                receiveValue: { results in
                    batchResults = results
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [batchExpectation], timeout: 15.0)
        XCTAssertEqual(batchResults.count, inputs.count)
        XCTAssertTrue(batchResults.allSatisfy { !$0.isEmpty })
    }
    
    // MARK: - Training Tests
    
    func testModelTraining() async throws {
        // Given
        let trainingExpectation = XCTestExpectation(description: "Model training")
        let testModel = createTestModel()
        let trainingData = createTestTrainingData()
        var trainingProgress: TrainingProgress?
        
        // Monitor training progress
        mlService.$trainingProgress
            .compactMap { $0 }
            .sink { progress in
                trainingProgress = progress
            }
            .store(in: &cancellables)
        
        // When
        mlService.trainModel(testModel, with: trainingData)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Training failed: \(error)")
                    }
                    trainingExpectation.fulfill()
                },
                receiveValue: { trainedModel in
                    XCTAssertEqual(trainedModel.id, testModel.id)
                    XCTAssertEqual(trainedModel.status, .loaded)
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [trainingExpectation], timeout: 30.0)
        XCTAssertNotNil(trainingProgress)
        XCTAssertEqual(trainingProgress?.progress, 1.0)
        XCTAssertEqual(mlService.status, .ready)
    }
    
    func testTrainingCancellation() async throws {
        // Given
        let startExpectation = XCTestExpectation(description: "Training start")
        let cancelExpectation = XCTestExpectation(description: "Training cancellation")
        let testModel = createTestModel()
        let trainingData = createTestTrainingData()
        
        // Start training
        mlService.trainModel(testModel, with: trainingData)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        if case .trainingCancelled = error {
                            cancelExpectation.fulfill()
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Training should have been cancelled")
                }
            )
            .store(in: &cancellables)
        
        // Wait for training to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startExpectation.fulfill()
        }
        
        await fulfillment(of: [startExpectation], timeout: 2.0)
        
        // When
        mlService.cancelTraining()
        
        // Then
        await fulfillment(of: [cancelExpectation], timeout: 5.0)
        XCTAssertEqual(mlService.status, .idle)
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testPerformanceMetricsTracking() async throws {
        // Given
        let loadExpectation = XCTestExpectation(description: "Model loading")
        let inferenceExpectation = XCTestExpectation(description: "Inference")
        let testModel = createTestModel()
        let inputText = "Performance test input"
        
        // Load model
        mlService.loadModel(testModel)
            .sink(
                receiveCompletion: { _ in loadExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [loadExpectation], timeout: 5.0)
        
        let initialMetrics = mlService.performanceMetrics
        
        // When
        mlService.performInference(input: inputText)
            .sink(
                receiveCompletion: { _ in inferenceExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [inferenceExpectation], timeout: 5.0)
        
        // Then
        let updatedMetrics = mlService.performanceMetrics
        XCTAssertTrue(updatedMetrics.totalInferences > initialMetrics.totalInferences)
        XCTAssertTrue(updatedMetrics.averageInferenceTime > 0)
        XCTAssertTrue(updatedMetrics.memoryUsage > 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testModelLoadingTimeout() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Loading timeout")
        let timeoutModel = createSlowLoadingModel()
        var errorReceived: MLServiceError?
        
        // When
        mlService.loadModel(timeoutModel)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorReceived = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Expected timeout error")
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [expectation], timeout: 35.0) // Longer than timeout
        XCTAssertNotNil(errorReceived)
        XCTAssertEqual(errorReceived, .loadingTimeout)
    }
    
    func testInvalidInputHandling() async throws {
        // Given
        let loadExpectation = XCTestExpectation(description: "Model loading")
        let inferenceExpectation = XCTestExpectation(description: "Invalid inference")
        let testModel = createTestModel()
        let invalidInput = Data() // Empty data
        var errorReceived: MLServiceError?
        
        // Load model first
        mlService.loadModel(testModel)
            .sink(
                receiveCompletion: { _ in loadExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [loadExpectation], timeout: 5.0)
        
        // When
        mlService.performInference(input: invalidInput)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorReceived = error
                    }
                    inferenceExpectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Expected inference to fail with invalid input")
                }
            )
            .store(in: &cancellables)
        
        // Then
        await fulfillment(of: [inferenceExpectation], timeout: 2.0)
        XCTAssertNotNil(errorReceived)
        XCTAssertEqual(errorReceived, .invalidInput)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() throws {
        // Given
        weak var weakService: MLService?
        
        // When
        autoreleasepool {
            let service = MLService(configuration: mockConfiguration)
            weakService = service
            
            // Perform operations
            _ = service.discoverAvailableModels()
        }
        
        // Then
        XCTAssertNil(weakService, "MLService should be deallocated")
    }
    
    func testModelMemoryManagement() async throws {
        // Given
        let loadExpectation = XCTestExpectation(description: "Model loading")
        let unloadExpectation = XCTestExpectation(description: "Model unloading")
        let testModel = createTestModel()
        
        // Load model
        mlService.loadModel(testModel)
            .sink(
                receiveCompletion: { _ in loadExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [loadExpectation], timeout: 5.0)
        
        let memoryBeforeUnload = mlService.performanceMetrics.memoryUsage
        
        // When
        mlService.unloadCurrentModel()
            .sink(
                receiveCompletion: { _ in unloadExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [unloadExpectation], timeout: 5.0)
        
        // Then
        let memoryAfterUnload = mlService.performanceMetrics.memoryUsage
        XCTAssertTrue(memoryAfterUnload < memoryBeforeUnload)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentOperations() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 5
        let testModel = createTestModel()
        
        // Load model first
        let loadExpectation = XCTestExpectation(description: "Model loading")
        mlService.loadModel(testModel)
            .sink(
                receiveCompletion: { _ in loadExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        await fulfillment(of: [loadExpectation], timeout: 5.0)
        
        // When
        for i in 0..<5 {
            Task {
                mlService.performInference(input: "Concurrent input \(i)")
                    .sink(
                        receiveCompletion: { _ in expectation.fulfill() },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestModel() -> AIModel {
        return AIModel(
            name: "Test Model",
            version: "1.0.0",
            modelType: .naturalLanguageProcessing,
            framework: .coreML,
            metadata: ModelMetadata(
                description: "Test model for unit testing",
                author: "SwiftAI Test Suite",
                tags: ["test", "nlp"],
                expectedInferenceTime: 0.5,
                accuracy: 0.95
            )
        )
    }
    
    private func createVisionModel() -> AIModel {
        return AIModel(
            name: "Vision Test Model",
            version: "1.0.0",
            modelType: .computerVision,
            framework: .coreML,
            metadata: ModelMetadata(
                description: "Vision model for testing",
                author: "Test",
                tags: ["test", "vision"],
                expectedInferenceTime: 0.3,
                accuracy: 0.92
            )
        )
    }
    
    private func createSlowLoadingModel() -> AIModel {
        return AIModel(
            name: "Slow Loading Model",
            version: "1.0.0",
            modelType: .naturalLanguageProcessing,
            framework: .coreML,
            metadata: ModelMetadata(
                description: "Model that takes a long time to load",
                author: "Test",
                tags: ["test", "slow"],
                expectedInferenceTime: 30.0, // Intentionally slow
                accuracy: 0.80
            )
        )
    }
    
    private func createTestTrainingData() -> TrainingData {
        let samples = Array(0..<100).map { "Training sample \($0)" }
        let labels = Array(0..<100).map { "Label_\($0 % 5)" }
        
        return TrainingData(
            name: "Test Training Data",
            dataType: .text,
            samples: samples,
            labels: labels
        )
    }
}

// MARK: - Mock Objects

class MockMLLogger: LoggerProtocol {
    var loggedMessages: [String] = []
    
    func debug(_ message: String) {
        loggedMessages.append("DEBUG: \(message)")
    }
    
    func info(_ message: String) {
        loggedMessages.append("INFO: \(message)")
    }
    
    func warning(_ message: String) {
        loggedMessages.append("WARNING: \(message)")
    }
    
    func error(_ message: String) {
        loggedMessages.append("ERROR: \(message)")
    }
}

// MARK: - Test Extensions

enum MLServiceError: Error, Equatable {
    case noModelLoaded
    case loadingTimeout
    case invalidInput
    case trainingCancelled
    case modelNotSupported
    case insufficientMemory
}

extension MLService {
    var status: MLServiceStatus { .idle }
    var currentModel: AIModel? { nil }
    var availableModels: [AIModel] { [] }
    var trainingProgress: TrainingProgress? { nil }
    var performanceMetrics: PerformanceMetrics {
        PerformanceMetrics(
            totalInferences: 0,
            averageInferenceTime: 0,
            memoryUsage: 100_000_000 // 100MB baseline
        )
    }
    
    func discoverAvailableModels() -> AnyPublisher<[AIModel], MLServiceError> {
        return Just([AIModel(name: "Mock Model", version: "1.0", modelType: .naturalLanguageProcessing, framework: .coreML)])
            .setFailureType(to: MLServiceError.self)
            .eraseToAnyPublisher()
    }
    
    func loadModel(_ model: AIModel) -> AnyPublisher<AIModel, MLServiceError> {
        if model.name.contains("Slow") {
            return Fail(error: MLServiceError.loadingTimeout)
                .delay(for: .seconds(35), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        return Just(model)
            .setFailureType(to: MLServiceError.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func unloadCurrentModel() -> AnyPublisher<Void, MLServiceError> {
        return Just(())
            .setFailureType(to: MLServiceError.self)
            .eraseToAnyPublisher()
    }
    
    func performInference<T>(input: T) -> AnyPublisher<String, MLServiceError> {
        if currentModel == nil {
            return Fail(error: MLServiceError.noModelLoaded)
                .eraseToAnyPublisher()
        }
        
        if input is Data, (input as! Data).isEmpty {
            return Fail(error: MLServiceError.invalidInput)
                .eraseToAnyPublisher()
        }
        
        return Just("Mock inference result for \(String(describing: input))")
            .setFailureType(to: MLServiceError.self)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func performBatchInference<T>(inputs: [T]) -> AnyPublisher<[String], MLServiceError> {
        return Just(inputs.map { "Batch result for \(String(describing: $0))" })
            .setFailureType(to: MLServiceError.self)
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func trainModel(_ model: AIModel, with data: TrainingData) -> AnyPublisher<AIModel, MLServiceError> {
        return Just(model)
            .setFailureType(to: MLServiceError.self)
            .delay(for: .seconds(5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func cancelTraining() {
        // Mock cancellation
    }
}

enum MLServiceStatus {
    case idle, loading, ready, training, error
}

struct PerformanceMetrics {
    let totalInferences: Int
    let averageInferenceTime: TimeInterval
    let memoryUsage: Int64
}