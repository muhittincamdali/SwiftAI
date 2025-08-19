// SwiftAI Base ViewModel - MVVM-C Architecture
// Copyright © 2024 SwiftAI. All rights reserved.
// Enterprise-Grade Base ViewModel with Combine Integration

import Foundation
import SwiftUI
import Combine

/// Base ViewModel class for all ViewModels in the application
/// Provides common functionality and state management
@MainActor
open class BaseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isLoading: Bool = false
    @Published public var error: Error?
    @Published public var showError: Bool = false
    @Published public var alertMessage: String = ""
    @Published public var navigationPath = NavigationPath()
    
    // MARK: - Properties
    
    public var cancellables = Set<AnyCancellable>()
    public let dependencyContainer: DependencyContainer
    
    // MARK: - Services
    
    public lazy var analyticsService: AnalyticsServiceProtocol = {
        dependencyContainer.resolve(AnalyticsServiceProtocol.self)
    }()
    
    public lazy var performanceMonitor: PerformanceMonitorProtocol = {
        dependencyContainer.resolve(PerformanceMonitorProtocol.self)
    }()
    
    // MARK: - Initialization
    
    public init(dependencyContainer: DependencyContainer = .shared) {
        self.dependencyContainer = dependencyContainer
        setupBindings()
        initialize()
    }
    
    // MARK: - Lifecycle
    
    open func initialize() {
        // Override in subclasses for initialization
    }
    
    open func setupBindings() {
        // Override in subclasses for bindings
    }
    
    open func onAppear() {
        // Override in subclasses for view appear logic
    }
    
    open func onDisappear() {
        // Override in subclasses for view disappear logic
    }
    
    // MARK: - Error Handling
    
    public func handleError(_ error: Error) {
        self.error = error
        self.showError = true
        self.alertMessage = error.localizedDescription
        
        // Track error
        analyticsService.trackError(error, context: nil)
    }
    
    public func clearError() {
        self.error = nil
        self.showError = false
        self.alertMessage = ""
    }
    
    // MARK: - Loading State
    
    public func startLoading(operation: String? = nil) {
        isLoading = true
        
        if let operation = operation {
            performanceMonitor.startTracking(operation: operation)
        }
    }
    
    public func stopLoading(operation: String? = nil) {
        isLoading = false
        
        if let operation = operation {
            performanceMonitor.stopTracking(operation: operation)
        }
    }
    
    // MARK: - Navigation
    
    public func navigate(to destination: any Hashable) {
        navigationPath.append(destination)
    }
    
    public func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    public func navigateToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}

// MARK: - ViewModels

public class HomeViewModel: BaseViewModel {
    @Published public var models: [AIModelEntity] = []
    @Published public var recentActivity: [ActivityItem] = []
    @Published public var statistics: DashboardStatistics?
    
    private var modelRepository: AIModelRepositoryProtocol?
    
    public override func initialize() {
        super.initialize()
        modelRepository = dependencyContainer.resolve(AIModelRepositoryProtocol.self)
        loadDashboard()
    }
    
    public func loadDashboard() {
        startLoading(operation: "load_dashboard")
        
        modelRepository?.loadAllModels()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.stopLoading(operation: "load_dashboard")
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] models in
                    self?.models = models
                    self?.updateStatistics()
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateStatistics() {
        statistics = DashboardStatistics(
            totalModels: models.count,
            activeInferences: 0,
            averageAccuracy: models.map { $0.performance.accuracy }.reduce(0, +) / Double(max(1, models.count)),
            totalProcessed: 0
        )
    }
}

public class ModelsViewModel: BaseViewModel {
    @Published public var models: [AIModelEntity] = []
    @Published public var selectedModel: AIModelEntity?
    @Published public var searchText: String = ""
    @Published public var filterType: AIModelEntity.ModelType?
    
    private var modelRepository: AIModelRepositoryProtocol?
    
    public override func initialize() {
        super.initialize()
        modelRepository = dependencyContainer.resolve(AIModelRepositoryProtocol.self)
        loadModels()
        setupSearch()
    }
    
    public func loadModels() {
        startLoading(operation: "load_models")
        
        modelRepository?.loadAllModels()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.stopLoading(operation: "load_models")
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] models in
                    self?.models = models
                }
            )
            .store(in: &cancellables)
    }
    
    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterModels(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func filterModels(searchText: String) {
        // Filter implementation
    }
    
    public func selectModel(_ model: AIModelEntity) {
        selectedModel = model
        navigate(to: ModelDetailDestination(modelId: model.id))
    }
    
    public func deleteModel(_ model: AIModelEntity) {
        modelRepository?.deleteModel(id: model.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.models.removeAll { $0.id == model.id }
                }
            )
            .store(in: &cancellables)
    }
}

public class TrainingViewModel: BaseViewModel {
    @Published public var trainingSessions: [TrainingSession] = []
    @Published public var currentSession: TrainingSession?
    @Published public var trainingProgress: TrainingProgress?
    @Published public var datasets: [TrainingDataset] = []
    
    public func startTraining(configuration: TrainingConfiguration) {
        // Training implementation
    }
    
    public func stopTraining() {
        // Stop training
    }
    
    public func loadDatasets() {
        // Load datasets
    }
}

public class InsightsViewModel: BaseViewModel {
    @Published public var performanceMetrics: [PerformanceMetric] = []
    @Published public var analyticsData: AnalyticsSummary?
    @Published public var selectedTimeRange: TimeRange = .week
    
    public enum TimeRange {
        case day, week, month, year
    }
    
    public override func initialize() {
        super.initialize()
        loadInsights()
    }
    
    public func loadInsights() {
        startLoading(operation: "load_insights")
        
        let timeRange = getTimeRange(for: selectedTimeRange)
        
        analyticsService.getAnalyticsSummary(timeRange: timeRange)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.stopLoading(operation: "load_insights")
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] summary in
                    self?.analyticsData = summary
                }
            )
            .store(in: &cancellables)
    }
    
    private func getTimeRange(for range: TimeRange) -> SwiftAI.TimeRange {
        let endDate = Date()
        let startDate: Date
        
        switch range {
        case .day:
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
        case .week:
            startDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: endDate)!
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
        case .year:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        }
        
        return SwiftAI.TimeRange(start: startDate, end: endDate)
    }
}

public class SettingsViewModel: BaseViewModel {
    @Published public var userPreferences: UserPreferences = UserPreferences()
    @Published public var appVersion: String = ""
    @Published public var cacheSize: String = ""
    @Published public var isNotificationsEnabled: Bool = true
    @Published public var selectedTheme: AppTheme = .system
    
    public enum AppTheme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }
    
    public override func initialize() {
        super.initialize()
        loadSettings()
    }
    
    public func loadSettings() {
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        updateCacheSize()
    }
    
    public func clearCache() {
        let cacheManager = dependencyContainer.resolve(CacheManagerProtocol.self)
        cacheManager.clearCache()
        updateCacheSize()
    }
    
    private func updateCacheSize() {
        let cacheManager = dependencyContainer.resolve(CacheManagerProtocol.self)
        let sizeInBytes = cacheManager.getCacheSize()
        cacheSize = ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }
    
    public func logout() {
        let authService = dependencyContainer.resolve(AuthenticationService.self)
        authService.isAuthenticated = false
    }
}

public class OnboardingViewModel: BaseViewModel {
    @Published public var currentPage: Int = 0
    @Published public var isLastPage: Bool = false
    
    public weak var delegate: OnboardingViewModelDelegate?
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to SwiftAI",
            description: "Enterprise-grade AI framework for iOS",
            imageName: "brain"
        ),
        OnboardingPage(
            title: "Powerful Models",
            description: "Access state-of-the-art AI models",
            imageName: "cube"
        ),
        OnboardingPage(
            title: "Easy Integration",
            description: "Seamlessly integrate AI into your apps",
            imageName: "link"
        )
    ]
    
    public var currentPageData: OnboardingPage {
        pages[currentPage]
    }
    
    public func nextPage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            isLastPage = currentPage == pages.count - 1
        }
    }
    
    public func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
            isLastPage = false
        }
    }
    
    public func completeOnboarding() {
        let authService = dependencyContainer.resolve(AuthenticationService.self)
        authService.isAuthenticated = true
        delegate?.onboardingViewModelDidComplete(self)
    }
}

public protocol OnboardingViewModelDelegate: AnyObject {
    func onboardingViewModelDidComplete(_ viewModel: OnboardingViewModel)
}

public class MainViewModel: BaseViewModel {
    @Published public var selectedTab: Int = 0
    @Published public var showSideMenu: Bool = false
    
    public func toggleSideMenu() {
        showSideMenu.toggle()
    }
}

// MARK: - Supporting Types

public struct ActivityItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let timestamp: Date
    public let type: ActivityType
    
    public enum ActivityType {
        case inference
        case training
        case modelUpdate
        case error
    }
}

public struct DashboardStatistics {
    public let totalModels: Int
    public let activeInferences: Int
    public let averageAccuracy: Double
    public let totalProcessed: Int
}

public struct ModelDetailDestination: Hashable {
    public let modelId: UUID
}

public struct OnboardingPage {
    public let title: String
    public let description: String
    public let imageName: String
}

public struct UserPreferences {
    public var enableNotifications: Bool = true
    public var autoDownloadModels: Bool = false
    public var useCellularData: Bool = false
    public var theme: String = "system"
}