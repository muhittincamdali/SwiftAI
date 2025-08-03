import SwiftUI
import Foundation
import Combine

// MARK: - AI ViewModel Protocol
public protocol AIViewModelProtocol: ObservableObject {
    var inputText: String { get set }
    var results: [String: Double] { get }
    var isProcessing: Bool { get }
    var errorMessage: String? { get }
    var performanceMetrics: PerformanceMetrics? { get }
    var analytics: AIAnalytics? { get }
    var usageStatistics: AIUsageStatistics? { get }
    
    func processTextClassification() async
    func processSentimentAnalysis() async
    func processEntityExtraction() async
    func processTranslation(to targetLanguage: NLLanguage) async
    func processSummarization(maxLength: Int) async
    func loadAnalytics() async
    func loadUsageStatistics() async
    func clearResults()
    func clearError()
}

// MARK: - AI ViewModel Implementation
@MainActor
public class AIViewModel: AIViewModelProtocol {
    
    // MARK: - Published Properties
    @Published public var inputText: String = ""
    @Published public var results: [String: Double] = [:]
    @Published public var isProcessing: Bool = false
    @Published public var errorMessage: String?
    @Published public var performanceMetrics: PerformanceMetrics?
    @Published public var analytics: AIAnalytics?
    @Published public var usageStatistics: AIUsageStatistics?
    
    // MARK: - Private Properties
    private let coordinator: AICoordinatorProtocol
    private let performanceOptimizer: PerformanceOptimizerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init(coordinator: AICoordinatorProtocol = AICoordinator()) {
        self.coordinator = coordinator
        self.performanceOptimizer = PerformanceOptimizer()
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    public func processTextClassification() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter some text to classify"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        results = [:]
        
        do {
            let startTime = Date()
            
            let classification = try await coordinator.processTextClassification(inputText)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                self.results = classification
                self.isProcessing = false
                self.performanceMetrics = PerformanceMetrics(
                    averageInferenceTime: processingTime,
                    memoryUsage: 50 * 1024 * 1024,
                    cacheHitRate: 0.8,
                    modelLoadTime: 0.2
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Classification failed: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    public func processSentimentAnalysis() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter some text for sentiment analysis"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        results = [:]
        
        do {
            let startTime = Date()
            
            let sentiment = try await coordinator.processSentimentAnalysis(inputText)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                self.results = convertSentimentToResults(sentiment)
                self.isProcessing = false
                self.performanceMetrics = PerformanceMetrics(
                    averageInferenceTime: processingTime,
                    memoryUsage: 60 * 1024 * 1024,
                    cacheHitRate: 0.8,
                    modelLoadTime: 0.2
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Sentiment analysis failed: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    public func processEntityExtraction() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter some text for entity extraction"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        results = [:]
        
        do {
            let startTime = Date()
            
            let entities = try await coordinator.processEntityExtraction(inputText)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                self.results = convertEntitiesToResults(entities)
                self.isProcessing = false
                self.performanceMetrics = PerformanceMetrics(
                    averageInferenceTime: processingTime,
                    memoryUsage: 70 * 1024 * 1024,
                    cacheHitRate: 0.8,
                    modelLoadTime: 0.2
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Entity extraction failed: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    public func processTranslation(to targetLanguage: NLLanguage) async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter some text to translate"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        results = [:]
        
        do {
            let startTime = Date()
            
            let translation = try await coordinator.processTranslation(inputText, to: targetLanguage)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                self.results = ["translation": 1.0, "text": translation.hashValue]
                self.isProcessing = false
                self.performanceMetrics = PerformanceMetrics(
                    averageInferenceTime: processingTime,
                    memoryUsage: 80 * 1024 * 1024,
                    cacheHitRate: 0.8,
                    modelLoadTime: 0.2
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Translation failed: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    public func processSummarization(maxLength: Int) async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter some text to summarize"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        results = [:]
        
        do {
            let startTime = Date()
            
            let summary = try await coordinator.processSummarization(inputText, maxLength: maxLength)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                self.results = ["summary": 1.0, "text": summary.hashValue]
                self.isProcessing = false
                self.performanceMetrics = PerformanceMetrics(
                    averageInferenceTime: processingTime,
                    memoryUsage: 90 * 1024 * 1024,
                    cacheHitRate: 0.8,
                    modelLoadTime: 0.2
                )
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Summarization failed: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    public func loadAnalytics() async {
        do {
            let analytics = try await coordinator.getAnalytics()
            await MainActor.run {
                self.analytics = analytics
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load analytics: \(error.localizedDescription)"
            }
        }
    }
    
    public func loadUsageStatistics() async {
        do {
            let statistics = try await coordinator.getUsageStatistics()
            await MainActor.run {
                self.usageStatistics = statistics
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load usage statistics: \(error.localizedDescription)"
            }
        }
    }
    
    public func clearResults() {
        results = [:]
        performanceMetrics = nil
        errorMessage = nil
    }
    
    public func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Auto-clear error when input changes
        $inputText
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.clearError()
            }
            .store(in: &cancellables)
    }
    
    private func convertSentimentToResults(_ sentiment: SentimentScore) -> [String: Double] {
        switch sentiment {
        case .positive(let value):
            return ["positive": value, "negative": 1.0 - value, "neutral": 0.0]
        case .negative(let value):
            return ["positive": 1.0 - value, "negative": value, "neutral": 0.0]
        case .neutral(let value):
            return ["positive": 0.0, "negative": 0.0, "neutral": value]
        }
    }
    
    private func convertEntitiesToResults(_ entities: [NLEntity]) -> [String: Double] {
        var entityCounts: [String: Int] = [:]
        
        for entity in entities {
            entityCounts[entity.type, default: 0] += 1
        }
        
        let total = Double(entities.count)
        return entityCounts.mapValues { Double($0) / total }
    }
}

// MARK: - Performance Metrics
public struct PerformanceMetrics {
    public let averageInferenceTime: TimeInterval
    public let memoryUsage: Int64
    public let cacheHitRate: Double
    public let modelLoadTime: TimeInterval
    
    public init(
        averageInferenceTime: TimeInterval,
        memoryUsage: Int64,
        cacheHitRate: Double,
        modelLoadTime: TimeInterval
    ) {
        self.averageInferenceTime = averageInferenceTime
        self.memoryUsage = memoryUsage
        self.cacheHitRate = cacheHitRate
        self.modelLoadTime = modelLoadTime
    }
}

// MARK: - Sentiment Score
public enum SentimentScore {
    case positive(Double)
    case negative(Double)
    case neutral(Double)
}

// MARK: - NLLanguage Extension
public extension NLLanguage {
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .spanish:
            return "Spanish"
        case .french:
            return "French"
        case .german:
            return "German"
        case .italian:
            return "Italian"
        case .portuguese:
            return "Portuguese"
        case .russian:
            return "Russian"
        case .japanese:
            return "Japanese"
        case .korean:
            return "Korean"
        case .chinese:
            return "Chinese"
        default:
            return rawValue
        }
    }
}
