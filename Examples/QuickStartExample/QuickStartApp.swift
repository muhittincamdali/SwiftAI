import SwiftUI

@main
struct QuickStartApp: App {
    var body: some Scene {
        WindowGroup {
            QuickStartView()
        }
    }
}

struct QuickStartView: View {
    @State private var inputText: String = ""
    @State private var classification: [String: Double] = [:]
    @State private var isProcessing: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Start with SwiftAI")
                    .font(.title)
                    .bold()
                
                TextField("Type something to classify...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: classifyText) {
                    Text("Classify")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isProcessing || inputText.isEmpty)
                
                if isProcessing {
                    ProgressView()
                }
                
                if !classification.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Classification Results:")
                            .font(.headline)
                        ForEach(classification.sorted(by: { $0.value > $1.value }), id: \ .key) { key, value in
                            HStack {
                                Text(key.capitalized)
                                Spacer()
                                Text(String(format: "%.2f", value))
                            }
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            .padding()
            .navigationTitle("QuickStart Example")
        }
    }
    
    func classifyText() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isProcessing = true
        classification = [:]
        Task {
            do {
                let nlpManager = NLPManager()
                let result = try await nlpManager.classifyText(inputText)
                await MainActor.run {
                    self.classification = result
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.classification = ["Error": 1.0]
                    self.isProcessing = false
                }
            }
        }
    }
}
