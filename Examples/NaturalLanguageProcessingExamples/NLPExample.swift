import SwiftUI
import SwiftAI

struct NLPExample: View {
    @State private var inputText = ""
    @State private var analysisResults: [String: String] = [:]
    @State private var isAnalyzing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Natural Language Processing")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Input Text:")
                    .font(.headline)
                
                TextField("Enter text for NLP analysis", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(4...8)
            }
            
            Button(action: performNLPAnalysis) {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "text.bubble")
                    }
                    Text(isAnalyzing ? "Analyzing..." : "Analyze Text")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(inputText.isEmpty || isAnalyzing)
            
            if !analysisResults.isEmpty {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(Array(analysisResults.keys.sorted()), id: \.self) { key in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(key)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(analysisResults[key] ?? "")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func performNLPAnalysis() {
        isAnalyzing = true
        analysisResults.removeAll()
        
        // Simulate NLP analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let words = inputText.split(separator: " ")
            let sentences = inputText.split(separator: ".").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            // Sentiment Analysis
            let sentiment = analyzeSentiment(inputText)
            analysisResults["Sentiment Analysis"] = sentiment
            
            // Text Statistics
            let stats = """
            • Words: \(words.count)
            • Characters: \(inputText.count)
            • Sentences: \(sentences.count)
            • Average word length: \(String(format: "%.1f", Double(inputText.count) / Double(max(words.count, 1))))
            """
            analysisResults["Text Statistics"] = stats
            
            // Named Entity Recognition
            let entities = extractNamedEntities(inputText)
            analysisResults["Named Entities"] = entities
            
            // Language Detection
            analysisResults["Language Detection"] = "English (Confidence: 95%)"
            
            // Text Classification
            let category = classifyText(inputText)
            analysisResults["Text Classification"] = category
            
            // Key Phrases
            let keyPhrases = extractKeyPhrases(inputText)
            analysisResults["Key Phrases"] = keyPhrases
            
            isAnalyzing = false
        }
    }
    
    private func analyzeSentiment(_ text: String) -> String {
        let positiveWords = ["good", "great", "excellent", "amazing", "wonderful", "love", "happy", "beautiful", "perfect"]
        let negativeWords = ["bad", "terrible", "awful", "hate", "sad", "angry", "disappointed", "horrible", "worst"]
        
        let words = text.lowercased().split(separator: " ")
        let positiveCount = words.filter { positiveWords.contains(String($0)) }.count
        let negativeCount = words.filter { negativeWords.contains(String($0)) }.count
        
        if positiveCount > negativeCount {
            return "Positive 😊 (Score: +\(positiveCount - negativeCount))"
        } else if negativeCount > positiveCount {
            return "Negative 😔 (Score: \(negativeCount - positiveCount))"
        } else {
            return "Neutral 😐 (Score: 0)"
        }
    }
    
    private func extractNamedEntities(_ text: String) -> String {
        let entities = [
            "Apple": "Organization",
            "iPhone": "Product",
            "Steve Jobs": "Person",
            "California": "Location",
            "2024": "Date",
            "iOS": "Technology"
        ]
        
        var foundEntities: [String] = []
        for (entity, type) in entities {
            if text.contains(entity) {
                foundEntities.append("\(entity) (\(type))")
            }
        }
        
        return foundEntities.isEmpty ? "No named entities found" : foundEntities.joined(separator: "\n")
    }
    
    private func classifyText(_ text: String) -> String {
        let categories = [
            "Technology": ["computer", "software", "app", "digital", "tech", "code", "programming"],
            "Business": ["company", "market", "profit", "business", "corporate", "finance"],
            "Science": ["research", "study", "scientific", "experiment", "data", "analysis"],
            "General": []
        ]
        
        let words = text.lowercased().split(separator: " ")
        var scores: [String: Int] = [:]
        
        for (category, keywords) in categories {
            scores[category] = words.filter { keywords.contains(String($0)) }.count
        }
        
        let bestCategory = scores.max { $0.value < $1.value }?.key ?? "General"
        return "\(bestCategory) (Confidence: \(String(format: "%.0f", Double(scores[bestCategory] ?? 0) / Double(max(words.count, 1)) * 100))%)"
    }
    
    private func extractKeyPhrases(_ text: String) -> String {
        let words = text.split(separator: " ")
        let phrases = words.enumerated().compactMap { index, word in
            if index < words.count - 1 {
                return "\(word) \(words[index + 1])"
            }
            return nil
        }
        
        let uniquePhrases = Array(Set(phrases)).prefix(5)
        return uniquePhrases.isEmpty ? "No key phrases found" : uniquePhrases.joined(separator: "\n")
    }
}

#Preview {
    NLPExample()
} 