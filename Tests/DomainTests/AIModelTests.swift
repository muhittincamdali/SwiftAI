import XCTest
@testable import SwiftAI

final class AIModelTests: XCTestCase {
    // MARK: - Model Initialization
    func testAIModelInitialization() {
        let metadata = ModelMetadata(
            description: "Test model",
            author: "SwiftAI",
            license: "MIT",
            framework: "Core ML",
            trainingData: "Test dataset"
        )
        let configuration = ModelConfiguration()
        let performance = ModelPerformance(
            averageInferenceTime: 0.1,
            averageMemoryUsage: 50 * 1024 * 1024,
            peakMemoryUsage: 100 * 1024 * 1024,
            cacheHitRate: 0.8,
            modelLoadTime: 0.2,
            throughput: 10.0,
            latency: 0.1,
            accuracy: 0.85,
            precision: 0.83,
            recall: 0.87,
            f1Score: 0.85
        )
        let model = AIModel(
            name: "test_model",
            version: "1.0.0",
            type: .classification,
            inputType: .text,
            outputType: .classification,
            size: 50 * 1024 * 1024,
            accuracy: 0.85,
            metadata: metadata,
            configuration: configuration,
            performance: performance
        )
        XCTAssertEqual(model.name, "test_model")
        XCTAssertEqual(model.version, "1.0.0")
        XCTAssertEqual(model.type, .classification)
        XCTAssertEqual(model.inputType, .text)
        XCTAssertEqual(model.outputType, .classification)
        XCTAssertEqual(model.size, 50 * 1024 * 1024)
        XCTAssertEqual(model.accuracy, 0.85)
        XCTAssertEqual(model.metadata.author, "SwiftAI")
        XCTAssertEqual(model.performance.f1Score, 0.85)
    }
    // MARK: - Model Equality
    func testAIModelEquality() {
        let model1 = AIModel(
            name: "model",
            version: "1.0.0",
            type: .classification,
            inputType: .text,
            outputType: .classification,
            size: 100,
            accuracy: 0.9,
            metadata: ModelMetadata(description: "desc", author: "author", license: "MIT", framework: "Core ML", trainingData: "data"),
            configuration: ModelConfiguration(),
            performance: ModelPerformance(averageInferenceTime: 0.1, averageMemoryUsage: 1, peakMemoryUsage: 2, cacheHitRate: 0.5, modelLoadTime: 0.1, throughput: 1, latency: 0.1, accuracy: 0.9, precision: 0.9, recall: 0.9, f1Score: 0.9)
        )
        let model2 = model1
        XCTAssertEqual(model1, model2)
    }
    // MARK: - Model Performance
    func testModelPerformanceMetrics() {
        let performance = ModelPerformance(
            averageInferenceTime: 0.2,
            averageMemoryUsage: 60 * 1024 * 1024,
            peakMemoryUsage: 120 * 1024 * 1024,
            cacheHitRate: 0.9,
            modelLoadTime: 0.3,
            throughput: 12.0,
            latency: 0.12,
            accuracy: 0.88,
            precision: 0.85,
            recall: 0.9,
            f1Score: 0.87
        )
        XCTAssertEqual(performance.averageInferenceTime, 0.2)
        XCTAssertEqual(performance.cacheHitRate, 0.9)
        XCTAssertEqual(performance.f1Score, 0.87)
    }
    // MARK: - Model Metadata
    func testModelMetadata() {
        let metadata = ModelMetadata(
            description: "A test model",
            author: "Tester",
            license: "MIT",
            framework: "Core ML",
            trainingData: "Test data"
        )
        XCTAssertEqual(metadata.license, "MIT")
        XCTAssertEqual(metadata.framework, "Core ML")
    }
    // MARK: - Model Configuration
    func testModelConfigurationDefaults() {
        let config = ModelConfiguration()
        XCTAssertNotNil(config)
    }
}
