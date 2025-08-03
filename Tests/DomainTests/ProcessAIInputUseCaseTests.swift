import XCTest
@testable import SwiftAI

final class ProcessAIInputUseCaseTests: XCTestCase {
    var useCase: ProcessAIInputUseCase!
    var mockRepository: MockAIRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAIRepository()
        useCase = ProcessAIInputUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testProcessAIInput_TextClassification_Success() async throws {
        // Given
        let input = AIInput.text("Test input")
        let expectedOutput = AIOutput.classification(["positive": 0.8, "negative": 0.2])
        mockRepository.processAIInputResult = expectedOutput
        
        // When
        let result = try await useCase.execute(input: input, type: .text)
        
        // Then
        XCTAssertEqual(result, expectedOutput)
        XCTAssertTrue(mockRepository.processAIInputCalled)
    }
    
    func testProcessAIInput_Error() async throws {
        // Given
        let input = AIInput.text("Test input")
        mockRepository.shouldThrowError = true
        
        // When & Then
        do {
            _ = try await useCase.execute(input: input, type: .text)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(mockRepository.processAIInputCalled)
        }
    }
    
    func testProcessBatchInputs_Success() async throws {
        // Given
        let inputs = [AIInput.text("A"), AIInput.text("B")]
        let expectedOutputs = [
            AIOutput.classification(["positive": 0.7]),
            AIOutput.classification(["negative": 0.6])
        ]
        mockRepository.processBatchInputsResult = expectedOutputs
        
        // When
        let results = try await useCase.executeBatch(inputs: inputs, type: .text)
        
        // Then
        XCTAssertEqual(results, expectedOutputs)
        XCTAssertTrue(mockRepository.processBatchInputsCalled)
    }
    
    func testProcessBatchInputs_Error() async throws {
        // Given
        let inputs = [AIInput.text("A"), AIInput.text("B")]
        mockRepository.shouldThrowError = true
        
        // When & Then
        do {
            _ = try await useCase.executeBatch(inputs: inputs, type: .text)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(mockRepository.processBatchInputsCalled)
        }
    }
}

// MARK: - Mock AIRepository
class MockAIRepository: AIRepositoryProtocol {
    var processAIInputResult: AIOutput = .classification([:])
    var processAIInputCalled = false
    var processBatchInputsResult: [AIOutput] = []
    var processBatchInputsCalled = false
    var shouldThrowError = false
    
    func processAIInput(_ input: AIInput, type: AIInputType) async throws -> AIOutput {
        processAIInputCalled = true
        if shouldThrowError { throw NSError(domain: "MockError", code: 1, userInfo: nil) }
        return processAIInputResult
    }
    func processBatchInputs(_ inputs: [AIInput], type: AIInputType) async throws -> [AIOutput] {
        processBatchInputsCalled = true
        if shouldThrowError { throw NSError(domain: "MockError", code: 1, userInfo: nil) }
        return processBatchInputsResult
    }
    // The rest of the protocol methods can be left unimplemented for brevity
    func loadModel(withName name: String) async throws -> MLModel { fatalError() }
    func saveModel(_ model: MLModel, withName name: String) async throws { fatalError() }
    func deleteModel(withName name: String) async throws { fatalError() }
    func getAllModels() async throws -> [String] { fatalError() }
    func validateModel(_ model: MLModel) async throws -> Bool { fatalError() }
    func optimizeModel(_ model: MLModel) async throws -> MLModel { fatalError() }
    func getInferenceHistory() async throws -> [InferenceRecord] { fatalError() }
    func clearInferenceHistory() async throws { fatalError() }
    func getPerformanceMetrics() async throws -> PerformanceMetrics { fatalError() }
    func syncWithRemote() async throws { fatalError() }
    func checkForUpdates() async throws -> [ModelUpdate] { fatalError() }
    func downloadUpdate(_ update: ModelUpdate) async throws -> MLModel { fatalError() }
    func getAnalytics() async throws -> AIAnalytics { fatalError() }
    func trackUsage(_ usage: AIUsage) async throws { fatalError() }
    func getUsageStatistics() async throws -> AIUsageStatistics { fatalError() }
}
