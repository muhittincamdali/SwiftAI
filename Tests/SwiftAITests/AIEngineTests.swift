import XCTest
import CoreML
@testable import SwiftAI

final class AIEngineTests: XCTestCase {
    
    var aiEngine: AIEngine!
    
    override func setUp() {
        super.setUp()
        aiEngine = AIEngine()
    }
    
    override func tearDown() {
        aiEngine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAIEngineInitialization() {
        XCTAssertNotNil(aiEngine)
        XCTAssertNotNil(aiEngine.configuration)
    }
    
    func testAIEngineWithCustomConfiguration() {
        let config = AIEngineConfiguration(
            modelPath: "test_model.mlmodel",
            enableGPU: true,
            enableNeuralEngine: true,
            batchSize: 5
        )
        
        let customEngine = AIEngine(configuration: config)
        XCTAssertNotNil(customEngine)
        XCTAssertEqual(customEngine.configuration.batchSize, 5)
    }
    
    // MARK: - Text Processing Tests
    
    func testTextClassification() async throws {
        let textInput = AIInput.text("Hello, how are you?")
        
        let result = try await aiEngine.process(textInput, type: .classification)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.confidence)
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
    
    func testTextSentimentAnalysis() async throws {
        let textInput = AIInput.text("I love this product!")
        
        let result = try await aiEngine.process(textInput, type: .sentimentAnalysis)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.sentiment)
    }
    
    func testTextLanguageDetection() async throws {
        let textInput = AIInput.text("Bonjour, comment allez-vous?")
        
        let result = try await aiEngine.process(textInput, type: .languageDetection)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.language)
    }
    
    func testEmptyTextInput() async throws {
        let textInput = AIInput.text("")
        
        XCTAssertThrowsError(try await aiEngine.process(textInput, type: .classification)) { error in
            XCTAssertEqual(error as? AIEngineError, .invalidInput)
        }
    }
    
    // MARK: - Image Processing Tests
    
    func testImageClassification() async throws {
        guard let image = createTestImage() else {
            XCTFail("Failed to create test image")
            return
        }
        
        let imageInput = AIInput.image(image)
        
        let result = try await aiEngine.process(imageInput, type: .classification)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.confidence)
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
    
    func testImageObjectDetection() async throws {
        guard let image = createTestImage() else {
            XCTFail("Failed to create test image")
            return
        }
        
        let imageInput = AIInput.image(image)
        
        let result = try await aiEngine.process(imageInput, type: .objectDetection)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.detections)
    }
    
    func testImageFaceDetection() async throws {
        guard let image = createTestImage() else {
            XCTFail("Failed to create test image")
            return
        }
        
        let imageInput = AIInput.image(image)
        
        let result = try await aiEngine.process(imageInput, type: .faceDetection)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.faces)
    }
    
    // MARK: - Audio Processing Tests
    
    func testAudioClassification() async throws {
        guard let audioData = createTestAudioData() else {
            XCTFail("Failed to create test audio data")
            return
        }
        
        let audioInput = AIInput.audio(audioData)
        
        let result = try await aiEngine.process(audioInput, type: .classification)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.confidence)
    }
    
    func testAudioSpeechRecognition() async throws {
        guard let audioData = createTestAudioData() else {
            XCTFail("Failed to create test audio data")
            return
        }
        
        let audioInput = AIInput.audio(audioData)
        
        let result = try await aiEngine.process(audioInput, type: .speechRecognition)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.transcription)
    }
    
    // MARK: - Batch Processing Tests
    
    func testBatchTextProcessing() async throws {
        let inputs = [
            AIInput.text("Hello, world!"),
            AIInput.text("How are you?"),
            AIInput.text("This is a test.")
        ]
        
        let results = try await aiEngine.processBatch(inputs, type: .classification)
        
        XCTAssertEqual(results.count, 3)
        for result in results {
            XCTAssertNotNil(result)
            XCTAssertNotNil(result.confidence)
        }
    }
    
    func testBatchImageProcessing() async throws {
        guard let image1 = createTestImage(),
              let image2 = createTestImage() else {
            XCTFail("Failed to create test images")
            return
        }
        
        let inputs = [
            AIInput.image(image1),
            AIInput.image(image2)
        ]
        
        let results = try await aiEngine.processBatch(inputs, type: .classification)
        
        XCTAssertEqual(results.count, 2)
        for result in results {
            XCTAssertNotNil(result)
            XCTAssertNotNil(result.confidence)
        }
    }
    
    func testMixedBatchProcessing() async throws {
        guard let image = createTestImage() else {
            XCTFail("Failed to create test image")
            return
        }
        
        let inputs = [
            AIInput.text("Hello, world!"),
            AIInput.image(image)
        ]
        
        let results = try await aiEngine.processBatch(inputs, type: .classification)
        
        XCTAssertEqual(results.count, 2)
        for result in results {
            XCTAssertNotNil(result)
            XCTAssertNotNil(result.confidence)
        }
    }
    
    // MARK: - Model Management Tests
    
    func testModelLoading() async throws {
        let modelPath = "test_model.mlmodel"
        
        let isLoaded = try await aiEngine.loadModel(at: modelPath)
        
        XCTAssertTrue(isLoaded)
    }
    
    func testModelUnloading() async throws {
        let modelPath = "test_model.mlmodel"
        
        try await aiEngine.loadModel(at: modelPath)
        let isUnloaded = try await aiEngine.unloadModel(at: modelPath)
        
        XCTAssertTrue(isUnloaded)
    }
    
    func testModelValidation() async throws {
        let modelPath = "test_model.mlmodel"
        
        let isValid = try await aiEngine.validateModel(at: modelPath)
        
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Performance Tests
    
    func testProcessingPerformance() async throws {
        let textInput = AIInput.text("Performance test input")
        
        measure {
            Task {
                do {
                    _ = try await aiEngine.process(textInput, type: .classification)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
    
    func testBatchProcessingPerformance() async throws {
        let inputs = Array(repeating: AIInput.text("Batch test input"), count: 10)
        
        measure {
            Task {
                do {
                    _ = try await aiEngine.processBatch(inputs, type: .classification)
                } catch {
                    XCTFail("Batch performance test failed: \(error)")
                }
            }
        }
    }
    
    func testMemoryUsage() async throws {
        let initialMemory = getMemoryUsage()
        
        let inputs = Array(repeating: AIInput.text("Memory test input"), count: 100)
        _ = try await aiEngine.processBatch(inputs, type: .classification)
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024) // 100MB limit
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidModelPath() async throws {
        let invalidPath = "invalid_model.mlmodel"
        
        XCTAssertThrowsError(try await aiEngine.loadModel(at: invalidPath)) { error in
            XCTAssertEqual(error as? AIEngineError, .modelNotFound)
        }
    }
    
    func testInvalidInputType() async throws {
        let invalidInput = AIInput.text("")
        
        XCTAssertThrowsError(try await aiEngine.process(invalidInput, type: .classification)) { error in
            XCTAssertEqual(error as? AIEngineError, .invalidInput)
        }
    }
    
    func testProcessingTimeout() async throws {
        let config = AIEngineConfiguration(
            modelPath: "test_model.mlmodel",
            enableGPU: false,
            enableNeuralEngine: false,
            batchSize: 1,
            timeout: 0.1 // Very short timeout
        )
        
        let timeoutEngine = AIEngine(configuration: config)
        let textInput = AIInput.text("Timeout test")
        
        XCTAssertThrowsError(try await timeoutEngine.process(textInput, type: .classification)) { error in
            XCTAssertEqual(error as? AIEngineError, .processingTimeout)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage? {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createTestAudioData() -> Data? {
        // Create a simple audio data for testing
        let sampleRate: Double = 44100
        let duration: Double = 1.0
        let frequency: Double = 440.0 // A4 note
        
        let frameCount = Int(sampleRate * duration)
        var audioData = Data()
        
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let amplitude = sin(2.0 * .pi * frequency * time)
            let sample = Int16(amplitude * 32767.0)
            audioData.append(contentsOf: withUnsafeBytes(of: sample) { Data($0) })
        }
        
        return audioData
    }
    
    private func getMemoryUsage() -> Int {
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
        
        return kerr == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
}

// MARK: - AIEngineError Extension

extension AIEngineError: Equatable {
    public static func == (lhs: AIEngineError, rhs: AIEngineError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidInput, .invalidInput),
             (.modelNotFound, .modelNotFound),
             (.processingFailed, .processingFailed),
             (.processingTimeout, .processingTimeout),
             (.invalidConfiguration, .invalidConfiguration):
            return true
        default:
            return false
        }
    }
} 