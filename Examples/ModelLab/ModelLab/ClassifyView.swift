import SwiftAI
import SwiftUI

/// The models the Classify screen offers, each trained on all 150 iris samples.
enum IrisModel: String, CaseIterable, Identifiable {
    case forest = "Random forest"
    case logistic = "Logistic regression"
    case neighbors = "k-nearest neighbours"
    case bayes = "Naive Bayes"

    var id: String { rawValue }

    func train() throws -> any ProbabilisticClassifier<String> {
        let iris = Dataset.iris
        switch self {
        case .forest:
            return try RandomForestClassifier.fit(iris, seed: 1)
        case .logistic:
            return try Pipeline.fit(iris, transformer: StandardScaler.fit) { try LogisticRegression.fit($0) }
        case .neighbors:
            return try Pipeline.fit(iris, transformer: StandardScaler.fit) { try KNearestNeighborsClassifier.fit($0, k: 7) }
        case .bayes:
            return try GaussianNaiveBayes.fit(iris)
        }
    }
}

/// Measure a flower with four sliders and see each species' probability.
struct ClassifyView: View {
    @State private var choice = IrisModel.forest
    @State private var models: [IrisModel: any ProbabilisticClassifier<String>] = [:]
    @State private var measurements: [Double] = [5.9, 3.0, 4.2, 1.5]

    private let ranges: [ClosedRange<Double>] = [4...8, 2...4.5, 1...7, 0.1...2.5]

    var body: some View {
        Form {
            Picker("Model", selection: $choice) {
                ForEach(IrisModel.allCases) { Text($0.rawValue).tag($0) }
            }
            Section("Measurements (cm)") {
                ForEach(0..<4, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text("\(Dataset.irisFeatureNames[index]): \(measurements[index].formatted(.number.precision(.fractionLength(1))))")
                        Slider(value: $measurements[index], in: ranges[index], step: 0.1)
                    }
                }
            }
            Section("Prediction") {
                prediction
            }
        }
        .task(id: choice) {
            if models[choice] == nil {
                models[choice] = try? choice.train()
            }
        }
    }

    @ViewBuilder private var prediction: some View {
        if let model = models[choice], let probabilities = try? model.probabilities(measurements) {
            ForEach(model.classes, id: \.self) { species in
                let probability = probabilities[species] ?? 0
                VStack(alignment: .leading) {
                    Text("\(species): \(probability.formatted(.percent.precision(.fractionLength(0))))")
                    ProgressView(value: probability)
                }
            }
        } else {
            ProgressView("Training…")
        }
    }
}

/// The decision boundaries of four models, as in the README image.
struct BoundariesView: View {
    @State private var panels: [BoundaryPanel] = []

    var body: some View {
        ScrollView {
            if panels.isEmpty {
                ProgressView("Training four models…").padding()
            } else if let samples = try? BoundaryPanel.petalData() {
                DecisionBoundaryGallery(panels: panels, samples: samples)
            }
        }
        .task {
            panels = await Task.detached { (try? BoundaryPanel.iris()) ?? [] }.value
        }
    }
}
