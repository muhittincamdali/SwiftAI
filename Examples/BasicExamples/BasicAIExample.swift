import SwiftUI
import SwiftAI

struct BasicAIExample: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Basic AI Examples")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Input Text:")
                    .font(.headline)
                
                TextField("Enter text to analyze", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            Button(action: analyzeText) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain.head.profile")
                    }
                    Text(isProcessing ? "Analyzing..." : "Analyze Text")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(inputText.isEmpty || isProcessing)
            
            if !outputText.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Analysis Result:")
                        .font(.headline)
                    
                    Text(outputText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    private func analyzeText() {
        isProcessing = true
        
        // Simulate AI analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let wordCount = inputText.split(separator: " ").count
            let charCount = inputText.count
            let sentiment = analyzeSentiment(inputText)
            
            outputText = """
            Text Analysis Results:
            
            • Word Count: \(wordCount)
            • Character Count: \(charCount)
            • Sentiment: \(sentiment)
            • Language: English
            • Complexity: \(analyzeComplexity(inputText))
            """
            
            isProcessing = false
        }
    }
    
    private func analyzeSentiment(_ text: String) -> String {
        let positiveWords = ["good", "great", "excellent", "amazing", "wonderful", "love", "happy"]
        let negativeWords = ["bad", "terrible", "awful", "hate", "sad", "angry", "disappointed"]
        
        let words = text.lowercased().split(separator: " ")
        let positiveCount = words.filter { positiveWords.contains(String($0)) }.count
        let negativeCount = words.filter { negativeWords.contains(String($0)) }.count
        
        if positiveCount > negativeCount {
            return "Positive 😊"
        } else if negativeCount > positiveCount {
            return "Negative 😔"
        } else {
            return "Neutral 😐"
        }
    }
    
    private func analyzeComplexity(_ text: String) -> String {
        let words = text.split(separator: " ")
        let avgWordLength = Double(text.count) / Double(max(words.count, 1))
        
        if avgWordLength > 8 {
            return "High"
        } else if avgWordLength > 5 {
            return "Medium"
        } else {
            return "Low"
        }
    }
}

#Preview {
    BasicAIExample()
} 