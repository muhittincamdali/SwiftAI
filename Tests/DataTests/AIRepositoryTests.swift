import XCTest
import CoreML
@testable import SwiftAI

final class AIRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    var repository: AIRepository!
    var mockLocalDataSource: MockAILocalDataSource!
    var mockRemoteDataSource: MockAIRemoteDataSource!
    var mockAIEngine: MockAIEngine!
    var mockPerformanceMonitor: MockPerformanceMonitor!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        mockLocalDataSource = MockAILocalDataSource()
        mockRemoteDataSource = MockAIRemoteDataSource()
        mockAIEngine = MockAIEngine()
        mockPerformanceMonitor = MockPerformanceMonitor()
        
        repository = AIRepository(
            localDataSource: mockLocalDataSource,
            remoteDataSource: mockRemoteDataSource,
            aiEngine: mockAIEngine,
            performanceMonitor: mockPerformanceMonitor
        )
    }
    
    override func tearDown() {
        repository = nil
        mockLocalDataSource = nil
        mockRemoteDataSource = nil
        mockAIEngine = nil
        mockPerformanceMonitor = nil
        super.tearDown()
    }
    
    // MARK: - AI Processing Tests
    func testProcessAIInput_Success() async throws {
        // Given
        let input = AIInput.text("Hello, world!")
        let expectedOutput = AIOutput.classification(["positive": 0.8, "negative": 0.2])
        
        mockAIEngine.processResult = expectedOutput
        mockPerformanceMonitor.metrics = PerformanceMetrics(
            averageInferenceTime: 0.1,
            memoryUsage: 50 * 1024 * 1024,
            cacheHitRate: 0.8,
            modelLoadTime: 0.2
        )
        
        // When
        let result = try await repository.processAIInput(input, type: .text)
        
        // Then
        XCTAssertEqual(result, expectedOutput)
        XCTAssertTrue(mockAIEngine.processCalled)
        XCTAssertTrue(mockLocalDataSource.saveInferenceResultCalled)
        XCTAssertTrue(mockLocalDataSource.savePerformanceMetricsCalled)
    }
    
    func testProcessAIInput_InvalidInput() async throws {
        // Given
        let input = AIInput.text("")
        
        // When & Then
        do {
            _ = try await repository.processAIInput(input, type: .text)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AIError)
        }
    }
    
    func testProcessBatchInputs_Success() async throws {
        // Given
        let inputs = [
            AIInput.text("Positive text"),
            AIInput.text("Negative text"),
            AIInput.text("Neutral text")
        ]
        
        let expectedOutputs = [
            AIOutput.classification(["positive": 0.9, "negative": 0.1]),
            AIOutput.classification(["positive": 0.1, "negative": 0.9]),
            AIOutput.classification(["positive": 0.5, "negative": 0.5])
        ]
        
        mockAIEngine.processBatchResult = expectedOutputs
        mockPerformanceMonitor.metrics = PerformanceMetrics(
            averageInferenceTime: 0.1,
            memoryUsage: 50 * 1024 * 1024,
            cacheHitRate: 0.8,
            modelLoadTime: 0.2
        )
        
        // When
        let results = try await repository.processBatchInputs(inputs, type: .text)
        
        // Then
        XCTAssertEqual(results.count, expectedOutputs.count)
        XCTAssertEqual(results, expectedOutputs)
        XCTAssertTrue(mockAIEngine.processBatchCalled)
    }
    
    // MARK: - Model Management Tests
    func testLoadModel_Success() async throws {
        // Given
        let modelName = "test_model"
        let mockModel = MockMLModel()
        
        mockLocalDataSource.loadModelResult = mockModel
        
        // When
        let result = try await repository.loadModel(withName: modelName)
        
        // Then
        XCTAssertEqual(result, mockModel)
        XCTAssertTrue(mockLocalDataSource.loadModelCalled)
        XCTAssertEqual(mockLocalDataSource.loadModelName, modelName)
    }
    
    func testLoadModel_LocalFailure_RemoteSuccess() async throws {
        // Given
        let modelName = "test_model"
        let mockModel = MockMLModel()
        
        mockLocalDataSource.loadModelError = AIRepositoryError.modelNotFound
        mockRemoteDataSource.downloadModelResult = mockModel
        
        // When
        let result = try await repository.loadModel(withName: modelName)
        
        // Then
        XCTAssertEqual(result, mockModel)
        XCTAssertTrue(mockLocalDataSource.loadModelCalled)
        XCTAssertTrue(mockRemoteDataSource.downloadModelCalled)
        XCTAssertTrue(mockLocalDataSource.saveModelCalled)
    }
    
    func testSaveModel_Success() async throws {
        // Given
        let modelName = "test_model"
        let mockModel = MockMLModel()
        
        // When
        try await repository.saveModel(mockModel, withName: modelName)
        
        // Then
        XCTAssertTrue(mockLocalDataSource.saveModelCalled)
        XCTAssertEqual(mockLocalDataSource.saveModelName, modelName)
        XCTAssertEqual(mockLocalDataSource.saveModelModel, mockModel)
    }
    
    func testDeleteModel_Success() async throws {
        // Given
        let modelName = "test_model"
        
        // When
        try await repository.deleteModel(withName: modelName)
        
        // Then
        XCTAssertTrue(mockLocalDataSource.deleteModelCalled)
        XCTAssertEqual(mockLocalDataSource.deleteModelName, modelName)
    }
    
    func testGetAllModels_Success() async throws {
        // Given
        let expectedModels = ["model1", "model2", "model3"]
        mockLocalDataSource.getAllModelsResult = expectedModels
        
        // When
        let result = try await repository.getAllModels()
        
        // Then
        XCTAssertEqual(result, expectedModels)
        XCTAssertTrue(mockLocalDataSource.getAllModelsCalled)
    }
    
    // MARK: - History Management Tests
    func testGetInferenceHistory_Success() async throws {
        // Given
        let expectedHistory = [
            InferenceRecord(
                id: UUID(),
                input: AIInput.text("test"),
                output: AIOutput.classification(["positive": 0.8]),
                timestamp: Date(),
                processingTime: 0.1
            )
        ]
        
        mockLocalDataSource.getInferenceHistoryResult = expectedHistory
        
        // When
        let result = try await repository.getInferenceHistory()
        
        // Then
        XCTAssertEqual(result, expectedHistory)
        XCTAssertTrue(mockLocalDataSource.getInferenceHistoryCalled)
    }
    
    func testClearInferenceHistory_Success() async throws {
        // When
        try await repository.clearInferenceHistory()
        
        // Then
        XCTAssertTrue(mockLocalDataSource.clearInferenceHistoryCalled)
    }
    
    func testGetPerformanceMetrics_Success() async throws {
        // Given
        let expectedMetrics = PerformanceMetrics(
            averageInferenceTime: 0.1,
            memoryUsage: 50 * 1024 * 1024,
            cacheHitRate: 0.8,
            modelLoadTime: 0.2
        )
        
        mockPerformanceMonitor.metrics = expectedMetrics
        
        // When
        let result = try await repository.getPerformanceMetrics()
        
        // Then
        XCTAssertEqual(result, expectedMetrics)
    }
    
    // MARK: - Remote Sync Tests
    func testSyncWithRemote_Success() async throws {
        // Given
        let history = [
            InferenceRecord(
                id: UUID(),
                input: AIInput.text("test"),
                output: AIOutput.classification(["positive": 0.8]),
                timestamp: Date(),
                processingTime: 0.1
            )
        ]
        
        let updates = [
            ModelUpdate(
                modelName: "model1",
                version: "1.1.0",
                downloadURL: URL(string: "https://example.com/model1")!,
                releaseNotes: "Bug fixes",
                isRequired: false,
                releaseDate: Date(),
                size: 100 * 1024 * 1024,
                checksum: "abc123"
            )
        ]
        
        mockLocalDataSource.getInferenceHistoryResult = history
        mockRemoteDataSource.checkForModelUpdatesResult = updates
        mockRemoteDataSource.downloadModelUpdateResult = MockMLModel()
        
        // When
        try await repository.syncWithRemote()
        
        // Then
        XCTAssertTrue(mockLocalDataSource.getInferenceHistoryCalled)
        XCTAssertTrue(mockRemoteDataSource.syncInferenceResultsCalled)
        XCTAssertTrue(mockRemoteDataSource.checkForModelUpdatesCalled)
    }
    
    // MARK: - Model Validation Tests
    func testValidateModel_Success() async throws {
        // Given
        let mockModel = MockMLModel()
        
        // When
        let result = try await repository.validateModel(mockModel)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testValidateModel_Failure() async throws {
        // Given
        let mockModel = MockMLModel()
        mockModel.isValid = false
        
        // When
        let result = try await repository.validateModel(mockModel)
        
        // Then
        XCTAssertFalse(result)
    }
    
    // MARK: - Model Optimization Tests
    func testOptimizeModel_Success() async throws {
        // Given
        let mockModel = MockMLModel()
        let optimizedModel = MockMLModel()
        
        // When
        let result = try await repository.optimizeModel(mockModel)
        
        // Then
        XCTAssertEqual(result, optimizedModel)
    }
}

// MARK: - Mock Classes
class MockAILocalDataSource: AILocalDataSourceProtocol {
    var loadModelResult: MLModel?
    var loadModelError: Error?
    var loadModelCalled = false
    var loadModelName: String?
    
    var saveModelCalled = false
    var saveModelName: String?
    var saveModelModel: MLModel?
    
    var deleteModelCalled = false
    var deleteModelName: String?
    
    var getAllModelsResult: [String] = []
    var getAllModelsCalled = false
    
    var saveInferenceResultCalled = false
    var savePerformanceMetricsCalled = false
    
    var getInferenceHistoryResult: [InferenceRecord] = []
    var getInferenceHistoryCalled = false
    
    var clearInferenceHistoryCalled = false
    
    func loadModel(withName name: String) async throws -> MLModel {
        loadModelCalled = true
        loadModelName = name
        
        if let error = loadModelError {
            throw error
        }
        
        return loadModelResult ?? MockMLModel()
    }
    
    func saveModel(_ model: MLModel, withName name: String) async throws {
        saveModelCalled = true
        saveModelName = name
        saveModelModel = model
    }
    
    func deleteModel(withName name: String) async throws {
        deleteModelCalled = true
        deleteModelName = name
    }
    
    func getAllModels() async throws -> [String] {
        getAllModelsCalled = true
        return getAllModelsResult
    }
    
    func saveInferenceResult(_ result: AIOutput, forInput input: AIInput) async throws {
        saveInferenceResultCalled = true
    }
    
    func getInferenceHistory() async throws -> [InferenceRecord] {
        getInferenceHistoryCalled = true
        return getInferenceHistoryResult
    }
    
    func clearInferenceHistory() async throws {
        clearInferenceHistoryCalled = true
    }
    
    func savePerformanceMetrics(_ metrics: PerformanceMetrics) async throws {
        savePerformanceMetricsCalled = true
    }
    
    func getPerformanceHistory() async throws -> [PerformanceRecord] {
        return []
    }
}

class MockAIRemoteDataSource: AIRemoteDataSourceProtocol {
    var downloadModelResult: MLModel?
    var downloadModelCalled = false
    
    var uploadModelCalled = false
    
    var fetchModelMetadataResult: ModelMetadata?
    var fetchModelMetadataCalled = false
    
    var syncInferenceResultsCalled = false
    
    var fetchPerformanceAnalyticsResult: PerformanceAnalytics?
    var fetchPerformanceAnalyticsCalled = false
    
    var validateModelSignatureResult = true
    var validateModelSignatureCalled = false
    
    var checkForModelUpdatesResult: [ModelUpdate] = []
    var checkForModelUpdatesCalled = false
    
    var downloadModelUpdateResult: MLModel?
    var downloadModelUpdateCalled = false
    
    func downloadModel(withName name: String, from url: URL) async throws -> MLModel {
        downloadModelCalled = true
        return downloadModelResult ?? MockMLModel()
    }
    
    func uploadModel(_ model: MLModel, withName name: String, to url: URL) async throws {
        uploadModelCalled = true
    }
    
    func fetchModelMetadata(for name: String) async throws -> ModelMetadata {
        fetchModelMetadataCalled = true
        return fetchModelMetadataResult ?? ModelMetadata(
            name: "test",
            version: "1.0.0",
            size: 1000,
            createdAt: Date(),
            lastAccessed: Date()
        )
    }
    
    func syncInferenceResults(_ results: [InferenceRecord]) async throws {
        syncInferenceResultsCalled = true
    }
    
    func fetchPerformanceAnalytics() async throws -> PerformanceAnalytics {
        fetchPerformanceAnalyticsCalled = true
        return fetchPerformanceAnalyticsResult ?? PerformanceAnalytics(
            totalInferences: 100,
            averageProcessingTime: 0.1,
            averageMemoryUsage: 50 * 1024 * 1024,
            successRate: 0.95,
            errorRate: 0.05,
            mostUsedModels: ["model1": 50],
            mostProcessedInputTypes: [.text: 80],
            performanceTrends: [],
            lastUpdated: Date()
        )
    }
    
    func validateModelSignature(_ model: MLModel, withSignature signature: String) async throws -> Bool {
        validateModelSignatureCalled = true
        return validateModelSignatureResult
    }
    
    func checkForModelUpdates() async throws -> [ModelUpdate] {
        checkForModelUpdatesCalled = true
        return checkForModelUpdatesResult
    }
    
    func downloadModelUpdate(_ update: ModelUpdate) async throws -> MLModel {
        downloadModelUpdateCalled = true
        return downloadModelUpdateResult ?? MockMLModel()
    }
}

class MockAIEngine: AIEngine {
    var processResult: AIOutput?
    var processCalled = false
    
    var processBatchResult: [AIOutput] = []
    var processBatchCalled = false
    
    override func process(_ input: AIInput, type: AIInputType) async throws -> AIOutput {
        processCalled = true
        return processResult ?? AIOutput.classification(["positive": 0.8, "negative": 0.2])
    }
    
    override func processBatch(_ inputs: [AIInput], type: AIInputType) async throws -> [AIOutput] {
        processBatchCalled = true
        return processBatchResult.isEmpty ? [AIOutput.classification(["positive": 0.8, "negative": 0.2])] : processBatchResult
    }
}

class MockPerformanceMonitor: PerformanceMonitorProtocol {
    var metrics = PerformanceMetrics(
        averageInferenceTime: 0.1,
        memoryUsage: 50 * 1024 * 1024,
        cacheHitRate: 0.8,
        modelLoadTime: 0.2
    )
    
    func startMonitoring() {}
    
    func stopMonitoring() {}
    
    func getMetrics() -> PerformanceMetrics {
        return metrics
    }
}

class MockMLModel: MLModel {
    var isValid = true
    
    override var modelDescription: MLModelDescription {
        return MLModelDescription()
    }
    
    override var url: URL {
        return URL(fileURLWithPath: "/tmp/mock_model.mlmodel")
    }
    
    override func prediction(from input: MLFeatureProvider) throws -> MLFeatureProvider {
        return MLDictionaryFeatureProvider()
    }
    
    override func modelData() throws -> Data {
        return Data()
    }
}
