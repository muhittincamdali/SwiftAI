//
//  AITrainingView.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import SwiftUI
import Combine

/// AI Training interface view with enterprise-grade training management
public struct AITrainingView: View {
    
    // MARK: - State Management
    
    @ObservedObject private var viewModel: AIViewModel
    @State private var selectedTrainingData: TrainingData?
    @State private var showingDataPicker = false
    @State private var showingTrainingConfig = false
    @State private var showingTrainingHistory = false
    @State private var trainingConfiguration = TrainingConfiguration()
    @State private var isConfigurationValid = false
    
    // Progress tracking
    @State private var trainingStartTime: Date?
    @State private var estimatedCompletionTime: Date?
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Initialization
    
    public init(viewModel: AIViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Training Data Section
                trainingDataSection
                
                // Configuration Section
                configurationSection
                
                // Training Controls
                trainingControlsSection
                
                // Progress Section
                if viewModel.operationStatus == .training || viewModel.trainingProgress != nil {
                    trainingProgressSection
                }
                
                // Training History
                if hasTrainingHistory {
                    trainingHistorySection
                }
            }
            .padding()
        }
        .background(backgroundView)
        .navigationTitle("AI Training")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingDataPicker) {
            TrainingDataPickerView(selectedData: $selectedTrainingData)
        }
        .sheet(isPresented: $showingTrainingConfig) {
            TrainingConfigurationView(
                configuration: $trainingConfiguration,
                isValid: $isConfigurationValid
            )
        }
        .sheet(isPresented: $showingTrainingHistory) {
            TrainingHistoryView()
        }
        .onAppear {
            setupInitialConfiguration()
        }
        .onChange(of: viewModel.operationStatus) { status in
            handleTrainingStatusChange(status)
        }
    }
    
    // MARK: - View Components
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color.white,
                colorScheme == .dark ? Color.gray.opacity(0.05) : Color.purple.opacity(0.02)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Training Status Overview
            trainingStatusCard
            
            // Quick Stats
            trainingStatsGrid
        }
    }
    
    private var trainingStatusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: trainingStatusIcon)
                        .foregroundColor(trainingStatusColor)
                        .font(.title2)
                    
                    Text(trainingStatusText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(trainingStatusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if viewModel.operationStatus == .training {
                VStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    if let progress = viewModel.trainingProgress {
                        Text("\(Int(progress.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(trainingStatusBackgroundColor)
        .cornerRadius(16)
    }
    
    private var trainingStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(
                title: "Total Sessions",
                value: "12",
                icon: "brain.head.profile",
                color: .blue
            )
            
            StatCard(
                title: "Success Rate",
                value: "94.2%",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Avg Duration",
                value: "2.3h",
                icon: "clock.fill",
                color: .orange
            )
            
            StatCard(
                title: "Best Accuracy",
                value: "96.8%",
                icon: "star.fill",
                color: .yellow
            )
        }
    }
    
    private var trainingDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Training Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Browse Data") {
                    showingDataPicker = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let trainingData = selectedTrainingData {
                selectedDataCard(data: trainingData)
            } else {
                noDataSelectedCard
            }
        }
    }
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Configuration")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Configure") {
                    showingTrainingConfig = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            configurationSummaryCard
        }
    }
    
    private var trainingControlsSection: some View {
        VStack(spacing: 16) {
            if viewModel.operationStatus == .training {
                // Stop Training Button
                Button(action: {
                    viewModel.cancelTraining()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop Training")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                // Start Training Button
                Button(action: {
                    startTraining()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Training")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canStartTraining ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!canStartTraining)
                
                // Validation Messages
                if !canStartTraining {
                    validationMessagesView
                }
            }
        }
    }
    
    private var trainingProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Training Progress")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let progress = viewModel.trainingProgress {
                trainingProgressCard(progress: progress)
            } else {
                initializingTrainingCard
            }
        }
    }
    
    private var trainingHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Training Sessions")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingTrainingHistory = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            recentTrainingSessionsView
        }
    }
    
    // MARK: - Individual Components
    
    private func selectedDataCard(data: TrainingData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(data.sampleCount) samples")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Quality Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(data.qualityScore, specifier: "%.1f")/10")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(data.qualityScore >= 8.0 ? .green : data.qualityScore >= 6.0 ? .orange : .red)
                }
            }
            
            // Data validation status
            dataValidationView(data: data)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var noDataSelectedCard: some View {
        Button(action: { showingDataPicker = true }) {
            VStack(spacing: 12) {
                Image(systemName: "doc.badge.plus")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text("Select Training Data")
                    .font(.headline)
                
                Text("Choose a dataset to train your AI model")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }
    
    private var configurationSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Configuration")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Circle()
                    .fill(isConfigurationValid ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
            }
            
            VStack(spacing: 8) {
                configRow("Model Type", value: trainingConfiguration.modelType.rawValue)
                configRow("Epochs", value: "\(trainingConfiguration.epochs)")
                configRow("Batch Size", value: "\(trainingConfiguration.batchSize)")
                configRow("Learning Rate", value: "\(trainingConfiguration.learningRate, specifier: "%.4f")")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func configRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private func dataValidationView(data: TrainingData) -> some View {
        let validationResult = data.validateDataset()
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: validationResult.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(validationResult.isValid ? .green : .orange)
                    .font(.caption)
                
                Text(validationResult.isValid ? "Data validation passed" : "Validation issues found")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            
            if !validationResult.isValid && !validationResult.issues.isEmpty {
                ForEach(validationResult.issues, id: \.self) { issue in
                    Text("• \(issue)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private func trainingProgressCard(progress: TrainingProgress) -> some View {
        VStack(spacing: 16) {
            // Overall Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Overall Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(progress.progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: progress.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            // Current Epoch
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Epoch \(progress.currentEpoch)/\(progress.totalEpochs)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(progress.epochProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: progress.epochProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
            
            // Metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCard(title: "Loss", value: "\(progress.currentLoss, specifier: "%.4f")", trend: .down)
                MetricCard(title: "Accuracy", value: "\(progress.currentAccuracy * 100, specifier: "%.1f")%", trend: .up)
                MetricCard(title: "Learning Rate", value: "\(progress.learningRate, specifier: "%.2e")", trend: .neutral)
                MetricCard(title: "Time Remaining", value: estimatedTimeRemaining, trend: .neutral)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var initializingTrainingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Initializing Training Session...")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Preparing model and data for training")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var validationMessagesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if selectedTrainingData == nil {
                validationMessage("No training data selected", icon: "doc.badge.plus")
            }
            
            if !isConfigurationValid {
                validationMessage("Configuration needs adjustment", icon: "gear.badge.xmark")
            }
            
            if viewModel.selectedModel == nil {
                validationMessage("No model selected for training", icon: "cube.box")
            }
        }
    }
    
    private func validationMessage(_ text: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.orange)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var recentTrainingSessionsView: some View {
        VStack(spacing: 8) {
            // Mock training sessions
            ForEach(0..<3, id: \.self) { index in
                TrainingSessionRowView(
                    sessionName: "Training Session \(index + 1)",
                    date: Date().addingTimeInterval(-Double(index) * 86400),
                    duration: TimeInterval(2.5 + Double(index) * 0.3) * 3600,
                    finalAccuracy: 0.94 - Double(index) * 0.02,
                    status: index == 0 ? .completed : .completed
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canStartTraining: Bool {
        selectedTrainingData != nil &&
        isConfigurationValid &&
        viewModel.selectedModel != nil &&
        viewModel.operationStatus != .training
    }
    
    private var hasTrainingHistory: Bool {
        // This would check actual training history
        return true // Placeholder
    }
    
    private var trainingStatusIcon: String {
        switch viewModel.operationStatus {
        case .training:
            return "brain.head.profile.fill"
        case .idle:
            return "pause.circle.fill"
        case .cancelled:
            return "stop.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    private var trainingStatusColor: Color {
        switch viewModel.operationStatus {
        case .training:
            return .blue
        case .idle:
            return .gray
        case .cancelled:
            return .red
        default:
            return .gray
        }
    }
    
    private var trainingStatusText: String {
        switch viewModel.operationStatus {
        case .training:
            return "Training in Progress"
        case .idle:
            return "Ready to Train"
        case .cancelled:
            return "Training Cancelled"
        default:
            return "Inactive"
        }
    }
    
    private var trainingStatusDescription: String {
        switch viewModel.operationStatus {
        case .training:
            return "Your AI model is currently being trained"
        case .idle:
            return "Select data and configure training to begin"
        case .cancelled:
            return "Training session was cancelled"
        default:
            return "Configure training parameters to start"
        }
    }
    
    private var trainingStatusBackgroundColor: Color {
        switch viewModel.operationStatus {
        case .training:
            return Color.blue.opacity(0.1)
        case .idle:
            return Color.secondary.opacity(0.1)
        case .cancelled:
            return Color.red.opacity(0.1)
        default:
            return Color.secondary.opacity(0.1)
        }
    }
    
    private var estimatedTimeRemaining: String {
        guard let progress = viewModel.trainingProgress,
              let startTime = trainingStartTime else {
            return "---"
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let totalEstimated = elapsed / Double(progress.progress)
        let remaining = totalEstimated - elapsed
        
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) % 3600 / 60
        
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: { showingTrainingHistory = true }) {
                Image(systemName: "clock.arrow.circlepath")
            }
            
            Button(action: { showingTrainingConfig = true }) {
                Image(systemName: "slider.horizontal.3")
            }
        }
    }
    
    // MARK: - Methods
    
    private func setupInitialConfiguration() {
        // Setup default training configuration
        trainingConfiguration = TrainingConfiguration(
            modelName: "custom_model_\(Date().timeIntervalSince1970)",
            modelType: .deepLearning,
            epochs: 50,
            batchSize: 32,
            learningRate: 0.001
        )
        
        validateConfiguration()
    }
    
    private func validateConfiguration() {
        // Validate training configuration
        isConfigurationValid = trainingConfiguration.epochs > 0 &&
                             trainingConfiguration.batchSize > 0 &&
                             trainingConfiguration.learningRate > 0
    }
    
    private func startTraining() {
        guard let trainingData = selectedTrainingData else { return }
        
        trainingStartTime = Date()
        estimatedCompletionTime = Date().addingTimeInterval(TimeInterval(trainingConfiguration.epochs) * 60)
        
        Task {
            await viewModel.startTraining(with: trainingData)
        }
    }
    
    private func handleTrainingStatusChange(_ status: AIOperationStatus) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if status != .training {
                trainingStartTime = nil
                estimatedCompletionTime = nil
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let trend: Trend
    
    enum Trend {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption2)
                    .foregroundColor(trend.color)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct TrainingSessionRowView: View {
    let sessionName: String
    let date: Date
    let duration: TimeInterval
    let finalAccuracy: Double
    let status: SessionStatus
    
    enum SessionStatus {
        case completed, failed, inProgress
        
        var color: Color {
            switch self {
            case .completed: return .green
            case .failed: return .red
            case .inProgress: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            case .inProgress: return "clock.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sessionName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: status.icon)
                        .foregroundColor(status.color)
                        .font(.caption)
                    
                    Text("\(finalAccuracy * 100, specifier: "%.1f")%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("\(duration / 3600, specifier: "%.1f")h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#if DEBUG
struct AITrainingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AITrainingView(viewModel: AIViewModel(
                mlService: MockMLService(),
                coordinator: MockAICoordinator()
            ))
        }
    }
}
#endif