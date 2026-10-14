/// Counts of actual versus predicted labels.
///
/// Row `i`, column `j` counts the samples whose actual label is `classes[i]` and whose predicted
/// label is `classes[j]`. The diagonal holds the correct predictions.
public struct ConfusionMatrix<Label: Hashable & Sendable>: Sendable, Equatable {
    /// The labels of the rows and columns.
    public let classes: [Label]
    /// The counts, indexed `[actual][predicted]`.
    public let counts: [[Int]]

    /// Counts the pairs of actual and predicted labels.
    ///
    /// - Parameters:
    ///   - actual: The true label of each sample.
    ///   - predicted: The predicted label of each sample, in the same order.
    ///   - classes: The row and column order. Labels that appear in the data but not here are
    ///     appended in order of first appearance. Defaults to the order of first appearance.
    /// - Throws: ``SwiftAIError/emptyDataset`` or
    ///   ``SwiftAIError/sampleCountMismatch(features:targets:)``.
    public init(actual: [Label], predicted: [Label], classes: [Label] = []) throws {
        try Metrics.checkPairs(actual.count, predicted.count)
        let index = ClassIndex(classes + actual + predicted)
        var counts = Array(repeating: Array(repeating: 0, count: index.classes.count), count: index.classes.count)
        for (truth, guess) in zip(index.encode(actual), index.encode(predicted)) {
            counts[truth][guess] += 1
        }
        self.classes = index.classes
        self.counts = counts
    }

    /// The number of samples with this actual and predicted label (0 for unknown labels).
    public subscript(actual actual: Label, predicted predicted: Label) -> Int {
        guard let row = classes.firstIndex(of: actual), let column = classes.firstIndex(of: predicted) else {
            return 0
        }
        return counts[row][column]
    }

    /// The number of samples counted.
    public var total: Int {
        counts.joined().reduce(0, +)
    }

    /// The number of correct predictions (the diagonal).
    public var correct: Int {
        classes.indices.map { counts[$0][$0] }.reduce(0, +)
    }
}

extension ConfusionMatrix: CustomStringConvertible {
    /// A text table with actual labels as rows and predicted labels as columns.
    public var description: String {
        let names = classes.map { "\($0)" }
        let width = max(names.map(\.count).max() ?? 0, counts.joined().map { "\($0)".count }.max() ?? 0, 6)
        func pad(_ text: String) -> String {
            String(repeating: " ", count: max(width - text.count, 0)) + text
        }
        var lines = [pad("actual") + " | " + names.map(pad).joined(separator: " ")]
        for (row, name) in names.enumerated() {
            lines.append(pad(name) + " | " + counts[row].map { pad("\($0)") }.joined(separator: " "))
        }
        return lines.joined(separator: "\n")
    }
}
