import XCTest
import CoreML
@testable import SwiftAI

final class CoreMLManagerTests: XCTestCase {
    
    // MARK: - Properties
    var coreMLManager: CoreMLManager!
    var mockModel: MockMLModel!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        coreMLManager = CoreMLManager()
        mockModel = MockMLModel()
    }
    
    override func tearDown() {
        coreMLManager = nil
        mockModel = nil
        super.tearDown()
    }
    
    // MARK: - Model Loading Tests
    func testLoadModel_Success() async throws {
        // Given
        let modelName = "test_model"
        
        // When
        let model = try await coreMLManager.loadModel(name: modelName)
        
        // Then
        XCTAssertNotNil(model)
        XCTAssertEqual(model.modelDescription.metadata[MLModelMetadataKey.creator] as? String, "SwiftAI")
    }
    
    func testLoadModel_InvalidName() async throws {
        // Given
        let invalidModelName = ""
        
        // When & Then
        do {
            _ = try await coreMLManager.loadModel(name: invalidModelName)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CoreMLError)
        }
    }
    
    func testLoadModel_ModelNotFound() async throws {
        // Given
        let nonExistentModelName = "non_existent_model"
        
        // When & Then
        do {
            _ = try await coreMLManager.loadModel(name: nonExistentModelName)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CoreMLError)
        }
    }
    
    // MARK: - Model Validation Tests
    func testValidateModel_ValidModel() async throws {
        // Given
        let validModel = mockModel
        
        // When
        let isValid = try await coreMLManager.validateModel(validModel)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testValidateModel_InvalidModel() async throws {
        // Given
        let invalidModel = MockMLModel()
        invalidModel.isValid = false
        
        // When
        let isValid = try await coreMLManager.validateModel(invalidModel)
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Model Optimization Tests
    func testOptimizeModel_Success() async throws {
        // Given
        let originalModel = mockModel
        
        // When
        let optimizedModel = try await coreMLManager.optimizeModel(originalModel)
        
        // Then
        XCTAssertNotNil(optimizedModel)
        XCTAssertNotEqual(originalModel, optimizedModel)
    }
    
    func testOptimizeModel_OptimizationFailed() async throws {
        // Given
        let unoptimizableModel = MockMLModel()
        unoptimizableModel.canOptimize = false
        
        // When & Then
        do {
            _ = try await coreMLManager.optimizeModel(unoptimizableModel)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CoreMLError)
        }
    }
    
    // MARK: - Model Compilation Tests
    func testCompileModel_Success() async throws {
        // Given
        let modelURL = URL(fileURLWithPath: "/tmp/test_model.mlmodel")
        
        // When
        let compiledURL = try await coreMLManager.compileModel(at: modelURL)
        
        // Then
        XCTAssertNotNil(compiledURL)
        XCTAssertTrue(compiledURL.path.hasSuffix(".mlmodelc"))
    }
    
    func testCompileModel_InvalidURL() async throws {
        // Given
        let invalidURL = URL(fileURLWithPath: "/invalid/path/model.mlmodel")
        
        // When & Then
        do {
            _ = try await coreMLManager.compileModel(at: invalidURL)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CoreMLError)
        }
    }
    
    // MARK: - Model Prediction Tests
    func testPredict_Success() async throws {
        // Given
        let input = AIInput.text("Test input")
        let model = mockModel
        
        // When
        let output = try await coreMLManager.predict(input: input, model: model)
        
        // Then
        XCTAssertNotNil(output)
    }
    
    func testPredict_InvalidInput() async throws {
        // Given
        let invalidInput = AIInput.text("")
        let model = mockModel
        
        // When & Then
        do {
            _ = try await coreMLManager.predict(input: invalidInput, model: model)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CoreMLError)
        }
    }
    
    func testPredict_ModelError() async throws {
        // Given
        let input = AIInput.text("Test input")
        let errorModel = MockMLModel()
        errorModel.shouldThrowError = true
        
        // When & Then
        do {
            _ = try await coreMLManager.predict(input: input, model: errorModel)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CoreMLError)
        }
    }
    
    // MARK: - Batch Prediction Tests
    func testPredictBatch_Success() async throws {
        // Given
        let inputs = [
            AIInput.text("Input 1"),
            AIInput.text("Input 2"),
            AIInput.text("Input 3")
        ]
        let model = mockModel
        
        // When
        let outputs = try await coreMLManager.predictBatch(inputs: inputs, model: model)
        
        // Then
        XCTAssertEqual(outputs.count, inputs.count)
        XCTAssertTrue(outputs.allSatisfy { $0 != nil })
    }
    
    func testPredictBatch_EmptyInput() async throws {
        // Given
        let inputs: [AIInput] = []
        let model = mockModel
        
        // When
        let outputs = try await coreMLManager.predictBatch(inputs: inputs, model: model)
        
        // Then
        XCTAssertTrue(outputs.isEmpty)
    }
    
    func testPredictBatch_PartialFailure() async throws {
        // Given
        let inputs = [
            AIInput.text("Valid input"),
            AIInput.text(""), // Invalid input
            AIInput.text("Another valid input")
        ]
        let model = mockModel
        
        // When & Then
        do {
            _ = try await coreMLManager.predictBatch(inputs: inputs, model: model)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CoreMLError)
        }
    }
    
    // MARK: - Model Management Tests
    func testGetAvailableModels() async throws {
        // When
        let models = try await coreMLManager.getAvailableModels()
        
        // Then
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.allSatisfy { !$0.isEmpty })
    }
    
    func testDeleteModel_Success() async throws {
        // Given
        let modelName = "test_model_to_delete"
        
        // When
        try await coreMLManager.deleteModel(name: modelName)
        
        // Then
        // Verify model is deleted by trying to load it
        do {
            _ = try await coreMLManager.loadModel(name: modelName)
            XCTFail("Model should be deleted")
        } catch {
            XCTAssertTrue(error is CoreMLError)
        }
    }
    
    func testDeleteModel_ModelNotFound() async throws {
        // Given
        let nonExistentModelName = "non_existent_model"
        
        // When & Then
        do {
            try await coreMLManager.deleteModel(name: nonExistentModelName)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CoreMLError)
        }
    }
    
    // MARK: - Performance Tests
    func testPerformance_Predict() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                do {
                    let input = AIInput.text("Performance test input")
                    let model = self.mockModel
                    _ = try await self.coreMLManager.predict(input: input, model: model)
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformance_PredictBatch() {
        measure {
            let expectation = XCTestExpectation(description: "Batch performance test")
            
            Task {
                do {
                    let inputs = Array(repeating: AIInput.text("Batch test input"), count: 10)
                    let model = self.mockModel
                    _ = try await self.coreMLManager.predictBatch(inputs: inputs, model: model)
                    expectation.fulfill()
                } catch {
                    XCTFail("Batch performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Memory Tests
    func testMemoryUsage_LoadModel() async throws {
        // Given
        let initialMemory = getCurrentMemoryUsage()
        
        // When
        _ = try await coreMLManager.loadModel(name: "test_model")
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024) // Less than 100MB increase
    }
    
    func testMemoryUsage_Predict() async throws {
        // Given
        let model = try await coreMLManager.loadModel(name: "test_model")
        let initialMemory = getCurrentMemoryUsage()
        
        // When
        let input = AIInput.text("Memory test input")
        _ = try await coreMLManager.predict(input: input, model: model)
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024) // Less than 50MB increase
    }
    
    // MARK: - Helper Methods
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Mock MLModel
class MockMLModel: MLModel {
    var isValid: Bool = true
    var canOptimize: Bool = true
    var shouldThrowError: Bool = false
    
    override var modelDescription: MLModelDescription {
        let description = MLModelDescription()
        description.metadata[MLModelMetadataKey.creator] = "SwiftAI"
        return description
    }
    
    override var url: URL {
        return URL(fileURLWithPath: "/tmp/mock_model.mlmodel")
    }
    
    override func prediction(from input: MLFeatureProvider) throws -> MLFeatureProvider {
        if shouldThrowError {
            throw CoreMLError(.modelPredictionError)
        }
        
        return MLDictionaryFeatureProvider()
    }
    
    override func modelData() throws -> Data {
        return Data(repeating: 0, count: 1024) // 1KB mock data
    }
}
