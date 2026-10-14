import Foundation

/// Functions that compare predictions with the true values.
///
/// Models offer the same measures through ``Classifier/evaluate(on:)`` and
/// ``Regressor/evaluate(on:)``; use these functions when you have predictions from elsewhere.
public enum Metrics {
    /// The share of predictions that equal the actual label, from 0 to 1.
    ///
    /// - Throws: ``SwiftAIError/emptyDataset`` for empty input,
    ///   ``SwiftAIError/sampleCountMismatch(features:targets:)`` when the counts differ.
    public static func accuracy<Label: Equatable>(actual: [Label], predicted: [Label]) throws -> Double {
        try checkPairs(actual.count, predicted.count)
        let correct = zip(actual, predicted).filter { $0 == $1 }.count
        return Double(correct) / Double(actual.count)
    }

    /// The mean of the squared differences between actual and predicted values.
    public static func meanSquaredError(actual: [Double], predicted: [Double]) throws -> Double {
        try checkPairs(actual.count, predicted.count)
        return zip(actual, predicted).map { ($0 - $1) * ($0 - $1) }.reduce(0, +) / Double(actual.count)
    }

    /// The mean of the absolute differences between actual and predicted values.
    public static func meanAbsoluteError(actual: [Double], predicted: [Double]) throws -> Double {
        try checkPairs(actual.count, predicted.count)
        return zip(actual, predicted).map { abs($0 - $1) }.reduce(0, +) / Double(actual.count)
    }

    /// The coefficient of determination, R².
    ///
    /// 1 means the predictions are exact, 0 means they are as good as predicting the mean, and
    /// negative values are worse than that. When all actual values are equal, the result is 1 for
    /// exact predictions and 0 otherwise.
    public static func r2Score(actual: [Double], predicted: [Double]) throws -> Double {
        try checkPairs(actual.count, predicted.count)
        let mean = actual.reduce(0, +) / Double(actual.count)
        let residual = zip(actual, predicted).map { ($0 - $1) * ($0 - $1) }.reduce(0, +)
        let total = actual.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
        guard total > 0 else { return residual == 0 ? 1 : 0 }
        return 1 - residual / total
    }

    /// The mean negative log-likelihood of the actual classes (cross-entropy).
    ///
    /// - Parameters:
    ///   - actual: The index of the true class of each sample.
    ///   - probabilities: For each sample, the predicted probability of every class.
    /// - Throws: ``SwiftAIError/invalidParameter(name:reason:)`` when a class index has no probability.
    public static func logLoss(actual: [Int], probabilities: [[Double]]) throws -> Double {
        try checkPairs(actual.count, probabilities.count)
        let epsilon = 1e-15
        var total = 0.0
        for (classIndex, row) in zip(actual, probabilities) {
            guard row.indices.contains(classIndex) else {
                throw SwiftAIError.invalidParameter(name: "actual", reason: "class index \(classIndex) has no probability")
            }
            total -= log(min(max(row[classIndex], epsilon), 1 - epsilon))
        }
        return total / Double(actual.count)
    }

    static func checkPairs(_ actual: Int, _ predicted: Int) throws {
        guard actual > 0 else { throw SwiftAIError.emptyDataset }
        guard actual == predicted else {
            throw SwiftAIError.sampleCountMismatch(features: actual, targets: predicted)
        }
    }
}

/// Error measures for a regression model.
public struct RegressionReport: Sendable, Equatable {
    /// The number of samples compared.
    public let count: Int
    /// The mean squared error.
    public let meanSquaredError: Double
    /// The square root of the mean squared error, in the unit of the target.
    public let rootMeanSquaredError: Double
    /// The mean absolute error, in the unit of the target.
    public let meanAbsoluteError: Double
    /// The coefficient of determination; see ``Metrics/r2Score(actual:predicted:)``.
    public let r2: Double

    /// Compares predictions with actual values.
    public init(actual: [Double], predicted: [Double]) throws {
        meanSquaredError = try Metrics.meanSquaredError(actual: actual, predicted: predicted)
        rootMeanSquaredError = meanSquaredError.squareRoot()
        meanAbsoluteError = try Metrics.meanAbsoluteError(actual: actual, predicted: predicted)
        r2 = try Metrics.r2Score(actual: actual, predicted: predicted)
        count = actual.count
    }
}
