//
//  AIModelTests.swift
//  SwiftAITests
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import XCTest
import Combine
@testable import SwiftAI

/// Comprehensive test suite for AIModel with enterprise-grade coverage
final class AIModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var aiModel: AIModel!
    private var cancellables: Set<AnyCancellable>!
    private var mockLogger: MockLogger!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockLogger = MockLogger()
        aiModel = createTestModel()
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        aiModel = nil
        mockLogger = nil
        super.tearDown()
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
    
    // MARK: - Initialization Tests
    
    func testModelInitialization() throws {
        // Given & When
        let model = createTestModel()
        
        // Then
        XCTAssertEqual(model.name, "Test Model")
        XCTAssertEqual(model.version, "1.0.0")
        XCTAssertEqual(model.modelType, .naturalLanguageProcessing)
        XCTAssertEqual(model.framework, .coreML)
        XCTAssertEqual(model.status, .notLoaded)
        XCTAssertEqual(model.metadata.description, "Test model for unit testing")
        XCTAssertEqual(model.metadata.accuracy, 0.95)
        XCTAssertNotNil(model.id)
        XCTAssertNotNil(model.createdAt)
    }
    
    func testModelUniqueIdentifiers() throws {
        // Given & When
        let model1 = createTestModel()
        let model2 = createTestModel()
        
        // Then
        XCTAssertNotEqual(model1.id, model2.id)
        XCTAssertNotEqual(model1.createdAt, model2.createdAt)
    }
    
    // MARK: - Model Loading Tests
    
    func testModelLoading() throws {
        // Given
        let expectation = XCTestExpectation(description: "Model loading")
        var loadingStates: [AIModelStatus] = []
        
        aiModel.$status
            .sink { status in
                loadingStates.append(status)
                if status == .loaded {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        aiModel.load()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Model loading failed: \(error)")
                    }
                },
                receiveValue: { _ in
                    // Loading completed successfully
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(loadingStates.contains(.loading))
        XCTAssertEqual(aiModel.status, .loaded)
    }
    
    func testModelLoadingFailure() throws {
        // Given
        let expectation = XCTestExpectation(description: "Model loading failure")
        var errorReceived: AIModelError?
        
        // Create a model that will fail to load
        let failingModel = AIModel(
            name: "Failing Model",
            version: "1.0.0",
            modelType: .custom,
            framework: .tensorFlow, // Unsupported framework for testing
            metadata: ModelMetadata(
                description: "Model that fails to load",
                author: "Test",
                tags: ["fail"],
                expectedInferenceTime: 1.0,
                accuracy: 0.0
            )
        )
        
        // When
        failingModel.load()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorReceived = error
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected model loading to fail")
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(errorReceived)
        XCTAssertEqual(failingModel.status, .error)
    }
    
    // MARK: - Model Unloading Tests
    
    func testModelUnloading() throws {
        // Given
        let loadExpectation = XCTestExpectation(description: "Model loading")
        let unloadExpectation = XCTestExpectation(description: "Model unloading")
        
        // First load the model
        aiModel.load()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    loadExpectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [loadExpectation], timeout: 5.0)
        
        // When
        aiModel.unload()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Model unloading failed: \(error)")
                    }
                    unloadExpectation.fulfill()
                },
                receiveValue: { _ in
                    // Unloading completed successfully
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [unloadExpectation], timeout: 5.0)
        XCTAssertEqual(aiModel.status, .notLoaded)
    }
    
    // MARK: - Prediction Tests
    
    func testTextPrediction() throws {
        // Given
        let expectation = XCTestExpectation(description: "Text prediction")
        let inputText = "Hello, world!"
        var predictionResult: String?
        
        // Load model first
        let loadExpectation = XCTestExpectation(description: "Model loading")
        aiModel.load()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in loadExpectation.fulfill() }
            )
            .store(in: &cancellables)
        
        wait(for: [loadExpectation], timeout: 5.0)
        
        // When
        aiModel.predict(input: inputText)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Prediction failed: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { result in
                    predictionResult = result
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(predictionResult)
        XCTAssertFalse(predictionResult!.isEmpty)
    }
    
    func testImagePrediction() throws {
        // Given
        let expectation = XCTestExpectation(description: "Image prediction")
        let inputImage = UIImage(systemName: "photo")!
        var predictionResult: [String]?
        
        // Create vision model
        let visionModel = AIModel(
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
        
        // Load model first
        let loadExpectation = XCTestExpectation(description: "Model loading")
        visionModel.load()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in loadExpectation.fulfill() }
            )
            .store(in: &cancellables)
        
        wait(for: [loadExpectation], timeout: 5.0)
        
        // When
        visionModel.predict(input: inputImage)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Image prediction failed: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { result in
                    predictionResult = result
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(predictionResult)
        XCTAssertFalse(predictionResult!.isEmpty)
    }
    
    func testPredictionWithoutLoadedModel() throws {
        // Given
        let expectation = XCTestExpectation(description: "Prediction failure")
        let inputText = "Test input"
        var errorReceived: AIModelError?
        
        // When (trying to predict without loading model)
        aiModel.predict(input: inputText)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorReceived = error
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected prediction to fail with unloaded model")
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(errorReceived)
        XCTAssertEqual(errorReceived, .modelNotLoaded)
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testPerformanceMetricsUpdate() throws {
        // Given
        let expectation = XCTestExpectation(description: "Performance metrics update")
        var metricsUpdated = false
        
        aiModel.$performance
            .dropFirst()
            .sink { performance in
                if performance.totalInferences > 0 {
                    metricsUpdated = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Load model first
        let loadExpectation = XCTestExpectation(description: "Model loading")
        aiModel.load()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in loadExpectation.fulfill() }
            )
            .store(in: &cancellables)
        
        wait(for: [loadExpectation], timeout: 5.0)
        
        // When
        aiModel.predict(input: "Test input")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(metricsUpdated)
        XCTAssertTrue(aiModel.performance.totalInferences > 0)
        XCTAssertTrue(aiModel.performance.averageInferenceTime > 0)
    }
    
    // MARK: - Configuration Tests
    
    func testModelConfiguration() throws {
        // Given
        let newConfig = ModelConfiguration(
            maxInputTokens: 8192,
            maxOutputTokens: 4096,
            temperature: 0.8,
            topP: 0.9,
            frequencyPenalty: 0.1,
            presencePenalty: 0.1
        )
        
        // When
        aiModel.updateConfiguration(newConfig)
        
        // Then
        XCTAssertEqual(aiModel.configuration.maxInputTokens, 8192)
        XCTAssertEqual(aiModel.configuration.temperature, 0.8)
        XCTAssertEqual(aiModel.configuration.topP, 0.9)
    }
    
    func testConfigurationValidation() throws {
        // Given
        let invalidConfig = ModelConfiguration(
            maxInputTokens: -1, // Invalid
            maxOutputTokens: 0, // Invalid
            temperature: 3.0, // Invalid (should be 0-2)
            topP: 1.5, // Invalid (should be 0-1)
            frequencyPenalty: -0.5, // Invalid
            presencePenalty: 2.5 // Invalid
        )
        
        // When
        let validationResult = aiModel.validateConfiguration(invalidConfig)
        
        // Then
        XCTAssertFalse(validationResult.isValid)
        XCTAssertFalse(validationResult.errors.isEmpty)
        XCTAssertTrue(validationResult.errors.count >= 6)
    }
    
    // MARK: - Model Persistence Tests
    
    func testModelSerialization() throws {
        // Given
        let originalModel = createTestModel()
        
        // When
        let encodedData = try JSONEncoder().encode(originalModel)
        let decodedModel = try JSONDecoder().decode(AIModel.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalModel.id, decodedModel.id)
        XCTAssertEqual(originalModel.name, decodedModel.name)
        XCTAssertEqual(originalModel.version, decodedModel.version)
        XCTAssertEqual(originalModel.modelType, decodedModel.modelType)
        XCTAssertEqual(originalModel.framework, decodedModel.framework)
        XCTAssertEqual(originalModel.metadata.description, decodedModel.metadata.description)
        XCTAssertEqual(originalModel.metadata.accuracy, decodedModel.metadata.accuracy)
    }
    
    // MARK: - Model Comparison Tests
    
    func testModelEquality() throws {
        // Given
        let model1 = createTestModel()
        let model2 = createTestModel()
        
        // Create identical model
        let model3 = AIModel(
            name: model1.name,
            version: model1.version,
            modelType: model1.modelType,
            framework: model1.framework,
            metadata: model1.metadata
        )
        model3.id = model1.id // Force same ID for equality test
        
        // Then
        XCTAssertNotEqual(model1, model2) // Different IDs
        XCTAssertEqual(model1, model3) // Same properties and ID
    }
    
    func testModelHashing() throws {
        // Given
        let model1 = createTestModel()
        let model2 = createTestModel()
        
        // When
        let hash1 = model1.hashValue
        let hash2 = model2.hashValue
        
        // Then
        XCTAssertNotEqual(hash1, hash2)
        
        // Test hash consistency
        XCTAssertEqual(model1.hashValue, model1.hashValue)
    }
    
    // MARK: - Model Type Tests
    
    func testModelTypeProperties() throws {
        // Given & When
        let nlpModel = AIModel(name: "NLP", version: "1.0", modelType: .naturalLanguageProcessing, framework: .coreML)
        let visionModel = AIModel(name: "Vision", version: "1.0", modelType: .computerVision, framework: .coreML)
        let speechModel = AIModel(name: "Speech", version: "1.0", modelType: .speechRecognition, framework: .coreML)
        
        // Then
        XCTAssertEqual(nlpModel.modelType, .naturalLanguageProcessing)
        XCTAssertEqual(visionModel.modelType, .computerVision)
        XCTAssertEqual(speechModel.modelType, .speechRecognition)
        
        // Verify different capabilities
        XCTAssertTrue(nlpModel.supportsTextInput)
        XCTAssertTrue(visionModel.supportsImageInput)
        XCTAssertTrue(speechModel.supportsAudioInput)
    }
    
    // MARK: - Error Handling Tests
    
    func testModelErrorTypes() throws {
        // Given
        let errors: [AIModelError] = [
            .modelNotLoaded,
            .modelLoadFailed("Test error"),
            .predictionFailed("Prediction error"),
            .invalidInput("Invalid input"),
            .configurationError("Config error"),
            .frameworkNotSupported(.tensorFlow),
            .insufficientMemory,
            .timeout
        ]
        
        // When & Then
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() throws {
        // Given
        weak var weakModel: AIModel?
        
        // When
        autoreleasepool {
            let model = createTestModel()
            weakModel = model
            
            // Perform operations
            model.updateConfiguration(ModelConfiguration())
            _ = model.validateConfiguration(ModelConfiguration())
        }
        
        // Then
        XCTAssertNil(weakModel, "Model should be deallocated")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentAccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        let numberOfThreads = 10
        
        // Load model first
        let loadExpectation = XCTestExpectation(description: "Model loading")
        aiModel.load()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in loadExpectation.fulfill() }
            )
            .store(in: &cancellables)
        
        wait(for: [loadExpectation], timeout: 5.0)
        
        // When
        for i in 0..<numberOfThreads {
            DispatchQueue.global().async {
                // Perform concurrent operations
                self.aiModel.predict(input: "Test input \(i)")
                    .sink(
                        receiveCompletion: { _ in expectation.fulfill() },
                        receiveValue: { _ in }
                    )
                    .store(in: &self.cancellables)
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Performance Tests
    
    func testModelCreationPerformance() throws {
        // Given & When & Then
        measure {
            for _ in 0..<1000 {
                _ = createTestModel()
            }
        }
    }
    
    func testModelValidationPerformance() throws {
        // Given
        let config = ModelConfiguration()
        
        // When & Then
        measure {
            for _ in 0..<10000 {
                _ = aiModel.validateConfiguration(config)
            }
        }
    }
}

// MARK: - Mock Objects

class MockLogger: LoggerProtocol {
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

extension AIModel {
    var supportsTextInput: Bool {
        return modelType == .naturalLanguageProcessing
    }
    
    var supportsImageInput: Bool {
        return modelType == .computerVision
    }
    
    var supportsAudioInput: Bool {
        return modelType == .speechRecognition
    }
}