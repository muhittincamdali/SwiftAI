// SwiftAI Content Views - SwiftUI Implementation
// Copyright © 2024 SwiftAI. All rights reserved.
// Enterprise-Grade SwiftUI Views with MVVM-C

import SwiftUI
import Combine
import Charts

// MARK: - Home View

public struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    
    public init(viewModel: HomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    // Statistics Cards
                    if let statistics = viewModel.statistics {
                        StatisticsCardsView(statistics: statistics)
                    }
                    
                    // Recent Models
                    RecentModelsSection(models: viewModel.models)
                    
                    // Activity Feed
                    ActivityFeedSection(activities: viewModel.recentActivity)
                }
                .padding()
            }
            .navigationTitle("SwiftAI Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.loadDashboard) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                viewModel.loadDashboard()
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

struct StatisticsCardsView: View {
    let statistics: DashboardStatistics
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            StatCard(
                title: "Total Models",
                value: "\(statistics.totalModels)",
                icon: "cube",
                color: .blue
            )
            
            StatCard(
                title: "Active Inferences",
                value: "\(statistics.activeInferences)",
                icon: "bolt.fill",
                color: .green
            )
            
            StatCard(
                title: "Avg Accuracy",
                value: String(format: "%.1f%%", statistics.averageAccuracy * 100),
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
            
            StatCard(
                title: "Processed",
                value: "\(statistics.totalProcessed)",
                icon: "checkmark.circle",
                color: .purple
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct RecentModelsSection: View {
    let models: [AIModelEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Models")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(models.prefix(5), id: \.id) { model in
                        ModelCard(model: model)
                    }
                }
            }
        }
    }
}

struct ModelCard: View {
    let model: AIModelEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForModelType(model.type))
                    .foregroundColor(.blue)
                Spacer()
                StatusBadge(status: model.status)
            }
            
            Text(model.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(model.type.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Label(
                    String(format: "%.1f%%", model.performance.accuracy * 100),
                    systemImage: "chart.bar"
                )
                .font(.caption2)
                .foregroundColor(.green)
            }
        }
        .padding()
        .frame(width: 160)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
    
    func iconForModelType(_ type: AIModelEntity.ModelType) -> String {
        switch type {
        case .textGeneration: return "text.alignleft"
        case .imageClassification: return "photo"
        case .objectDetection: return "viewfinder"
        case .sentimentAnalysis: return "face.smiling"
        case .translation: return "globe"
        case .speechRecognition: return "mic"
        case .customVision: return "eye"
        case .reinforcementLearning: return "brain"
        }
    }
}

struct StatusBadge: View {
    let status: AIModelEntity.ModelStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorForStatus(status))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    func colorForStatus(_ status: AIModelEntity.ModelStatus) -> Color {
        switch status {
        case .ready: return .green
        case .processing: return .blue
        case .loading: return .orange
        case .error: return .red
        default: return .gray
        }
    }
}

struct ActivityFeedSection: View {
    let activities: [ActivityItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Activity")
                .font(.headline)
            
            if activities.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(activities) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForActivityType(activity.type))
                .foregroundColor(colorForActivityType(activity.type))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(activity.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    func iconForActivityType(_ type: ActivityItem.ActivityType) -> String {
        switch type {
        case .inference: return "bolt.fill"
        case .training: return "chart.line.uptrend.xyaxis"
        case .modelUpdate: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    func colorForActivityType(_ type: ActivityItem.ActivityType) -> Color {
        switch type {
        case .inference: return .blue
        case .training: return .green
        case .modelUpdate: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Models View

public struct ModelsView: View {
    @StateObject private var viewModel: ModelsViewModel
    
    public init(viewModel: ModelsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            List {
                ForEach(viewModel.models) { model in
                    ModelListRow(model: model) {
                        viewModel.selectModel(model)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteModel(viewModel.models[index])
                    }
                }
            }
            .searchable(text: $viewModel.searchText)
            .navigationTitle("AI Models")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.loadModels) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .navigationDestination(for: ModelDetailDestination.self) { destination in
                if let model = viewModel.models.first(where: { $0.id == destination.modelId }) {
                    ModelDetailView(model: model)
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
}

struct ModelListRow: View {
    let model: AIModelEntity
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(model.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(
                            String(format: "%.1f%%", model.performance.accuracy * 100),
                            systemImage: "chart.bar"
                        )
                        
                        Label(
                            "\(Int(model.performance.inferenceTimeMs))ms",
                            systemImage: "timer"
                        )
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: model.status)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModelDetailView: View {
    let model: AIModelEntity
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(model.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        StatusBadge(status: model.status)
                    }
                    
                    Text("Version \(model.version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Performance Metrics
                PerformanceMetricsView(metrics: model.performance)
                
                // Configuration
                ConfigurationView(configuration: model.configuration)
                
                // Metadata
                MetadataView(metadata: model.metadata)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PerformanceMetricsView: View {
    let metrics: AIModelEntity.PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Performance Metrics")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                SimpleMetricCard(title: "Accuracy", value: String(format: "%.1f%%", metrics.accuracy * 100))
                SimpleMetricCard(title: "Precision", value: String(format: "%.1f%%", metrics.precision * 100))
                SimpleMetricCard(title: "Recall", value: String(format: "%.1f%%", metrics.recall * 100))
                SimpleMetricCard(title: "F1 Score", value: String(format: "%.2f", metrics.f1Score))
                SimpleMetricCard(title: "Inference", value: "\(Int(metrics.inferenceTimeMs))ms")
                SimpleMetricCard(title: "Memory", value: "\(Int(metrics.memoryUsageMB))MB")
            }
            .padding(.horizontal)
        }
    }
}

struct SimpleMetricCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ConfigurationView: View {
    let configuration: AIModelEntity.ModelConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Configuration")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                InfoRow(label: "Input Shape", value: configuration.inputShape.map(String.init).joined(separator: " × "))
                InfoRow(label: "Output Shape", value: configuration.outputShape.map(String.init).joined(separator: " × "))
                InfoRow(label: "Batch Size", value: "\(configuration.batchSize)")
                InfoRow(label: "Quantization", value: configuration.quantizationType.rawValue)
            }
        }
        .padding()
    }
}

struct MetadataView: View {
    let metadata: AIModelEntity.ModelMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Metadata")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                InfoRow(label: "Author", value: metadata.author)
                InfoRow(label: "License", value: metadata.license)
                InfoRow(label: "Framework", value: "\(metadata.framework) \(metadata.frameworkVersion)")
                InfoRow(label: "Model Size", value: ByteCountFormatter.string(fromByteCount: metadata.modelSize, countStyle: .file))
            }
        }
        .padding()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Training View

public struct TrainingView: View {
    @StateObject private var viewModel: TrainingViewModel
    
    public init(viewModel: TrainingViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            VStack {
                if let currentSession = viewModel.currentSession {
                    TrainingSessionView(session: currentSession, progress: viewModel.trainingProgress)
                } else {
                    StartTrainingView(viewModel: viewModel)
                }
            }
            .navigationTitle("Training")
        }
    }
}

struct TrainingSessionView: View {
    let session: TrainingSession
    let progress: TrainingProgress?
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress indicators
            if let progress = progress {
                VStack(spacing: 15) {
                    ProgressView(value: Double(progress.currentEpoch), total: Double(progress.totalEpochs))
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        Text("Epoch \(progress.currentEpoch)/\(progress.totalEpochs)")
                        Spacer()
                        Text("Loss: \(String(format: "%.4f", progress.loss))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            
            Spacer()
        }
    }
}

struct StartTrainingView: View {
    let viewModel: TrainingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Start Training")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Train custom AI models with your data")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // Start training
            }) {
                Text("Configure Training")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Insights View

public struct InsightsView: View {
    @StateObject private var viewModel: InsightsViewModel
    
    public init(viewModel: InsightsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                        Text("Day").tag(InsightsViewModel.TimeRange.day)
                        Text("Week").tag(InsightsViewModel.TimeRange.week)
                        Text("Month").tag(InsightsViewModel.TimeRange.month)
                        Text("Year").tag(InsightsViewModel.TimeRange.year)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Analytics Summary
                    if let analytics = viewModel.analyticsData {
                        AnalyticsSummaryView(summary: analytics)
                    }
                    
                    // Performance Charts
                    PerformanceChartsView(metrics: viewModel.performanceMetrics)
                }
            }
            .navigationTitle("Insights")
            .onChange(of: viewModel.selectedTimeRange) { _ in
                viewModel.loadInsights()
            }
        }
    }
}

struct AnalyticsSummaryView: View {
    let summary: AnalyticsSummary
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                SummaryCard(
                    title: "Total Requests",
                    value: "\(summary.totalRequests)",
                    trend: .up
                )
                
                SummaryCard(
                    title: "Success Rate",
                    value: String(format: "%.1f%%", summary.successRate * 100),
                    trend: .neutral
                )
            }
            
            HStack(spacing: 15) {
                SummaryCard(
                    title: "Avg Latency",
                    value: "\(Int(summary.averageLatency))ms",
                    trend: .down
                )
                
                SummaryCard(
                    title: "Active Models",
                    value: "\(summary.topModels.count)",
                    trend: .up
                )
            }
        }
        .padding()
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let trend: Trend
    
    enum Trend {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
    
    var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }
    
    var trendColor: Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}

struct PerformanceChartsView: View {
    let metrics: [PerformanceMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Performance Trends")
                .font(.headline)
                .padding(.horizontal)
            
            // Chart placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Performance Chart")
                        .foregroundColor(.secondary)
                )
                .padding(.horizontal)
        }
    }
}

// MARK: - Settings View

public struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    
    public init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Notifications", isOn: $viewModel.isNotificationsEnabled)
                    
                    Picker("Theme", selection: $viewModel.selectedTheme) {
                        ForEach(SettingsViewModel.AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
                
                Section("Storage") {
                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text(viewModel.cacheSize)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Cache") {
                        viewModel.clearCache()
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://swiftai.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://swiftai.com/terms")!)
                }
                
                Section {
                    Button("Sign Out") {
                        viewModel.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Onboarding View

public struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    
    public init(viewModel: OnboardingViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: viewModel.currentPageData.imageName)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 20) {
                Text(viewModel.currentPageData.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(viewModel.currentPageData.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                if viewModel.currentPage > 0 {
                    Button("Previous") {
                        viewModel.previousPage()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button(viewModel.isLastPage ? "Get Started" : "Next") {
                    if viewModel.isLastPage {
                        viewModel.completeOnboarding()
                    } else {
                        viewModel.nextPage()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Main View

public struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    
    public init(viewModel: MainViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedTab) {
                NavigationLink(value: 0) {
                    Label("Dashboard", systemImage: "house")
                }
                
                NavigationLink(value: 1) {
                    Label("Models", systemImage: "cube")
                }
                
                NavigationLink(value: 2) {
                    Label("Training", systemImage: "chart.line.uptrend.xyaxis")
                }
                
                NavigationLink(value: 3) {
                    Label("Insights", systemImage: "chart.bar")
                }
                
                NavigationLink(value: 4) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("SwiftAI")
        } detail: {
            switch viewModel.selectedTab {
            case 0:
                HomeView(viewModel: HomeViewModel())
            case 1:
                ModelsView(viewModel: ModelsViewModel())
            case 2:
                TrainingView(viewModel: TrainingViewModel())
            case 3:
                InsightsView(viewModel: InsightsViewModel())
            case 4:
                SettingsView(viewModel: SettingsViewModel())
            default:
                HomeView(viewModel: HomeViewModel())
            }
        }
    }
}