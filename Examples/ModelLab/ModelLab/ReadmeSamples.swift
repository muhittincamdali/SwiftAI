// The code samples in README.md are copied from this file. The ModelLab app and the package's
// test target (through the symlink Tests/SwiftAITests/ReadmeExamples.swift) both compile it, and
// the tests run every sample and check its result.

import Foundation
import SwiftAI
#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(SwiftUI)
/// The quick start: paste into ContentView.swift of a new app.
struct ContentView: View {
    var body: some View {
        Text(irisSummary())
            .padding()
    }

    func irisSummary() -> String {
        do {
            // 1. Split the built-in iris flowers into training and test samples.
            let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.2, seed: 42)
            // 2. Train a random forest on the training samples.
            let model = try RandomForestClassifier.fit(training, seed: 42)
            // 3. Measure it on the test samples and classify a new flower.
            let accuracy = try model.accuracy(on: test)
            let species = try model.predict([6.3, 2.8, 5.1, 1.5])
            return "Test accuracy: \(accuracy.formatted(.percent))\nNew flower: \(species)"
        } catch {
            return error.localizedDescription
        }
    }
}
#endif

/// Usage: load your own data.
func loadCSV() throws -> Dataset<String> {
    let csv = """
        petal_length,petal_width,species
        1.4,0.2,setosa
        4.7,1.4,versicolor
        6.0,2.5,virginica
        1.3,0.2,setosa
        4.5,1.5,versicolor
        5.1,1.9,virginica
        """
    let table = try CSVTable(csv)   // or CSVTable(contentsOf: fileURL)
    return try table.classificationDataset(target: "species")
}

/// Usage: scale features and train a classifier.
func scaledClassifier() throws -> ClassificationReport<String> {
    let (training, test) = try Dataset.iris.stratifiedSplit(testFraction: 0.3, seed: 1)
    let model = try Pipeline.fit(training, transformer: StandardScaler.fit) { scaled in
        try LogisticRegression.fit(scaled)
    }
    let report = try model.evaluate(on: test)
    print(report)                       // precision, recall and F1 per class
    print(report.confusionMatrix)
    return report
}

/// Usage: predict a number.
func predictPrice() throws -> Double {
    // Size in square metres and number of rooms → price.
    let houses = try Dataset<Double>(
        features: [[50, 1], [65, 2], [80, 2], [95, 3], [120, 3], [140, 4]],
        targets: [150_000, 190_000, 236_000, 280_000, 350_000, 405_000]
    )
    let model = try LinearRegression.fit(houses, regularization: 0.1)
    return try model.predict([100, 3])
}

/// Usage: compare models with cross-validation.
func compareModels() throws -> [String: CrossValidationResult] {
    let data = Dataset.iris
    return [
        "k-nearest neighbours": try data.crossValidate(folds: 5) { try KNearestNeighborsClassifier.fit($0, k: 7) },
        "naive Bayes": try data.crossValidate(folds: 5) { try GaussianNaiveBayes.fit($0) },
        "decision tree": try data.crossValidate(folds: 5) { try DecisionTreeClassifier.fit($0, maxDepth: 3) },
    ]
}

/// Usage: save a trained model and load it in the app.
func saveAndLoad() throws -> RandomForestClassifier<String> {
    let model = try RandomForestClassifier.fit(Dataset.iris, treeCount: 50, seed: 7)
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("iris-forest.json")

    try JSONEncoder().encode(model).write(to: file)
    let data = try Data(contentsOf: file)
    let loaded = try JSONDecoder().decode(RandomForestClassifier<String>.self, from: data)
    return loaded   // predicts exactly like `model`
}

/// Usage: find groups without labels.
func findClusters() throws -> (clusters: [Int], explained: [Double]) {
    let features = Dataset.iris.features
    let pca = try PrincipalComponentAnalysis.fit(features, componentCount: 2)
    let points = try pca.transform(features)          // 150 × 2, for a scatter plot
    let kMeans = try KMeans.fit(points, clusterCount: 3, seed: 1)
    return (try kMeans.predict(points), pca.explainedVarianceRatio)
}
