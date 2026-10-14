import Foundation

/// Precision, recall and F1 score of one class.
public struct ClassMetrics<Label: Hashable & Sendable>: Sendable, Equatable {
    /// The class.
    public let label: Label
    /// Of the samples predicted as this class, the share that really are (0 when none were predicted).
    public let precision: Double
    /// Of the samples that really are this class, the share predicted as it (0 when there are none).
    public let recall: Double
    /// The harmonic mean of precision and recall (0 when both are 0).
    public let f1Score: Double
    /// The number of samples that really are this class.
    public let support: Int
}

/// How well a classifier did on a set of samples.
///
/// ```swift
/// let report = try model.evaluate(on: test)
/// report.accuracy            // 0.9666…
/// print(report)              // per-class table and confusion matrix
/// ```
public struct ClassificationReport<Label: Hashable & Sendable>: Sendable, Equatable {
    /// The share of correct predictions.
    public let accuracy: Double
    /// Precision, recall and F1 score of each class, in the order of ``ConfusionMatrix/classes``.
    public let classMetrics: [ClassMetrics<Label>]
    /// The counts behind the other values.
    public let confusionMatrix: ConfusionMatrix<Label>

    /// Compares predicted with actual labels.
    ///
    /// - Parameter classes: The order of the classes in the report; see
    ///   ``ConfusionMatrix/init(actual:predicted:classes:)``.
    public init(actual: [Label], predicted: [Label], classes: [Label] = []) throws {
        let matrix = try ConfusionMatrix(actual: actual, predicted: predicted, classes: classes)
        confusionMatrix = matrix
        accuracy = Double(matrix.correct) / Double(matrix.total)
        classMetrics = matrix.classes.indices.map { Self.metrics(for: $0, in: matrix) }
    }

    /// The unweighted mean F1 score over the classes that occur in the actual labels.
    public var macroF1Score: Double {
        let present = classMetrics.filter { $0.support > 0 }
        return present.map(\.f1Score).reduce(0, +) / Double(max(present.count, 1))
    }

    /// The mean F1 score weighted by the number of samples of each class.
    public var weightedF1Score: Double {
        let total = classMetrics.map(\.support).reduce(0, +)
        return classMetrics.map { $0.f1Score * Double($0.support) }.reduce(0, +) / Double(max(total, 1))
    }

    private static func metrics(for index: Int, in matrix: ConfusionMatrix<Label>) -> ClassMetrics<Label> {
        let truePositives = Double(matrix.counts[index][index])
        let predictedCount = Double(matrix.counts.map { $0[index] }.reduce(0, +))
        let support = matrix.counts[index].reduce(0, +)
        let precision = predictedCount > 0 ? truePositives / predictedCount : 0
        let recall = support > 0 ? truePositives / Double(support) : 0
        let f1 = precision + recall > 0 ? 2 * precision * recall / (precision + recall) : 0
        return ClassMetrics(label: matrix.classes[index], precision: precision, recall: recall, f1Score: f1, support: support)
    }
}

extension ClassificationReport: CustomStringConvertible {
    /// A text table of the per-class values, the accuracy and the confusion matrix.
    public var description: String {
        let names = classMetrics.map { "\($0.label)" }
        let width = max(names.map(\.count).max() ?? 0, 9)
        func column(_ text: String, _ size: Int) -> String {
            String(repeating: " ", count: max(size - text.count, 0)) + text
        }
        func number(_ value: Double) -> String {
            column(String(format: "%.3f", value), 9)
        }
        var lines = [column("", width) + column("precision", 10) + column("recall", 10) + column("f1", 10) + column("support", 10)]
        for (metrics, name) in zip(classMetrics, names) {
            lines.append(
                column(name, width) + " " + number(metrics.precision) + " " + number(metrics.recall) + " "
                    + number(metrics.f1Score) + column("\(metrics.support)", 10)
            )
        }
        lines.append("")
        lines.append("accuracy \(String(format: "%.3f", accuracy)) (\(confusionMatrix.correct) of \(confusionMatrix.total))")
        lines.append("")
        lines.append(confusionMatrix.description)
        return lines.joined(separator: "\n")
    }
}
