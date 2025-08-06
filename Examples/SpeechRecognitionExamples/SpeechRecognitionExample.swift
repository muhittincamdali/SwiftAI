import SwiftUI
import SwiftAI
import Speech

struct SpeechRecognitionExample: View {
    @State private var isRecording = false
    @State private var recognizedText = ""
    @State private var confidence: Float = 0.0
    @State private var isAuthorized = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Speech Recognition")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Recognized Text:")
                    .font(.headline)
                
                Text(recognizedText.isEmpty ? "Tap the microphone to start recording..." : recognizedText)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            
            if confidence > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confidence:")
                        .font(.headline)
                    
                    HStack {
                        Text("\(String(format: "%.1f", confidence * 100))%")
                            .fontWeight(.bold)
                            .foregroundColor(confidence > 0.8 ? .green : confidence > 0.6 ? .orange : .red)
                        
                        Spacer()
                        
                        ProgressView(value: confidence)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 100)
                    }
                }
            }
            
            Button(action: toggleRecording) {
                HStack {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 30))
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRecording ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!isAuthorized)
            
            if !isAuthorized {
                Button("Request Microphone Permission") {
                    requestSpeechPermission()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            checkSpeechPermission()
        }
        .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone access in Settings to use speech recognition.")
        }
    }
    
    private func checkSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                isAuthorized = status == .authorized
            }
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                isAuthorized = status == .authorized
                if status != .authorized {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        recognizedText = "Listening..."
        
        // Simulate speech recognition
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let sampleTexts = [
                "Hello, this is a test of speech recognition",
                "The weather is beautiful today",
                "I love using Swift for iOS development",
                "Artificial intelligence is transforming technology",
                "Speech recognition makes apps more accessible"
            ]
            
            let randomText = sampleTexts.randomElement() ?? "Speech recognition is working"
            confidence = Float.random(in: 0.7...0.95)
            
            recognizedText = randomText
            isRecording = false
        }
    }
    
    private func stopRecording() {
        isRecording = false
    }
}

#Preview {
    SpeechRecognitionExample()
} 