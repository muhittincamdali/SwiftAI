import SwiftUI

@main
struct SwiftAIApp: App {
    @StateObject private var viewModel = AIViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Example ContentView
struct ContentView: View {
    @EnvironmentObject var viewModel: AIViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("SwiftAI Demo")
                    .font(.largeTitle)
                    .bold()
                
                TextField("Enter text for classification", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    viewModel.processTextClassification()
                }) {
                    Text("Classify Text")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(viewModel.isProcessing)
                
                if viewModel.isProcessing {
                    ProgressView()
                }
                
                if !viewModel.results.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Results:")
                            .font(.headline)
                        ForEach(viewModel.results.sorted(by: { $0.value > $1.value }), id: \ .key) { key, value in
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
            .navigationTitle("SwiftAI Example")
        }
    }
}

// MARK: - Example ViewModel
class AIViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var results: [String: Double] = [:]
    @Published var isProcessing: Bool = false
    
    private let nlpManager: NLPManagerProtocol
    
    init(nlpManager: NLPManagerProtocol = NLPManager()) {
        self.nlpManager = nlpManager
    }
    
    func processTextClassification() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isProcessing = true
        results = [:]
        Task {
            do {
                let classification = try await nlpManager.classifyText(inputText)
                await MainActor.run {
                    self.results = classification
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.results = ["Error": 1.0]
                    self.isProcessing = false
                }
            }
        }
    }
}