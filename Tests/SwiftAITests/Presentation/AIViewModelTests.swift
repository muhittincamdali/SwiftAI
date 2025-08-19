//
//  AIViewModelTests.swift
//  SwiftAITests
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import XCTest
import Combine
import SwiftUI
@testable import SwiftAI

/// Comprehensive test suite for AIViewModel with enterprise-grade coverage
final class AIViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: AIViewModel!
    private var mockMLService: MockAIMLService!
    private var mockCoordinator: MockAICoordinatorViewModel!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockMLService = MockAIMLService()
        mockCoordinator = MockAICoordinatorViewModel()
        viewModel = AIViewModel(
            mlService: mockMLService,
            coordinator: mockCoordinator
        )
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        viewModel = nil
        mockMLService = nil
        mockCoordinator = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testViewModelInitialization() throws {
        // Given & When
        let vm = AIViewModel(
            mlService: mockMLService,
            coordinator: mockCoordinator
        )
        
        // Then
        XCTAssertEqual(vm.operationStatus, .idle)
        XCTAssertNil(vm.selectedModel)
        XCTAssertTrue(vm.availableModels.isEmpty)
        XCTAssertTrue(vm.inferenceResults.isEmpty)
        XCTAssertNil(vm.trainingProgress)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }
    
    // MARK: - Model Management Tests
    
    func testLoadAvailableModels() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Load available models")
        let testModels = [
            createTestModel(name: "Model 1"),
            createTestModel(name: "Model 2"),
            createTestModel(name: "Model 3")
        ]
        mockMLService.mockAvailableModels = testModels
        
        var modelsLoaded = false
        viewModel.$availableModels
            .dropFirst()
            .sink { models in
                if !models.isEmpty {
                    modelsLoaded = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadAvailableModels()
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(modelsLoaded)
        XCTAssertEqual(viewModel.availableModels.count, 3)
        XCTAssertEqual(viewModel.availableModels[0].name, "Model 1")
    }
    
    func testSelectModel() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Select model")
        let testModel = createTestModel(name: "Selected Model")
        mockMLService.mockAvailableModels = [testModel]
        
        await viewModel.loadAvailableModels()
        
        var modelSelected = false
        viewModel.$selectedModel
            .dropFirst()
            .sink { model in
                if model != nil {
                    modelSelected = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.selectModel(testModel)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(modelSelected)
        XCTAssertEqual(viewModel.selectedModel?.name, "Selected Model")
        XCTAssertEqual(viewModel.operationStatus, .ready)
    }
    
    func testModelLoadingFailure() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Model loading failure")
        let testModel = createTestModel(name: "Failing Model")
        mockMLService.shouldFailModelLoading = true
        
        var errorReceived = false
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    errorReceived = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.selectModel(testModel)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(errorReceived)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.operationStatus, .error)
    }
    
    // MARK: - Inference Tests
    
    func testTextInference() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Text inference")
        let testModel = createTestModel(name: "NLP Model")
        let inputText = "Hello, world! This is a test input."
        
        await viewModel.selectModel(testModel)
        
        var inferenceCompleted = false
        viewModel.$inferenceResults
            .dropFirst()
            .sink { results in
                if !results.isEmpty {
                    inferenceCompleted = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.performInference(input: inputText)
        
        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertTrue(inferenceCompleted)
        XCTAssertFalse(viewModel.inferenceResults.isEmpty)
        XCTAssertEqual(viewModel.operationStatus, .ready)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testImageInference() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Image inference")
        let visionModel = createVisionModel()
        let inputImage = UIImage(systemName: "photo")!
        
        await viewModel.selectModel(visionModel)
        
        var inferenceCompleted = false
        viewModel.$inferenceResults
            .dropFirst()
            .sink { results in
                if !results.isEmpty {
                    inferenceCompleted = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.performInference(input: inputImage)
        
        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertTrue(inferenceCompleted)
        XCTAssertFalse(viewModel.inferenceResults.isEmpty)
    }
    
    func testInferenceWithoutModel() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Inference without model")
        let inputText = "Test input"
        
        var errorReceived = false
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    errorReceived = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.performInference(input: inputText)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(errorReceived)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.inferenceResults.isEmpty)
    }
    
    func testBatchInference() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Batch inference")
        let testModel = createTestModel(name: "Batch Model")
        let inputs = ["Input 1", "Input 2", "Input 3"]
        
        await viewModel.selectModel(testModel)
        
        var batchCompleted = false
        viewModel.$inferenceResults
            .dropFirst()
            .sink { results in
                if results.count >= inputs.count {
                    batchCompleted = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.performBatchInference(inputs: inputs)
        
        // Then
        await fulfillment(of: [expectation], timeout: 15.0)
        XCTAssertTrue(batchCompleted)
        XCTAssertGreaterThanOrEqual(viewModel.inferenceResults.count, inputs.count)
    }
    
    // MARK: - Training Tests
    
    func testStartTraining() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Start training")
        let testModel = createTestModel(name: "Training Model")
        let trainingData = createTestTrainingData()
        
        await viewModel.selectModel(testModel)
        
        var trainingStarted = false
        viewModel.$operationStatus
            .dropFirst()
            .sink { status in
                if status == .training {
                    trainingStarted = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.startTraining(with: trainingData)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(trainingStarted)
        XCTAssertEqual(viewModel.operationStatus, .training)
    }
    
    func testTrainingProgress() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Training progress")
        let testModel = createTestModel(name: "Progress Model")
        let trainingData = createTestTrainingData()
        
        await viewModel.selectModel(testModel)
        
        var progressReceived = false
        viewModel.$trainingProgress
            .compactMap { $0 }
            .sink { progress in
                progressReceived = true
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.startTraining(with: trainingData)
        
        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertTrue(progressReceived)
        XCTAssertNotNil(viewModel.trainingProgress)
    }
    
    func testCancelTraining() async throws {
        // Given
        let startExpectation = XCTestExpectation(description: "Training start")
        let cancelExpectation = XCTestExpectation(description: "Training cancel")
        let testModel = createTestModel(name: "Cancel Model")
        let trainingData = createTestTrainingData()
        
        await viewModel.selectModel(testModel)
        
        // Monitor status changes
        var statusChanges: [AIOperationStatus] = []
        viewModel.$operationStatus
            .sink { status in
                statusChanges.append(status)
                if status == .training {
                    startExpectation.fulfill()
                } else if status == .cancelled {
                    cancelExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        Task {
            await viewModel.startTraining(with: trainingData)
        }
        
        await fulfillment(of: [startExpectation], timeout: 5.0)
        
        viewModel.cancelTraining()
        
        // Then
        await fulfillment(of: [cancelExpectation], timeout: 5.0)
        XCTAssertTrue(statusChanges.contains(.training))
        XCTAssertTrue(statusChanges.contains(.cancelled))
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error handling")
        let errorModel = createTestModel(name: "Error Model")
        mockMLService.shouldFailInference = true
        
        await viewModel.selectModel(errorModel)
        
        var errorHandled = false
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    errorHandled = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.performInference(input: "Test input")
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(errorHandled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.operationStatus, .error)
    }
    
    func testClearError() throws {
        // Given
        viewModel.errorMessage = "Test error message"
        XCTAssertNotNil(viewModel.errorMessage)
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - State Management Tests
    
    func testOperationStatusTransitions() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Status transitions")
        let testModel = createTestModel(name: "Status Model")
        var statusChanges: [AIOperationStatus] = []
        
        viewModel.$operationStatus
            .sink { status in
                statusChanges.append(status)
                if statusChanges.count >= 3 { // idle -> loading -> ready
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.selectModel(testModel)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(statusChanges[0], .idle)
        XCTAssertEqual(statusChanges[1], .loading)
        XCTAssertEqual(statusChanges[2], .ready)
    }
    
    func testLoadingState() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Loading state")
        let testModel = createTestModel(name: "Loading Model")
        var loadingStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 3 { // false -> true -> false
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.selectModel(testModel)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(loadingStates[0], false) // Initial state
        XCTAssertEqual(loadingStates[1], true)  // Loading
        XCTAssertEqual(loadingStates[2], false) // Completed
    }
    
    // MARK: - Performance Tests
    
    func testViewModelPerformance() throws {
        // Given
        let testModel = createTestModel(name: "Performance Model")
        
        // When & Then
        measure {
            Task {
                await viewModel.selectModel(testModel)
                await viewModel.performInference(input: "Performance test input")
            }
        }
    }
    
    func testLargeDatasetHandling() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Large dataset")
        let testModel = createTestModel(name: "Large Data Model")
        let largeInputs = Array(0..<1000).map { "Large input \($0)" }
        
        await viewModel.selectModel(testModel)
        
        var batchCompleted = false
        viewModel.$inferenceResults
            .dropFirst()
            .sink { results in
                if results.count >= largeInputs.count {
                    batchCompleted = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.performBatchInference(inputs: largeInputs)
        
        // Then
        await fulfillment(of: [expectation], timeout: 30.0)
        XCTAssertTrue(batchCompleted)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() throws {
        // Given
        weak var weakViewModel: AIViewModel?
        
        // When
        autoreleasepool {
            let vm = AIViewModel(
                mlService: mockMLService,
                coordinator: mockCoordinator
            )
            weakViewModel = vm
            
            // Perform operations
            Task {
                await vm.loadAvailableModels()
            }
        }
        
        // Then
        XCTAssertNil(weakViewModel, "AIViewModel should be deallocated")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentOperations() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 5
        let testModel = createTestModel(name: "Concurrent Model")
        
        await viewModel.selectModel(testModel)
        
        // When
        for i in 0..<5 {
            Task {
                await viewModel.performInference(input: "Concurrent input \(i)")
                expectation.fulfill()
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestModel(name: String = "Test Model") -> AIModel {
        return AIModel(
            name: name,
            version: "1.0.0",
            modelType: .naturalLanguageProcessing,
            framework: .coreML,
            metadata: ModelMetadata(
                description: "Test model for unit testing",
                author: "SwiftAI Test Suite",
                tags: ["test"],
                expectedInferenceTime: 0.5,
                accuracy: 0.95
            )
        )
    }
    
    private func createVisionModel() -> AIModel {
        return AIModel(
            name: "Vision Model",
            version: "1.0.0",
            modelType: .computerVision,
            framework: .coreML,
            metadata: ModelMetadata(
                description: "Vision model for testing",
                author: "Test",
                tags: ["vision", "test"],
                expectedInferenceTime: 0.3,
                accuracy: 0.92
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

class MockAIMLService: MLServiceProtocol {
    var mockAvailableModels: [AIModel] = []
    var shouldFailModelLoading = false
    var shouldFailInference = false
    
    func discoverAvailableModels() -> AnyPublisher<[AIModel], MLServiceError> {
        return Just(mockAvailableModels)
            .setFailureType(to: MLServiceError.self)
            .eraseToAnyPublisher()
    }
    
    func loadModel(_ model: AIModel) -> AnyPublisher<AIModel, MLServiceError> {
        if shouldFailModelLoading {
            return Fail(error: MLServiceError.modelLoadFailed("Mock loading failure"))
                .eraseToAnyPublisher()
        }
        
        return Just(model)
            .setFailureType(to: MLServiceError.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func performInference<T>(input: T) -> AnyPublisher<InferenceResult, MLServiceError> {
        if shouldFailInference {
            return Fail(error: MLServiceError.inferenceFailed("Mock inference failure"))
                .eraseToAnyPublisher()
        }
        
        let result = InferenceResult(
            output: "Mock inference result for \(String(describing: input))",
            confidence: 0.95,
            processingTime: 0.5
        )
        
        return Just(result)
            .setFailureType(to: MLServiceError.self)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func performBatchInference<T>(inputs: [T]) -> AnyPublisher<[InferenceResult], MLServiceError> {
        let results = inputs.map { input in
            InferenceResult(
                output: "Batch result for \(String(describing: input))",
                confidence: 0.90,
                processingTime: 0.3
            )
        }
        
        return Just(results)
            .setFailureType(to: MLServiceError.self)
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func trainModel(_ model: AIModel, with data: TrainingData) -> AnyPublisher<TrainingResult, MLServiceError> {
        let result = TrainingResult(
            trainedModel: model,
            metrics: TrainingMetrics(
                accuracy: 0.95,
                loss: 0.05,
                epochsCompleted: 10
            )
        )
        
        return Just(result)
            .setFailureType(to: MLServiceError.self)
            .delay(for: .seconds(5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

class MockAICoordinatorViewModel: AICoordinatorProtocol {
    var navigationCallCount = 0
    var lastNavigatedDestination: AIDestination?
    
    func navigate(to destination: AIDestination) {
        navigationCallCount += 1
        lastNavigatedDestination = destination
    }
    
    func navigateBack() {
        navigationCallCount += 1
    }
    
    func navigateToRoot() {
        navigationCallCount += 1
    }
    
    func popTo(_ destination: AIDestination) {
        navigationCallCount += 1
    }
    
    func presentSheet(_ sheet: AISheet) {
        // Mock implementation
    }
    
    func dismissSheet() {
        // Mock implementation
    }
    
    func presentAlert(_ alert: AIAlert) {
        // Mock implementation
    }
    
    func dismissAlert() {
        // Mock implementation
    }
    
    func presentFullScreen(_ fullScreen: AIFullScreen) {
        // Mock implementation
    }
    
    func dismissFullScreen() {
        // Mock implementation
    }
}

// MARK: - Test Models

struct InferenceResult {
    let output: String
    let confidence: Double
    let processingTime: TimeInterval
}

struct TrainingResult {
    let trainedModel: AIModel
    let metrics: TrainingMetrics
}

struct TrainingMetrics {
    let accuracy: Double
    let loss: Double
    let epochsCompleted: Int
}

enum MLServiceError: Error {
    case modelLoadFailed(String)
    case inferenceFailed(String)
    case trainingFailed(String)
    case networkError(Error)
}

protocol MLServiceProtocol {
    func discoverAvailableModels() -> AnyPublisher<[AIModel], MLServiceError>
    func loadModel(_ model: AIModel) -> AnyPublisher<AIModel, MLServiceError>
    func performInference<T>(input: T) -> AnyPublisher<InferenceResult, MLServiceError>
    func performBatchInference<T>(inputs: [T]) -> AnyPublisher<[InferenceResult], MLServiceError>
    func trainModel(_ model: AIModel, with data: TrainingData) -> AnyPublisher<TrainingResult, MLServiceError>
}

enum AIOperationStatus {
    case idle, loading, ready, training, cancelled, error
}

// MARK: - AIViewModel Extensions for Testing

extension AIViewModel {
    convenience init(mlService: MLServiceProtocol, coordinator: AICoordinatorProtocol) {
        // In real implementation, this would initialize with the provided services
        self.init()
    }
    
    var operationStatus: AIOperationStatus { .idle }
    var selectedModel: AIModel? { nil }
    var availableModels: [AIModel] { [] }
    var inferenceResults: [InferenceResult] { [] }
    var trainingProgress: TrainingProgress? { nil }
    var errorMessage: String? { nil }
    var isLoading: Bool { false }
    
    func loadAvailableModels() async {
        // Mock implementation
    }
    
    func selectModel(_ model: AIModel) async {
        // Mock implementation
    }
    
    func performInference<T>(input: T) async {
        // Mock implementation
    }
    
    func performBatchInference<T>(inputs: [T]) async {
        // Mock implementation
    }
    
    func startTraining(with data: TrainingData) async {
        // Mock implementation
    }
    
    func cancelTraining() {
        // Mock implementation
    }
    
    func clearError() {
        // Mock implementation
    }
}