//
//  AIMainView.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import SwiftUI
import Combine

/// Main AI interface view implementing enterprise-grade MVVM-C architecture
public struct AIMainView: View {
    
    // MARK: - State Management
    
    @StateObject private var viewModel: AIViewModel
    @StateObject private var coordinator: AICoordinator
    @State private var selectedTab: AIMainTab = .inference
    @State private var showingModelSelection = false
    @State private var showingSettings = false
    @State private var showingPerformanceDashboard = false
    @State private var isTraining = false
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // MARK: - Initialization
    
    public init(
        viewModel: AIViewModel,
        coordinator: AICoordinator
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._coordinator = StateObject(wrappedValue: coordinator)
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                // Main Content
                if horizontalSizeClass == .compact {
                    compactLayout
                } else {
                    regularLayout
                }
                
                // Loading Overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
                
                // Error Alert
                if let error = viewModel.error {
                    errorAlert(error: error)
                }
            }
            .navigationTitle("SwiftAI")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingModelSelection) {
                ModelSelectionView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingPerformanceDashboard) {
                PerformanceDashboardView(viewModel: viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            setupView()
        }
        .onChange(of: viewModel.operationStatus) { status in
            handleOperationStatusChange(status)
        }
    }
    
    // MARK: - Layout Components
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color.white,
                colorScheme == .dark ? Color.gray.opacity(0.1) : Color.blue.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var compactLayout: some View {
        TabView(selection: $selectedTab) {
            inferenceTab
                .tabItem {
                    Image(systemName: "cpu.fill")
                    Text("Inference")
                }
                .tag(AIMainTab.inference)
            
            trainingTab
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Training")
                }
                .tag(AIMainTab.training)
            
            modelsTab
                .tabItem {
                    Image(systemName: "square.stack.3d.up.fill")
                    Text("Models")
                }
                .tag(AIMainTab.models)
            
            analyticsTab
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
                .tag(AIMainTab.analytics)
        }
        .accentColor(.blue)
    }
    
    private var regularLayout: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 0) {
                sidebarHeader
                sidebarContent
                Spacer()
                sidebarFooter
            }
            .frame(width: 280)
            .background(Color.secondary.opacity(0.1))
            
            Divider()
            
            // Main Content
            VStack(spacing: 0) {
                selectedTabContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Sidebar Components
    
    private var sidebarHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("SwiftAI")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Enterprise AI Platform")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Model Status
            if let model = viewModel.selectedModel {
                modelStatusCard(model: model)
            } else {
                noModelSelectedCard
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
    }
    
    private var sidebarContent: some View {
        List(AIMainTab.allCases, id: \.self, selection: $selectedTab) { tab in
            HStack {
                Image(systemName: tab.iconName)
                    .foregroundColor(selectedTab == tab ? .blue : .primary)
                
                Text(tab.title)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                
                Spacer()
                
                if tab == .training && isTraining {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .listStyle(SidebarListStyle())
    }
    
    private var sidebarFooter: some View {
        VStack(spacing: 12) {
            Divider()
            
            // Performance Stats
            performanceStatsView
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .font(.title2)
                }
                
                Button(action: { showingPerformanceDashboard = true }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                }
                
                Button(action: { showingModelSelection = true }) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.title2)
                }
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
    
    // MARK: - Tab Content
    
    private var selectedTabContent: some View {
        Group {
            switch selectedTab {
            case .inference:
                inferenceTab
            case .training:
                trainingTab
            case .models:
                modelsTab
            case .analytics:
                analyticsTab
            }
        }
    }
    
    private var inferenceTab: some View {
        AIInferenceView(viewModel: viewModel)
            .transition(.opacity)
    }
    
    private var trainingTab: some View {
        AITrainingView(viewModel: viewModel)
            .transition(.slide)
    }
    
    private var modelsTab: some View {
        AIModelsView(viewModel: viewModel)
            .transition(.move(edge: .trailing))
    }
    
    private var analyticsTab: some View {
        AIAnalyticsView(viewModel: viewModel)
            .transition(.move(edge: .bottom))
    }
    
    // MARK: - UI Components
    
    private func modelStatusCard(model: AIModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(model.status == .loaded ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(model.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
            }
            
            HStack {
                Text(model.modelType.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(model.version)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var noModelSelectedCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("No Model Selected")
                .font(.caption)
                .fontWeight(.medium)
            
            Button("Select Model") {
                showingModelSelection = true
            }
            .font(.caption2)
            .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var performanceStatsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Performance")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg Time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.performance.averageInferenceTime, specifier: "%.2f")s")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.performance.totalInferences)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(loadingMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
    }
    
    private var loadingMessage: String {
        switch viewModel.operationStatus {
        case .inference:
            return "Processing AI Inference..."
        case .training:
            return "Training AI Model..."
        case .evaluation:
            return "Evaluating Model Performance..."
        case .cancelled:
            return "Cancelling Operation..."
        case .idle:
            return "Loading..."
        }
    }
    
    private func errorAlert(error: AIViewError) -> some View {
        EmptyView()
            .alert("Error", isPresented: .constant(true)) {
                Button("Dismiss") {
                    // Error is automatically cleared when alert is dismissed
                }
                
                if case .noModelSelected = error {
                    Button("Select Model") {
                        showingModelSelection = true
                    }
                }
            } message: {
                Text(error.localizedDescription)
            }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            // Network Status
            networkStatusIndicator
            
            // Settings
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
            }
            
            // Performance Dashboard
            Button(action: { showingPerformanceDashboard = true }) {
                Image(systemName: "chart.line.uptrend.xyaxis")
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarLeading) {
            // Model Selection
            Button(action: { showingModelSelection = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "cube.box")
                    
                    if let model = viewModel.selectedModel {
                        Text(model.name)
                            .font(.caption)
                    } else {
                        Text("Select Model")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var networkStatusIndicator: some View {
        Circle()
            .fill(networkStatusColor)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1)
            )
    }
    
    private var networkStatusColor: Color {
        // This would integrate with the APIClient's network status
        return .green // Placeholder
    }
    
    // MARK: - Methods
    
    private func setupView() {
        // Initial setup
        Task {
            await viewModel.loadModels()
        }
    }
    
    private func handleOperationStatusChange(_ status: AIOperationStatus) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isTraining = status == .training
        }
        
        // Provide haptic feedback for status changes
        if status == .idle {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Supporting Types

public enum AIMainTab: String, CaseIterable {
    case inference = "inference"
    case training = "training" 
    case models = "models"
    case analytics = "analytics"
    
    var title: String {
        switch self {
        case .inference:
            return "Inference"
        case .training:
            return "Training"
        case .models:
            return "Models"
        case .analytics:
            return "Analytics"
        }
    }
    
    var iconName: String {
        switch self {
        case .inference:
            return "cpu.fill"
        case .training:
            return "brain.head.profile"
        case .models:
            return "square.stack.3d.up.fill"
        case .analytics:
            return "chart.bar.fill"
        }
    }
}

// MARK: - Model Extensions

extension ModelType {
    var displayName: String {
        switch self {
        case .naturalLanguageProcessing:
            return "NLP"
        case .computerVision:
            return "Vision"
        case .speechRecognition:
            return "Speech"
        case .deepLearning:
            return "Deep Learning"
        case .reinforcementLearning:
            return "RL"
        case .custom:
            return "Custom"
        }
    }
}

extension ModelStatus {
    var displayName: String {
        switch self {
        case .notLoaded:
            return "Not Loaded"
        case .loading:
            return "Loading"
        case .loaded:
            return "Ready"
        case .training:
            return "Training"
        case .error:
            return "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .notLoaded:
            return .gray
        case .loading:
            return .orange
        case .loaded:
            return .green
        case .training:
            return .blue
        case .error:
            return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AIMainView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AIViewModel(
            mlService: MockMLService(),
            coordinator: MockAICoordinator()
        )
        
        let coordinator = AICoordinator()
        
        AIMainView(viewModel: viewModel, coordinator: coordinator)
            .preferredColorScheme(.light)
        
        AIMainView(viewModel: viewModel, coordinator: coordinator)
            .preferredColorScheme(.dark)
            .previewDevice("iPad Pro (12.9-inch) (5th generation)")
    }
}

// Mock objects for preview
class MockMLService: MLServiceProtocol {
    func loadModel(_ model: AIModel) -> AnyPublisher<Void, MLServiceError> {
        Just(()).setFailureType(to: MLServiceError.self).eraseToAnyPublisher()
    }
    
    func unloadModel(withId modelId: String) -> Bool { true }
    
    func predict<T: AIInputValidatable, U: AIOutputValidatable>(
        modelId: String,
        input: T
    ) -> AnyPublisher<U, MLServiceError> {
        fatalError("Not implemented for preview")
    }
    
    func startTraining(configuration: TrainingConfiguration, trainingData: TrainingData) -> AnyPublisher<TrainingSession, MLServiceError> {
        fatalError("Not implemented for preview")
    }
    
    func evaluateModel(modelId: String, testData: TrainingData, metrics: [EvaluationMetric]) -> AnyPublisher<ModelEvaluationResult, MLServiceError> {
        fatalError("Not implemented for preview")
    }
}

class MockAICoordinator: AICoordinatorProtocol {
    func showModelSelection() {}
    func showTrainingInterface() {}
    func showPerformanceDashboard() {}
}

#endif