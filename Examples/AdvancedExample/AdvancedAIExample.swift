import SwiftUI
import SwiftAI
import CoreML
import Vision
import NaturalLanguage

struct AdvancedAIExample: View {
    @State private var selectedInputType: AIInputType = .text
    @State private var inputText = ""
    @State private var selectedImage: UIImage?
    @State private var audioData: Data?
    @State private var sensorData: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
    @State private var isProcessing = false
    @State private var results: [AIOutput] = []
    @State private var performanceMetrics: PerformanceMetrics?
    @State private var showAdvancedSettings = false
    @State private var confidenceThreshold: Double = 0.7
    @State private var enableGPU = true
    @State private var enableNeuralEngine = true
    @State private var batchSize: Int = 5
    
    private let aiEngine = AIEngine()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Input Type Selection
                    inputTypeSection
                    
                    // Input Fields
                    inputFieldsSection
                    
                    // Advanced Settings
                    advancedSettingsSection
                    
                    // Process Button
                    processButton
                    
                    // Results
                    resultsSection
                    
                    // Performance Metrics
                    performanceMetricsSection
                }
                .padding()
            }
            .navigationTitle("Advanced AI Examples")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showAdvancedSettings.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $showAdvancedSettings) {
            advancedSettingsSheet
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Advanced AI Processing")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Experience the full power of SwiftAI with advanced features including multimodal processing, performance monitoring, and custom configurations.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Input Type Selection
    
    private var inputTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Input Type")
                .font(.headline)
            
            Picker("Input Type", selection: $selectedInputType) {
                Text("Text").tag(AIInputType.text)
                Text("Image").tag(AIInputType.image)
                Text("Audio").tag(AIInputType.audio)
                Text("Video").tag(AIInputType.video)
                Text("Sensor Data").tag(AIInputType.sensorData)
                Text("Multimodal").tag(AIInputType.multimodal)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Input Fields
    
    private var inputFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Input Data")
                .font(.headline)
            
            switch selectedInputType {
            case .text:
                textInputField
            case .image:
                imageInputField
            case .audio:
                audioInputField
            case .video:
                videoInputField
            case .sensorData:
                sensorDataInputField
            case .multimodal:
                multimodalInputField
            }
        }
    }
    
    private var textInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text Input")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("Enter text to analyze", text: $inputText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var imageInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image Input")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(12)
            }
            
            Button("Select Image") {
                // Image picker implementation
                selectImage()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var audioInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Audio Input")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if audioData != nil {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.green)
                    Text("Audio data loaded")
                        .foregroundColor(.green)
                }
            }
            
            Button("Record Audio") {
                // Audio recording implementation
                recordAudio()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var videoInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Video Input")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Select Video") {
                // Video picker implementation
                selectVideo()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var sensorDataInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sensor Data")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(0..<sensorData.count, id: \.self) { index in
                HStack {
                    Text("Sensor \(index + 1):")
                        .frame(width: 80, alignment: .leading)
                    
                    Slider(value: $sensorData[index], in: -100...100, step: 0.1)
                    
                    Text(String(format: "%.1f", sensorData[index]))
                        .frame(width: 50, alignment: .trailing)
                        .font(.caption)
                }
            }
        }
    }
    
    private var multimodalInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Multimodal Input")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Combines multiple input types for comprehensive analysis")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Add Text") {
                    // Add text input
                }
                .buttonStyle(.bordered)
                
                Button("Add Image") {
                    // Add image input
                }
                .buttonStyle(.bordered)
                
                Button("Add Audio") {
                    // Add audio input
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Advanced Settings
    
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Advanced Settings")
                    .font(.headline)
                
                Spacer()
                
                Button(showAdvancedSettings ? "Hide" : "Show") {
                    showAdvancedSettings.toggle()
                }
                .font(.caption)
            }
            
            if showAdvancedSettings {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Confidence Threshold:")
                        Spacer()
                        Text("\(Int(confidenceThreshold * 100))%")
                            .font(.caption)
                    }
                    
                    Slider(value: $confidenceThreshold, in: 0.1...1.0, step: 0.05)
                    
                    HStack {
                        Toggle("Enable GPU", isOn: $enableGPU)
                        Toggle("Neural Engine", isOn: $enableNeuralEngine)
                    }
                    
                    HStack {
                        Text("Batch Size:")
                        Spacer()
                        Picker("Batch Size", selection: $batchSize) {
                            Text("1").tag(1)
                            Text("5").tag(5)
                            Text("10").tag(10)
                            Text("20").tag(20)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Process Button
    
    private var processButton: some View {
        Button(action: processInput) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "play.circle.fill")
                }
                Text(isProcessing ? "Processing..." : "Process with AI")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isProcessing ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isProcessing || !hasValidInput)
    }
    
    private var hasValidInput: Bool {
        switch selectedInputType {
        case .text:
            return !inputText.isEmpty
        case .image:
            return selectedImage != nil
        case .audio:
            return audioData != nil
        case .video:
            return true // Video URL would be set
        case .sensorData:
            return true // Sensor data is always available
        case .multimodal:
            return true // Multimodal is always available
        }
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !results.isEmpty {
                Text("Results")
                    .font(.headline)
                
                ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                    resultView(for: result, index: index)
                }
            }
        }
    }
    
    private func resultView(for result: AIOutput, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Result \(index + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(resultTypeString(for: result))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            resultContentView(for: result)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func resultContentView(for result: AIOutput) -> some View {
        switch result {
        case .classification(let classifications):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(classifications.sorted(by: { $0.value > $1.value })), id: \.key) { key, value in
                    HStack {
                        Text(key.capitalized)
                        Spacer()
                        Text("\(Int(value * 100))%")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
            
        case .detection(let detections):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(detections.enumerated()), id: \.offset) { index, detection in
                    HStack {
                        Text("\(detection.label)")
                        Spacer()
                        Text("\(Int(detection.confidence * 100))%")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
            
        case .generation(let text):
            Text(text)
                .font(.body)
            
        case .translation(let text):
            Text(text)
                .font(.body)
                .italic()
            
        case .sentiment(let sentiment):
            HStack {
                Text("Sentiment:")
                Spacer()
                sentimentView(for: sentiment)
            }
            
        case .recommendation(let recommendations):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.item)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(recommendation.reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
        case .anomaly(let anomaly):
            HStack {
                Text("Anomaly Detected:")
                Spacer()
                Text(anomaly.isAnomaly ? "Yes" : "No")
                    .foregroundColor(anomaly.isAnomaly ? .red : .green)
            }
            
        case .prediction(let prediction):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Predicted Value:")
                    Spacer()
                    Text(String(format: "%.2f", prediction.value))
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Confidence:")
                    Spacer()
                    Text("\(Int(prediction.confidence * 100))%")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func resultTypeString(for result: AIOutput) -> String {
        switch result {
        case .classification: return "Classification"
        case .detection: return "Detection"
        case .generation: return "Generation"
        case .translation: return "Translation"
        case .sentiment: return "Sentiment"
        case .recommendation: return "Recommendation"
        case .anomaly: return "Anomaly"
        case .prediction: return "Prediction"
        }
    }
    
    private func sentimentView(for sentiment: SentimentScore) -> some View {
        switch sentiment {
        case .positive(let value):
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundColor(.green)
                Text("Positive (\(Int(value * 100))%)")
                    .foregroundColor(.green)
            }
        case .negative(let value):
            HStack {
                Image(systemName: "face.frown")
                    .foregroundColor(.red)
                Text("Negative (\(Int(value * 100))%)")
                    .foregroundColor(.red)
            }
        case .neutral(let value):
            HStack {
                Image(systemName: "face.neutral")
                    .foregroundColor(.orange)
                Text("Neutral (\(Int(value * 100))%)")
                    .foregroundColor(.orange)
            }
        case .mixed(let value):
            HStack {
                Image(systemName: "face.dashed")
                    .foregroundColor(.purple)
                Text("Mixed (\(Int(value * 100))%)")
                    .foregroundColor(.purple)
            }
        }
    }
    
    // MARK: - Performance Metrics
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let metrics = performanceMetrics {
                Text("Performance Metrics")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    metricRow("Inference Time", "\(String(format: "%.3f", metrics.averageInferenceTime))s")
                    metricRow("Memory Usage", "\(ByteCountFormatter.string(fromByteCount: metrics.memoryUsage, countStyle: .file))")
                    metricRow("Cache Hit Rate", "\(Int(metrics.cacheHitRate * 100))%")
                    metricRow("Model Load Time", "\(String(format: "%.3f", metrics.modelLoadTime))s")
                    metricRow("GPU Utilization", "\(Int(metrics.gpuUtilization * 100))%")
                    metricRow("Neural Engine", "\(Int(metrics.neuralEngineUtilization * 100))%")
                    metricRow("Battery Impact", "\(Int(metrics.batteryImpact * 100))%")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Advanced Settings Sheet
    
    private var advancedSettingsSheet: some View {
        NavigationView {
            Form {
                Section("Performance") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confidence Threshold: \(Int(confidenceThreshold * 100))%")
                        Slider(value: $confidenceThreshold, in: 0.1...1.0, step: 0.05)
                    }
                    
                    Toggle("Enable GPU Acceleration", isOn: $enableGPU)
                    Toggle("Enable Neural Engine", isOn: $enableNeuralEngine)
                    
                    Picker("Batch Size", selection: $batchSize) {
                        Text("1").tag(1)
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("20").tag(20)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Model Configuration") {
                    Text("Text Model: text_model_v1")
                    Text("Image Model: image_model_v1")
                    Text("Audio Model: audio_model_v1")
                    Text("Video Model: video_model_v1")
                    Text("Sensor Model: sensor_model_v1")
                    Text("Multimodal Model: multimodal_model_v1")
                }
                
                Section("About") {
                    Text("SwiftAI Advanced Example")
                    Text("Version 1.0.0")
                    Text("Built with SwiftUI and Core ML")
                }
            }
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAdvancedSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func processInput() {
        isProcessing = true
        results.removeAll()
        
        Task {
            do {
                let input = createAIInput()
                let result = try await aiEngine.process(input, type: selectedInputType)
                
                await MainActor.run {
                    results.append(result)
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    // Handle error
                    isProcessing = false
                }
            }
        }
    }
    
    private func createAIInput() -> AIInput {
        switch selectedInputType {
        case .text:
            return .text(inputText)
        case .image:
            return .image(selectedImage ?? UIImage())
        case .audio:
            return .audio(audioData ?? Data())
        case .video:
            return .video(URL(fileURLWithPath: "/tmp/test_video.mp4"))
        case .sensorData:
            return .sensorData(sensorData)
        case .multimodal:
            return .multimodal([
                .text(inputText.isEmpty ? "Sample text" : inputText),
                .image(selectedImage ?? UIImage())
            ])
        }
    }
    
    private func selectImage() {
        // Image picker implementation
    }
    
    private func recordAudio() {
        // Audio recording implementation
    }
    
    private func selectVideo() {
        // Video picker implementation
    }
}

#Preview {
    AdvancedAIExample()
} 