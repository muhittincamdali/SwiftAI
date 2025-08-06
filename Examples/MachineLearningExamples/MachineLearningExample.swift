import SwiftUI
import SwiftAI

struct MachineLearningExample: View {
    @State private var selectedAlgorithm = "Classification"
    @State private var trainingData = ""
    @State private var testData = ""
    @State private var predictionResult = ""
    @State private var isTraining = false
    @State private var accuracy: Double = 0.0
    
    let algorithms = ["Classification", "Regression", "Clustering", "Neural Network"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Machine Learning Examples")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Algorithm:")
                    .font(.headline)
                
                Picker("Algorithm", selection: $selectedAlgorithm) {
                    ForEach(algorithms, id: \.self) { algorithm in
                        Text(algorithm).tag(algorithm)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Training Data:")
                    .font(.headline)
                
                TextField("Enter training data (CSV format)", text: $trainingData, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Test Data:")
                    .font(.headline)
                
                TextField("Enter test data", text: $testData, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2...4)
            }
            
            Button(action: trainModel) {
                HStack {
                    if isTraining {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain")
                    }
                    Text(isTraining ? "Training Model..." : "Train Model")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(trainingData.isEmpty || isTraining)
            
            if accuracy > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Model Performance:")
                        .font(.headline)
                    
                    HStack {
                        Text("Accuracy:")
                        Spacer()
                        Text("\(String(format: "%.1f", accuracy * 100))%")
                            .fontWeight(.bold)
                            .foregroundColor(accuracy > 0.8 ? .green : accuracy > 0.6 ? .orange : .red)
                    }
                    
                    ProgressView(value: accuracy)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
            
            if !predictionResult.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Prediction Result:")
                        .font(.headline)
                    
                    Text(predictionResult)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    private func trainModel() {
        isTraining = true
        
        // Simulate model training
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulate training process
            let epochs = Int.random(in: 50...200)
            let loss = Double.random(in: 0.1...0.5)
            accuracy = Double.random(in: 0.7...0.95)
            
            predictionResult = """
            Model Training Complete!
            
            Algorithm: \(selectedAlgorithm)
            Epochs: \(epochs)
            Final Loss: \(String(format: "%.3f", loss))
            Accuracy: \(String(format: "%.1f", accuracy * 100))%
            
            Model is ready for predictions.
            """
            
            isTraining = false
        }
    }
}

#Preview {
    MachineLearningExample()
} 