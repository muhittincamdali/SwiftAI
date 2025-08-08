import SwiftAI
import Foundation

// Basic Machine Learning Example
class BasicMLExample {
    
    private let aiManager = AIManager()
    
    func setupAI() {
        let config = AIConfiguration()
        config.enableMachineLearning = true
        config.enableGPUAcceleration = true
        config.enableRealTimeInference = true
        
        aiManager.configure(config)
    }
    
    func performBasicPrediction() {
        let simpleML = SimpleML()
        
        simpleML.predict(
            model: "classification_model",
            input: [1.0, 2.0, 3.0, 4.0]
        ) { result in
            switch result {
            case .success(let prediction):
                print("✅ Prediction successful: \(prediction)")
            case .failure(let error):
                print("❌ Prediction failed: \(error)")
            }
        }
    }
    
    func analyzeText() {
        let simpleNLP = SimpleNLP()
        
        simpleNLP.analyzeText("This is a great AI framework!") { result in
            switch result {
            case .success(let analysis):
                print("✅ Text analysis completed")
                print("Sentiment: \(analysis.sentiment)")
                print("Keywords: \(analysis.keywords)")
            case .failure(let error):
                print("❌ Text analysis failed: \(error)")
            }
        }
    }
}

// Usage Example
let example = BasicMLExample()
example.setupAI()
example.performBasicPrediction()
example.analyzeText()
