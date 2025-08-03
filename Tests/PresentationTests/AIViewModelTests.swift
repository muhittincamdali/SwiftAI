import XCTest
import Combine
@testable import SwiftAI

@MainActor
final class AIViewModelTests: XCTestCase {
    
    // MARK: - Properties
    var viewModel: AIViewModel!
    var mockCoordinator: MockAICoordinator!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        mockCoordinator = MockAICoordinator()
        viewModel = AIViewModel(coordinator: mockCoordinator)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockCoordinator = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testInitialization_DefaultValues() {
        // Then
        XCTAssertEqual(viewModel.inputText, "")
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.performanceMetrics)
        XCTAssertNil(viewModel.analytics)
        XCTAssertNil(viewModel.usageStatistics)
    }
    
    // MARK: - Text Classification Tests
    func testProcessTextClassification_Success() async {
        // Given
        viewModel.inputText = "Test input for classification"
        let expectedResults = ["positive": 0.8, "negative": 0.2]
        mockCoordinator.classificationResult = expectedResults
        
        // When
        await viewModel.processTextClassification()
        
        // Then
        XCTAssertEqual(viewModel.results, expectedResults)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.performanceMetrics)
    }
    
    func testProcessTextClassification_EmptyInput() async {
        // Given
        viewModel.inputText = ""
        
        // When
        await viewModel.processTextClassification()
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.errorMessage, "Please enter some text to classify")
    }
    
    func testProcessTextClassification_WhitespaceOnly() async {
        // Given
        viewModel.inputText = "   "
        
        // When
        await viewModel.processTextClassification()
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.errorMessage, "Please enter some text to classify")
    }
    
    func testProcessTextClassification_Error() async {
        // Given
        viewModel.inputText = "Test input"
        mockCoordinator.shouldThrowError = true
        mockCoordinator.errorMessage = "Classification failed"
        
        // When
        await viewModel.processTextClassification()
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.errorMessage, "Classification failed: Classification failed")
    }
    
    // MARK: - Sentiment Analysis Tests
    func testProcessSentimentAnalysis_Success() async {
        // Given
        viewModel.inputText = "I love this product!"
        let expectedSentiment = SentimentScore.positive(0.9)
        mockCoordinator.sentimentResult = expectedSentiment
        
        // When
        await viewModel.processSentimentAnalysis()
        
        // Then
        XCTAssertEqual(viewModel.results["positive"], 0.9)
        XCTAssertEqual(viewModel.results["negative"], 0.1)
        XCTAssertEqual(viewModel.results["neutral"], 0.0)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testProcessSentimentAnalysis_EmptyInput() async {
        // Given
        viewModel.inputText = ""
        
        // When
        await viewModel.processSentimentAnalysis()
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.errorMessage, "Please enter some text for sentiment analysis")
    }
    
    func testProcessSentimentAnalysis_Error() async {
        // Given
        viewModel.inputText = "Test input"
        mockCoordinator.shouldThrowError = true
        mockCoordinator.errorMessage = "Sentiment analysis failed"
        
        // When
        await viewModel.processSentimentAnalysis()
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.errorMessage, "Sentiment analysis failed: Sentiment analysis failed")
    }
    
    // MARK: - Entity Extraction Tests
    func testProcessEntityExtraction_Success() async {
        // Given
        viewModel.inputText = "John Smith works at Apple Inc."
        let expectedEntities = [
            NLEntity(text: "John Smith", type: "PersonName", range: "John Smith".startIndex..<"John Smith".endIndex, confidence: 0.9),
            NLEntity(text: "Apple Inc.", type: "OrganizationName", range: "Apple Inc.".startIndex..<"Apple Inc.".endIndex, confidence: 0.8)
        ]
        mockCoordinator.entitiesResult = expectedEntities
        
        // When
        await viewModel.processEntityExtraction()
        
        // Then
        XCTAssertEqual(viewModel.results["PersonName"], 0.5)
        XCTAssertEqual(viewModel.results["OrganizationName"], 0.5)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testProcessEntityExtraction_EmptyInput() async {
        // Given
        viewModel.inputText = ""
        
        // When
        await viewModel.processEntityExtraction()
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.errorMessage, "Please enter some text for entity extraction")
    }
    
    // MARK: - Translation Tests
    func testProcessTranslation_Success() async {
        // Given
        viewModel.inputText = "Hello world"
        let expectedTranslation = "Hola mundo"
        mockCoordinator.translationResult = expectedTranslation
        
        // When
        await viewModel.processTranslation(to: .spanish)
        
        // Then
        XCTAssertEqual(viewModel.results["translation"], 1.0)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testProcessTranslation_EmptyInput() async {
        // Given
        viewModel.inputText = ""
        
        // When
        await viewModel.processTranslation(to: .spanish)
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.errorMessage, "Please enter some text to translate")
    }
    
    // MARK: - Summarization Tests
    func testProcessSummarization_Success() async {
        // Given
        viewModel.inputText = "This is a long text that needs to be summarized into a shorter version."
        let expectedSummary = "Long text summarized."
        mockCoordinator.summarizationResult = expectedSummary
        
        // When
        await viewModel.processSummarization(maxLength: 50)
        
        // Then
        XCTAssertEqual(viewModel.results["summary"], 1.0)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testProcessSummarization_EmptyInput() async {
        // Given
        viewModel.inputText = ""
        
        // When
        await viewModel.processSummarization(maxLength: 50)
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.errorMessage, "Please enter some text to summarize")
    }
    
    // MARK: - Analytics Tests
    func testLoadAnalytics_Success() async {
        // Given
        let expectedAnalytics = AIAnalytics(
            totalInferences: 100,
            averageProcessingTime: 0.1,
            averageMemoryUsage: 50 * 1024 * 1024,
            successRate: 0.95,
            errorRate: 0.05,
            mostUsedModels: ["text_classifier": 50],
            mostProcessedInputTypes: [.text: 100],
            performanceTrends: [],
            lastUpdated: Date()
        )
        mockCoordinator.analyticsResult = expectedAnalytics
        
        // When
        await viewModel.loadAnalytics()
        
        // Then
        XCTAssertEqual(viewModel.analytics?.totalInferences, expectedAnalytics.totalInferences)
        XCTAssertEqual(viewModel.analytics?.successRate, expectedAnalytics.successRate)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadAnalytics_Error() async {
        // Given
        mockCoordinator.shouldThrowError = true
        mockCoordinator.errorMessage = "Analytics loading failed"
        
        // When
        await viewModel.loadAnalytics()
        
        // Then
        XCTAssertNil(viewModel.analytics)
        XCTAssertEqual(viewModel.errorMessage, "Failed to load analytics: Analytics loading failed")
    }
    
    // MARK: - Usage Statistics Tests
    func testLoadUsageStatistics_Success() async {
        // Given
        let expectedStatistics = AIUsageStatistics(
            totalUsage: 100,
            successfulUsage: 95,
            failedUsage: 5,
            averageProcessingTime: 0.1,
            averageMemoryUsage: 50 * 1024 * 1024,
            usageByModel: ["text_classifier": 50],
            usageByInputType: [.text: 100],
            usageByHour: [12: 10],
            usageByDay: ["2024-01-01": 100],
            lastUsage: Date()
        )
        mockCoordinator.usageStatisticsResult = expectedStatistics
        
        // When
        await viewModel.loadUsageStatistics()
        
        // Then
        XCTAssertEqual(viewModel.usageStatistics?.totalUsage, expectedStatistics.totalUsage)
        XCTAssertEqual(viewModel.usageStatistics?.successfulUsage, expectedStatistics.successfulUsage)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadUsageStatistics_Error() async {
        // Given
        mockCoordinator.shouldThrowError = true
        mockCoordinator.errorMessage = "Usage statistics loading failed"
        
        // When
        await viewModel.loadUsageStatistics()
        
        // Then
        XCTAssertNil(viewModel.usageStatistics)
        XCTAssertEqual(viewModel.errorMessage, "Failed to load usage statistics: Usage statistics loading failed")
    }
    
    // MARK: - Clear Methods Tests
    func testClearResults() {
        // Given
        viewModel.results = ["test": 1.0]
        viewModel.performanceMetrics = PerformanceMetrics(
            averageInferenceTime: 0.1,
            memoryUsage: 50 * 1024 * 1024,
            cacheHitRate: 0.8,
            modelLoadTime: 0.2
        )
        viewModel.errorMessage = "Test error"
        
        // When
        viewModel.clearResults()
        
        // Then
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertNil(viewModel.performanceMetrics)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testClearError() {
        // Given
        viewModel.errorMessage = "Test error"
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Combine Tests
    func testInputTextBinding_AutoClearError() async {
        // Given
        viewModel.errorMessage = "Test error"
        
        // When
        viewModel.inputText = "New input"
        
        // Wait for debounce
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Performance Tests
    func testPerformance_ProcessTextClassification() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                viewModel.inputText = "Performance test input"
                await viewModel.processTextClassification()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformance_ProcessSentimentAnalysis() {
        measure {
            let expectation = XCTestExpectation(description: "Sentiment performance test")
            
            Task {
                viewModel.inputText = "Performance test input for sentiment analysis"
                await viewModel.processSentimentAnalysis()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}

// MARK: - Mock AI Coordinator
class MockAICoordinator: AICoordinatorProtocol {
    var classificationResult: [String: Double] = [:]
    var sentimentResult: SentimentScore = .neutral(0.5)
    var entitiesResult: [NLEntity] = []
    var translationResult: String = ""
    var summarizationResult: String = ""
    var analyticsResult: AIAnalytics?
    var usageStatisticsResult: AIUsageStatistics?
    var shouldThrowError: Bool = false
    var errorMessage: String = "Mock error"
    
    func start() -> AnyView {
        return AnyView(Text("Mock View"))
    }
    
    func navigateToClassification() -> AnyView {
        return AnyView(Text("Classification"))
    }
    
    func navigateToSentimentAnalysis() -> AnyView {
        return AnyView(Text("Sentiment"))
    }
    
    func navigateToEntityExtraction() -> AnyView {
        return AnyView(Text("Entities"))
    }
    
    func navigateToTranslation() -> AnyView {
        return AnyView(Text("Translation"))
    }
    
    func navigateToSummarization() -> AnyView {
        return AnyView(Text("Summarization"))
    }
    
    func navigateToSettings() -> AnyView {
        return AnyView(Text("Settings"))
    }
    
    func navigateBack() {}
    
    func dismiss() {}
    
    func processTextClassification(_ text: String) async throws -> [String: Double] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return classificationResult
    }
    
    func processSentimentAnalysis(_ text: String) async throws -> SentimentScore {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return sentimentResult
    }
    
    func processEntityExtraction(_ text: String) async throws -> [NLEntity] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return entitiesResult
    }
    
    func processTranslation(_ text: String, to targetLanguage: NLLanguage) async throws -> String {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return translationResult
    }
    
    func processSummarization(_ text: String, maxLength: Int) async throws -> String {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return summarizationResult
    }
    
    func getAnalytics() async throws -> AIAnalytics {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return analyticsResult ?? AIAnalytics(
            totalInferences: 0,
            averageProcessingTime: 0,
            averageMemoryUsage: 0,
            successRate: 0,
            errorRate: 0,
            mostUsedModels: [:],
            mostProcessedInputTypes: [:],
            performanceTrends: [],
            lastUpdated: Date()
        )
    }
    
    func getUsageStatistics() async throws -> AIUsageStatistics {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return usageStatisticsResult ?? AIUsageStatistics(
            totalUsage: 0,
            successfulUsage: 0,
            failedUsage: 0,
            averageProcessingTime: 0,
            averageMemoryUsage: 0,
            usageByModel: [:],
            usageByInputType: [:],
            usageByHour: [:],
            usageByDay: [:],
            lastUsage: nil
        )
    }
    
    func optimizePerformance() async throws {}
    
    func clearCache() async throws {}
}
