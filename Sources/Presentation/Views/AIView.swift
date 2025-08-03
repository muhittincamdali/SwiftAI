import SwiftUI

// MARK: - AI View Protocol
public protocol AIViewProtocol: View {
    var viewModel: AIViewModelProtocol { get }
}

// MARK: - AI View Implementation
public struct AIView: AIViewProtocol {
    
    // MARK: - Properties
    @StateObject public var viewModel: AIViewModelProtocol
    
    // MARK: - Initialization
    public init(viewModel: AIViewModelProtocol = AIViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Input Section
                inputSection
                
                // Action Buttons
                actionButtons
                
                // Results Section
                resultsSection
                
                // Performance Metrics
                performanceSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("SwiftAI")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("SwiftAI Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Experience the power of AI in your iOS app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Input")
                .font(.headline)
            
            TextField("Enter text for AI processing...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                .disabled(viewModel.isProcessing)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ActionButton(
                    title: "Classify",
                    icon: "textformat",
                    color: .blue,
                    action: { Task { await viewModel.processTextClassification() } }
                )
                
                ActionButton(
                    title: "Sentiment",
                    icon: "heart",
                    color: .red,
                    action: { Task { await viewModel.processSentimentAnalysis() } }
                )
            }
            
            HStack(spacing: 12) {
                ActionButton(
                    title: "Entities",
                    icon: "person.2",
                    color: .green,
                    action: { Task { await viewModel.processEntityExtraction() } }
                )
                
                ActionButton(
                    title: "Translate",
                    icon: "globe",
                    color: .orange,
                    action: { Task { await viewModel.processTranslation(to: .spanish) } }
                )
            }
            
            ActionButton(
                title: "Summarize",
                icon: "doc.text",
                color: .purple,
                action: { Task { await viewModel.processSummarization(maxLength: 100) } }
            )
        }
        .disabled(viewModel.isProcessing)
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        Group {
            if !viewModel.results.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Results")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Clear") {
                            viewModel.clearResults()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.results.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                                ResultRow(key: key, value: value)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        Group {
            if let metrics = viewModel.performanceMetrics {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        MetricCard(
                            title: "Inference Time",
                            value: String(format: "%.2fs", metrics.averageInferenceTime),
                            icon: "clock"
                        )
                        
                        MetricCard(
                            title: "Memory Usage",
                            value: formatMemory(metrics.memoryUsage),
                            icon: "memorychip"
                        )
                        
                        MetricCard(
                            title: "Cache Hit Rate",
                            value: String(format: "%.0f%%", metrics.cacheHitRate * 100),
                            icon: "bolt"
                        )
                        
                        MetricCard(
                            title: "Model Load Time",
                            value: String(format: "%.2fs", metrics.modelLoadTime),
                            icon: "arrow.down.circle"
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatMemory(_ bytes: Int64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Result Row
struct ResultRow: View {
    let key: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(key.capitalized)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(String(format: "%.2f", value))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Processing...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct AIView_Previews: PreviewProvider {
    static var previews: some View {
        AIView()
    }
}
