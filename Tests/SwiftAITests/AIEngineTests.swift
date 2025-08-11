import XCTest
import CoreML
import Vision
import NaturalLanguage
@testable import SwiftAI

final class AIEngineTests: XCTestCase {
    
    var aiEngine: AIEngine!
    var mockModelManager: MockModelManager!
    var mockInferenceEngine: MockInferenceEngine!
    var mockPerformanceMonitor: MockPerformanceMonitor!
    
    override func setUp() {
        super.setUp()
        mockModelManager = MockModelManager()
        mockInferenceEngine = MockInferenceEngine()
        mockPerformanceMonitor = MockPerformanceMonitor()
        
        let configuration = AIEngineConfiguration(
            textModelName: "test_text_model",
            imageModelName: "test_image_model",
            audioModelName: "test_audio_model",
            videoModelName: "test_video_model",
            sensorModelName: "test_sensor_model",
            multimodalModelName: "test_multimodal_model",
            enableGPU: true,
            enableNeuralEngine: true,
            maxBatchSize: 5,
            enableCaching: true,
            performanceMode: .balanced
        )
        
        aiEngine = AIEngine(
            modelManager: mockModelManager,
            inferenceEngine: mockInferenceEngine,
            performanceMonitor: mockPerformanceMonitor,
            configuration: configuration
        )
    }
    
    override func tearDown() {
        aiEngine = nil
        mockModelManager = nil
        mockInferenceEngine = nil
        mockPerformanceMonitor = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAIEngineInitialization() {
        XCTAssertNotNil(aiEngine)
        XCTAssertNotNil(mockModelManager)
        XCTAssertNotNil(mockInferenceEngine)
        XCTAssertNotNil(mockPerformanceMonitor)
    }
    
    func testAIEngineWithCustomConfiguration() {
        let customConfig = AIEngineConfiguration(
            textModelName: "custom_text_model",
            imageModelName: "custom_image_model",
            audioModelName: "custom_audio_model",
            videoModelName: "custom_video_model",
            sensorModelName: "custom_sensor_model",
            multimodalModelName: "custom_multimodal_model",
            enableGPU: false,
            enableNeuralEngine: false,
            maxBatchSize: 10,
            enableCaching: false,
            performanceMode: .powerEfficient
        )
        
        let customEngine = AIEngine(
            modelManager: mockModelManager,
            inferenceEngine: mockInferenceEngine,
            performanceMonitor: mockPerformanceMonitor,
            configuration: customConfig
        )
        
        XCTAssertNotNil(customEngine)
    }
    
    // MARK: - Text Processing Tests
    
    func testTextClassification() async throws {
        let textInput = AIInput.text("Hello, how are you?")
        let expectedOutput = AIOutput.classification(["positive": 0.8, "negative": 0.1, "neutral": 0.1])
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(textInput, type: .text)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(mockPerformanceMonitor.startMonitoringCalled, true)
        XCTAssertEqual(mockPerformanceMonitor.stopMonitoringCalled, true)
        XCTAssertEqual(mockModelManager.loadModelCalled, true)
        XCTAssertEqual(mockInferenceEngine.inferCalled, true)
    }
    
    func testTextSentimentAnalysis() async throws {
        let textInput = AIInput.text("I love this product!")
        let expectedOutput = AIOutput.sentiment(.positive(0.9))
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(textInput, type: .text)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testTextLanguageDetection() async throws {
        let textInput = AIInput.text("Bonjour, comment allez-vous?")
        let expectedOutput = AIOutput.classification(["french": 0.95, "english": 0.05])
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(textInput, type: .text)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testEmptyTextInput() async throws {
        let textInput = AIInput.text("")
        
        XCTAssertThrowsError(try await aiEngine.process(textInput, type: .text)) { error in
            XCTAssertEqual(error as? AIError, .invalidInput)
        }
    }
    
    func testTextWithSpecialCharacters() async throws {
        let textInput = AIInput.text("Hello! How are you? 😊 #AI #MachineLearning")
        let expectedOutput = AIOutput.classification(["positive": 0.7, "neutral": 0.3])
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(textInput, type: .text)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    // MARK: - Image Processing Tests
    
    func testImageClassification() async throws {
        guard let image = createTestImage() else {
            XCTFail("Failed to create test image")
            return
        }
        
        let imageInput = AIInput.image(image)
        let expectedOutput = AIOutput.classification(["person": 0.95, "background": 0.05])
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(imageInput, type: .image)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testImageObjectDetection() async throws {
        guard let image = createTestImage() else {
            XCTFail("Failed to create test image")
            return
        }
        
        let imageInput = AIInput.image(image)
        let detections = [
            DetectionResult(
                label: "person",
                confidence: 0.95,
                boundingBox: CGRect(x: 0, y: 0, width: 100, height: 200),
                metadata: ["age": "25-35"],
                timestamp: Date()
            ),
            DetectionResult(
                label: "car",
                confidence: 0.87,
                boundingBox: CGRect(x: 150, y: 50, width: 200, height: 100),
                metadata: ["color": "red"],
                timestamp: Date()
            )
        ]
        let expectedOutput = AIOutput.detection(detections)
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(imageInput, type: .image)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testImageWithNilImage() async throws {
        let imageInput = AIInput.image(UIImage())
        
        // This should not crash and should handle gracefully
        let expectedOutput = AIOutput.classification(["unknown": 1.0])
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(imageInput, type: .image)
        
        XCTAssertNotNil(result)
    }
    
    // MARK: - Audio Processing Tests
    
    func testAudioClassification() async throws {
        let audioData = createTestAudioData()
        let audioInput = AIInput.audio(audioData)
        let expectedOutput = AIOutput.classification(["speech": 0.9, "music": 0.05, "noise": 0.05])
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(audioInput, type: .audio)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testAudioWithEmptyData() async throws {
        let audioInput = AIInput.audio(Data())
        
        XCTAssertThrowsError(try await aiEngine.process(audioInput, type: .audio)) { error in
            XCTAssertEqual(error as? AIError, .invalidInput)
        }
    }
    
    // MARK: - Video Processing Tests
    
    func testVideoClassification() async throws {
        let videoURL = createTestVideoURL()
        let videoInput = AIInput.video(videoURL)
        let expectedOutput = AIOutput.classification(["action": 0.7, "drama": 0.2, "comedy": 0.1])
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(videoInput, type: .video)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    // MARK: - Sensor Data Tests
    
    func testSensorDataProcessing() async throws {
        let sensorData = [1.0, 2.0, 3.0, 4.0, 5.0]
        let sensorInput = AIInput.sensorData(sensorData)
        let expectedOutput = AIOutput.prediction(
            PredictionResult(
                value: 3.0,
                confidence: 0.95,
                range: 2.5...3.5,
                factors: ["temperature": 0.8, "humidity": 0.6]
            )
        )
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(sensorInput, type: .sensorData)
        
            XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    // MARK: - Multimodal Tests
    
    func testMultimodalProcessing() async throws {
        let textInput = AIInput.text("Describe this image")
        let imageInput = AIInput.image(createTestImage() ?? UIImage())
        let multimodalInput = AIInput.multimodal([textInput, imageInput])
        
        let expectedOutput = AIOutput.generation("This image shows a person standing in front of a car")
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.process(multimodalInput, type: .multimodal)
        
            XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    // MARK: - Batch Processing Tests
    
    func testBatchProcessing() async throws {
        let inputs = [
            AIInput.text("Hello"),
            AIInput.text("World"),
            AIInput.text("AI")
        ]
        
        let expectedOutputs = [
            AIOutput.classification(["positive": 0.8]),
            AIOutput.classification(["neutral": 0.7]),
            AIOutput.classification(["positive": 0.6])
        ]
        
        mockInferenceEngine.mockBatchOutputs = expectedOutputs
        
        let results = try await aiEngine.processBatch(inputs, type: .text)
        
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results, expectedOutputs)
    }
    
    // MARK: - Confidence Threshold Tests
    
    func testProcessingWithConfidenceThreshold() async throws {
        let textInput = AIInput.text("Test text")
        let expectedOutput = AIOutput.classification(["positive": 0.9])
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        let result = try await aiEngine.processWithConfidence(textInput, type: .text, threshold: 0.8)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedOutput)
    }
    
    // MARK: - Error Handling Tests
    
    func testModelNotFoundError() async throws {
        let textInput = AIInput.text("Test text")
        
        mockModelManager.shouldThrowError = true
        mockModelManager.errorToThrow = AIError.modelNotFound
        
        XCTAssertThrowsError(try await aiEngine.process(textInput, type: .text)) { error in
            XCTAssertEqual(error as? AIError, .modelNotFound)
        }
    }
    
    func testInvalidInputError() async throws {
        let textInput = AIInput.text("")
        
        XCTAssertThrowsError(try await aiEngine.process(textInput, type: .text)) { error in
            XCTAssertEqual(error as? AIError, .invalidInput)
        }
    }
    
    func testInferenceFailedError() async throws {
        let textInput = AIInput.text("Test text")
        
        mockInferenceEngine.shouldThrowError = true
        mockInferenceEngine.errorToThrow = AIError.inferenceFailed
        
        XCTAssertThrowsError(try await aiEngine.process(textInput, type: .text)) { error in
            XCTAssertEqual(error as? AIError, .inferenceFailed)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceMonitoring() async throws {
        let textInput = AIInput.text("Performance test")
        let expectedOutput = AIOutput.classification(["test": 1.0])
        
        mockInferenceEngine.mockOutput = expectedOutput
        
        _ = try await aiEngine.process(textInput, type: .text)
        
        XCTAssertTrue(mockPerformanceMonitor.startMonitoringCalled)
        XCTAssertTrue(mockPerformanceMonitor.stopMonitoringCalled)
    }
    
    func testPerformanceMetrics() {
        let metrics = mockPerformanceMonitor.getMetrics()
        
        XCTAssertNotNil(metrics)
        XCTAssertGreaterThanOrEqual(metrics.averageInferenceTime, 0)
        XCTAssertGreaterThanOrEqual(metrics.memoryUsage, 0)
        XCTAssertGreaterThanOrEqual(metrics.cacheHitRate, 0)
        XCTAssertLessThanOrEqual(metrics.cacheHitRate, 1)
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationValues() {
        let config = aiEngine.configuration
        
        XCTAssertEqual(config.textModelName, "test_text_model")
        XCTAssertEqual(config.imageModelName, "test_image_model")
        XCTAssertEqual(config.audioModelName, "test_audio_model")
        XCTAssertEqual(config.videoModelName, "test_video_model")
        XCTAssertEqual(config.sensorModelName, "test_sensor_model")
        XCTAssertEqual(config.multimodalModelName, "test_multimodal_model")
        XCTAssertTrue(config.enableGPU)
        XCTAssertTrue(config.enableNeuralEngine)
        XCTAssertEqual(config.maxBatchSize, 5)
        XCTAssertTrue(config.enableCaching)
        XCTAssertEqual(config.performanceMode, .balanced)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage? {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func createTestAudioData() -> Data {
        // Create a simple audio data for testing
        let sampleRate: Double = 44100
        let duration: Double = 1.0
        let frameCount = Int(sampleRate * duration)
        var audioData = Data()
        
        for i in 0..<frameCount {
            let sample = sin(2.0 * Double.pi * 440.0 * Double(i) / sampleRate)
            let sampleInt16 = Int16(sample * 32767.0)
            withUnsafeBytes(of: sampleInt16.littleEndian) { bytes in
                audioData.append(contentsOf: bytes)
            }
        }
        
        return audioData
    }
    
    private func createTestVideoURL() -> URL {
        // Create a temporary URL for testing
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("test_video.mp4")
    }
}

// MARK: - Mock Classes

class MockModelManager: ModelManagerProtocol {
    var loadModelCalled = false
    var validateModelCalled = false
    var optimizeModelCalled = false
    var clearCacheCalled = false
    var preloadModelsCalled = false
    var getModelInfoCalled = false
    
    var shouldThrowError = false
    var errorToThrow: AIError = .modelNotFound
    
    func loadModel(name: String) async throws -> MLModel {
        loadModelCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Return a mock MLModel
        return try MLModel(contentsOf: URL(fileURLWithPath: "/dev/null"))
    }
    
    func validateModel(_ model: MLModel) async throws -> Bool {
        validateModelCalled = true
        return true
    }
    
    func optimizeModel(_ model: MLModel) async throws -> MLModel {
        optimizeModelCalled = true
        return model
    }
    
    func clearCache() async {
        clearCacheCalled = true
    }
    
    func preloadModels(_ names: [String]) async throws -> [MLModel] {
        preloadModelsCalled = true
        return []
    }
    
    func getModelInfo(_ model: MLModel) -> ModelInfo {
        getModelInfoCalled = true
        return ModelInfo(
            name: "mock_model",
            version: "1.0.0",
            size: 1024,
            supportedInputTypes: [.text, .image],
            performanceMetrics: PerformanceMetrics(
                averageInferenceTime: 0.1,
                memoryUsage: 1024,
                cacheHitRate: 0.8,
                modelLoadTime: 0.05,
                gpuUtilization: 0.5,
                neuralEngineUtilization: 0.7,
                batteryImpact: 0.1
            ),
            lastUpdated: Date()
        )
    }
}

class MockInferenceEngine: InferenceEngineProtocol {
    var inferCalled = false
    var inferBatchCalled = false
    var inferWithConfidenceCalled = false
    var inferWithMetadataCalled = false
    
    var mockOutput: AIOutput = .classification(["test": 1.0])
    var mockBatchOutputs: [AIOutput] = []
    var mockOutputWithMetadata: AIOutputWithMetadata?
    
    var shouldThrowError = false
    var errorToThrow: AIError = .inferenceFailed
    
    func infer(input: AIInput, model: MLModel) async throws -> AIOutput {
        inferCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockOutput
    }
    
    func inferBatch(inputs: [AIInput], model: MLModel) async throws -> [AIOutput] {
        inferBatchCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockBatchOutputs.isEmpty ? Array(repeating: mockOutput, count: inputs.count) : mockBatchOutputs
    }
    
    func inferWithConfidence(input: AIInput, model: MLModel, threshold: Double) async throws -> AIOutput {
        inferWithConfidenceCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockOutput
    }
    
    func inferWithMetadata(input: AIInput, model: MLModel) async throws -> AIOutputWithMetadata {
        inferWithMetadataCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockOutputWithMetadata ?? AIOutputWithMetadata(
            output: mockOutput,
            confidence: 0.9,
            processingTime: 0.1,
            modelVersion: "1.0.0",
            metadata: [:]
        )
    }
}

class MockPerformanceMonitor: PerformanceMonitorProtocol {
    var startMonitoringCalled = false
    var stopMonitoringCalled = false
    var getMetricsCalled = false
    var resetMetricsCalled = false
    var exportMetricsCalled = false
    var setPerformanceThresholdCalled = false
    
    func startMonitoring() {
        startMonitoringCalled = true
    }
    
    func stopMonitoring() {
        stopMonitoringCalled = true
    }
    
    func getMetrics() -> PerformanceMetrics {
        getMetricsCalled = true
        return PerformanceMetrics(
            averageInferenceTime: 0.15,
            memoryUsage: 2048,
            cacheHitRate: 0.85,
            modelLoadTime: 0.08,
            gpuUtilization: 0.6,
            neuralEngineUtilization: 0.8,
            batteryImpact: 0.12
        )
    }
    
    func resetMetrics() {
        resetMetricsCalled = true
    }
    
    func exportMetrics() -> Data {
        exportMetricsCalled = true
        return Data()
    }
    
    func setPerformanceThreshold(_ threshold: PerformanceThreshold) {
        setPerformanceThresholdCalled = true
    }
}

// MARK: - Extensions for Testing

extension AIEngine {
    var configuration: AIEngineConfiguration {
        // This is a test-only accessor
        return Mirror(reflecting: self).children.first { $0.label == "configuration" }?.value as! AIEngineConfiguration
    }
} 