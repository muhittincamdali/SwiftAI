//
//  ValidationServiceTests.swift
//  SwiftAITests
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import XCTest
import Combine
@testable import SwiftAI

/// Comprehensive test suite for ValidationService with enterprise-grade coverage
final class ValidationServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var validationService: ValidationService!
    private var cancellables: Set<AnyCancellable>!
    private var mockLogger: MockValidationLogger!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockLogger = MockValidationLogger()
        validationService = ValidationService(logger: mockLogger)
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        validationService = nil
        mockLogger = nil
        super.tearDown()
    }
    
    // MARK: - Model Configuration Validation Tests
    
    func testValidModelConfiguration() throws {
        // Given
        let validConfig = ModelConfiguration(
            maxInputTokens: 4096,
            maxOutputTokens: 2048,
            temperature: 0.7,
            topP: 0.9,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        
        // When
        let result = validationService.validateModelConfiguration(validConfig)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertTrue(result.warnings.isEmpty)
    }
    
    func testInvalidModelConfigurationTokens() throws {
        // Given
        let invalidConfig = ModelConfiguration(
            maxInputTokens: 0, // Invalid
            maxOutputTokens: -100, // Invalid
            temperature: 0.7,
            topP: 0.9,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        
        // When
        let result = validationService.validateModelConfiguration(invalidConfig)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("maxInputTokens") })
        XCTAssertTrue(result.errors.contains { $0.contains("maxOutputTokens") })
    }
    
    func testInvalidModelConfigurationTemperature() throws {
        // Given
        let invalidConfig = ModelConfiguration(
            maxInputTokens: 4096,
            maxOutputTokens: 2048,
            temperature: 3.0, // Invalid (should be 0-2)
            topP: 0.9,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        
        // When
        let result = validationService.validateModelConfiguration(invalidConfig)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("temperature") })
    }
    
    func testInvalidModelConfigurationTopP() throws {
        // Given
        let invalidConfig = ModelConfiguration(
            maxInputTokens: 4096,
            maxOutputTokens: 2048,
            temperature: 0.7,
            topP: 1.5, // Invalid (should be 0-1)
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        
        // When
        let result = validationService.validateModelConfiguration(invalidConfig)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("topP") })
    }
    
    func testModelConfigurationWarnings() throws {
        // Given
        let configWithWarnings = ModelConfiguration(
            maxInputTokens: 16384, // High but valid - should trigger warning
            maxOutputTokens: 8192, // High but valid - should trigger warning
            temperature: 1.8, // High but valid - should trigger warning
            topP: 0.9,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        
        // When
        let result = validationService.validateModelConfiguration(configWithWarnings)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertFalse(result.warnings.isEmpty)
    }
    
    // MARK: - Training Data Validation Tests
    
    func testValidTrainingData() throws {
        // Given
        let validTrainingData = TrainingData(
            name: "Test Dataset",
            dataType: .text,
            samples: Array(0..<1000).map { "Sample \($0)" },
            labels: Array(0..<1000).map { "Label \($0)" }
        )
        
        // When
        let result = validationService.validateTrainingData(validTrainingData)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testInvalidTrainingDataEmpty() throws {
        // Given
        let emptyTrainingData = TrainingData(
            name: "Empty Dataset",
            dataType: .text,
            samples: [],
            labels: []
        )
        
        // When
        let result = validationService.validateTrainingData(emptyTrainingData)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("empty") || $0.contains("samples") })
    }
    
    func testInvalidTrainingDataMismatchedSamples() throws {
        // Given
        let mismatchedData = TrainingData(
            name: "Mismatched Dataset",
            dataType: .text,
            samples: Array(0..<100).map { "Sample \($0)" },
            labels: Array(0..<50).map { "Label \($0)" } // Mismatched count
        )
        
        // When
        let result = validationService.validateTrainingData(mismatchedData)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("mismatch") || $0.contains("count") })
    }
    
    func testTrainingDataQualityValidation() throws {
        // Given
        let lowQualityData = TrainingData(
            name: "Low Quality Dataset",
            dataType: .text,
            samples: Array(0..<10).map { _ in "" }, // Empty samples
            labels: Array(0..<10).map { "Label \($0)" }
        )
        
        // When
        let result = validationService.validateTrainingData(lowQualityData)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("quality") || $0.contains("empty") })
    }
    
    // MARK: - AI Input Validation Tests
    
    func testValidTextInput() throws {
        // Given
        let validTextInput = MockAITextInput(content: "This is a valid text input for AI processing")
        
        // When
        let result = validationService.validateAIInput(validTextInput)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testInvalidTextInputEmpty() throws {
        // Given
        let emptyTextInput = MockAITextInput(content: "")
        
        // When
        let result = validationService.validateAIInput(emptyTextInput)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("empty") || $0.contains("content") })
    }
    
    func testInvalidTextInputTooLong() throws {
        // Given
        let longContent = String(repeating: "a", count: 100_000)
        let longTextInput = MockAITextInput(content: longContent)
        
        // When
        let result = validationService.validateAIInput(longTextInput)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("length") || $0.contains("too long") })
    }
    
    func testValidImageInput() throws {
        // Given
        let validImageInput = MockAIImageInput(imageData: Data(count: 1024))
        
        // When
        let result = validationService.validateAIInput(validImageInput)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testInvalidImageInputEmpty() throws {
        // Given
        let emptyImageInput = MockAIImageInput(imageData: Data())
        
        // When
        let result = validationService.validateAIInput(emptyImageInput)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("empty") || $0.contains("data") })
    }
    
    // MARK: - AI Output Validation Tests
    
    func testValidTextOutput() throws {
        // Given
        let validTextOutput = MockAITextOutput(
            content: "This is a valid AI-generated response",
            confidence: 0.95,
            processingTime: 0.5
        )
        
        // When
        let result = validationService.validateAIOutput(validTextOutput)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testInvalidTextOutputLowConfidence() throws {
        // Given
        let lowConfidenceOutput = MockAITextOutput(
            content: "Low confidence response",
            confidence: 0.3, // Below threshold
            processingTime: 0.5
        )
        
        // When
        let result = validationService.validateAIOutput(lowConfidenceOutput)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("confidence") })
    }
    
    func testInvalidTextOutputSlowProcessing() throws {
        // Given
        let slowOutput = MockAITextOutput(
            content: "Slow processing response",
            confidence: 0.95,
            processingTime: 30.0 // Too slow
        )
        
        // When
        let result = validationService.validateAIOutput(slowOutput)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("processing time") || $0.contains("slow") })
    }
    
    // MARK: - Performance Metrics Validation Tests
    
    func testValidPerformanceMetrics() throws {
        // Given
        let validMetrics: [String: Any] = [
            "inference_time": 0.5,
            "memory_usage": 150.0,
            "cpu_usage": 45.0,
            "accuracy": 0.95,
            "throughput": 100.0
        ]
        
        // When
        let result = validationService.validatePerformanceMetrics(validMetrics)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testInvalidPerformanceMetricsNegativeValues() throws {
        // Given
        let invalidMetrics: [String: Any] = [
            "inference_time": -0.5, // Invalid
            "memory_usage": -150.0, // Invalid
            "cpu_usage": 45.0,
            "accuracy": 0.95,
            "throughput": 100.0
        ]
        
        // When
        let result = validationService.validatePerformanceMetrics(invalidMetrics)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("negative") || $0.contains("invalid") })
    }
    
    func testInvalidPerformanceMetricsOutOfBounds() throws {
        // Given
        let outOfBoundsMetrics: [String: Any] = [
            "inference_time": 0.5,
            "memory_usage": 150.0,
            "cpu_usage": 150.0, // Over 100%
            "accuracy": 1.5, // Over 100%
            "throughput": 100.0
        ]
        
        // When
        let result = validationService.validatePerformanceMetrics(outOfBoundsMetrics)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("range") || $0.contains("bounds") })
    }
    
    // MARK: - Batch Validation Tests
    
    func testBatchValidationMixed() throws {
        // Given
        let validInputs = [
            MockAITextInput(content: "Valid input 1"),
            MockAITextInput(content: "Valid input 2")
        ]
        let invalidInputs = [
            MockAITextInput(content: ""), // Invalid
            MockAITextInput(content: String(repeating: "x", count: 100_000)) // Invalid
        ]
        let allInputs = validInputs + invalidInputs
        
        // When
        let results = allInputs.map { validationService.validateAIInput($0) }
        
        // Then
        XCTAssertEqual(results.filter { $0.isValid }.count, 2)
        XCTAssertEqual(results.filter { !$0.isValid }.count, 2)
    }
    
    // MARK: - Async Validation Tests
    
    func testAsyncValidation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Async validation")
        let config = ModelConfiguration()
        
        // When
        let future = Future<ValidationResult, Never> { promise in
            let result = self.validationService.validateModelConfiguration(config)
            promise(.success(result))
        }
        
        future
            .sink { result in
                // Then
                XCTAssertTrue(result.isValid)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Edge Cases Tests
    
    func testValidationWithNilValues() throws {
        // Given
        let metricsWithNil: [String: Any?] = [
            "inference_time": 0.5,
            "memory_usage": nil,
            "cpu_usage": 45.0
        ]
        
        // When
        let compactMetrics = metricsWithNil.compactMapValues { $0 }
        let result = validationService.validatePerformanceMetrics(compactMetrics)
        
        // Then
        XCTAssertTrue(result.isValid) // Should handle missing optional values gracefully
    }
    
    func testValidationWithExtremeValues() throws {
        // Given
        let extremeConfig = ModelConfiguration(
            maxInputTokens: Int.max,
            maxOutputTokens: Int.max,
            temperature: Double.greatestFiniteMagnitude,
            topP: Double.greatestFiniteMagnitude,
            frequencyPenalty: Double.greatestFiniteMagnitude,
            presencePenalty: Double.greatestFiniteMagnitude
        )
        
        // When
        let result = validationService.validateModelConfiguration(extremeConfig)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.errors.isEmpty)
    }
    
    func testConcurrentValidation() throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent validation")
        expectation.expectedFulfillmentCount = 10
        let config = ModelConfiguration()
        
        // When
        for _ in 0..<10 {
            DispatchQueue.global().async {
                let result = self.validationService.validateModelConfiguration(config)
                XCTAssertTrue(result.isValid)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testValidationPerformance() throws {
        // Given
        let config = ModelConfiguration()
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = validationService.validateModelConfiguration(config)
            }
        }
    }
    
    func testBatchValidationPerformance() throws {
        // Given
        let inputs = Array(0..<1000).map { MockAITextInput(content: "Test input \($0)") }
        
        // When & Then
        measure {
            for input in inputs {
                _ = validationService.validateAIInput(input)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testValidationErrorDetails() throws {
        // Given
        let invalidConfig = ModelConfiguration(
            maxInputTokens: -1,
            maxOutputTokens: -1,
            temperature: -1,
            topP: -1,
            frequencyPenalty: -1,
            presencePenalty: -1
        )
        
        // When
        let result = validationService.validateModelConfiguration(invalidConfig)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.count >= 6) // Each invalid field should generate an error
        
        // Verify error details
        for error in result.errors {
            XCTAssertFalse(error.isEmpty)
            XCTAssertTrue(error.contains("must be") || error.contains("should be") || error.contains("invalid"))
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() throws {
        // Given
        weak var weakService: ValidationService?
        
        // When
        autoreleasepool {
            let service = ValidationService()
            weakService = service
            
            // Perform validations
            _ = service.validateModelConfiguration(ModelConfiguration())
        }
        
        // Then
        XCTAssertNil(weakService, "ValidationService should be deallocated")
    }
}

// MARK: - Mock Objects

class MockValidationLogger: LoggerProtocol {
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

struct MockAITextInput: AIInputValidatable {
    let content: String
    
    func validate() -> ValidationResult {
        if content.isEmpty {
            return .failure(["Content cannot be empty"])
        }
        if content.count > 50_000 {
            return .failure(["Content is too long"])
        }
        return .success
    }
}

struct MockAIImageInput: AIInputValidatable {
    let imageData: Data
    
    func validate() -> ValidationResult {
        if imageData.isEmpty {
            return .failure(["Image data cannot be empty"])
        }
        if imageData.count > 50_000_000 { // 50MB limit
            return .failure(["Image data is too large"])
        }
        return .success
    }
}

struct MockAITextOutput: AIOutputValidatable {
    let content: String
    let confidence: Double
    let processingTime: TimeInterval
    
    func validate() -> ValidationResult {
        var errors: [String] = []
        
        if content.isEmpty {
            errors.append("Output content cannot be empty")
        }
        
        if confidence < 0.5 {
            errors.append("Confidence score is too low")
        }
        
        if processingTime > 10.0 {
            errors.append("Processing time is too slow")
        }
        
        return errors.isEmpty ? .success : .failure(errors)
    }
}

// MARK: - Test Extensions

extension ValidationResult {
    static let success = ValidationResult(isValid: true, errors: [], warnings: [])
    
    static func failure(_ errors: [String]) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors, warnings: [])
    }
}