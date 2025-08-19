//
//  TrainingDataTests.swift
//  SwiftAITests
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import XCTest
import Combine
@testable import SwiftAI

/// Comprehensive test suite for TrainingData with enterprise-grade coverage
final class TrainingDataTests: XCTestCase {
    
    // MARK: - Properties
    
    private var trainingData: TrainingData!
    private var cancellables: Set<AnyCancellable>!
    private var mockProcessor: MockDataProcessor!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockProcessor = MockDataProcessor()
        trainingData = createTestTrainingData()
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        trainingData = nil
        mockProcessor = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrainingData() -> TrainingData {
        let samples = Array(0..<1000).map { "Sample text \($0) for training purposes" }
        let labels = Array(0..<1000).map { "Label_\($0 % 10)" } // 10 different labels
        
        return TrainingData(
            name: "Test Training Dataset",
            dataType: .text,
            samples: samples,
            labels: labels
        )
    }
    
    private func createImageTrainingData() -> TrainingData {
        let samples = Array(0..<100).map { _ in Data(count: 1024) } // Mock image data
        let labels = Array(0..<100).map { "ImageClass_\($0 % 5)" } // 5 different classes
        
        return TrainingData(
            name: "Image Training Dataset",
            dataType: .image,
            samples: samples,
            labels: labels
        )
    }
    
    // MARK: - Initialization Tests
    
    func testTrainingDataInitialization() throws {
        // Given & When
        let data = createTestTrainingData()
        
        // Then
        XCTAssertEqual(data.name, "Test Training Dataset")
        XCTAssertEqual(data.dataType, .text)
        XCTAssertEqual(data.sampleCount, 1000)
        XCTAssertEqual(data.samples.count, 1000)
        XCTAssertEqual(data.labels.count, 1000)
        XCTAssertNotNil(data.id)
        XCTAssertNotNil(data.createdAt)
        XCTAssertTrue(data.qualityScore > 0)
    }
    
    func testEmptyTrainingDataInitialization() throws {
        // Given & When
        let emptyData = TrainingData(
            name: "Empty Dataset",
            dataType: .text,
            samples: [],
            labels: []
        )
        
        // Then
        XCTAssertEqual(emptyData.sampleCount, 0)
        XCTAssertTrue(emptyData.samples.isEmpty)
        XCTAssertTrue(emptyData.labels.isEmpty)
        XCTAssertEqual(emptyData.qualityScore, 0.0)
    }
    
    // MARK: - Data Validation Tests
    
    func testValidDatasetValidation() throws {
        // Given
        let validData = createTestTrainingData()
        
        // When
        let result = validData.validateDataset()
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.issues.isEmpty)
        XCTAssertEqual(result.severity, .none)
    }
    
    func testEmptyDatasetValidation() throws {
        // Given
        let emptyData = TrainingData(
            name: "Empty",
            dataType: .text,
            samples: [],
            labels: []
        )
        
        // When
        let result = emptyData.validateDataset()
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.issues.isEmpty)
        XCTAssertEqual(result.severity, .critical)
        XCTAssertTrue(result.issues.contains { $0.contains("empty") })
    }
    
    func testMismatchedSampleLabelValidation() throws {
        // Given
        let mismatchedData = TrainingData(
            name: "Mismatched",
            dataType: .text,
            samples: Array(0..<100).map { "Sample \($0)" },
            labels: Array(0..<50).map { "Label \($0)" } // Mismatched count
        )
        
        // When
        let result = mismatchedData.validateDataset()
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.severity, .critical)
        XCTAssertTrue(result.issues.contains { $0.contains("mismatch") || $0.contains("count") })
    }
    
    func testDuplicateSamplesValidation() throws {
        // Given
        let duplicateData = TrainingData(
            name: "Duplicates",
            dataType: .text,
            samples: Array(repeating: "Duplicate sample", count: 100),
            labels: Array(0..<100).map { "Label \($0)" }
        )
        
        // When
        let result = duplicateData.validateDataset()
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.severity, .warning)
        XCTAssertTrue(result.issues.contains { $0.contains("duplicate") })
    }
    
    // MARK: - Data Preprocessing Tests
    
    func testTextDataPreprocessing() throws {
        // Given
        let textData = TrainingData(
            name: "Text Data",
            dataType: .text,
            samples: [
                "  Hello World!  ",
                "UPPERCASE TEXT",
                "mixed CaSe TeXt",
                "text with numbers 123"
            ],
            labels: ["greeting", "emphasis", "mixed", "alphanumeric"]
        )
        
        // When
        let preprocessedData = textData.preprocessData()
        
        // Then
        XCTAssertEqual(preprocessedData.samples.count, 4)
        
        // Check preprocessing results
        let processedSamples = preprocessedData.samples as! [String]
        XCTAssertEqual(processedSamples[0], "hello world") // Trimmed and lowercased
        XCTAssertEqual(processedSamples[1], "uppercase text") // Lowercased
        XCTAssertEqual(processedSamples[2], "mixed case text") // Lowercased
        XCTAssertEqual(processedSamples[3], "text with numbers") // Numbers removed
    }
    
    func testImageDataPreprocessing() throws {
        // Given
        let imageData = createImageTrainingData()
        
        // When
        let preprocessedData = imageData.preprocessData()
        
        // Then
        XCTAssertEqual(preprocessedData.samples.count, imageData.samples.count)
        XCTAssertEqual(preprocessedData.labels.count, imageData.labels.count)
        
        // Verify image data is normalized
        let processedSamples = preprocessedData.samples as! [Data]
        for sample in processedSamples {
            XCTAssertFalse(sample.isEmpty)
        }
    }
    
    // MARK: - Data Shuffling Tests
    
    func testDataShuffling() throws {
        // Given
        let originalSamples = trainingData.samples as! [String]
        let originalLabels = trainingData.labels
        
        // When
        let shuffledData = trainingData.shuffleData()
        let shuffledSamples = shuffledData.samples as! [String]
        let shuffledLabels = shuffledData.labels
        
        // Then
        XCTAssertEqual(shuffledSamples.count, originalSamples.count)
        XCTAssertEqual(shuffledLabels.count, originalLabels.count)
        
        // Verify data is shuffled (with high probability)
        let isShuffled = shuffledSamples != originalSamples
        XCTAssertTrue(isShuffled)
        
        // Verify sample-label pairs are maintained
        for i in 0..<shuffledSamples.count {
            let shuffledSample = shuffledSamples[i]
            let shuffledLabel = shuffledLabels[i]
            
            if let originalIndex = originalSamples.firstIndex(of: shuffledSample) {
                XCTAssertEqual(shuffledLabel, originalLabels[originalIndex])
            }
        }
    }
    
    // MARK: - Data Splitting Tests
    
    func testTrainTestSplit() throws {
        // Given
        let splitRatio: Double = 0.8
        
        // When
        let (trainData, testData) = trainingData.trainTestSplit(ratio: splitRatio)
        
        // Then
        let expectedTrainSize = Int(Double(trainingData.sampleCount) * splitRatio)
        let expectedTestSize = trainingData.sampleCount - expectedTrainSize
        
        XCTAssertEqual(trainData.sampleCount, expectedTrainSize)
        XCTAssertEqual(testData.sampleCount, expectedTestSize)
        XCTAssertEqual(trainData.sampleCount + testData.sampleCount, trainingData.sampleCount)
        
        // Verify no overlap
        let trainSamples = trainData.samples as! [String]
        let testSamples = testData.samples as! [String]
        let intersection = Set(trainSamples).intersection(Set(testSamples))
        XCTAssertTrue(intersection.isEmpty)
    }
    
    func testTrainValidationTestSplit() throws {
        // Given
        let trainRatio: Double = 0.7
        let validationRatio: Double = 0.2
        let testRatio: Double = 0.1
        
        // When
        let (trainData, validationData, testData) = trainingData.trainValidationTestSplit(
            trainRatio: trainRatio,
            validationRatio: validationRatio,
            testRatio: testRatio
        )
        
        // Then
        let totalSamples = trainingData.sampleCount
        let expectedTrainSize = Int(Double(totalSamples) * trainRatio)
        let expectedValidationSize = Int(Double(totalSamples) * validationRatio)
        let expectedTestSize = totalSamples - expectedTrainSize - expectedValidationSize
        
        XCTAssertEqual(trainData.sampleCount, expectedTrainSize)
        XCTAssertEqual(validationData.sampleCount, expectedValidationSize)
        XCTAssertEqual(testData.sampleCount, expectedTestSize)
        
        // Verify total count matches
        XCTAssertEqual(
            trainData.sampleCount + validationData.sampleCount + testData.sampleCount,
            totalSamples
        )
    }
    
    func testInvalidSplitRatio() throws {
        // Given
        let invalidRatio: Double = 1.5 // Invalid ratio > 1.0
        
        // When & Then
        XCTAssertThrowsError(try {
            _ = trainingData.trainTestSplit(ratio: invalidRatio)
        }())
    }
    
    // MARK: - Batch Processing Tests
    
    func testBatchGeneration() throws {
        // Given
        let batchSize = 32
        
        // When
        let batches = trainingData.generateBatches(size: batchSize)
        
        // Then
        let expectedBatchCount = (trainingData.sampleCount + batchSize - 1) / batchSize
        XCTAssertEqual(batches.count, expectedBatchCount)
        
        // Verify batch sizes
        for i in 0..<batches.count - 1 {
            XCTAssertEqual(batches[i].sampleCount, batchSize)
        }
        
        // Last batch might be smaller
        let lastBatch = batches.last!
        XCTAssertTrue(lastBatch.sampleCount <= batchSize)
        XCTAssertTrue(lastBatch.sampleCount > 0)
        
        // Verify total sample count
        let totalSamplesInBatches = batches.reduce(0) { $0 + $1.sampleCount }
        XCTAssertEqual(totalSamplesInBatches, trainingData.sampleCount)
    }
    
    func testAsyncBatchProcessing() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Async batch processing")
        let batchSize = 50
        
        // When
        let batches = trainingData.generateBatches(size: batchSize)
        var processedBatches = 0
        
        await withTaskGroup(of: Void.self) { group in
            for batch in batches {
                group.addTask {
                    // Simulate async processing
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    processedBatches += 1
                }
            }
        }
        
        expectation.fulfill()
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(processedBatches, batches.count)
    }
    
    // MARK: - Data Quality Assessment Tests
    
    func testQualityScoreCalculation() throws {
        // Given
        let highQualityData = TrainingData(
            name: "High Quality",
            dataType: .text,
            samples: Array(0..<1000).map { "High quality sample \($0) with sufficient length and diversity" },
            labels: Array(0..<1000).map { "Category_\($0 % 10)" }
        )
        
        let lowQualityData = TrainingData(
            name: "Low Quality",
            dataType: .text,
            samples: Array(0..<10).map { "short" }, // Very short samples
            labels: Array(0..<10).map { "same" } // All same label
        )
        
        // When
        let highQualityScore = highQualityData.qualityScore
        let lowQualityScore = lowQualityData.qualityScore
        
        // Then
        XCTAssertTrue(highQualityScore > lowQualityScore)
        XCTAssertTrue(highQualityScore >= 7.0) // Should be high quality
        XCTAssertTrue(lowQualityScore <= 5.0) // Should be low quality
    }
    
    func testDataStatistics() throws {
        // Given
        let data = createTestTrainingData()
        
        // When
        let stats = data.getStatistics()
        
        // Then
        XCTAssertEqual(stats.totalSamples, 1000)
        XCTAssertEqual(stats.uniqueLabels, 10)
        XCTAssertEqual(stats.dataType, "text")
        XCTAssertTrue(stats.averageSampleLength > 0)
        XCTAssertFalse(stats.labelDistribution.isEmpty)
        XCTAssertEqual(stats.labelDistribution.values.reduce(0, +), 1000)
    }
    
    // MARK: - Data Serialization Tests
    
    func testTrainingDataSerialization() throws {
        // Given
        let originalData = createTestTrainingData()
        
        // When
        let encodedData = try JSONEncoder().encode(originalData)
        let decodedData = try JSONDecoder().decode(TrainingData.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalData.id, decodedData.id)
        XCTAssertEqual(originalData.name, decodedData.name)
        XCTAssertEqual(originalData.dataType, decodedData.dataType)
        XCTAssertEqual(originalData.sampleCount, decodedData.sampleCount)
        XCTAssertEqual(originalData.qualityScore, decodedData.qualityScore, accuracy: 0.01)
    }
    
    // MARK: - Data Augmentation Tests
    
    func testTextDataAugmentation() throws {
        // Given
        let originalData = TrainingData(
            name: "Original",
            dataType: .text,
            samples: ["Hello world", "Good morning", "How are you"],
            labels: ["greeting", "greeting", "question"]
        )
        
        // When
        let augmentedData = originalData.augmentData(factor: 2.0)
        
        // Then
        XCTAssertTrue(augmentedData.sampleCount > originalData.sampleCount)
        XCTAssertEqual(augmentedData.dataType, originalData.dataType)
        
        // Verify augmented samples maintain original labels
        let augmentedSamples = augmentedData.samples as! [String]
        let augmentedLabels = augmentedData.labels
        
        XCTAssertEqual(augmentedSamples.count, augmentedLabels.count)
    }
    
    // MARK: - Performance Tests
    
    func testLargeDatasetPerformance() throws {
        // Given
        let largeDataSize = 10_000
        let largeSamples = Array(0..<largeDataSize).map { "Sample \($0)" }
        let largeLabels = Array(0..<largeDataSize).map { "Label_\($0 % 100)" }
        
        let largeData = TrainingData(
            name: "Large Dataset",
            dataType: .text,
            samples: largeSamples,
            labels: largeLabels
        )
        
        // When & Then
        measure {
            _ = largeData.validateDataset()
            _ = largeData.shuffleData()
            _ = largeData.generateBatches(size: 128)
        }
    }
    
    func testPreprocessingPerformance() throws {
        // Given
        let data = createTestTrainingData()
        
        // When & Then
        measure {
            _ = data.preprocessData()
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryUsage() throws {
        // Given
        weak var weakData: TrainingData?
        
        // When
        autoreleasepool {
            let data = createTestTrainingData()
            weakData = data
            
            // Perform operations
            _ = data.validateDataset()
            _ = data.shuffleData()
            _ = data.generateBatches(size: 32)
        }
        
        // Then
        XCTAssertNil(weakData, "TrainingData should be deallocated")
    }
    
    // MARK: - Edge Cases Tests
    
    func testSingleSampleData() throws {
        // Given
        let singleSampleData = TrainingData(
            name: "Single Sample",
            dataType: .text,
            samples: ["Only one sample"],
            labels: ["single"]
        )
        
        // When
        let batches = singleSampleData.generateBatches(size: 10)
        let (train, test) = singleSampleData.trainTestSplit(ratio: 0.8)
        
        // Then
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches[0].sampleCount, 1)
        XCTAssertEqual(train.sampleCount, 1)
        XCTAssertEqual(test.sampleCount, 0)
    }
    
    func testExtremelyLargeLabels() throws {
        // Given
        let largeLabelData = TrainingData(
            name: "Large Labels",
            dataType: .text,
            samples: ["sample"],
            labels: [String(repeating: "x", count: 10_000)] // Very large label
        )
        
        // When
        let result = largeLabelData.validateDataset()
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.contains("label") && $0.contains("large") })
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        let data = createTestTrainingData()
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                // Perform concurrent operations
                _ = data.validateDataset()
                _ = data.getStatistics()
                
                // Verify data integrity
                XCTAssertEqual(data.sampleCount, 1000)
                XCTAssertEqual(data.name, "Test Training Dataset")
                
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Mock Objects

class MockDataProcessor {
    func processTextSamples(_ samples: [String]) -> [String] {
        return samples.map { sample in
            return sample
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: "\\d+", with: "", options: .regularExpression)
        }
    }
    
    func processImageSamples(_ samples: [Data]) -> [Data] {
        return samples.map { data in
            // Mock image normalization
            return data
        }
    }
}

// MARK: - Test Extensions

extension TrainingData {
    func trainTestSplit(ratio: Double) throws -> (TrainingData, TrainingData) {
        guard ratio > 0 && ratio < 1 else {
            throw TrainingDataError.invalidSplitRatio
        }
        
        let trainSize = Int(Double(sampleCount) * ratio)
        let trainSamples = Array(samples[0..<trainSize])
        let trainLabels = Array(labels[0..<trainSize])
        let testSamples = Array(samples[trainSize...])
        let testLabels = Array(labels[trainSize...])
        
        let trainData = TrainingData(
            name: "\(name) - Train",
            dataType: dataType,
            samples: trainSamples,
            labels: trainLabels
        )
        
        let testData = TrainingData(
            name: "\(name) - Test",
            dataType: dataType,
            samples: testSamples,
            labels: testLabels
        )
        
        return (trainData, testData)
    }
    
    func trainValidationTestSplit(
        trainRatio: Double,
        validationRatio: Double,
        testRatio: Double
    ) -> (TrainingData, TrainingData, TrainingData) {
        let trainSize = Int(Double(sampleCount) * trainRatio)
        let validationSize = Int(Double(sampleCount) * validationRatio)
        
        let trainSamples = Array(samples[0..<trainSize])
        let trainLabels = Array(labels[0..<trainSize])
        
        let validationSamples = Array(samples[trainSize..<(trainSize + validationSize)])
        let validationLabels = Array(labels[trainSize..<(trainSize + validationSize)])
        
        let testSamples = Array(samples[(trainSize + validationSize)...])
        let testLabels = Array(labels[(trainSize + validationSize)...])
        
        let trainData = TrainingData(name: "\(name) - Train", dataType: dataType, samples: trainSamples, labels: trainLabels)
        let validationData = TrainingData(name: "\(name) - Validation", dataType: dataType, samples: validationSamples, labels: validationLabels)
        let testData = TrainingData(name: "\(name) - Test", dataType: dataType, samples: testSamples, labels: testLabels)
        
        return (trainData, validationData, testData)
    }
}

enum TrainingDataError: Error {
    case invalidSplitRatio
}