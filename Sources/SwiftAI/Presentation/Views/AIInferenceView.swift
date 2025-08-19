//
//  AIInferenceView.swift
//  SwiftAI
//
//  Created by Muhittin Camdali on 17/08/2024.
//

import SwiftUI
import Combine

/// AI Inference interface view with enterprise-grade input/output handling
public struct AIInferenceView: View {
    
    // MARK: - State Management
    
    @ObservedObject private var viewModel: AIViewModel
    @State private var inputMode: InputMode = .text
    @State private var showingImagePicker = false
    @State private var showingAudioRecorder = false
    @State private var showingResultsHistory = false
    @State private var selectedInputImage: UIImage?
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Constants
    
    private let maxTextInputLength = 10000
    private let maxRecordingDuration: TimeInterval = 300 // 5 minutes
    
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
                
                // Input Section
                inputSection
                
                // Action Buttons
                actionButtonsSection
                
                // Output Section
                if hasOutput {
                    outputSection
                }
                
                // Results History
                if !viewModel.inferenceResults.isEmpty {
                    resultsHistorySection
                }
            }
            .padding()
        }
        .background(backgroundView)
        .navigationTitle("AI Inference")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedInputImage)
        }
        .sheet(isPresented: $showingAudioRecorder) {
            AudioRecorderView(
                isRecording: $isRecording,
                recordingDuration: $recordingDuration,
                onAudioRecorded: handleAudioRecorded
            )
        }
        .sheet(isPresented: $showingResultsHistory) {
            ResultsHistoryView(results: viewModel.inferenceResults)
        }
        .onChange(of: selectedInputImage) { image in
            viewModel.inputImage = image
        }
        .onReceive(viewModel.$operationStatus) { status in
            if status == .idle && recordingTimer != nil {
                stopRecordingTimer()
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color.white,
                colorScheme == .dark ? Color.gray.opacity(0.05) : Color.blue.opacity(0.02)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Model Info
            if let model = viewModel.selectedModel {
                modelInfoCard(model: model)
            } else {
                noModelSelectedBanner
            }
            
            // Input Mode Selector
            inputModeSelector
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 16) {
            switch inputMode {
            case .text:
                textInputView
            case .image:
                imageInputView
            case .audio:
                audioInputView
            case .multimodal:
                multimodalInputView
            }
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            // Clear Button
            Button(action: {
                withAnimation(.spring()) {
                    viewModel.clearInputs()
                    selectedInputImage = nil
                }
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Clear")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
            .disabled(!hasInput)
            
            // Inference Button
            Button(action: {
                Task {
                    await performInference()
                }
            }) {
                HStack {
                    if viewModel.operationStatus == .inference {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "cpu.fill")
                    }
                    Text(viewModel.operationStatus == .inference ? "Processing..." : "Run Inference")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canRunInference ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canRunInference)
        }
    }
    
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Confidence Score
                confidenceIndicator
            }
            
            // Output Content
            outputContentView
            
            // Inference Statistics
            inferenceStatsView
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var resultsHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Results")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("View All") {
                    showingResultsHistory = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(viewModel.inferenceResults.prefix(3).enumerated()), id: \.offset) { index, result in
                    ResultRowView(result: result, index: index)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Input Views
    
    private var textInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Text Input")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.inputText.count)/\(maxTextInputLength)")
                    .font(.caption)
                    .foregroundColor(viewModel.inputText.count > maxTextInputLength * 9 / 10 ? .orange : .secondary)
            }
            
            TextEditor(text: $viewModel.inputText)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: viewModel.inputText.isEmpty ? 0 : 1)
                )
        }
    }
    
    private var imageInputView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image Input")
                .font(.headline)
            
            if let image = viewModel.inputImage {
                VStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text("Image Size: \(Int(image.size.width)) × \(Int(image.size.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: { showingImagePicker = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        Text("Select Image")
                            .font(.headline)
                        
                        Text("Tap to choose an image from your library")
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
        }
    }
    
    private var audioInputView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio Input")
                .font(.headline)
            
            if let audioData = viewModel.inputAudio {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "waveform")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Audio Recorded")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Duration: \(formatDuration(audioData.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Record New") {
                            showingAudioRecorder = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            } else {
                Button(action: { showingAudioRecorder = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        
                        Text("Record Audio")
                            .font(.headline)
                        
                        Text("Tap to start audio recording")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 2)
                    )
                }
            }
        }
    }
    
    private var multimodalInputView: some View {
        VStack(spacing: 16) {
            textInputView
            imageInputView
            audioInputView
        }
    }
    
    // MARK: - UI Components
    
    private func modelInfoCard(model: AIModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(model.modelType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Circle()
                        .fill(model.status.color)
                        .frame(width: 8, height: 8)
                    
                    Text(model.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("v\(model.version)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var noModelSelectedBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No Model Selected")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("Please select an AI model to perform inference")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var inputModeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring()) {
                            inputMode = mode
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: mode.iconName)
                            Text(mode.title)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            inputMode == mode ? Color.blue : Color.secondary.opacity(0.1)
                        )
                        .foregroundColor(
                            inputMode == mode ? .white : .primary
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var outputContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.outputText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Output")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(viewModel.outputText)
                        .font(.body)
                        .padding()
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            
            if let outputImage = viewModel.outputImage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Image Output")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Image(uiImage: outputImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var confidenceIndicator: some View {
        HStack(spacing: 4) {
            Text("Confidence:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(viewModel.confidence * 100, specifier: "%.1f")%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(confidenceColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var confidenceColor: Color {
        switch viewModel.confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var inferenceStatsView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Inference Time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.performance.averageInferenceTime, specifier: "%.3f")s")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Total Processed")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.performance.totalInferences)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: { showingResultsHistory = true }) {
                Image(systemName: "clock.arrow.circlepath")
            }
            .disabled(viewModel.inferenceResults.isEmpty)
            
            Button(action: { viewModel.clearAll() }) {
                Image(systemName: "trash")
            }
            .disabled(!hasInput && !hasOutput)
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasInput: Bool {
        !viewModel.inputText.isEmpty || viewModel.inputImage != nil || viewModel.inputAudio != nil
    }
    
    private var hasOutput: Bool {
        !viewModel.outputText.isEmpty || viewModel.outputImage != nil || viewModel.confidence > 0
    }
    
    private var canRunInference: Bool {
        hasInput && viewModel.selectedModel != nil && viewModel.operationStatus != .inference
    }
    
    // MARK: - Methods
    
    private func performInference() async {
        await viewModel.performInference()
    }
    
    private func handleAudioRecorded(_ audioData: Data) {
        viewModel.inputAudio = audioData
    }
    
    private func formatDuration(_ dataSize: Int) -> String {
        // Estimate duration based on data size (placeholder implementation)
        let estimatedDuration = Double(dataSize) / 44100.0 / 2.0 // Assuming 44.1kHz, 16-bit
        let minutes = Int(estimatedDuration) / 60
        let seconds = Int(estimatedDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
            if recordingDuration >= maxRecordingDuration {
                stopRecordingTimer()
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDuration = 0
    }
}

// MARK: - Supporting Types

public enum InputMode: String, CaseIterable {
    case text = "text"
    case image = "image"
    case audio = "audio"
    case multimodal = "multimodal"
    
    var title: String {
        switch self {
        case .text:
            return "Text"
        case .image:
            return "Image"
        case .audio:
            return "Audio"
        case .multimodal:
            return "Multimodal"
        }
    }
    
    var iconName: String {
        switch self {
        case .text:
            return "text.cursor"
        case .image:
            return "photo"
        case .audio:
            return "mic"
        case .multimodal:
            return "square.grid.3x3.fill"
        }
    }
}

// MARK: - Supporting Views

struct ResultRowView: View {
    let result: AIInferenceResult
    let index: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Result \(index + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let text = result.output.text {
                    Text(text)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(result.inferenceTime, specifier: "%.2f")s")
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Text("\(result.output.confidence * 100, specifier: "%.0f")%")
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
struct AIInferenceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AIInferenceView(viewModel: AIViewModel(
                mlService: MockMLService(),
                coordinator: MockAICoordinator()
            ))
        }
    }
}
#endif