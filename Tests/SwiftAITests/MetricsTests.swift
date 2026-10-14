import Testing
@testable import SwiftAI

@Suite("Metrics")
struct MetricsTests {
    let actual = ["a", "a", "b", "b", "c"]
    let predicted = ["a", "b", "b", "b", "a"]

    @Test("Confusion matrix counts actual against predicted labels")
    func confusionMatrix() throws {
        let matrix = try ConfusionMatrix(actual: actual, predicted: predicted)
        #expect(matrix.classes == ["a", "b", "c"])
        #expect(matrix.counts == [[1, 1, 0], [0, 2, 0], [1, 0, 0]])
        #expect(matrix.total == 5)
        #expect(matrix.correct == 3)
        #expect(matrix[actual: "c", predicted: "a"] == 1)
        #expect(matrix[actual: "z", predicted: "a"] == 0)
    }

    @Test("A given class order comes first; unseen labels follow")
    func confusionMatrixOrder() throws {
        let matrix = try ConfusionMatrix(actual: actual, predicted: predicted, classes: ["c", "x"])
        #expect(matrix.classes == ["c", "x", "a", "b"])
        #expect(matrix.counts[1] == [0, 0, 0, 0])
    }

    // Reference values from scikit-learn's classification_report with zero_division=0.
    @Test("Per-class precision, recall and F1 match the textbook definitions")
    func classificationReport() throws {
        let report = try ClassificationReport(actual: actual, predicted: predicted)
        #expect(report.accuracy == 0.6)
        let byLabel = Dictionary(uniqueKeysWithValues: report.classMetrics.map { ($0.label, $0) })
        #expect(byLabel["a"]?.precision == 0.5)
        #expect(byLabel["a"]?.recall == 0.5)
        #expect(abs(byLabel["b"]!.precision - 2.0 / 3.0) < 1e-12)
        #expect(byLabel["b"]?.recall == 1)
        #expect(abs(byLabel["b"]!.f1Score - 0.8) < 1e-12)
        #expect(byLabel["c"] == ClassMetrics(label: "c", precision: 0, recall: 0, f1Score: 0, support: 1))
        #expect(abs(report.macroF1Score - 1.3 / 3) < 1e-12)
        #expect(abs(report.weightedF1Score - 0.52) < 1e-12)
    }

    @Test("The printed report has a row per class and the accuracy line")
    func reportDescription() throws {
        let text = try ClassificationReport(actual: actual, predicted: predicted).description
        #expect(text.contains("accuracy 0.600 (3 of 5)"))
        #expect(text.contains("    0.667     1.000     0.800         2"))
        #expect(text.contains("actual |"))
    }

    // Example from the scikit-learn documentation of r2_score and mean_squared_error.
    @Test("Regression errors match the reference example")
    func regressionReport() throws {
        let report = try RegressionReport(actual: [3, -0.5, 2, 7], predicted: [2.5, 0, 2, 8])
        #expect(report.count == 4)
        #expect(report.meanSquaredError == 0.375)
        #expect(report.meanAbsoluteError == 0.5)
        #expect(abs(report.rootMeanSquaredError - 0.375.squareRoot()) < 1e-15)
        #expect(abs(report.r2 - 0.9486081370449679) < 1e-12)
    }

    @Test("R² of constant targets is 1 for exact predictions and 0 otherwise")
    func constantTargets() throws {
        #expect(try Metrics.r2Score(actual: [2, 2, 2], predicted: [2, 2, 2]) == 1)
        #expect(try Metrics.r2Score(actual: [2, 2, 2], predicted: [2, 2, 3]) == 0)
    }

    // Example from the scikit-learn documentation of log_loss (classes ham = 0, spam = 1).
    @Test("Log loss matches the reference example and clips zero probabilities")
    func logLoss() throws {
        let loss = try Metrics.logLoss(
            actual: [1, 0, 0, 1],
            probabilities: [[0.1, 0.9], [0.9, 0.1], [0.8, 0.2], [0.35, 0.65]]
        )
        #expect(abs(loss - 0.21616187468057912) < 1e-12)
        let clipped = try Metrics.logLoss(actual: [0], probabilities: [[0, 1]])
        #expect(clipped.isFinite)
        #expect(throws: SwiftAIError.self) {
            try Metrics.logLoss(actual: [2], probabilities: [[0.5, 0.5]])
        }
    }

    @Test("Empty or mismatched inputs throw instead of dividing by zero")
    func invalidInput() {
        #expect(throws: SwiftAIError.emptyDataset) {
            try Metrics.accuracy(actual: [String](), predicted: [])
        }
        #expect(throws: SwiftAIError.sampleCountMismatch(features: 2, targets: 1)) {
            try Metrics.meanSquaredError(actual: [1, 2], predicted: [1])
        }
        #expect(throws: SwiftAIError.emptyDataset) {
            try ClassificationReport<Int>(actual: [], predicted: [])
        }
    }
}
